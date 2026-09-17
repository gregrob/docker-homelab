#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_SEMAPHOREUI_ADMIN_PASSWORD "apps/semaphoreui/semaphoreui-admin-password.secret.age"

    echo ""
    echo "Volumes for SemaphoreUI need to have the correct owner and group set - 1001:root"
    echo "Please execute the following commands to set up volume permissions:"
    echo "sudo chown 1001:root ./data/host/semaphoreui/config"
    echo "sudo chown 1001:root ./data/host/semaphoreui/data"
    echo "sudo chown 1001:root ./data/host/semaphoreui/keys"
    echo "sudo chown 1001:root ./data/host/semaphoreui/tmp"
    echo ""
}

# =============================================================================
# Delegate Guard, Bootstrap & Execution to Parent Helper
# =============================================================================
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../docker-env-repo-helper.sh"
docker_env_repo_bootstrap "${BASH_SOURCE[0]}" "${0}"
