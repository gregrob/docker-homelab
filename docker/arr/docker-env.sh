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

    echo "--------------------------------------------------"
    echo "Setting up environment with container versions ..."
    echo "--------------------------------------------------" 

    #export_var ENV_GLUETUN_VERSION "v3.41.1"
    export_var ENV_GLUETUN_VERSION "v3.41.3" # Should address port forward failures

    #export_var ENV_QBITTORRENT_VERSION "5.1.4"
    #export_var ENV_QBITTORRENT_VERSION "5.2.3"
    #export_var ENV_QBITTORRENT_VERSION "5.2.3_v2.0.14-ls475"
    #export_var ENV_QBITTORRENT_VERSION "5.2.3_v2.0.14-ls476"
    #export_var ENV_QBITTORRENT_VERSION "5.2.4_v2.0.15-ls479"
    #export_var ENV_QBITTORRENT_VERSION "5.3.0_v2.1.2-ls484"
    export_var ENV_QBITTORRENT_VERSION "5.3.0_v2.1.2-ls486"

    #export_var ENV_PROWLARR_VERSION "2.3.5.5327-ls141"
    #export_var ENV_PROWLARR_VERSION "2.5.2.5491-ls156"
    #export_var ENV_PROWLARR_VERSION "2.5.2.5491-ls158"
    #export_var ENV_PROWLARR_VERSION "2.5.2.5491-ls159"
    #export_var ENV_PROWLARR_VERSION "2.6.5.5623-ls162"
    #export_var ENV_PROWLARR_VERSION "2.6.5.5623-ls165"
    export_var ENV_PROWLARR_VERSION "2.7.0.5723-ls166"

    #export_var ENV_FLARESOLVERR_VERSION "v3.4.6"
    #export_var ENV_FLARESOLVERR_VERSION "v3.5.0"
    export_var ENV_FLARESOLVERR_VERSION "v3.5.2"

    #export_var ENV_SONARR_VERSION "4.0.19.2979-ls322"
    #export_var ENV_SONARR_VERSION "4.0.19.2979-ls323"
    #export_var ENV_SONARR_VERSION "4.0.19.2979-ls324"
    #export_var ENV_SONARR_VERSION "4.0.20.3014-ls326"
    export_var ENV_SONARR_VERSION "4.0.20.3014-ls329"

    #export_var ENV_RADARR_VERSION "6.3.0.10514-ls314"
    #export_var ENV_RADARR_VERSION "6.3.0.10514-ls315"
    #export_var ENV_RADARR_VERSION "6.3.0.10514-ls316"
    #export_var ENV_RADARR_VERSION "6.4.4.10685-ls318"
    #export_var ENV_RADARR_VERSION "6.4.4.10685-ls323"
    export_var ENV_RADARR_VERSION "6.4.4.10685-ls325"

    #export_var ENV_ALPINE_VERSION "3.24.1"
    #export_var ENV_ALPINE_VERSION "3.24.2"
    export_var ENV_ALPINE_VERSION "3.24.3"

    #export_var ENV_SEERR_VERSION "v3.4.1"
    #export_var ENV_SEERR_VERSION "v3.5.0"
    export_var ENV_SEERR_VERSION "v3.5.1"

    #export_var ENV_LIDARR_VERSION "3.1.0.4875-ls40"
    #export_var ENV_LIDARR_VERSION "3.1.0.4875-ls41"
    #export_var ENV_LIDARR_VERSION "3.1.0.4875-ls42"
    #export_var ENV_LIDARR_VERSION "3.1.0.4875-ls45"
    export_var ENV_LIDARR_VERSION "3.1.6.5079-ls46"

    #export_var ENV_AURRAL_VERSION "2.8.0"
    #export_var ENV_AURRAL_VERSION "2.9.0"
    #export_var ENV_AURRAL_VERSION "2.10.0"
    #export_var ENV_AURRAL_VERSION "2.11.0"
    export_var ENV_AURRAL_VERSION "2.12.0"

    export_var ENV_AUTOHEAL_VERSION "1.2.0"

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
