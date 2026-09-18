#!/bin/bash
# docker-env-bootstrap.sh
#
# Single, shared bootstrap function for EVERY docker-env.sh in a repo —
# both the repo-level orchestrator (docker/docker-env.sh) and every
# container's own docker-env.sh. Pure logic only — settings (paths,
# defaults) live in docker-config.sh, not here.
#
# WHY repo_dir IS PASSED IN EXPLICITLY:
# Self-bootstrapping needs to locate docker-config.sh, which sits in the
# repo's docker/ folder. That folder is a DIFFERENT relative distance
# away depending on the caller — right next to the repo-level
# docker-env.sh, but one level up from a container's docker-env.sh. This
# function can't guess that from its own location (it always resolves to
# scripts/, regardless of who called it), so the caller — which knows its
# own position — passes the correct absolute path in.
#
# Usage:
#   docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$repo_dir" <true|false> [callback_fn]
#
#   repo_dir      - absolute path to this repo's docker/ folder
#   source_common - "true" to source docker-env-common.sh (tier 1); pass
#                   "true" from the repo-level orchestrator, "false" from
#                   a container's docker-env.sh (tier 1 has already run
#                   earlier in the normal chain by the time a container
#                   level file runs — see the self-bootstrap branch below
#                   for the one case where it still needs to happen)
#   callback_fn   - optional function name to call then unset afterwards
#                   (container level's load_container_env; omit at repo
#                   level, which has no such callback)

docker_env_bootstrap() {
    local calling_source="$1"
    local invoked_as="$2"
    local repo_dir="$3"
    local source_common="${4:-true}"
    local callback_fn="${5:-}"
    local _bootstrapped_tier1=false

    # 1. Enforce sourcing guard
    if [[ "$calling_source" == "$invoked_as" ]]; then
        echo "FAIL: Please source this script rather than executing it directly:"
        echo "      source ./$(basename "$calling_source")"
        exit 1
    fi

    # 2. Self-bootstrap helpers if missing — lets ANY docker-env.sh (repo
    # or container level) be sourced standalone for local testing,
    # without the normal chain having run first. A shell cold enough to
    # be missing these functions has also never seen tier 1, so pull that
    # in here too rather than leaving a standalone container test with
    # host facts / fleet-wide secrets missing.
    if ! declare -f export_var >/dev/null 2>&1 || \
       ! declare -f export_secret >/dev/null 2>&1; then

        echo "Helper functions not found in shell. Self-bootstrapping environment..."
        source "$repo_dir/docker-config.sh"
        source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
        source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"
        export SECRET_DEBUG="$SECRET_DEBUG_DEFAULT"

        source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-common.sh"
        _bootstrapped_tier1=true
    fi

    # 3. Tier 1 (fleet-wide common vars/secrets) — only when explicitly
    # requested AND not already pulled in by the self-bootstrap branch
    # just above (avoids sourcing it twice, with two banners, on a cold
    # repo-level run).
    if [[ "$source_common" == "true" && "$_bootstrapped_tier1" != "true" ]]; then
        source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-common.sh"
    fi

    # 4. Run and clean up a named callback function, if one was given
    # (container level's load_container_env) — called only after the
    # guard has already passed, then unset so it doesn't linger in the
    # shell's function table.
    if [[ -n "$callback_fn" ]] && declare -f "$callback_fn" >/dev/null 2>&1; then
        "$callback_fn"
        unset -f "$callback_fn"
    fi
}
