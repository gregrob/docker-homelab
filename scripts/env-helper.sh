#!/bin/bash
# env-helper.sh
#
# export_var: a single, small helper for exporting host-level environment
# variables into container start scripts, replacing the old two-line
# pattern repeated everywhere:
#   export X=...
#   echo "Exported X=$X"
#
# This mirrors export_secret's design intent (see secrets-helper.sh in
# secrets-homelab) for a specific reason: routing every ordinary
# environment lookup through one function — even though today it does
# nothing more than export + print — means there's a single place to add
# behaviour later without touching every container script again. For
# example: an override file for a specific host, validation, or
# deferring a particular variable name to get_secret instead of a plain
# value. None of that exists yet; this is deliberately just the choke
# point for it, not a feature implementation ahead of a real need.
#
# Unlike secrets-helper.sh, this has no server, no network call, and
# nothing to lock — it only ever operates on values already computed
# locally, so there's no concurrency concern to guard against.
#
# Usage:
#   export_var ENV_HOSTNAME "$HOSTNAME"
#   export_var ENV_LOCALIP "$(hostname -I | awk '{print $1}')"
#   export_var ENV_LOOPBACK "127.0.0.1"

export_var() {
    local var_name="$1"
    local value="$2"

    if [[ -z "$var_name" ]]; then
        echo "Usage: export_var <VAR_NAME> <value>" >&2
        return 1
    fi

    # Intentional interception point: nothing here today, but this is
    # where future logic (an override lookup, a per-host value swap,
    # deferring a specific var name to get_secret, etc.) would apply to
    # every call site at once, without editing container scripts.

    export "$var_name=$value"

    # Indirect expansion (${!var_name}) reads back whatever actually
    # landed in the environment, rather than trusting that $value matches
    # it — if export silently failed (e.g. var_name isn't a valid
    # identifier), this surfaces that as a visibly empty/wrong value
    # instead of a confident but false "Exported X=Y" message.
    echo "Exported $var_name=${!var_name}"
}
