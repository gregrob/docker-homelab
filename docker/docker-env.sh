#!/bin/bash
# docker-env.sh
#
# Repo-specific environment setup for docker-homelab. Sourced by
# docker-control.sh (via docker-start.sh / docker-stop.sh) before every
# container start/stop, and can also be sourced directly for local
# testing.
#
# Calls the shared docker_env_bootstrap (repo_dir = this file's own
# directory, source_common = true, no callback), then sources this
# repo's own tier-2 common vars/secrets.

# Get the true folder where THIS script lives on disk
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Source configuration (paths, defaults) relative to this script's directory
source "$SCRIPT_DIR/docker-config.sh"

# Source and run environment setup script (setup and common vars/secrets)
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$SCRIPT_DIR" true

# Source repo vars/secrets
source "$SCRIPT_DIR/docker-env-repo.sh"
