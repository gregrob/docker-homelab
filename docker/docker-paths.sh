#!/bin/bash
# docker-paths.sh
#
# Fixed, repo-level path constants — where the shared scripts and
# secrets-homelab client live on disk. Sourced by docker-start.sh,
# docker-stop.sh, and docker-env.sh before anything else, so every other
# file in this repo can rely on these being set.

# Local directory paths for this environment
export DOCKER_HOMELAB_SCRIPTS_DIR="/srv/docker-homelab/scripts"
export SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR="/srv/secrets-homelab/client/scripts"
