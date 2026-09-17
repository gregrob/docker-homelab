#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_var ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS "10.24.4.1"
    export_var ENV_HOST_IP_FRIGATE_API "$(dig +short frigate-002.apps.gregrob.net | head -n1)"
    export_var ENV_HOST_IP_FRIGATE_UI "$(dig +short frigate-002.home.gregrob.net | head -n1)"

    export_secret ENV_FRIGATE_HOST_MQTT_USER "apps/frigate/frigate-mqtt-user.secret.age"
    export_secret ENV_FRIGATE_HOST_MQTT_PASSWORD "apps/frigate/frigate-mqtt-password.secret.age"

    echo ""
}

# =============================================================================
# Delegate Guard, Bootstrap & Execution to Parent Helper
# =============================================================================
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../docker-env-repo-helper.sh"
docker_env_repo_bootstrap "${BASH_SOURCE[0]}" "${0}"
