#!/bin/bash
# docker-config.sh
#
# Single point of configuration for this repo — fixed paths and default
# settings. This is the ONE file to edit if either ever needs changing;
# every other file (docker-start.sh, docker-stop.sh, docker-env.sh, every
# container's docker-env.sh) sources this and nothing else defines these
# values.

# --- Paths ---------------------------------------------------------------
export DOCKER_HOMELAB_SCRIPTS_DIR="/srv/docker-homelab/scripts"
export SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR="/srv/secrets-homelab/client/scripts"

# --- Defaults --------------------------------------------------------------
# Set to 'true' to display secrets in the console during troubleshooting.
export SECRET_DEBUG_DEFAULT=false
