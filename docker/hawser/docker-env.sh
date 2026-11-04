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

    export_var ENV_HAWSER_CONTAINER_PATH_ROOT "$(pwd -P)"
    export_var ENV_HAWSER_CONTAINER_PATH_STACKS "${ENV_HAWSER_CONTAINER_PATH_ROOT}/data/host/stacks"
    
    export_secret ENV_HAWSER_TOKEN "apps/hawser/hawser-token.secret.age"

    export_var ENV_HAWSER_VERSION "0.2.53"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
