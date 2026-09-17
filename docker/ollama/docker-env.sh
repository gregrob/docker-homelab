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

    echo ""
}

# =============================================================================
# Delegate Guard, Bootstrap & Execution to Parent Helper
# =============================================================================
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../docker-env-repo-helper.sh"
