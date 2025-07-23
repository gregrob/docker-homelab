#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then
    echo "--------------------------------------------"
    echo "Setting up COMMON environment for docker ..."
    echo "--------------------------------------------"

    export ENV_HOSTNAME=$HOSTNAME
    echo "Exported ENV_HOSTNAME=$ENV_HOSTNAME"

    export ENV_LOCALIP=$(hostname -I | awk '{print $1}')
    echo "Exported ENV_LOCALIP=$ENV_LOCALIP"

    export ENV_LOOPBACK="127.0.0.1"
    echo "Exported ENV_LOOPBACK=$ENV_LOOPBACK"

    export ENV_DOCKER_USER=$USER
    echo "Exported ENV_DOCKER_USER=$ENV_DOCKER_USER"

    export ENV_DOCKER_UID=$(id -u $ENV_DOCKER_USER)
    echo "Exported ENV_DOCKER_UID=$ENV_DOCKER_UID"

    export ENV_DOCKER_GID=$(id -g $ENV_DOCKER_USER)
    echo "Exported ENV_DOCKER_GID=$ENV_DOCKER_GID"

    export ENV_TZ=$(timedatectl show --property=Timezone --value)
    echo "Exported ENV_TZ=$ENV_TZ"

    export ENV_TEST_DECRYPTION_COMMON=$(get_secret "test/test-code-string.secret.age")
    echo "Exported ENV_TEST_DECRYPTION_COMMON=$ENV_TEST_DECRYPTION_COMMON"

    echo ""

else
    echo "FAIL: Please call script with - source ./$(basename "${BASH_SOURCE[0]}")"

    exit 1

fi
