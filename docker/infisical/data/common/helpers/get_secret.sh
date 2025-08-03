#!/bin/bash

ENV_SCRIPT_NAME=$0
ENV_SECRET_KEY=$1
ENV_SECRET_PATH=$2


ENV_INFISICAL_URL="http://infisical.max.lan"
ENV_INFISICAL_CLIENT_ID='xxx'
ENV_INFISICAL_CLIENT_SECRET='xxx'

ENV_INFISICAL_WORKSPACE_ID='xxx'
ENV_INFISICAL_ENVIRONMENT='dev'


# Script parameters
COLOUR_GREEN='\033[0;32m'  # Green colour
COLOUR_NC='\033[0m'        # No colour
SYMBOL_TICK='\xE2\x9C\x94' # Tick symbol
GREEN_TICK="$COLOUR_GREEN$SYMBOL_TICK$COLOUR_NC"


# Get a secret
get_secret () {
   
    if [ -z $ENV_SECRET_KEY ]; then
        echo -e "usage $ENV_SCRIPT_NAME secretKey secretPath"
        exit 0
    
    fi

    # Get the access token
    RESPONSE=$(curl --silent \
      --request POST \
      --url "$ENV_INFISICAL_URL/api/v1/auth/universal-auth/login" \
      --header 'Content-Type: application/json' \
      --data "{ \"clientId\": \"$ENV_INFISICAL_CLIENT_ID\", 
                \"clientSecret\": \"$ENV_INFISICAL_CLIENT_SECRET\" }")

    ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.accessToken')

    # Check if the access token was returned
    if [ "$ACCESS_TOKEN" == null ]; then
        echo -e "Problem reqesting access token. Check ENV_INFISICAL_URL, ENV_INFISICAL_CLIENT_ID and ENV_INFISICAL_CLIENT_SECRET."
        echo -e $RESPONSE
        exit 0

    fi

    if [ -z $ENV_SECRET_PATH ]; then
        ENV_SECRET_PATH="/"
    
    fi

    # Get secret
    RESPONSE=$(curl --silent \
      --request GET \
      --url "$ENV_INFISICAL_URL/api/v3/secrets/raw/$ENV_SECRET_KEY?secretPath=$ENV_SECRET_PATH&workspaceId=$ENV_INFISICAL_WORKSPACE_ID&environment=$ENV_INFISICAL_ENVIRONMENT" \
      --header "Authorization: Bearer $ACCESS_TOKEN")

    SECRET_VALUE=$(echo $RESPONSE | jq -r '.secret.secretValue')

    # Check if the secret value was returned
    if [ "$SECRET_VALUE" == null ]; then
        echo -e "Problem requesting the secret value. Check ENV_SECRET_KEY, ENV_INFISICAL_WORKSPACE_ID and ENV_INFISICAL_ENVIRONMENT."
        echo -e $RESPONSE
        exit 0

    fi

    echo $SECRET_VALUE

}


# Execute the stages for container configuration
get_secret
