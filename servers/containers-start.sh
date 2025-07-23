#!/bin/bash

# Shortcut to the server's folder
SERVER_PATH=./${HOSTNAME}

# Docker method (start or stop)
DOCKER_METHOD="docker-start.sh"
DOCKER_METHOD_STR="Starting"

# Change into the servers folder
cd ${SERVER_PATH}

# Loop through all of the folders
for dir in */; do

    # Change into container folder
    cd $dir

    echo "${DOCKER_METHOD_STR} container inside $dir"
    eval ../$DOCKER_METHOD v2

    # Change out of container
    cd ..

done

