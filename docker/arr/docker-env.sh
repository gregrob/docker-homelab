#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_var ENV_QBITTORRENT_UI_PORT_PUB 8080
    export_var ENV_QBITTORRENT_UI_PORT_PRV 8081
    export_var ENV_PROWLARR_PORT 9696
    export_var ENV_SONARR_PORT 8989
    export_var ENV_RADARR_PORT 7878
    export_var ENV_SEERR_PORT 5055
    export_var ENV_LIDARR_PORT 8686
    export_var ENV_AURRAL_PORT 3001

    export_secret ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_001 "apps/gluetun/gluetun-wireguard-private-key-001.secret.age"
    export_secret ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_002 "apps/gluetun/gluetun-wireguard-private-key-002.secret.age"
    export_secret ENV_GLUETUN_CONTROL_SERVER_API_KEY "apps/gluetun/gluetun-control-server-api-key.secret.age"

    echo ""

    echo "To test that our VPN is correctly routing our QBittorrent traffic, we can download a test torrent and check our IP."
    echo "Use https://www.whatismyip.net/tools/torrent-ip-checker/ for this."
    echo "Also use https://www.dnsleaktest.com/ to check for DNS leaks."

    echo ""

    # Creates the network if missing, ignores if it already exists
    echo "Create arr-net for sharing between stacks..."    
    docker network inspect arr-net >/dev/null 2>&1 || docker network create --driver bridge arr-net

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
