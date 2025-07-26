#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then   
    
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    export ENV_SEMAPHOREUI_ADMIN_PASSWORD=$(get_secret "apps/semaphoreui/semaphoreui-admin-password.secret.age")
    echo "Exported ENV_SEMAPHOREUI_ADMIN_PASSWORD=$ENV_SEMAPHOREUI_ADMIN_PASSWORD"

    export ENV_SEMAPHOREUI_ACCESS_KEY_ENCRYPTION=$(get_secret "apps/semaphoreui/semaphoreui-access-key-encryption.secret.age")
    echo "Exported ENV_SEMAPHOREUI_ACCESS_KEY_ENCRYPTION=$ENV_SEMAPHOREUI_ACCESS_KEY_ENCRYPTION"

    export ENV_SEMAPHOREUI_MYSQL_PASSWORD=$(get_secret "apps/semaphoreui/semaphoreui-mysql-password.secret.age")
    echo "Exported ENV_SEMAPHOREUI_MYSQL_PASSWORD=$ENV_SEMAPHOREUI_MYSQL_PASSWORD"

    export ENV_TEST_DECRYPTION_SPECIFIC=$(get_secret "test/test-code-string.secret.age")
    echo "Exported ENV_TEST_DECRYPTION_SPECIFIC=$ENV_TEST_DECRYPTION_SPECIFIC"

    echo ""

    echo "Volumes for SemaphoreUI need to have the correct owner and group set - 1001:root"
    echo "Please execute the following commands to set up volume permissions:"
    echo "sudo chown 1001:root ./data/host/semaphoreui/config"
    echo "sudo chown 1001:root ./data/host/semaphoreui/data"
    echo "sudo chown 1001:root ./data/host/semaphoreui/keys"
    echo "sudo chown 1001:root ./data/host/semaphoreui/tmp"

else
    echo "FAIL: Please call script with - source ./$(basename "${BASH_SOURCE[0]}")"

    exit 1
  
fi
