#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then

    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY=$(get_secret "apps/homepage/homepage-speedtest-tracker-key.secret.age")
    echo "Exported ENV_HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY=$ENV_HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY"

    export ENV_HOMEPAGE_VAR_JELLYFIN_KEY=$(get_secret "apps/homepage/homepage-jellyfin-key.secret.age")
    echo "Exported ENV_HOMEPAGE_VAR_JELLYFIN_KEY=$ENV_HOMEPAGE_VAR_JELLYFIN_KEY"

    export ENV_HOMEPAGE_VAR_SONARR_KEY=$(get_secret "apps/homepage/homepage-sonarr-key.secret.age")
    echo "Exported ENV_HOMEPAGE_VAR_SONARR_KEY=$ENV_HOMEPAGE_VAR_SONARR_KEY"

    export ENV_HOMEPAGE_VAR_RADARR_KEY=$(get_secret "apps/homepage/homepage-radarr-key.secret.age")
    echo "Exported ENV_HOMEPAGE_VAR_RADARR_KEY=$ENV_HOMEPAGE_VAR_RADARR_KEY"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1

fi
