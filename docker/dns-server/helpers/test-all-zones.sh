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

print_usage() {
    cat << 'USAGE'
Usage:
  ./test-all-zones.sh [server] [test_ptr] [query_delay]

  server        DNS server to query (default: development-002.containers.max.lan)
  test_ptr      true|false - run PTR checks at all (default: true)
                PTR checks only actually run for IPs matching PTR_ENABLED_PREFIX
                (currently 192.168.1.), everything else is skipped automatically
                since those reverse zones were deleted.
  query_delay   seconds to sleep between queries, e.g. 0.05 (default: 0)
                Use this against Pi-hole to avoid tripping its rate limiter.

Examples:
  ./test-all-zones.sh                                           # Technitium, PTR on, no delay
  ./test-all-zones.sh development-002.containers.max.lan true   # same, explicit
  ./test-all-zones.sh gw-homelab-dns.max.lan false               # old dnsmasq server, PTR off
  ./test-all-zones.sh 10.24.19.20 false 0.05                     # Pi-hole, paced to avoid rate limiting

Back-to-back comparison:
  ./test-all-zones.sh <old-dnsmasq-server> false > old-results.log
  ./test-all-zones.sh <new-technitium-server> true > new-results.log
  diff old-results.log new-results.log
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    print_usage
    exit 0
fi

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../../secrets-helper.sh"
RECORDS_JSON=$(get_secret "apps/technitium/technitium-dns-server-initial-records.secret.age")

SERVER="${1:-dns-001.dns.gregrob.net}"
TEST_PTR="${2:-true}"
QUERY_DELAY="${3:-0}"

echo "Server: ${SERVER}  |  PTR: ${TEST_PTR}  |  Query delay: ${QUERY_DELAY}s  (run with -h for usage)"

PASS=0
FAIL=0
FAILED_ITEMS=()

check_a() {
    local name="$1" expected_ip="$2"
    local actual
    actual=$(dig @"${SERVER}" "${name}" A +short +timeout=2 +tries=1 2>/dev/null </dev/null | tail -n1) || true
    if [ "${actual}" = "${expected_ip}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("A     ${name}  expected=${expected_ip}  got=${actual:-<empty>}")
    fi
    if [ "${QUERY_DELAY}" != "0" ]; then
        sleep "${QUERY_DELAY}"
    fi
}

check_cname() {
    local name="$1" expected_ip="$2"
    local actual
    actual=$(dig @"${SERVER}" "${name}" A +short +timeout=2 +tries=1 2>/dev/null </dev/null | tail -n1) || true
    if [ "${actual}" = "${expected_ip}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("CNAME ${name}  expected_ip=${expected_ip}  got=${actual:-<empty>}")
    fi
    if [ "${QUERY_DELAY}" != "0" ]; then
        sleep "${QUERY_DELAY}"
    fi
}

check_ptr() {
    local ip="$1" expected_name="$2"
    local actual
    actual=$(dig @"${SERVER}" -x "${ip}" +short +timeout=2 +tries=1 2>/dev/null </dev/null | sed 's/\.$//') || true
    if [ "${actual,,}" = "${expected_name,,}" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        FAILED_ITEMS+=("PTR   ${ip}  expected=${expected_name}  got=${actual:-<empty>}")
    fi
    if [ "${QUERY_DELAY}" != "0" ]; then
        sleep "${QUERY_DELAY}"
    fi
}

echo "=== Testing A records ==="
mapfile -t A_LINES < <(echo "${RECORDS_JSON}" | jq -r '.a_records[] | [.name, .ip] | @tsv')
TOTAL_A=${#A_LINES[@]}
i=0
for line in "${A_LINES[@]}"; do
    IFS=$'\t' read -r name ip <<< "${line}"
    check_a "${name}" "${ip}"
    i=$((i+1))
    if [ $((i % 20)) -eq 0 ]; then
        echo "  ...${i}/${TOTAL_A} A records checked"
    fi
done

echo "=== Testing CNAME records ==="
mapfile -t CNAME_LINES < <(echo "${RECORDS_JSON}" | jq -r '.cname_records[] | [.name, .target] | @tsv')
for line in "${CNAME_LINES[@]}"; do
    IFS=$'\t' read -r name target <<< "${line}"
    target_ip=$(echo "${RECORDS_JSON}" | jq -r --arg t "${target}" '.a_records[] | select(.name==$t) | .ip' | head -n1)
    [ -n "${target_ip}" ] && check_cname "${name}" "${target_ip}"
done

PTR_ENABLED_PREFIX="192.168.1."   # only test PTR for IPs where a reverse zone still exists (match cleanup-reverse-zones.sh's KEEP_ZONE)

if [ "${TEST_PTR}" = "true" ]; then
    echo "=== Testing PTR records (only for ${PTR_ENABLED_PREFIX}x, others skipped) ==="
    i=0
    skipped=0
    for line in "${A_LINES[@]}"; do
        IFS=$'\t' read -r name ip <<< "${line}"
        case "${ip}" in
            ${PTR_ENABLED_PREFIX}*)
                check_ptr "${ip}" "${name}"
                ;;
            *)
                skipped=$((skipped+1))
                ;;
        esac
        i=$((i+1))
        if [ $((i % 20)) -eq 0 ]; then
            echo "  ...${i}/${TOTAL_A} processed (${skipped} skipped, no reverse zone)"
        fi
    done
    echo "  Skipped ${skipped} records outside ${PTR_ENABLED_PREFIX}x (no reverse zone)"
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
