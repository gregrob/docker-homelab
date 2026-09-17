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
# export_var ENV_HOSTNAME "$HOSTNAME"
# export_secret ENV_TEST_DECRYPTION_COMMON "test/test-code-string.secret.age" true
