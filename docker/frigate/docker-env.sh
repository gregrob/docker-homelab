#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS="10.24.4.1"
    echo "Exported ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS=$ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS"

    export ENV_FRIGATE_HOST_MQTT_USER=$(get_secret "apps/frigate/frigate-mqtt-user.secret.age")
    echo "Exported ENV_FRIGATE_HOST_MQTT_USER=$ENV_FRIGATE_HOST_MQTT_USER"

    export ENV_FRIGATE_HOST_MQTT_PASSWORD=$(get_secret "apps/frigate/frigate-mqtt-password.secret.age")
    echo "Exported ENV_FRIGATE_HOST_MQTT_PASSWORD=$ENV_FRIGATE_HOST_MQTT_PASSWORD"

    export ENV_HOST_IP_FRIGATE_BACKEND=$(dig +short frigate-001.containers.max.lan | head -n1)
    echo "Exported ENV_HOST_IP_FRIGATE_BACKEND=$ENV_HOST_IP_FRIGATE_BACKEND"

    export ENV_HOST_IP_FRIGATE_FRONTEND=$(dig +short frigate-001.home.max.lan | head -n1)
    echo "Exported ENV_HOST_IP_FRIGATE_FRONTEND=$ENV_HOST_IP_FRIGATE_FRONTEND"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
