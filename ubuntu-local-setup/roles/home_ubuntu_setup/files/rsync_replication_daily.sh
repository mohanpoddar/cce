#!/bin/bash

# Replication script for syncing exact data in either direction:
#   server1 -> server2
#   server2 -> server1
#
# Usage examples:
#   sudo ./rsync_replication_daily.sh \
#       cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
#       /opt/ccpldata/ccplnewdata/CCEPL_SERVER/
#
#   sudo ./rsync_replication_daily.sh \
#       /opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
#       cce@192.168.10.219:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/
#
# Dry run example:
#   sudo DRY_RUN=true ./rsync_replication_daily.sh \
#       cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
#       /opt/ccpldata/ccplnewdata/CCEPL_SERVER/

set -u

# Host-specific configuration
if [ "$(hostname)" = "av-pc" ]; then
    DC="GreaterNoida"
elif [ "$(hostname)" = "av-pc-dr" ]; then
    DC="GreaterNoida"
elif [ "$(hostname)" = "503S" ]; then
    DC="Vashundhara"
elif [ "$(hostname)" = "mylearnersepoint" ]; then
    DC="TESTLEPOINT"
else
    DC="UNKNOWN"
fi

RSYNC_USER="${RSYNC_USER:-cce}"
RSYNC_LOG_DIR="${RSYNC_LOG_DIR:-/home/cce/logs/rsync}"
RSYNC_EMAIL_FILE="${RSYNC_EMAIL_FILE:-/home/cce/rayo/scripts/github/cceplrsyncmail.py}"
DRY_RUN="${DRY_RUN:-false}"

# Source and destination can be passed as positional arguments or via environment variables.
SRC="${1:-${RSYNC_SOURCE:-}}"
DST="${2:-${RSYNC_DEST:-}}"

if [ -z "$SRC" ] || [ -z "$DST" ]; then
    echo "Usage: $0 <source> <destination>"
    echo "Example 1 (server1 -> server2):"
    echo "  $0 cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/ /opt/ccpldata/ccplnewdata/CCEPL_SERVER/"
    echo "Example 2 (server2 -> server1):"
    echo "  $0 /opt/ccpldata/ccplnewdata/CCEPL_SERVER/ cce@192.168.10.219:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/"
    exit 1
fi

mkdir -p "$RSYNC_LOG_DIR"

# Count currently running rsync jobs matching the source path when possible.
PS1=$(ps -ef | egrep "rsync .*${SRC}" | grep -v grep | wc -l)

echo "Hostname: $(hostname)"
echo "Number of rsync process: $PS1"
echo "Host Location: ${DC}"
echo "Source: ${SRC}"
echo "Destination: ${DST}"

ccersync () {
    if [ "$PS1" -gt 1 ]; then
        echo "Rsync is already running. Skipping replication."
        return 0
    else
        starttime=$(date +'%d-%m-%Y-%H%M%S')
        LOG_FILE="${RSYNC_LOG_DIR}/rsync_replication_${DC}_${starttime}.log"

        echo ${LOG_FILE}

        echo "TASK STARTS AT : $(date)" >> "$LOG_FILE"
        echo "START rsync replication at : $(date)" >> "$LOG_FILE"
        echo "SOURCE : ${SRC}" >> "$LOG_FILE"
        echo "DESTINATION : ${DST}" >> "$LOG_FILE"

        if [ "$DRY_RUN" = "true" ]; then
            echo "DRY RUN MODE ENABLED" >> "$LOG_FILE"
            rsync -avh --delete --checksum --dry-run --stats "$SRC" "$DST" >> "$LOG_FILE" 2>&1
            status=$?
        else
            rsync -avh --delete --checksum --stats "$SRC" "$DST" >> "$LOG_FILE" 2>&1
            status=$?
        fi

        echo "RSYNC EXIT CODE : ${status}" >> "$LOG_FILE"
        echo "END rsync at : $(date)" >> "$LOG_FILE"
        echo "TASK ENDS AT : $(date)" >> "$LOG_FILE"

        if [ "$status" -eq 0 ]; then
            echo "Replication finished successfully at $(date)"
            if [ -f "$RSYNC_EMAIL_FILE" ]; then
                python3 "$RSYNC_EMAIL_FILE"
            fi
        else
            echo "Replication failed with exit code ${status} at $(date)"
            if [ -f "$RSYNC_EMAIL_FILE" ]; then
                python3 "$RSYNC_EMAIL_FILE"
            fi
            return "$status"
        fi
    fi
}

ccersync
