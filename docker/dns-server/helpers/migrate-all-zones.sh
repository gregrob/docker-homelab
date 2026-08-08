#!/usr/bin/env bash
#
# Technitium migration script. Contains NO hostnames or IPs, safe for a public
# repo. All actual DNS data (zones, A records, CNAMEs) is loaded at runtime
# from an encrypted secret via get_secret, so only ciphertext ever touches git.
#
# Secret expected at: dns/technitium-records.secret.age
# Format: JSON, same shape as parsed.json produced by parse.py:
#   {
#     "a_records":     [{"zone": "...", "name": "...", "ip": "..."}, ...],
#     "cname_records": [{"zone": "...", "name": "...", "target": "..."}, ...]
#   }
#
# Zone plan (see /docs or your own notes for the reasoning):
#   - One Primary zone per genuine VLAN/subnet boundary.
#   - Everything else lives as nested records inside the flat "max.lan" zone.
#
# Usage:
#   1. In Technitium web console: Administration -> Sessions -> Create Token
#   2. Store that token as apps/technitium/technitium-dns-server-api-token.secret.age
#   3. Store your records JSON as dns/technitium-records.secret.age
#   4. Make sure jq is installed: apt install -y jq
#   5. chmod +x migrate-all-zones.sh && ./migrate-all-zones.sh
#
# Safe to re-run: zone creation ignores "already exists" errors, and
# add_record/add_cname use overwrite=true.

set -euo pipefail

SERVER="http://dns-001.dns.gregrob.net:5380"

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../../secrets-helper.sh"
TOKEN=$(get_secret "apps/technitium/technitium-dns-server-api-token.secret.age")
RECORDS_JSON=$(get_secret "apps/technitium/technitium-dns-server-initial-records.secret.age")

TTL=3600
RESPONSIBLE_PERSON="gregrob@mac.com"

# ---- Toggles ----
ENABLE_PTR="false"                     # dont create PTR records + reverse zones for the A records below
ENABLE_CONDITIONAL_FORWARDER="true"    # forward reverse (PTR) lookups for DHCP clients to the router
ROUTER_IP="10.24.19.1"                 # router doing DHCP, mirrors dnsmasq's rev-server= line
DHCP_REVERSE_ZONE="24.10.in-addr.arpa" # reverse zone for 10.24.0.0/16

fix_reverse_zone_soas() {
    echo "Finding auto-created reverse zones to fix SOA on..."
    local zones_json
    zones_json=$(curl -s -G "${SERVER}/api/zones/list" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "pageNumber=1" \
        --data-urlencode "zonesPerPage=1000")

    local reverse_zones
    reverse_zones=$(echo "$zones_json" | jq -r '.response.zones[] | select(.type=="Primary") | select(.name | endswith("in-addr.arpa")) | .name')

    for rz in $reverse_zones; do
        set_responsible_person "$rz"
    done
}

create_conditional_forwarder() {
    if [ "${ENABLE_CONDITIONAL_FORWARDER}" != "true" ]; then
        echo "Skipping conditional forwarder (disabled)"
        return
    fi
    echo "Creating conditional forwarder: ${DHCP_REVERSE_ZONE} -> ${ROUTER_IP}"
    curl -s -G "${SERVER}/api/zones/create" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${DHCP_REVERSE_ZONE}" \
        --data-urlencode "type=Forwarder" \
        --data-urlencode "forwarder=${ROUTER_IP}" \
        --data-urlencode "protocol=Udp" \
        --data-urlencode "initializeForwarder=true" \
        --data-urlencode "useSoaSerialDateScheme=true" \
        | grep -o '"status":"[^"]*"' || true
    set_responsible_person "${DHCP_REVERSE_ZONE}"
}

create_zone() {
    local zone="$1"
    echo "Creating zone: ${zone}"
    curl -s -G "${SERVER}/api/zones/create" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "type=Primary" \
        --data-urlencode "useSoaSerialDateScheme=true" \
        | grep -o '"status":"[^"]*"' || true
}

set_responsible_person() {
    local zone="$1"
    echo "Setting responsible person for ${zone}: ${RESPONSIBLE_PERSON}"

    local soa
    soa=$(curl -s -G "${SERVER}/api/zones/records/get" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "domain=${zone}" \
        --data-urlencode "listZone=false")

    local mname serial refresh retry expire minimum
    mname=$(echo "$soa"   | jq -r '.response.records[] | select(.type=="SOA") | .rData.primaryNameServer')
    serial=$(echo "$soa"  | jq -r '.response.records[] | select(.type=="SOA") | .rData.serial')
    refresh=$(echo "$soa" | jq -r '.response.records[] | select(.type=="SOA") | .rData.refresh')
    retry=$(echo "$soa"   | jq -r '.response.records[] | select(.type=="SOA") | .rData.retry')
    expire=$(echo "$soa"  | jq -r '.response.records[] | select(.type=="SOA") | .rData.expire')
    minimum=$(echo "$soa" | jq -r '.response.records[] | select(.type=="SOA") | .rData.minimum')

    curl -s -G "${SERVER}/api/zones/records/update" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "domain=${zone}" \
        --data-urlencode "type=SOA" \
        --data-urlencode "primaryNameServer=${mname}" \
        --data-urlencode "responsiblePerson=${RESPONSIBLE_PERSON}" \
        --data-urlencode "serial=${serial}" \
        --data-urlencode "refresh=${refresh}" \
        --data-urlencode "retry=${retry}" \
        --data-urlencode "expire=${expire}" \
        --data-urlencode "minimum=${minimum}" \
        --data-urlencode "useSerialDateScheme=true" \
        | grep -o '"status":"[^"]*"' || true
}

add_record() {
    local zone="$1" name="$2" ip="$3"
    echo "  A     ${name}  ->  ${ip}"
    local ptr_args=()
    if [ "${ENABLE_PTR}" = "true" ]; then
        ptr_args=(--data-urlencode "ptr=true" --data-urlencode "createPtrZone=true")
    fi
    curl -s -G "${SERVER}/api/zones/records/add" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "domain=${name}" \
        --data-urlencode "type=A" \
        --data-urlencode "ipAddress=${ip}" \
        --data-urlencode "ttl=${TTL}" \
        --data-urlencode "overwrite=true" \
        "${ptr_args[@]}" \
        | grep -o '"status":"[^"]*"' || true
}

add_cname() {
    local zone="$1" name="$2" target="$3"
    echo "  CNAME ${name}  ->  ${target}"
    curl -s -G "${SERVER}/api/zones/records/add" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "domain=${name}" \
        --data-urlencode "type=CNAME" \
        --data-urlencode "cname=${target}" \
        --data-urlencode "ttl=${TTL}" \
        --data-urlencode "overwrite=true" \
        | grep -o '"status":"[^"]*"' || true
}

# ---- Zones (derived from the secret data, not hardcoded) ----
ZONES=$(echo "${RECORDS_JSON}" | jq -r '[.a_records[].zone, .cname_records[].zone] | unique | .[]')
for z in ${ZONES}; do
    create_zone "${z}"
    set_responsible_person "${z}"
done

# ---- A records ----
echo "${RECORDS_JSON}" | jq -r '.a_records[] | [.zone, .name, .ip] | @tsv' | \
while IFS=$'\t' read -r zone name ip; do
    add_record "${zone}" "${name}" "${ip}"
done

# ---- CNAME records ----
echo "${RECORDS_JSON}" | jq -r '.cname_records[] | [.zone, .name, .target] | @tsv' | \
while IFS=$'\t' read -r zone name target; do
    add_cname "${zone}" "${name}" "${target}"
done

echo "Fixing SOA on any auto-created reverse zones..."
fix_reverse_zone_soas

echo "Creating conditional forwarder for DHCP client PTRs..."
create_conditional_forwarder

echo "Done."
