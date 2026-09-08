#!/bin/sh
# ==============================================================================
# Post-Prune Backup & Offsite Sync Script
# Executed by offen/docker-volume-backup via the prune-post hook
# ==============================================================================

# Abort script execution immediately if any command fails
set -e
# Ensure pipelines (like ls | awk | xargs) fail if an intermediate command fails
set -o pipefail

# Ensure rsync is present inside the Alpine container without cluttering logs
apk add --no-cache rsync >/dev/null 2>&1

# ------------------------------------------------------------------------------
# Environment Variables & Validation
# ------------------------------------------------------------------------------
# Number of local backups to retain on disk (defaults to 7)
KEEP="${ENV_DOCKER_VOLUME_BACKUP_KEEP_LAST_BACKUPS:-7}"

# ASUSTOR NAS Rsync daemon credentials and target module configuration
NAS_HOST="${ENV_RSYNC_SYNC_NAS_HOST:?missing host}"
NAS_USER="${ENV_RSYNC_SYNC_NAS_USER:?missing user}"
RSYNC_PASSWORD="${ENV_RSYNC_SYNC_NAS_PASSWORD:?missing password}"
NAS_MODULE="${ENV_RSYNC_SYNC_NAS_MODULE:?missing module}"
NODE_HOSTNAME="${ENV_RSYNC_SYNC_HOSTNAME:?missing hostname}"

# Export password so native rsync can authenticate without interactive prompts
export RSYNC_PASSWORD

# ------------------------------------------------------------------------------
# Local Archive Pruning
# ------------------------------------------------------------------------------
# List local archives by modification time (newest first), skip the newest $KEEP files,
# and remove older archives to prevent local disk exhaustion
ls -1t /archive/*.tar.gz | awk "NR > $KEEP" | xargs -r -t rm -rf

# ------------------------------------------------------------------------------
# Offsite Daemon Sync (Port 873)
# ------------------------------------------------------------------------------
# Sync local /archive contents to the NAS Rsync module subfolder for this host.
# Flags: -a (archive mode), -v (verbose), -z (compress data), --delete (purge remote files deleted locally)
rsync -avz --delete /archive/ rsync://"${NAS_USER}"@"${NAS_HOST}"/"${NAS_MODULE}"/"${NODE_HOSTNAME}"/
