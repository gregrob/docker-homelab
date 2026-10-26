#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_DOCKER_VOLUME_BACKUP_GMAIL_APP_PASSWORD "apps/docker-volume-backup/docker-volume-backup-gmail-app-password.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_GMAIL_EMAIL "apps/docker-volume-backup/docker-volume-backup-gmail-email.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_EMAIL_TO "apps/docker-volume-backup/docker-volume-backup-email-to.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_RSYNC_SYNC_NAS_USER "apps/docker-volume-backup/docker-volume-backup-rsync-nas-user.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_RSYNC_SYNC_NAS_PASSWORD "apps/docker-volume-backup/docker-volume-backup-rsync-nas-password.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_RSYNC_SYNC_NAS_MODULE "apps/docker-volume-backup/docker-volume-backup-rsync-nas-module.secret.age"
    export_secret ENV_DOCKER_VOLUME_BACKUP_GPG_PASSPHRASE "apps/docker-volume-backup/docker-volume-backup-gpg-passphrase.secret.age"

    echo ""
    echo "Please run 'docker exec docker-volume-backup backup' to perform an immediate manual backup"

    echo ""
    echo "Backups are encrypted with gpg (symmetric, AES256). Files end in .tar.gz.gpg and must be"
    echo "  decrypted before tar can read them. The passphrase is the shared backup passphrase"
    echo "  (ENV_DOCKER_VOLUME_BACKUP_GPG_PASSPHRASE / backup_encryption_passphrase). Older backups"
    echo "  ending in .tar.gz are unencrypted and can be extracted directly."

    echo ""
    echo "Permission issues when restoring files under Linux can be problematic."
    echo "  tar (which this backup tool uses) stores both the numeric UID/GID and the resolved"
    echo "  username at creation time. On extraction, by default, it tries to resolve using the"
    echo "  stored username first — looking that name up in /etc/passwd on the destination system —"
    echo "  and only falls back to the numeric ID if that username doesn't exist there."
    echo "  Only --numeric-owner on extraction forces it to ignore the name entirely and use the number."
    echo ""
    echo "To decrypt and extract an encrypted backup (prompts for the passphrase):"
    echo "  sudo -v    # cache sudo first so its password prompt doesn't collide with gpg's"
    echo "  gpg --decrypt backup.tar.gz.gpg | sudo tar --numeric-owner -xzpf - -C /destination/"
    echo ""
    echo "To extract an old unencrypted backup:"
    echo "  sudo tar --numeric-owner -xzpf backup.tar.gz -C /destination/"
    echo ""
    echo "Flag breakdown:"
    echo "  gpg --decrypt   — Decrypts the .gpg file to stdout. Ownership is not involved at this"
    echo "                    step, so it runs as your normal user. The sudo that matters is on"
    echo "                    the tar half of the pipe."
    echo "  --numeric-owner — Forces tar to use the numeric UID/GID stored in the archive,"
    echo "                    ignoring the username entirely."
    echo "  sudo            — Required on tar. Non-root users cannot chown files to arbitrary numeric"
    echo "                    owners, and --numeric-owner only takes effect when run as root."
    echo "                    Without it, every restored file ends up owned by you."
    echo "  -x              — Extract files from the archive."
    echo "  -z              — Decompress gzip (use -j for bzip2, or -a for auto-detection)."
    echo "  -p              — Preserve permissions explicitly."
    echo "  -f              — Specify the archive file. '-f -' reads from stdin (the gpg pipe);"
    echo "                    use the filename (backup.tar.gz) for an unencrypted backup."
    echo "  -C              — Extract into the destination directory (/destination/)."
    echo ""
    echo "To check UID/GID distribution before and after extraction and including symlinked directories:"
    echo "  find -L /path/to/data -exec stat -c \"%u:%g\" {} + | sort | uniq -c | sort -rn"
    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
