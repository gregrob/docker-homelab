#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    echo "--------------------------------------------------"
    echo "Setting up environment with container versions ..."
    echo "--------------------------------------------------" 

    #export_var ENV_SPOOLMAN_VERSION "0.23.1"
    #export_var ENV_SPOOLMAN_VERSION "0.26.1"
    #export_var ENV_SPOOLMAN_VERSION "0.27.0"
    export_var ENV_SPOOLMAN_VERSION "0.27.1"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
