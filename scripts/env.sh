#!/usr/bin/env bash
set -e

ENV_LIST=(
    BITCOIN_COMPOSE_PROJECT_NAME
    LND_COMPOSE_PROJECT_NAME
    NETWORK_NAME
    NETWORK_SUBNET
)
# check variables is all set in list
IS_ALL_SET=true

for env in "${ENV_LIST[@]}"; do
    if [ -z "${!env}" ]; then
        echo "Error: $env is not set"
        IS_ALL_SET=false
    else
      export "$env"
    fi
done

if [ "$IS_ALL_SET" = false ]; then
    echo "Error: Not all environment variables are set"
    exit 1
fi
echo "Environment variables are all set"

