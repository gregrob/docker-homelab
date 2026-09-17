#!/bin/bash
# docker-env-repo-helper.sh (Repository parent helper)

# =============================================================================
# 1. Enforce Sourcing Guard
# =============================================================================
if [[ "${BASH_SOURCE[1]}" == "${0}" ]]; then
    echo "FAIL: Please source this script rather than executing it directly:"
    echo "      source ./$(basename "${BASH_SOURCE[1]}")"
    exit 1
fi

# =============================================================================
# 2. Self-Bootstrap Helper Functions (If Missing)
# =============================================================================
if ! declare -f export_var >/dev/null 2>&1 || \
   ! declare -f export_secret >/dev/null 2>&1; then

    _REPO_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    echo "Helper functions not found in shell. Self-bootstrapping environment..."

    source "$_REPO_DIR/docker-paths.sh"
    source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
    source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"
fi

# =============================================================================
# 3. Execute Environment Setup & Clean Up Memory
# =============================================================================
if declare -f load_container_env >/dev/null 2>&1; then
    load_container_env
    unset -f load_container_env
fi
