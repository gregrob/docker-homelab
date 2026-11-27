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

    #export_var ENV_BAMBUDDY_VERSION "0.2.2.1"
    #export_var ENV_BAMBUDDY_VERSION "0.2.3.2"
    #export_var ENV_BAMBUDDY_VERSION "0.2.4.1"
    #export_var ENV_BAMBUDDY_VERSION "0.2.4.2"
    #export_var ENV_BAMBUDDY_VERSION "0.2.4.3"
    #export_var ENV_BAMBUDDY_VERSION "0.2.4.7"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.2"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.3"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.4"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.5"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.6"
    #export_var ENV_BAMBUDDY_VERSION "1.2.5.7"
    export_var ENV_BAMBUDDY_VERSION "1.3.2"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
