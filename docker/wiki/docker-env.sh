#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_POSTGRES_USER=$(get_secret "apps/wiki/wiki-postgres-user.secret.age")
    echo "Exported ENV_POSTGRES_USER=$ENV_POSTGRES_USER"

    export ENV_POSTGRES_PASSWORD=$(get_secret "apps/wiki/wiki-postgres-password.secret.age")
    echo "Exported ENV_POSTGRES_PASSWORD=$ENV_POSTGRES_PASSWORD"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
