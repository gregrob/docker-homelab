#!/bin/bash
# docker-env-bootstrap.sh
#
# Shared boilerplate for every repo's docker/docker-env.sh: verifies the
# calling file was sourced (not run directly), then sources the two
# helper scripts, sets the default SECRET_DEBUG state, sources the
# common environment (docker-env-common.sh), and prints the "REPO"
# banner. A repo's own docker-env.sh sources this, calls
# docker_env_bootstrap, then adds only its own repo-specific vars/secrets
# after that call.
#
# WHY THE CALLER PASSES BASH_SOURCE[0]/$0 IN, RATHER THAN THIS FUNCTION
# CHECKING THEM ITSELF: inside a function, BASH_SOURCE[0] always resolves
# to the file the function was DEFINED in (this file), not whichever
# repo's docker-env.sh called it — so this function could never correctly
# detect "was docker-homelab's docker-env.sh run directly?" on its own.
# The caller evaluates BASH_SOURCE[0]/$0 in ITS OWN top-level context
# (where they're guaranteed correct) and passes the results in as plain
# strings; this function only ever compares two strings it was handed,
# so it works correctly regardless of which repo's docker-env.sh calls it.
#
# Usage (from a repo's docker-env.sh, not called directly):
#   docker_env_bootstrap "${BASH_SOURCE[0]}" "${0}"

# Set to 'true' to display secrets in the console during troubleshooting
SECRET_DEBUG_VALUE=false

docker_env_bootstrap() {
    local calling_source="$1"
    local invoked_as="$2"

    if [[ "$calling_source" == "$invoked_as" ]]; then
        echo "FAIL: Please call script with - source ./$(basename "$calling_source")"
        exit 1
    fi

    # Shared helpers
    source "$DOCKER_HOMELAB_SCRIPTS_DIR/env-helper.sh"
    source "$SECRETS_HOMELAB_CLIENT_SCRIPTS_DIR/secrets-helper.sh"

    # Only set the following to true during DEBUG as it will display all secrets in the console
    export SECRET_DEBUG="$SECRET_DEBUG_VALUE"

    # Generic host-level vars and commonly-shared secrets, sourced by every docker-* repo
    source "$DOCKER_HOMELAB_SCRIPTS_DIR/docker-env-common.sh"

}
