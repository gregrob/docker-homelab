#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then   
    
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"
    
    #export ENV_INFISICAL_TAG="v0.77.0-postgres"
    export ENV_INFISICAL_TAG="v0.128.0-postgres"
    echo "Exported ENV_INFISICAL_TAG=$ENV_INFISICAL_TAG"

    export ENV_POSTGRES_USER="infisical"
    echo "Exported ENV_POSTGRES_USER=$ENV_POSTGRES_USER"

    export ENV_POSTGRES_PASSWORD="infisical"
    echo "Exported ENV_POSTGRES_PASSWORD=$ENV_POSTGRES_PASSWORD"

    export ENV_POSTGRES_DB="infisical"
    echo "Exported ENV_POSTGRES_DB=$ENV_POSTGRES_DB"

    export ENV_HOST="infisical.max.lan"
    echo "Exported ENV_HOST=$ENV_HOST"
    
    export ENV_ENCRYPTION_KEY=$(get_secret "apps/infisical/infisical-encryption-key.secret.age")
    echo "Generate new encryption key with: openssl rand -hex 16"
    echo "Exported ENV_ENCRYPTION_KEY=$ENV_ENCRYPTION_KEY"

    export ENV_AUTH_SECRET=$(get_secret "apps/infisical/infisical-auth-secret.secret.age")
    echo "Generate new auth secret with: openssl rand -base64 32"
    echo "Exported ENV_AUTH_SECRET=$ENV_AUTH_SECRET"
    
    export ENV_INFISICAL_EMAIL_HOST="smtp.gmail.com"
    echo "Exported ENV_INFISICAL_EMAIL_HOST=$ENV_INFISICAL_EMAIL_HOST"

    export ENV_INFISICAL_EMAIL_USERNAME=$(get_secret "apps/infisical/infisical-gmail-email.secret.age")
    echo "Exported ENV_INFISICAL_EMAIL_USERNAME=$ENV_INFISICAL_EMAIL_USERNAME"

    export ENV_INFISICAL_EMAIL_PASSWORD=$(get_secret "apps/infisical/infisical-gmail-app-password.secret.age")
    echo "Exported ENV_INFISICAL_EMAIL_PASSWORD=$ENV_INFISICAL_EMAIL_PASSWORD"

    export ENV_INFISICAL_EMAIL_PORT=587
    echo "Exported ENV_INFISICAL_EMAIL_PORT=$ENV_INFISICAL_EMAIL_PORT"

    export ENV_INFISICAL_EMAIL_FROM=$(get_secret "apps/infisical/infisical-gmail-email.secret.age")
    echo "Exported ENV_INFISICAL_EMAIL_FROM=$ENV_INFISICAL_EMAIL_FROM"

    export ENV_INFISICAL_EMAIL_NAME="Infisical"
    echo "Exported ENV_INFISICAL_EMAIL_NAME=$ENV_INFISICAL_EMAIL_NAME"

    export ENV_TEST_DECRYPTION_COMMON=$(get_secret "test/test-code-string.secret.age")
    echo "Exported ENV_TEST_DECRYPTION_COMMON=$ENV_TEST_DECRYPTION_COMMON"

    echo ""
    echo ""
    echo "WARNING: In my original setup with v0.77.0-postgres, the unifi firewall was blocking" 
    echo "         the connection to the Infisical server. I had to add a signature supression rule to"
    echo "         allow allow both directions to the Infisical server for signature:"
    echo "           ET WEB_SPECIFIC_APPS MOVEit File Transfer - Folder Request - CVE-2023-34362 Stage 4"
    echo ""
    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1
  
fi
