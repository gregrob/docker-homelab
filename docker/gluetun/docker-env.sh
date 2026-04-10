#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"
    
    export ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_001=$(get_secret "apps/gluetun/gluetun-wireguard-private-key-001.secret.age")
    echo "Exported ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_001=$ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_001"

    export ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_002=$(get_secret "apps/gluetun/gluetun-wireguard-private-key-002.secret.age")
    echo "Exported ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_002=$ENV_WIREGUARD_PRIVATE_KEY_GLUETUN_002"

    export ENV_QBITTORRENT_UI_PORT_PUB=8080
    echo "Exported ENV_QBITTORRENT_UI_PORT_PUB=$ENV_QBITTORRENT_UI_PORT_PUB"
    
    export ENV_QBITTORRENT_UI_PORT_PRV=8081
    echo "Exported ENV_QBITTORRENT_UI_PORT_PRV=$ENV_QBITTORRENT_UI_PORT_PRV"

    export ENV_PROWLARR_PORT=9696
    echo "Exported ENV_PROWLARR_PORT=$ENV_PROWLARR_PORT"

    echo ""

    echo "To test that our VPN is correctly routing our QBittorrent traffic, we can download a test torrent and check our IP."
    echo "Use https://www.whatismyip.net/tools/torrent-ip-checker/ for this."
    echo "Also use https://www.dnsleaktest.com/ to check for DNS leaks."

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
