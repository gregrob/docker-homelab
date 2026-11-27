#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_OPEN_WEBUI_OAUTH_CLIENT_ID "apps/open-webui/open-webui-oauth-client-id.secret.age"
    export_secret ENV_OPEN_WEBUI_OAUTH_CLIENT_SECRET "apps/open-webui/open-webui-oauth-client-secret.secret.age"

    #export_var ENV_OLLAMA_VERSION "0.30.8"
    #export_var ENV_OLLAMA_VERSION "0.33.2"
    #export_var ENV_OLLAMA_VERSION "0.33.3"
    #export_var ENV_OLLAMA_VERSION "0.34.0"
    #export_var ENV_OLLAMA_VERSION "0.35.0"
    #export_var ENV_OLLAMA_VERSION "0.35.1"
    #export_var ENV_OLLAMA_VERSION "0.40.9"
    export_var ENV_OLLAMA_VERSION "0.40.18"

    #export_var ENV_OPEN_WEBUI_VERSION "0.9.6"
    #export_var ENV_OPEN_WEBUI_VERSION "0.11.1"
    #export_var ENV_OPEN_WEBUI_VERSION "v0.11.3"
    #export_var ENV_OPEN_WEBUI_VERSION "v0.11.4"
    #export_var ENV_OPEN_WEBUI_VERSION "v0.12.3"
    export_var ENV_OPEN_WEBUI_VERSION "v0.13.5"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
