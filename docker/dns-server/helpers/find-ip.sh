#!/usr/bin/env bash
#
# Searches every forward (non-reverse) Primary zone on Technitium for A records
# matching a given IP, and prints the name(s) found. Useful once PTR zones are
# mostly gone, since dig -x won't work for those ranges anymore.
#
# Usage:
#   ./find-ip.sh 192.168.1.1
#   ./find-ip.sh 10.24.4.67

set -euo pipefail

SERVER="http://dns-001.dns.gregrob.net:5380"

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../../secrets-helper.sh"
TOKEN=$(get_secret "apps/technitium/technitium-dns-server-api-token.secret.age")

TARGET_IP="${1:-}"
if [ -z "$TARGET_IP" ]; then
    echo "Usage: $0 <ip-address>"
    exit 1
fi

zones_json=$(curl -s -G "${SERVER}/api/zones/list" \
    --data-urlencode "token=${TOKEN}" \
    --data-urlencode "pageNumber=1" \
    --data-urlencode "zonesPerPage=1000")

forward_zones=$(echo "$zones_json" | jq -r \
    '.response.zones[] | select(.type=="Primary") | select(.name | endswith("in-addr.arpa") | not) | .name')

found=0
for zone in $forward_zones; do
    records_json=$(curl -s -G "${SERVER}/api/zones/records/get" \
        --data-urlencode "token=${TOKEN}" \
        --data-urlencode "zone=${zone}" \
        --data-urlencode "domain=${zone}" \
        --data-urlencode "listZone=true")

    matches=$(echo "$records_json" | jq -r --arg ip "$TARGET_IP" \
        '.response.records[] | select(.type=="A") | select(.rData.ipAddress==$ip) | .name')

    for name in $matches; do
        [ -z "$name" ] && continue
        echo "${name}  (zone: ${zone})"
        found=1
    done
done

if [ "$found" -eq 0 ]; then
    echo "No A record found for ${TARGET_IP}"
fi
