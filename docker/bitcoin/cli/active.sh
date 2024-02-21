#!/bin/sh

export PATH=$PATH:/cli/bin

# check if arguments are provided
if [ -z "$1" ]; then
  exec /bin/sh
else
  exec "$@"
fi
