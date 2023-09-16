#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOGFILE="$SCRIPT_DIR/jact.log"

JACT_DEBUG_LOG=true
if [ "${JACT_DEBUG_LOG}" == "true" ]; then
    while IFS= read -r line; do
        echo "$(date "+%Y-%m-%d %H:%M:%S") - $line" >> "$LOGFILE"
    done
fi
