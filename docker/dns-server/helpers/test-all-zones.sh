#!/usr/bin/env bash
#
# Verifies every record from the records secret actually resolves correctly.
# Contains NO hostnames or IPs, safe for a public repo. Loads expected data
# at runtime from the same secret migrate-all-zones.sh uses.
#
# Usage:
#   chmod +x test-all-zones.sh
#   ./test-all-zones.sh                                          # test Technitium, PTR on
#   ./test-all-zones.sh development-002.containers.max.lan true  # same, explicit
#   ./test-all-zones.sh gw-homelab-dns.max.lan false              # test old dnsmasq server, PTR off
#   ./test-all-zones.sh 10.24.19.20 false 0.05                    # add delay to avoid Pi-hole rate limiting
#
# Run against BOTH servers and diff the logs for a true back-to-back comparison:
#   ./test-all-zones.sh <old-dnsmasq-server> false > old-results.log
#   ./test-all-zones.sh <new-technitium-server> true > new-results.log
#   diff old-results.log new-results.log

set -euo pipefail

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../../secrets-helper.sh"
RECORDS_JSON=$(get_secret "apps/technitium/technitium-dns-server-initial-records.secret.age")

SERVER="${1:-development-002.containers.max.lan}"
TEST_PTR="${2:-true}"
QUERY_DELAY="${3:-0}"

PASS=0
FAIL=0
FAILED_ITEMS=()

check_a() {
    local name="$1" expected_ip="$2"
    local actual
    actual=$(dig @"${SERVER}" "${name}" A +short | tail -n1)
    if [ "${actual}" = "${expected_ip}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("A     ${name}  expected=${expected_ip}  got=${actual:-<empty>}")
    fi
    [ "${QUERY_DELAY}" != "0" ] && sleep "${QUERY_DELAY}"
}

check_cname() {
    local name="$1" expected_ip="$2"
    local actual
    actual=$(dig @"${SERVER}" "${name}" A +short | tail -n1)
    if [ "${actual}" = "${expected_ip}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("CNAME ${name}  expected_ip=${expected_ip}  got=${actual:-<empty>}")
    fi
    [ "${QUERY_DELAY}" != "0" ] && sleep "${QUERY_DELAY}"
}

check_ptr() {
    local ip="$1" expected_name="$2"
    local actual
    actual=$(dig @"${SERVER}" -x "${ip}" +short | sed 's/\.$//')
    if [ "${actual,,}" = "${expected_name,,}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("PTR   ${ip}  expected=${expected_name}  got=${actual:-<empty>}")
    fi
    [ "${QUERY_DELAY}" != "0" ] && sleep "${QUERY_DELAY}"
}

echo "=== Testing A records ==="
while IFS=$'\t' read -r name ip; do
    check_a "${name}" "${ip}"
done < <(echo "${RECORDS_JSON}" | jq -r '.a_records[] | [.name, .ip] | @tsv')

echo "=== Testing CNAME records ==="
while IFS=$'\t' read -r name target; do
    target_ip=$(echo "${RECORDS_JSON}" | jq -r --arg t "${target}" '.a_records[] | select(.name==$t) | .ip' | head -n1)
    [ -n "${target_ip}" ] && check_cname "${name}" "${target_ip}"
done < <(echo "${RECORDS_JSON}" | jq -r '.cname_records[] | [.name, .target] | @tsv')

if [ "${TEST_PTR}" = "true" ]; then
    echo "=== Testing PTR records ==="
    while IFS=$'\t' read -r name ip; do
        check_ptr "${ip}" "${name}"
    done < <(echo "${RECORDS_JSON}" | jq -r '.a_records[] | [.name, .ip] | @tsv')
fi

echo ""
echo "=== Results ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
if [ "${FAIL}" -gt 0 ]; then
    echo ""
    echo "Failed items:"
    for item in "${FAILED_ITEMS[@]}"; do
        echo "  - ${item}"
    done
    exit 1
fi
echo "All checks passed."
