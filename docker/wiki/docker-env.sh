#!/bin/bash

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_POSTGRES_USER "apps/wiki/wiki-postgres-user.secret.age"
    export_secret ENV_POSTGRES_PASSWORD "apps/wiki/wiki-postgres-password.secret.age"

    echo ""

    echo "The mounted volume /wiki/data/content is owned by node:node inside the container (1000:1000)."
    echo "Need to make sure the local volume has the same permissions."

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
