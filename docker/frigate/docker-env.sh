#!/bin/bash

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS="10.24.4.1"
    echo "Exported ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS=$ENV_FRIGATE_HOST_UNIFI_PROTECT_IP_ADDRESS"

    export_secret ENV_FRIGATE_HOST_MQTT_USER "apps/frigate/frigate-mqtt-user.secret.age"

    export_secret ENV_FRIGATE_HOST_MQTT_PASSWORD "apps/frigate/frigate-mqtt-password.secret.age"

    export ENV_HOST_IP_FRIGATE_API=$(dig +short frigate-002.apps.gregrob.net | head -n1)
    echo "Exported ENV_HOST_IP_FRIGATE_API=$ENV_HOST_IP_FRIGATE_API"

    export ENV_HOST_IP_FRIGATE_UI=$(dig +short frigate-002.home.gregrob.net | head -n1)
    echo "Exported ENV_HOST_IP_FRIGATE_UI=$ENV_HOST_IP_FRIGATE_UI"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
