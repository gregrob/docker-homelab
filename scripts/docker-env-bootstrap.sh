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
#                   a container's docker-env.sh. This is the ONLY thing
#                   that controls tier 1 — self-bootstrapping below never
#                   pulls it in as a side effect, even on a cold shell,
#                   so a standalone test of one container's docker-env.sh
#                   loads only that container's own vars/secrets, not the
#                   full fleet-wide common environment too.
#   callback_fn   - optional function name to call then unset afterwards
#                   (container level's load_container_env; omit at repo
#                   level, which has no such callback)

docker_env_bootstrap() {
    local calling_source="$1"
    local invoked_as="$2"
    local repo_dir="$3"
    local source_common="${4:-true}"
    local callback_fn="${5:-}"

    # 1. Enforce sourcing guard
    if [[ "$calling_source" == "$invoked_as" ]]; then
        echo "FAIL: Please source this script rather than executing it directly:"
        echo "      source ./$(basename "$calling_source")"
        exit 1
    fi

    # 2. Self-bootstrap helper FUNCTIONS only, if missing — lets ANY
    # docker-env.sh (repo or container level) be sourced standalone for
    # local testing, without the normal chain having run first. Only
    # ensures export_var / export_secret exist, since load_container_env
    # (or a repo's own exports) needs them to run at all — deliberately
    # does NOT also pull in tier 1 here, so this stays scoped to "make
    # the required functions available," not "replicate the whole chain."
    if ! declare -f export_var >/dev/null 2>&1 || \
       ! declare -f export_secret >/dev/null 2>&1; then

        echo "Helper functions not found in shell. Self-bootstrapping environment..."
        source "$repo_dir/docker-config.sh"
        source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
        source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"
        export SECRET_DEBUG="$SECRET_DEBUG_DEFAULT"
    fi

    # 3. Tier 1 (fleet-wide common vars/secrets) — governed solely by
    # source_common, regardless of whether step 2 just fired. A
    # standalone container test (source_common=false) intentionally
    # skips this; source the repo-level docker-env.sh first if a test
    # needs tier 1 too.
    if [[ "$source_common" == "true" ]]; then
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
