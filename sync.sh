#!/usr/bin/env bash

# Load configuration from config.txt
CONFIG_FILE="config.txt"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Rsync options
RSYNC_OPTIONS="-az --exclude-from=./exclude.txt"

# Check if --dry-run option is provided
if [[ "$1" == "--dry-run" ]]; then
    RSYNC_OPTIONS="$RSYNC_OPTIONS --dry-run"
    echo "Performing dry run..."
fi

# Check if -v option is provided
if [[ "$1" == "-v" || "$2" == "-v" ]]; then
    # Enable tracing and add -v option to rsync
    set -x
    RSYNC_OPTIONS="$RSYNC_OPTIONS -v"
fi

# Perform the rsync operation
rsync $RSYNC_OPTIONS "$localdir" "$user@$host:$remotedir"

# Disable tracing if -v option was provided
if [[ "$1" == "-v" || "$2" == "-v" ]]; then
    set +x
fi