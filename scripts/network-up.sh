#!/bin/bash -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/env.sh"

if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
    echo "Network $NETWORK_NAME exists."
else
    echo "Network $NETWORK_NAME does not exist. Creating..."
    docker network create --subnet=$NETWORK_SUBNET $NETWORK_NAME
fi