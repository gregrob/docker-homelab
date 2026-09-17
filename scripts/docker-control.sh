#!/bin/bash
# docker-control.sh
#
# Shared logic behind docker-start.sh / docker-stop.sh across every
# docker-* repo (docker-homelab, docker-homelab-private, etc.) — those
# files are now thin jumpers that source this and call docker_control_run
# with a mode. Adding a new docker-* repo now only needs its own
# docker-env.sh (repo-specific vars/secrets); the start/stop machinery
# itself lives here once, not duplicated per repo.
#
# Usage (from a jumper script, not called directly):
#   docker_control_run <start|stop> <jumper_dir> "$@"
#
# jumper_dir MUST be the directory the CALLING jumper script itself lives
# in, computed there and passed in — this file can't infer it via its own
# BASH_SOURCE, since that always resolves to this shared file's own
# location in scripts/, not wherever a given repo's docker-start.sh /
# docker-stop.sh happen to live.

readonly _DC_RED='\033[0;31m'
readonly _DC_NC='\033[0m'

# Refuse to run if called from the jumper's own directory rather than a
# container subfolder.
_docker_control_check_calling_source() {
    local jumper_dir="$1"

    if [[ "$jumper_dir" == "$PWD" ]]; then
        echo -e "${_DC_RED}ERROR${_DC_NC}:"
        echo "        This script is intended to be called from a container's own folder."
        echo "        It appears like you have called it from its source location."
        echo "        Are you sure you are in the correct folder?"
        echo ""
        echo "        This is OK:     /srv/.../docker/container-a"
        echo "        This is NOT OK: /srv/.../docker"
        echo ""
        exit 1
    fi
}

# Sources, in order: the repo-level docker-env.sh (in jumper_dir), an
# optional per-host override, then an optional per-container override in
# the current directory. Same layering as before this refactor.
_docker_control_setup_environment() {
    local jumper_dir="$1"

    source "$jumper_dir/docker-env.sh"

    local host_specific="$jumper_dir/docker-env-${HOSTNAME}.sh"
    if [[ -f "$host_specific" ]]; then
        source "$host_specific"
    fi

    local container_specific="./docker-env.sh"
    if [[ -f "$container_specific" ]]; then
        source "$container_specific"
    fi
}

_docker_control_invalid_parameters() {
    local method_name="$1"

    echo -e "${_DC_RED}ERROR${_DC_NC}:"
    echo "        Usage: ../${method_name} [METHOD]"
    echo ""
    echo "        Valid METHODS:"
    echo "        1. dryrun - tests generation of the environment"
    echo "        2. v2     - to use the docker compose v2 method"
    echo "        3. v1     - to use the docker compose v1 method (deprecated)"
    echo ""
    exit 1
}

# docker_control_run: the actual entrypoint, called by each jumper.
#
# Arguments:
#   $1   - mode: "start" or "stop"
#   $2   - jumper_dir: the calling jumper script's own directory
#   $3.. - whatever the user passed to the jumper (dryrun/v1/v2)
docker_control_run() {
    local mode="$1"
    local jumper_dir="$2"
    shift 2

    local method_name method_str v1_command v2_command
    case "$mode" in
        start)
            method_name="docker-start.sh"
            method_str="Starting"
            v1_command="docker-compose up -d"
            v2_command="docker compose up -d"
            ;;
        stop)
            method_name="docker-stop.sh"
            method_str="Stopping"
            v1_command="docker-compose down"
            v2_command="docker compose down"
            ;;
        *)
            echo "ERROR: docker_control_run called with unknown mode '$mode'" >&2
            exit 1
            ;;
    esac

    _docker_control_check_calling_source "$jumper_dir"

    local method_specific="./${method_name}"

    if [[ -f "$method_specific" ]]; then
        _docker_control_setup_environment "$jumper_dir"
        echo "${method_str} with specific script"
        "$method_specific"

    elif [[ "$1" == "dryrun" ]]; then
        _docker_control_setup_environment "$jumper_dir"
        echo "Not calling docker container commands"

    elif [[ "$1" == "v2" ]]; then
        _docker_control_setup_environment "$jumper_dir"
        echo "${method_str} with the v2 API"
        eval "$v2_command"

    elif [[ "$1" == "v1" ]]; then
        _docker_control_setup_environment "$jumper_dir"
        echo "${method_str} with the V1 API"
        eval "$v1_command"

    else
        _docker_control_invalid_parameters "$method_name"
    fi
}
