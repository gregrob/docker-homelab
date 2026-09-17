#!/bin/bash

# Include the environment variable helper script to use export_var function
source "/srv/docker-homelab/scripts/env-helper.sh"

# Include the secrets helper script to use export_secret function
source "/srv/secrets-homelab/client/scripts/secrets-helper.sh"

# Only set the following to true during DEBUG as it will display all secrets in the console
export SECRET_DEBUG=false

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then
    echo "--------------------------------------------"
    echo "Setting up COMMON environment for docker ..."
    echo "--------------------------------------------"

    export_var ENV_HOSTNAME "$HOSTNAME"
    export_var ENV_LOCALIP "$(hostname -I | awk '{print $1}')"
    export_var ENV_LOOPBACK "127.0.0.1"
    export_var ENV_DOCKER_USER "$USER"
    export_var ENV_DOCKER_UID "$(id -u "$ENV_DOCKER_USER")"
    export_var ENV_DOCKER_GID "$(id -g "$ENV_DOCKER_USER")"
    export_var ENV_TZ "$(timedatectl show --property=Timezone --value)"

    export_secret ENV_NAS_BACKUP_TARGET "infra/nas-backup-target.secret.age"
    export_secret ENV_TEST_DECRYPTION_COMMON "test/test-code-string.secret.age" true

else
    echo "FAIL: Please call script with - source ./$(basename "${BASH_SOURCE[0]}")"

    exit 1

fi
