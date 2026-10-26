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
# Remove everything except the newest $KEEP archives. Handles both encrypted
# (.tar.gz.gpg) and legacy unencrypted (.tar.gz) archives so old ones age out.
#
# The next command is ONE multi-stage pipeline, written on a single line so a
# missing "|" can't silently split it. Each stage feeds the next:
#   1. ls -1t        List the directory, one name per line, newest first
#   2. grep -E ...   Keep only archive files (.tar.gz or .tar.gz.gpg), ignoring
#                    anything else. grep exits non-zero when nothing matches, so
#                    "|| true" stops set -e and pipefail from aborting the script
#                    (and skipping the rsync below). The { } groups the two.
#   3. awk "NR > N"  Skip the newest $KEEP lines; what is left are the ones to
#                    delete
#   4. xargs -r -t rm -f
#                    Delete them. -r: do nothing if the list is empty.
#                    -t: echo each rm to the container log so you can see what
#                    was pruned.
cd /archive
ls -1t | { grep -E '\.tar\.gz(\.gpg)?$' || true; } | awk "NR > $KEEP" | xargs -r -t rm -f

# ------------------------------------------------------------------------------
# Offsite Daemon Sync (Port 873)
# ------------------------------------------------------------------------------
# Sync local /archive contents to the NAS Rsync module subfolder for this host.
# Flags: -a (archive mode), -v (verbose), -z (compress data), --delete (purge remote files deleted locally)
rsync -avz --delete /archive/ rsync://"${NAS_USER}"@"${NAS_HOST}"/"${NAS_MODULE}"/"${NODE_HOSTNAME}"/
