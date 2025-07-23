#!/bin/bash

# Colours to use in echo
RED='\033[0;31m' # Red colour for printing errors
NC='\033[0m'     # No colour

# Docker method (start or stop)
DOCKER_METHOD="docker-start.sh"
DOCKER_METHOD_STR="Starting"

# Path to specific compose file
DOCKER_METHOD_SPECIFIC="./${DOCKER_METHOD}"

# Docker V1 command
DOCKER_V1_COMMAND="docker-compose up -d"

# Docker V2 command
DOCKER_V2_COMMAND="docker compose up -d"


# Setup the environment
setup_environment () {
    # Setup common environment
    DOCKER_ENV_COMMON=../docker-env.sh
    source "$DOCKER_ENV_COMMON"

    # Setup server specific environment (if it exists)
    DOCKER_ENV_SERVER_SPECIFIC=../docker-env-${HOSTNAME}.sh

    if test -f "$DOCKER_ENV_SERVER_SPECIFIC"; then
        source "$DOCKER_ENV_SERVER_SPECIFIC"
        
    fi

    # Setup speficic environment (if it exists)
    DOCKER_ENV_SPECIFIC=./docker-env.sh

    if test -f "$DOCKER_ENV_SPECIFIC"; then
        source "$DOCKER_ENV_SPECIFIC"
    fi
}

# Check script is called from the correct location
check_script_calling_source () {

    # Make sure the script is not called from its source location
    SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    if [ $SCRIPT_DIR = $PWD ]; then
        echo -e "${RED}ERROR${NC}:"
        echo "        This script is intended to be called for the container folder itself."
        echo "        It appears like you have called from the source location."
        echo "        Are you sure you are in the correct folder?"
        echo ""
        echo "        This is OK:     \srv\containers\pihole"
        echo "        This is NOT OK: \srv\containers"
        echo ""
        
        # Exit from the script
        exit 1
    fi
}


# Invalid parameters
invalid_parameters () {
    echo -e "${RED}ERROR${NC}:"
    echo "        Usage: ../${DOCKER_METHOD} [METHOD]"
    echo ""
    echo "        Valid METHODS:"
    echo "        1. dryrun - tests generation of the environment"
    echo "        2. v2     - to use the docker compose v2 method"
    echo "        3. v1     - to use the docker compose v1 method (depreciated)"
    echo ""

    # Exit from the script
    exit 1
}


# Check script is called from the right path (i.e. docker subfolder)
check_script_calling_source

# Check how to call the docker compose command in the following priority order
#   1. Specific script exists
#   2. Passing "dryrun" test generation of the environment
#   2. Passing "v2" to use the docker compose v2 method
#   3. Passing "v1" to use the docker compose v1 method (depreciated)    
if test -f "$DOCKER_METHOD_SPECIFIC"; then
    setup_environment
    echo "${DOCKER_METHOD_STR} with specific script"
    $DOCKER_METHOD_SPECIFIC

elif [ "$1" = "dryrun" ]; then
    setup_environment
    echo "Not calling docker container commands"

elif [ "$1" = "v2" ]; then
    setup_environment
    echo "${DOCKER_METHOD_STR} with the v2 API"
    eval $DOCKER_V2_COMMAND

elif [ "$1" = "v1" ]; then
    setup_environment
    echo "${DOCKER_METHOD_STR} with the V1 API"
    eval $DOCKER_V1_COMMAND

else
    invalid_parameters

fi

exit 0
