#!/bin/bash
# get_secret: Fetches and decrypts a secret file from a remote server using SSH and age.
#
# Usage:
#   get_secret <remote_path>
#
# Environment variables (optional):
#   SECRET_SSH_SERVER - SSH user and host (default: secrets@secrets.max.lan)
#   SECRET_AGE_KEY    - Path to age private key (default: $HOME/.ssh/id_ed25519_secrets-server)
#   SECRET_BASE_DIR   - Base directory on remote server (default: /srv/secrets/encrypted)
#
# Example:
#   export SECRET_SSH_SERVER="user@host"
#   export SECRET_AGE_KEY="/path/to/key"
#   export SECRET_BASE_DIR="/custom/secrets/path"
#   secret=$(get_secret "database/password.age")  # Will fetch from $SECRET_BASE_DIR/database/password.age

get_secret() {
    local remote_path="$1"
    local ssh_server="${SECRET_SSH_SERVER:-secrets@secrets.max.lan}"
    local ssh_key="${SECRET_AGE_KEY:-$HOME/.ssh/id_ed25519_secrets-server}"
    local base_dir="${SECRET_BASE_DIR:-/srv/secrets/encrypted}"

    if [[ -z "$remote_path" ]]; then
        echo "Usage: get_secret <remote_path>" >&2
        return 1
    fi

    # If remote_path starts with /, use it as absolute path, otherwise prepend base_dir
    if [[ "$remote_path" == /* ]]; then
        local full_path="$remote_path"
    else
        local full_path="$base_dir/$remote_path"
    fi

    ssh "$ssh_server" "cat \"$full_path\"" | age -d -i "$ssh_key"
    if [[ ${PIPESTATUS[0]} -ne 0 || ${PIPESTATUS[1]} -ne 0 ]]; then
        echo "Error: Failed to fetch or decrypt secret from $full_path" >&2
        return 2
    fi
}