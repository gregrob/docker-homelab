#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export_secret ENV_POSTGRES_USER "apps/wiki/wiki-postgres-user.secret.age"
    export_secret ENV_POSTGRES_PASSWORD "apps/wiki/wiki-postgres-password.secret.age"

    echo ""
    echo "The mounted volume /wiki/data/content is owned by node:node inside the container (1000:1000)."
    echo "Need to make sure the local volume has the same permissions."
    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
