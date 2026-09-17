#!/bin/bash
# docker-env.sh
#
# Environment orchestrator. Sourced by docker-control.sh
# (via docker-start.sh / docker-stop.sh) before container actions, or directly
# for local shell environments.
#
# Execution flow:
# 1. Resolves script directory via realpath (which covers symlinks).
# 2. Sources local docker-paths.sh for shared script locations.
# 3. Invokes docker-env-bootstrap.sh for core functions, safety guards, and common env.
# 4. Sources repo-specific vars and secrets from docker-env-repo.sh.

# Get the true folder where THIS script lives on disk
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Source paths.sh relative to this script's directory
source "$SCRIPT_DIR/docker-paths.sh"

# Source and run environment setup script (setup and common vars/secrets)
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}"

# Source repo vars/secrets
source "$SCRIPT_DIR/docker-env-repo.sh"
