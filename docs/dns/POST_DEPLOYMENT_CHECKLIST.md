# DNS HA / Load Balancing — Post-Deployment Checklist

Run through in order — each step is cheaper/lower-risk than the next, so a
failure early on saves you from chasing something confusing further down.
See `DNS_HA_LB_ARCHITECTURE.md` for the "why" behind anything referenced
here, and its Debug Command Reference for stage-by-stage troubleshooting
if a step fails.

## 1. Playbook idempotency

```bash
ansible-playbook -i inventories/local/hosts.yaml playbooks/configure-keepalived-dns.yaml --ask-vault-pass -e skip_confirmation=true
```
A clean second run reporting `changed=0` confirms the role isn't flapping
or re-applying the same thing differently each run.

## 2. Docker host networking

```bash
sudo docker inspect dns-server --format '{{.HostConfig.NetworkMode}}'   # both nodes: "host"
sudo iptables -t nat -L DOCKER -n -v                                     # both nodes: no dpt:53 rule
```
If a `dpt:53` DNAT rule is present, Docker is still intercepting VIP
traffic before IPVS ever sees it — the single most common root cause of
"load balancing isn't distributing anything" during this build.

## 3. Config matches proven-working ground truth

```bash
sudo cat /etc/keepalived/keepalived.conf
```
Compare against the saved `dns-001-keepalived.conf.txt` / `dns-002-...`
reference files — same `fwmark 1`/`fwmark 2` blocks, same priorities,
same `virtual_router_id`, no leftover IP:port `virtual_server` blocks.

## 4. Peer MAC and check-extra-arg derivation (hostvars cross-lookups, worth re-confirming after any role update)

Add temporary debug tasks right after their respective set_fact tasks in
`tasks/main.yaml` — "Determine peer real server MAC addresses for mangle
rules" and "Determine per-real-server check extra args" — then run once
and confirm:

```yaml
- debug: var=keepalived_peer_macs
- debug: var=keepalived_real_server_extra_args
```

- On `dns-001`: `keepalived_peer_macs` → `["bc:24:11:a9:20:38"]` (dns-002's MAC)
- On `dns-002`: `keepalived_peer_macs` → `["bc:24:11:22:c1:70"]` (dns-001's MAC)
- On both: `keepalived_real_server_extra_args` → `{"10.24.19.30": "<token>", "10.24.19.32": "<token>"}` — same token value on both entries, since it's confirmed cluster-shared (see `DNS_HA_LB_ARCHITECTURE.md`)

Then confirm the deployed mangle rule matches:
```bash
sudo iptables -t mangle -L PREROUTING -n -v --line-numbers
sudo cat /etc/keepalived/scripts/mangle-rules.sh
```
And that the rendered config carries the token through correctly:
```bash
sudo cat /etc/keepalived/keepalived.conf | grep -A2 misc_path
```
Remove both temporary debug tasks once confirmed.

## 5. Services and VRRP state

```bash
sudo systemctl status keepalived
sudo systemctl status keepalived-lb-loopback
sudo systemctl status keepalived-lb-mangle
ip addr show | grep 10.24.19.29    # exactly one node shows it on ens18
```

## 6. IPVS table

```bash
sudo ipvsadm -L -n
```
Expect `FWM 1` and `FWM 2`, both real servers listed at weight 10,
`Route` as the forward method.

## 7. Functional distribution test

Repeat a fresh-domain test sequence (unique names, not previously
queried/cached) from a client machine, capturing on both nodes
simultaneously:
```bash
sudo tcpdump -i ens18 -e -n host 10.24.19.29 and port 53
```
Confirm: no repeated MAC bounce on any single query (the loop stays
fixed), and:
```bash
sudo ipvsadm -L -n --stats
```
`Conns` climbing on **both** real servers across the test.

## 8. Health check itself — manual validation before trusting it end-to-end

```bash
# get the real token keepalived is using right now
sudo grep -A1 misc_path /etc/keepalived/keepalived.conf

# healthy case - should exit 0
/etc/keepalived/scripts/check.sh 10.24.19.30 THE_REAL_TOKEN
echo "exit: $?"

# bad token - should exit non-zero, not hang or false-pass
/etc/keepalived/scripts/check.sh 10.24.19.30 clearly-wrong-token
echo "exit: $?"

# unreachable target with no timeout protection would hang forever - confirm
# it doesn't (should return within roughly keepalived_check_timeout seconds)
time /etc/keepalived/scripts/check.sh 10.24.19.99 THE_REAL_TOKEN
echo "exit: $?"
```

## 9. Health-check integration under IPVS (MISC_CHECK, independent of VRRP)

```bash
docker pause dns-server   # on dns-002 - freezes the process without
                           # tearing down docker-proxy, the scenario
                           # this check was specifically built to catch
sleep 15
sudo ipvsadm -L -n        # dns-002's weight should now show 0, automatically
docker unpause dns-server
sleep 15
sudo ipvsadm -L -n        # weight should return to 10, automatically
```

## 10. Full node failure (VRRP + IPVS together)

**Do not use `systemctl stop keepalived` for this test** — that only
stops VRRP, and leaves the loopback binding, mangle rule, and Technitium
itself fully intact, so the node correctly remains a valid real server
and stays in the IPVS pool. That's expected, not a bug (see
`DNS_HA_LB_ARCHITECTURE.md`) — but it means `systemctl stop keepalived`
alone doesn't exercise the failure path this test is meant to prove.

To genuinely simulate a node going down:
```bash
docker stop dns-server   # on the current MASTER — DNS actually stops
```
Then, from the other node:
```bash
sudo journalctl -u keepalived -f   # watch for MASTER transition (VRRP)
ip addr show | grep 10.24.19.29    # confirm the VIP moved
sudo ipvsadm -L -n                 # confirm the failed node's weight
                                    # dropped to 0 (MISC_CHECK), independent
                                    # of the VRRP transition above
```
Restore with `docker start dns-server` on the stopped node, then confirm
its weight returns to 10 automatically.

## 11. Reboot test — do last, one node at a time

Reboot `dns-002` first (leave `dns-001` serving), and after it comes back
confirm — with **zero manual intervention** —:
```bash
ip addr show | grep 10.24.19.29
sudo iptables -t mangle -L PREROUTING -n -v
sudo ipvsadm -L -n
sudo systemctl status keepalived keepalived-lb-loopback keepalived-lb-mangle
```
Once confirmed, reboot `dns-001` the same way while `dns-002` covers.
