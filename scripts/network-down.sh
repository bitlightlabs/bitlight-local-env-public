#!/bin/bash -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/env.sh"

if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
    echo "Removing network $NETWORK_NAME..."
    docker network rm $NETWORK_NAME
else
    echo "Network $NETWORK_NAME does not exist."
fi

