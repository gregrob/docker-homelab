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

    #export_var ENV_SEMAPHORE_VERSION "v2.19.8"
    #export_var ENV_SEMAPHORE_VERSION "v2.19.11"
    #export_var ENV_SEMAPHORE_VERSION "v2.19.12"
    #export_var ENV_SEMAPHORE_VERSION "v2.19.14"
    #export_var ENV_SEMAPHORE_VERSION "v2.19.17"
    export_var ENV_SEMAPHORE_VERSION "v2.20.24"
    
    #export_var ENV_ALPINE_VERSION "3.24.1"
    #export_var ENV_ALPINE_VERSION "3.24.2"
    #export_var ENV_ALPINE_VERSION "3.24.3"
    export_var ENV_ALPINE_VERSION "3.24.4"

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
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
