#!/bin/bash

# this is the development entrypoint wrapper script: sets up the right env
# variables for caching the bundle

export PATH="/usr/local/app-bundle:$PATH"
export BUNDLE_PATH='/usr/local/app-bundle'

[ -n "$DEBUG" ] && echo "Running: $@"

exec $@
