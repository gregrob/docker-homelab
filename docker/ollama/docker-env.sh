#!/bin/bash

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_OPEN_WEBUI_OAUTH_CLIENT_ID "apps/open-webui/open-webui-oauth-client-id.secret.age"
    export_secret ENV_OPEN_WEBUI_OAUTH_CLIENT_SECRET "apps/open-webui/open-webui-oauth-client-secret.secret.age"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
