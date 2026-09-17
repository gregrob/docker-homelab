#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    #export ENV_INFISICAL_TAG="v0.77.0-postgres"
    #export ENV_INFISICAL_TAG="v0.128.0-postgres"
    export_var ENV_INFISICAL_TAG "v0.158.22"
    export_var ENV_POSTGRES_USER "infisical"
    export_var ENV_POSTGRES_PASSWORD "infisical"
    export_var ENV_POSTGRES_DB "infisical"
    export_var ENV_HOST "infisical.max.lan"
    export_var ENV_INFISICAL_EMAIL_HOST "smtp.gmail.com"
    export_var ENV_INFISICAL_EMAIL_PORT 587
    export_var ENV_INFISICAL_EMAIL_NAME "Infisical"

    export_secret ENV_ENCRYPTION_KEY "apps/infisical/infisical-encryption-key.secret.age"
    echo "Generate new encryption key with: openssl rand -hex 16"

    export_secret ENV_AUTH_SECRET "apps/infisical/infisical-auth-secret.secret.age"
    echo "Generate new auth secret with: openssl rand -base64 32"

    export_secret ENV_INFISICAL_EMAIL_USERNAME "apps/infisical/infisical-gmail-email.secret.age"
    export_secret ENV_INFISICAL_EMAIL_PASSWORD "apps/infisical/infisical-gmail-app-password.secret.age"
    export_secret ENV_INFISICAL_EMAIL_FROM "apps/infisical/infisical-gmail-email.secret.age"

    echo ""
    echo "WARNING: In my original setup with v0.77.0-postgres, the unifi firewall was blocking" 
    echo "         the connection to the Infisical server. I had to add a signature supression rule to"
    echo "         allow allow both directions to the Infisical server for signature:"
    echo "           ET WEB_SPECIFIC_APPS MOVEit File Transfer - Folder Request - CVE-2023-34362 Stage 4"
    echo ""
}

# =============================================================================
# Delegate Guard, Bootstrap & Execution to Parent Helper
# =============================================================================
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../docker-env-repo-helper.sh"
