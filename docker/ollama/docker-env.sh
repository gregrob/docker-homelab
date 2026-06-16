#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_OPEN_WEBUI_OAUTH_CLIENT_ID=$(get_secret "apps/open-webui/open-webui-oauth-client-id.secret.age")
    echo "Exported ENV_OPEN_WEBUI_OAUTH_CLIENT_ID=$ENV_OPEN_WEBUI_OAUTH_CLIENT_ID"

    export ENV_OPEN_WEBUI_OAUTH_CLIENT_SECRET=$(get_secret "apps/open-webui/open-webui-oauth-client-secret.secret.age")
    echo "Exported ENV_OPEN_WEBUI_OAUTH_CLIENT_SECRET=$ENV_OPEN_WEBUI_OAUTH_CLIENT_SECRET"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
