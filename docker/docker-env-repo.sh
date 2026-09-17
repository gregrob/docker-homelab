#!/bin/bash
# docker-env-repo.sh
#
# Environment variables and secrets unique to this repo.
#
# Assumes the caller has already sourced env-helper.sh AND
# secrets-helper.sh (the export_secret and export_var calls below 
# depend on it).

echo "--------------------------------------------"
echo "Setting up REPO environment for docker ..."
echo "--------------------------------------------"

# Repo-specific exports go here
# export_var ENV_DOCKER_HOMELAB_COMPOSE_PROJECT "docker-homelab"
# export_secret ENV_DOCKER_HOMELAB_SHARED_API_TOKEN "apps/docker-homelab/shared-api-token.secret.age"
