#!/bin/bash
# docker-env-common.sh
#
# Environment variables and secrets shared across every repo
# (docker-homelab, docker-homelab-prv, etc.) — values every container
# host needs regardless of which repo it lives in. Sourced by each repo's
# own docker/docker-env.sh, which adds its own repo-specific vars/secrets
# after this.
#
# Assumes the caller has already sourced env-helper.sh AND
# secrets-helper.sh (the export_secret and export_var calls below 
# depend on it).

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
