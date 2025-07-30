#!/bin/bash

# Include the secrets helper script to use get_secret function
source "$(dirname "${BASH_SOURCE[0]}")/../secrets-helper.sh"

# Check if the script is being sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]
then   
    
    echo "----------------------------------------------"
    echo "Setting up SPECIFIC environment for docker ..."
    echo "----------------------------------------------"

    #export EXAMPLE="example var"
    #echo "Exported EXAMPLE=$EXAMPLE"

    echo ""

else
    echo "FAIL: Please call script with - source ./env.sh"

    exit 1
  
fi
