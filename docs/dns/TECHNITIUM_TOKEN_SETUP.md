# Generating and vaulting the Technitium API token

Uses the existing `admin` account — deliberately not a separate
low-privilege account, since adding one just for this check isn't worth
the extra account/credential to maintain on a home LAN. Trade-off: the
token has full admin API access, not just health-check read access.
Acceptable here; revisit if this pattern is ever reused somewhere with
different stakes.

**Confirmed via direct testing: Technitium clusters/syncs API tokens
across nodes.** A token generated on `dns-001` works identically when
calling `dns-002`'s API, and vice versa — so only **one** token needs to
be generated and stored, not one per node.

## 1. Generate a non-expiring token (on either node — it'll work for both)

```bash
curl -s "http://127.0.0.1:5380/api/user/createToken" \
  --data-urlencode "user=admin" \
  --data-urlencode "pass=YOUR_ADMIN_PASSWORD" \
  --data-urlencode "tokenName=keepalived-healthcheck"
```
Returns JSON containing a `token` field — that's the value to save.

## 2. Confirm it works against BOTH nodes

```bash
curl -s "http://10.24.19.30:5380/api/dnsClient/healthCheck?token=YOUR_TOKEN"
curl -s "http://10.24.19.32:5380/api/dnsClient/healthCheck?token=YOUR_TOKEN"
```
Both should return `{"server": "...", "status": "ok"}` — confirming the
shared-token behavior holds on your actual cluster, not just assumed.

## 3. Vault-encrypt the single token

```bash
ansible-vault encrypt_string 'THE_TOKEN_VALUE' --name 'keepalived_technitium_api_token_clustered' \
  --vault-password-file ~/.vault_pass.txt
```
Paste the output block into `group_vars/all/vault.yaml` — this is a
**shared** secret, not a per-host one, so it belongs alongside other
fleet-wide secrets like `keepalived_auth_pass`, not in a per-host file:

```yaml
# group_vars/all/vault.yaml
keepalived_technitium_api_token_clustered: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
```

## 4. Reference it explicitly from each host's own host_vars

Even though the value is shared, each host's `host_vars` file explicitly
references it — this keeps every host_vars file a complete,
self-describing picture of what that host actually uses, rather than
requiring a reader to already know a value comes from `group_vars/all/`:

```yaml
# host_vars/dns-001.dns.gregrob.net.yaml (and dns-002...yaml, identical)
keepalived_check_extra_arg: "{{ keepalived_technitium_api_token_clustered }}"
```

Note the variable name on the *left* is `keepalived_check_extra_arg` —
the role-generic slot (see `roles/keepalived/defaults/main.yaml`), not
anything Technitium-specific. The role has no idea this value happens to
be an API token; it just passes whatever's here as the second argument to
every health check invocation. This is what makes the role reusable for a
future non-DNS service with a completely different (or no) extra-arg
need — see `DNS_HA_LB_ARCHITECTURE.md`'s health-check section for the
full generic design.

## 5. Verify the derived per-real-server lookup before trusting it live

`tasks/main.yaml` builds `keepalived_real_server_extra_args` — an IP →
extra-arg dict, one entry per real server, via a `hostvars` cross-lookup
(same technique as the peer-MAC derivation). Add a temporary debug task
right after "Determine per-real-server check extra args" to confirm it:

```yaml
- debug: var=keepalived_real_server_extra_args
```

Expect the **same token value under both IPs** (`10.24.19.30` and
`10.24.19.32`), confirming the shared-token design resolved correctly.
Remove the debug task once confirmed. See `POST_DEPLOYMENT_CHECKLIST.md`
step 4 for the full verification sequence, including the corresponding
peer-MAC check.

## If cluster-shared tokens ever stop being true

Nothing in the role depends on it — only the host_vars reference would
need to change, from pointing at the one shared vault entry to a genuine
per-host one:

```yaml
# host_vars/dns-001.dns.gregrob.net.yaml
keepalived_check_extra_arg: "{{ vault_dns_001_technitium_token }}"
# host_vars/dns-002.dns.gregrob.net.yaml
keepalived_check_extra_arg: "{{ vault_dns_002_technitium_token }}"
```
No changes needed in `tasks/main.yaml`, `keepalived.conf.j2`, or
`check.sh.j2` — the per-host lookup already handles either case
identically.
