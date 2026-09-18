#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_HOMEPAGE_VAR_GLUETUN_CONTROL_SERVER_API_KEY "apps/gluetun/gluetun-control-server-api-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY "apps/homepage/homepage-speedtest-tracker-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_JELLYFIN_KEY "apps/homepage/homepage-jellyfin-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_SONARR_KEY "apps/homepage/homepage-sonarr-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_RADARR_KEY "apps/homepage/homepage-radarr-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_SEERR_KEY "apps/homepage/homepage-seerr-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_PROWLARR_KEY "apps/homepage/homepage-prowlarr-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_LIDARR_KEY "apps/homepage/homepage-lidarr-key.secret.age"
    export_secret ENV_HOMEPAGE_VAR_FRIGATE_HOMEPAGE_USER_PASSWORD "apps/homepage/homepage-frigate-homepage-user-password.secret.age"
    export_secret ENV_HOMEPAGE_VAR_TECHNITIUM_DNS_SERVER_KEY "apps/homepage/homepage-technitium-dns-server-key.secret.age"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
