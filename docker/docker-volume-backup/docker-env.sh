#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then   
    
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_DOCKER_VOLUME_BACKUP_GMAIL_APP_PASSWORD=$(get_secret "apps/docker-volume-backup/docker-volume-backup-gmail-app-password.secret.age")
    echo "Exported ENV_DOCKER_VOLUME_BACKUP_GMAIL_APP_PASSWORD=$ENV_DOCKER_VOLUME_BACKUP_GMAIL_APP_PASSWORD"

    export ENV_DOCKER_VOLUME_BACKUP_GMAIL_EMAIL=$(get_secret "apps/docker-volume-backup/docker-volume-backup-gmail-email.secret.age")
    echo "Exported ENV_DOCKER_VOLUME_BACKUP_GMAIL_EMAIL=$ENV_DOCKER_VOLUME_BACKUP_GMAIL_EMAIL"

    export ENV_DOCKER_VOLUME_BACKUP_EMAIL_TO=$(get_secret "apps/docker-volume-backup/docker-volume-backup-email-to.secret.age")
    echo "Exported ENV_DOCKER_VOLUME_BACKUP_EMAIL_TO=$ENV_DOCKER_VOLUME_BACKUP_EMAIL_TO"

    # This is always +1 (e.g. a value of 9 keeps 10 backups)
    export ENV_DOCKER_VOLUME_BACKUP_KEEP_LAST_BACKUPS="9"
    echo "Exported ENV_DOCKER_VOLUME_BACKUP_KEEP_LAST_BACKUPS=$ENV_DOCKER_VOLUME_BACKUP_KEEP_LAST_BACKUPS"

    echo ""
    echo "Please run 'docker exec docker-volume-backup backup' to perform an immediate manual backup"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1
  
fi
