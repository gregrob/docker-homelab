#!/bin/bash
# docker-env.sh (container level)

# =============================================================================
# ENVIRONMENT VARIABLES & SECRETS
# =============================================================================
load_container_env() {
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    echo "--------------------------------------------------"
    echo "Setting up environment with container versions ..."
    echo "--------------------------------------------------" 

    export_var ENV_TRAEFIK_CERTIFICATE_STORE "./data/host/acme.json" 

    export_secret ENV_TRAEFIK_CF_DNS_API_EMAIL "apps/traefik/traefik-cf-dns-api-email.secret.age"
    export_secret ENV_TRAEFIK_CF_DNS_API_TOKEN "apps/traefik/traefik-cf-dns-api-token.secret.age"

    export_var ENV_TRAEFIK_VERSION "v3.8.0"

    export_var ENV_WHOAMI_VERSION "v1.12.0"

    echo ""
    echo "Checking $ENV_TRAEFIK_CERTIFICATE_STORE (must exist, mode 600, before the container starts)"

    if test -f "$ENV_TRAEFIK_CERTIFICATE_STORE"; then
        echo "Skipping creation of $ENV_TRAEFIK_CERTIFICATE_STORE as it exists"
    else
        echo "Creating $ENV_TRAEFIK_CERTIFICATE_STORE as it does not exist"
        mkdir -p "$(dirname "$ENV_TRAEFIK_CERTIFICATE_STORE")"
        touch "$ENV_TRAEFIK_CERTIFICATE_STORE"
    fi

    # Always enforce, not just on create: Traefik refuses to use acme.json
    # if it is group/world readable (e.g. restored from a backup or git).
    echo "Applying permissions 600 to $ENV_TRAEFIK_CERTIFICATE_STORE"
    chmod 600 "$ENV_TRAEFIK_CERTIFICATE_STORE"

    echo ""
}

# =============================================================================
# Bootstrap & Execution (shared docker_env_bootstrap)
# =============================================================================
CONTAINER_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$CONTAINER_DIR/../docker-config.sh"
source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-bootstrap.sh"
docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}" "$CONTAINER_DIR/.." false load_container_env
