#!/bin/bash
# docker-start.sh
#
# Thin jumper — all real logic lives in
# /srv/docker-homelab/scripts/docker-control.sh, shared across every
# docker-* repo. This file's only job is to compute its own directory
# (needed so the shared logic can correctly detect misuse and find this
# repo's docker-env.sh) and hand off.

# Get the true folder where THIS script lives on disk
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Source configuration (paths, defaults) relative to this script's directory
source "$SCRIPT_DIR/docker-config.sh"

# Source and run control script
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-control.sh"
docker_control_run "start" "$SCRIPT_DIR" "$@"
