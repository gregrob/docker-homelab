#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_SPEEDTEST_TRACKER_APP_KEY "apps/speedtest-tracker/speedtest-tracker-app-key.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_ADMIN_NAME "apps/speedtest-tracker/speedtest-tracker-admin-name.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_ADMIN_EMAIL "apps/speedtest-tracker/speedtest-tracker-admin-email.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_ADMIN_PASSWORD "apps/speedtest-tracker/speedtest-tracker-admin-password.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_MAIL_USERNAME "apps/speedtest-tracker/speedtest-tracker-mail-username.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_MAIL_PASSWORD "apps/speedtest-tracker/speedtest-tracker-mail-password.secret.age"
    export_secret ENV_SPEEDTEST_TRACKER_MAIL_FROM_ADDRESS "apps/speedtest-tracker/speedtest-tracker-mail-from-address.secret.age"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
