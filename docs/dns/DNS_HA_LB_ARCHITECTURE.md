# DNS High-Availability + Load Balancing — Architecture & Debug Reference

## Overview

`dns-001` and `dns-002` run Technitium DNS (Docker, host networking) and
together present a single virtual IP (`10.24.19.29`) that DNS clients
query. The pair provides two things simultaneously:

1. **VRRP failover** (keepalived) — one node always holds the VIP; if it
   fails, the other takes over automatically, typically within a few
   seconds.
2. **IPVS load balancing** (LVS-DR mode, also keepalived) — whichever node
   currently holds the VIP also acts as a *director*, splitting incoming
   query traffic across both nodes rather than always answering locally.
   Each node independently health-checks the other and pulls it from
   rotation if its DNS stops answering.

Both nodes run identical roles simultaneously: each is a VRRP peer, a
potential director, and a real server in the load-balanced pool.

## Topology

```mermaid
graph TB
    subgraph Clients
        C1[Windows PC]
        C2[iPhone]
        C3[Other LAN clients]
    end

    VIP["VIP 10.24.19.29<br/>held by whichever node is VRRP MASTER"]

    subgraph "dns-001 (10.24.19.30)"
        D1_VRRP["VRRP instance<br/>priority 150"]
        D1_IPVS["IPVS director<br/>fwmark 1=UDP, 2=TCP"]
        D1_MANGLE["mangle rule:<br/>mark unless src MAC = dns-002"]
        D1_TECH["Technitium<br/>(host networking)"]
        D1_LO["VIP bound to lo<br/>ARP suppressed"]
    end

    subgraph "dns-002 (10.24.19.32)"
        D2_VRRP["VRRP instance<br/>priority 100"]
        D2_IPVS["IPVS director<br/>fwmark 1=UDP, 2=TCP"]
        D2_MANGLE["mangle rule:<br/>mark unless src MAC = dns-001"]
        D2_TECH["Technitium<br/>(host networking)"]
        D2_LO["VIP bound to lo<br/>ARP suppressed"]
    end

    C1 --> VIP
    C2 --> VIP
    C3 --> VIP
    VIP -.currently held by.-> D1_VRRP

    VIP --> D1_MANGLE --> D1_IPVS
    D1_IPVS -- "wrr: ~50%" --> D1_TECH
    D1_IPVS -- "wrr: ~50%,<br/>DR forward (MAC rewrite only)" --> D2_MANGLE
    D2_MANGLE -- "unmarked (src MAC = dns-001)<br/>never re-scheduled" --> D2_LO --> D2_TECH

    D1_VRRP <-.VRRP advert / health.-> D2_VRRP

    style VIP fill:#f9f,stroke:#333,stroke-width:2px
    style D1_MANGLE fill:#ffd,stroke:#333
    style D2_MANGLE fill:#ffd,stroke:#333
```

## Sequence: a normal query, load-balanced to the peer

```mermaid
sequenceDiagram
    participant Client
    participant dns001 as dns-001 (MASTER/director)
    participant mangle1 as dns-001 mangle rule
    participant ipvs1 as dns-001 IPVS (fwmark)
    participant mangle2 as dns-002 mangle rule
    participant tech2 as dns-002 Technitium

    Client->>dns001: DNS query to VIP:53
    dns001->>mangle1: packet arrives, src MAC = client
    Note over mangle1: src MAC != dns-002 → MARK set
    mangle1->>ipvs1: marked packet
    ipvs1->>ipvs1: wrr scheduler picks dns-002
    ipvs1->>mangle2: forward (DR: dest MAC rewritten<br/>to dns-002, IP unchanged)
    Note over mangle2: src MAC = dns-001 (the peer)<br/>→ NOT marked (excluded)
    mangle2->>tech2: unmarked packet falls through<br/>to local delivery via loopback VIP
    tech2-->>Client: reply sent directly<br/>(source = VIP, dest = Client)
    Note over dns001: dns-001 never sees the reply -<br/>DR mode bypasses the director<br/>on the return path
```

## Sequence: VRRP failover + IPVS director handoff

```mermaid
sequenceDiagram
    participant dns001 as dns-001 (was MASTER)
    participant dns002 as dns-002 (was BACKUP)
    participant VIP

    Note over dns001: vrrp_script health check fails<br/>(fall: 2 consecutive failures)
    dns001->>dns001: Entering FAULT state
    Note over dns002: no advert received from dns-001<br/>within advert_int window
    dns002->>dns002: Entering MASTER state
    dns002->>VIP: claims VIP (gratuitous ARP)
    Note over dns002: MISC_CHECK continues running<br/>independently on both nodes -<br/>no change needed to IPVS/mangle state,<br/>they were never tied to VRRP role
    VIP-->>dns002: clients now reach dns-002<br/>directly (ARP updated)
```

## Why it's built this way (the non-obvious parts)

### Docker must use host networking

Docker's default bridge networking publishes container ports via iptables
DNAT rules matching `ADDRTYPE dst-type LOCAL` — meaning *any* locally-owned
IP, not just the container host's original address. The moment the VIP
becomes locally bound (via VRRP or the DR-mode loopback binding below),
Docker's DNAT rule intercepts VIP-addressed traffic and delivers it
straight to the container, before IPVS's own kernel hook ever gets a
chance to schedule it. This was the root cause of hours of "why won't load
balancing distribute traffic" debugging — confirmed directly via
`iptables -t nat -L DOCKER -n -v`. Host networking removes Docker's
NAT/port-publishing layer entirely, letting IPVS see and schedule the
traffic correctly.

### LVS-DR mode and the loopback VIP binding

Direct Routing (DR) mode never rewrites IP headers — only the destination
MAC address. This means the response can go directly from whichever real
server handled the query straight back to the client, without passing
back through the director. It's what preserves the real client source IP
(unlike a reverse proxy, which would make every query look like it came
from the proxy itself). For a real server to accept and answer VIP-
addressed traffic without "owning" the VIP on its main interface, the VIP
is bound to `lo` (loopback) with ARP suppressed (`arp_ignore`/
`arp_announce` sysctls) — so the node accepts the traffic locally but
never announces itself as the VIP's owner via ARP.

### The dual-director ping-pong loop, and why it needs mangle rules

keepalived normally activates a `virtual_server`'s IPVS rules on **every**
node that has that block configured, regardless of VRRP state — not just
the current MASTER. Since both `dns-001` and `dns-002` are always real
servers *and* always potential directors, without any additional
protection both nodes independently run an active IPVS scheduler for the
same VIP simultaneously. If the current director forwards a packet to the
peer, that packet is still addressed to the VIP (DR mode never rewrites
IPs) — so the peer's own IPVS instance intercepts it a second time and can
reschedule it right back. This produces an **unbounded** MAC-layer
ping-pong loop, confirmed directly via packet capture: DR mode never
decrements IP TTL, so nothing kills the loop on its own once it starts.

The fix: an `iptables mangle` rule on each node marks VIP-destined traffic
**unless** its source MAC belongs to the peer real server. `keepalived.conf`
then uses `fwmark`-based `virtual_server` blocks instead of matching the
VIP/port directly — so a packet the peer already forwarded (unmarked on
arrival) never matches this node's own virtual_server and never gets
rescheduled. Genuinely new client traffic still gets marked and scheduled
normally. Critically, this preserves keepalived's own continuous
`MISC_CHECK` health monitoring on both nodes — an earlier approach that
tried to solve this by disabling IPVS entirely on the non-MASTER node
(via a notify-script hook) was rejected specifically because it lost
continuous health awareness between VRRP transitions.

### Why the health check is a real script file, not inline in keepalived.conf

`enable_script_security` causes keepalived to exec check commands directly
rather than via a shell. An inline shell pipeline (e.g. `dig ... | grep
...`) written directly in `keepalived.conf` has its pipe character passed
as a literal argument to `dig` instead of being interpreted — silently
breaking the check (it always "succeeds" regardless of the actual
response). Wrapping the same command in a real script file with its own
`#!/bin/bash` shebang avoids this, since the shell interpretation happens
inside the script's own execution, not in how keepalived invokes it.

### Why the health check uses TCP, not UDP

A frozen/paused Technitium container can still appear to answer UDP
queries via Docker's `docker-proxy` layer, even when the application
itself isn't processing anything — confirmed directly via testing (`docker
pause` + a UDP query still returned a stale/successful-looking result). A
TCP query requires the application to actually `accept()` the connection,
which a frozen process can't do — so TCP correctly times out where UDP
falsely succeeded.

## Variable / config ownership map

| Concern | Lives in |
|---|---|
| This node's identity (interface, priority, own IP, peer list) | `host_vars/dns-00N...yaml` |
| Pool-wide facts that must match across every node (VIP, router ID, real server list, health check definition) | `group_vars/keepalived_dns_target/keepalived-dns-config.yaml` |
| Generic role behavior/timing (not DNS-specific) | `roles/keepalived/defaults/main.yaml` |
| Admin account identity | `group_vars/all/admin-user.yaml` |

## Debug command reference — mapped to each stage

Each stage below corresponds to a box/arrow in the topology diagram or a
step in one of the sequence diagrams above, so you can isolate exactly
where in the pipeline something is going wrong rather than guessing.

### Stage 0 — Who currently holds the VIP (topology: `VIP -.currently held by.->`)

```bash
# run on both nodes; exactly one should show the VIP on ens18
ip addr show ens18 | grep 10.24.19.29

# both nodes should show it bound to lo too (DR-mode real-server binding,
# independent of who's MASTER)
ip addr show lo | grep 10.24.19.29
```

### Stage 1 — Is keepalived running and what does it believe its own state is

```bash
sudo systemctl status keepalived
sudo journalctl -u keepalived -f
# watch for: "Entering MASTER STATE" / "Entering BACKUP STATE" /
# "VRRP_Script(chk_service) succeeded" or "failed"
```

### Stage 2 — Mangle rule (topology: `D1_MANGLE` / `D2_MANGLE` boxes)

```bash
# on both nodes - confirm both UDP and TCP rules are present, and check
# whether pkts/bytes counters are incrementing (proof traffic is actually
# hitting the rule, not just that it exists)
sudo iptables -t mangle -L PREROUTING -n -v --line-numbers
```
If a node's rule shows 0 packets ever, it has never received forwarded
traffic from its peer — either it's never been the non-director side, or
something upstream (Stage 0/1) isn't working.

### Stage 3 — IPVS scheduling decision (topology: `D1_IPVS` / `D2_IPVS`)

```bash
# current pool state: which real servers are active, at what weight
sudo ipvsadm -L -n

# cumulative connection counts per real server - the definitive answer to
# "is this actually distributing across both nodes" (don't rely on
# eyeballing packet captures for this, connection tracking noise makes it
# easy to misread - see the "why not tcpdump for this" note below)
sudo ipvsadm -L -n --stats
```
Take two snapshots a minute or so apart under real traffic and diff the
`Conns` column for each real server - both should be climbing.

### Stage 4 — DR forward + local delivery on the peer (sequence diagram: `mangle2->>tech2`)

```bash
# confirm Technitium is actually listening on the real interface, not
# just via Docker's old published-port mechanism
sudo ss -tulnp | grep :53

# confirm Docker isn't intercepting VIP traffic before it reaches this
# point at all - should show NO rule matching dpt:53
sudo iptables -t nat -L DOCKER -n -v
```

### Stage 5 — Health check (drives both Stage 1's vrrp_script and Stage 3's MISC_CHECK)

```bash
# manually run the exact check keepalived uses, against a specific node
/etc/keepalived/scripts/check.sh 10.24.19.30
echo "exit: $?"     # 0 = healthy, non-zero = would be marked down
```

### Stage 6 — Watching a query flow through every stage at once

Use a unique test domain (not a real one) so it's unambiguous in the
capture, and run this **simultaneously on both nodes** — DR mode means a
reply from the non-director node never passes back through the director,
so you need both vantage points to see the complete round trip (this is
also why `tcpdump` alone is a poor tool for the "is it actually load
balancing" question — a single node's capture is structurally unable to
show you the whole picture; use Stage 3's `ipvsadm --stats` for that
question instead, and reserve `tcpdump` for tracing one specific
problematic exchange):

```bash
sudo tcpdump -i ens18 -e -n host 10.24.19.29 and port 53
```
`-e` shows MAC addresses, which is how you distinguish "genuinely new
client traffic" from "a packet the peer just forwarded" (source MAC =
peer's real interface MAC) when reading the capture.

### Simulating failures (exercises the full failover + rebalancing path)

**Simulate one node's DNS going unhealthy without stopping the whole
container** (exercises Stage 5 → Stage 3's MISC_CHECK path, independent
of VRRP):
```bash
docker pause dns-server   # on the node you want to fail
sleep 15
sudo ipvsadm -L -n        # its weight should now show 0, automatically
docker unpause dns-server
sleep 15
sudo ipvsadm -L -n        # weight should return to normal, automatically
```

**Force a full VRRP failover** (exercises the second sequence diagram,
Stage 0 → Stage 1 end to end):
```bash
sudo systemctl stop keepalived   # on the current MASTER
# on the other node, watch for the takeover:
sudo journalctl -u keepalived -f
ip addr show | grep 10.24.19.29   # confirm VIP moved to this node
```

## Scaling beyond two nodes

Not currently planned, but the role was designed with this in mind rather
than hardcoded to exactly two nodes. What's confirmed to generalize versus
what's untested if a third node were ever added:

**Designed to scale, but only validated at N=2:**
- `keepalived_dns_nodes` / `keepalived_unicast_peers` — adding a third IP
  to the group var automatically updates every existing node's peer list
  (via the `reject('equalto', ...)` filter), no manual edits needed.
- `keepalived_real_servers` / the `real_server` loop in
  `keepalived.conf.j2` — already list-driven, adding a third entry just
  adds a third `real_server` block on every node.
- The mangle-rule peer-MAC exclusion (`mangle-rules.sh.j2`) — the Jinja
  loop already chains one `-m mac ! --mac-source` clause per peer
  (ANDed together), so a third node would correctly produce two exclusion
  clauses instead of one. This is generic by design, but has only ever
  been exercised with exactly one peer (N=2) - not proven at N=3.

**Would need a deliberate decision, not automatic:**
- Whether a third node should be a full director+real-server (like
  dns-001/dns-002) or a VRRP-only fallback with
  `keepalived_load_balancer_enabled: false` overridden in its own
  host_vars (lower VRRP priority, never receives IPVS-forwarded traffic,
  none of the DR-mode/mangle/loopback machinery applied to it at all).
  The role supports either via existing vars - nothing new to build for
  this specific choice, it's just not automatic either way.

**Before trusting N=3 in practice:** run a `--check` dry-run with a third
host stubbed into the inventory and inspect the rendered
`keepalived_peer_macs` and `keepalived.conf` on all three nodes before
applying for real - this exact scenario has not been run through live
Ansible.
