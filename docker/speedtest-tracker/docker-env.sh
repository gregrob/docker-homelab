#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then   
    
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_SPEEDTEST_TRACKER_APP_KEY=$(get_secret "apps/speedtest-tracker/speedtest-tracker-app-key.secret.age")
    echo "Exported ENV_SPEEDTEST_TRACKER_APP_KEY=$ENV_SPEEDTEST_TRACKER_APP_KEY"

    export ENV_SPEEDTEST_TRACKER_ADMIN_NAME=$(get_secret "apps/speedtest-tracker/speedtest-tracker-admin-name.secret.age")
    echo "Exported ENV_SPEEDTEST_TRACKER_ADMIN_NAME=$ENV_SPEEDTEST_TRACKER_ADMIN_NAME"

    export ENV_SPEEDTEST_TRACKER_ADMIN_EMAIL=$(get_secret "apps/speedtest-tracker/speedtest-tracker-admin-email.secret.age")
    echo "Exported ENV_SPEEDTEST_TRACKER_ADMIN_EMAIL=$ENV_SPEEDTEST_TRACKER_ADMIN_EMAIL"

    export ENV_SPEEDTEST_TRACKER_ADMIN_PASSWORD=$(get_secret "apps/speedtest-tracker/speedtest-tracker-admin-password.secret.age")
    echo "Exported ENV_SPEEDTEST_TRACKER_ADMIN_PASSWORD=$ENV_SPEEDTEST_TRACKER_ADMIN_PASSWORD"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1
  
fi
