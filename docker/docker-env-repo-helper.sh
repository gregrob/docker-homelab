#!/bin/bash
# docker-env-repo-helper.sh (Repository parent helper)
#
# Shared guard + bootstrap for every container's docker-env.sh within
# this repo. Mirrors docker-env-bootstrap.sh's idiom exactly: the caller
# passes its own BASH_SOURCE[0]/$0 explicitly, rather than this file
# trying to inspect the call stack itself — see docker-env-bootstrap.sh
# for why that matters (BASH_SOURCE inside a function always resolves to
# where the function is DEFINED, not the caller). The one exception is
# _repo_dir below, which deliberately DOES use this file's own
# BASH_SOURCE[0] — that's correct there, since we want docker-paths.sh's
# location (next to this file, in docker/), not the container's.
#
# Usage (from a container's docker-env.sh, after defining
# load_container_env):
#   source "$SCRIPT_DIR/../docker-env-repo-helper.sh"
#   docker_env_repo_bootstrap "${BASH_SOURCE[0]}" "${0}"

docker_env_repo_bootstrap() {
    local calling_source="$1"
    local invoked_as="$2"

    # 1. Enforce Sourcing Guard
    if [[ "$calling_source" == "$invoked_as" ]]; then
        echo "FAIL: Please source this script rather than executing it directly:"
        echo "      source ./$(basename "$calling_source")"
        exit 1
    fi

    # 2. Self-Bootstrap Helper Functions (If Missing) — lets a
    # container's docker-env.sh be sourced standalone (e.g. for local
    # testing) without going through the full docker-start.sh chain first.
    if ! declare -f export_var >/dev/null 2>&1 || \
       ! declare -f export_secret >/dev/null 2>&1; then

        local _repo_dir
        _repo_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
        echo "Helper functions not found in shell. Self-bootstrapping environment..."

        source "$_repo_dir/docker-paths.sh"
        source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
        source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"
    fi

    # 3. Execute Environment Setup & Clean Up Memory
    if declare -f load_container_env >/dev/null 2>&1; then
        load_container_env
        unset -f load_container_env
    fi
}
