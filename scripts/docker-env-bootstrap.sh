#!/bin/bash
# docker-env-bootstrap.sh
#
# Shared boilerplate for every repo's docker-env.sh: verifies the calling
# file was sourced (not run directly), sources helper functions, sets the
# default SECRET_DEBUG state, and sources common environment variables
# (docker-env-common.sh).
#
# WHY THE CALLER PASSES BASH_SOURCE[0]/$0 IN:
# Inside a function, BASH_SOURCE[0] always resolves to this file (where the
# function was defined), not the caller. The caller evaluates BASH_SOURCE[0]
# and $0 in its own top-level context and passes them as arguments so this
# function can accurately detect if docker-env.sh was executed directly.
#
# Usage (from docker-env.sh):
#   docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}"

# Set to 'true' to display secrets in the console during troubleshooting
SECRET_DEBUG_VALUE=false

docker_env_bootstrap() {
    local calling_source="$1"
    local invoked_as="$2"

    if [[ "$calling_source" == "$invoked_as" ]]; then
        echo "FAIL: Please source this script rather than executing it directly:"
        echo "      source ./$(basename "$calling_source")"
        exit 1
    fi

    echo "Paths sourced: DOCKER_HOMELAB_SCRIPTS_DIR=$DOCKER_HOMELAB_SCRIPTS_DIR | SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR=$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR"

    # Shared helpers
    source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
    source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"

    # Only set to true during debug (displays secrets in console output)
    export SECRET_DEBUG="$SECRET_DEBUG_VALUE"

    # Generic host-level vars and shared secrets
    source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-common.sh"
}
