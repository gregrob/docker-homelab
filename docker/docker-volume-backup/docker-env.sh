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
    echo "Permission issues when restoring files under Linux can be problematic."
    echo "  tar (which this backup tool uses) stores both the numeric UID/GID and the resolved"
    echo "  username at creation time. On extraction, by default, it tries to resolve using the"
    echo "  stored username first — looking that name up in /etc/passwd on the destination system —"
    echo "  and only falls back to the numeric ID if that username doesn't exist there."
    echo "  Only --numeric-owner on extraction forces it to ignore the name entirely and use the number."
    echo ""
    echo "To extract:"
    echo "  sudo tar --numeric-owner -xzpf backup.tar.gz -C /destination/"
    echo ""
    echo "Flag breakdown:"
    echo "  --numeric-owner — Forces tar to use the numeric UID/GID stored in the archive,"
    echo "                    ignoring the username entirely."
    echo "  sudo            — Required. Non-root users cannot chown files to arbitrary numeric"
    echo "                    owners. --numeric-owner only takes effect when run as root."
    echo "  -x              — Extract files from the archive."
    echo "  -z              — Decompress gzip (use -j for bzip2, or -a for auto-detection)."
    echo "  -p              — Preserve permissions explicitly."
    echo "  -f              — Specify the archive file (backup.tar.gz)."
    echo "  -C              — Extract into the destination directory (/destination/)."
    echo ""
    echo "To check UID/GID distribution before and after extraction and including symlinked directories:"
    echo "  find -L /path/to/data -exec stat -c \"%u:%g\" {} + | sort | uniq -c | sort -rn"
    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1
  
fi
