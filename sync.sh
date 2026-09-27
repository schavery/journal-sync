#!/usr/bin/env bash

# Run from the script's directory so relative paths work however it is launched
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Every run appends timestamped output here; trimmed to the last LOG_MAX_LINES
LOG_FILE="sync.log"
LOG_MAX_LINES=5000

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

# Prefix each line of piped output with a timestamp and append it to the log
log_stream() {
    while IFS= read -r line; do
        log "  $line"
    done
}

if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt "$LOG_MAX_LINES" ]; then
    tail -n "$LOG_MAX_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Touched after each successful (non-dry-run) sync
STAMP_FILE=".last_success"
# Scheduled runs skip if the last success is newer than this
SYNC_EVERY_HOURS=20
# Scheduled runs that can't reach the NAS stay quiet until the last success is older than this
ALERT_AFTER_HOURS=48

# Scheduled runs come from launchd via Automator with no terminal attached;
# manual runs from a terminal always sync
scheduled=false
[ -t 1 ] || scheduled=true

hours_since_success() {
    if [ -f "$STAMP_FILE" ]; then
        echo $(( ($(date +%s) - $(stat -f %m "$STAMP_FILE")) / 3600 ))
    else
        echo 999999
    fi
}

if $scheduled && [ "$(hours_since_success)" -lt "$SYNC_EVERY_HOURS" ]; then
    exit 0
fi

START=$(date +%s)
log "=== sync started${1:+ ($1)}$($scheduled && echo ' [scheduled]')"

# Load configuration from config.txt
CONFIG_FILE="config.txt"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    log "ERROR: configuration file not found: $CONFIG_FILE"
    echo "Journal sync failed: configuration file not found: $PWD/$CONFIG_FILE" >&2
    exit 1
fi

log "source: $localdir"
log "target: $user@$host:$remotedir"

SSH_CMD="ssh -o ConnectTimeout=30"

# A scheduled run often fires during a brief dark wake while the Mac is
# asleep, when the network (and Tailscale) may not be up. Don't treat that
# as a failure unless it has gone on too long.
if ! probe=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$user@$host" true 2>&1); then
    log "NAS not reachable: ${probe:-no output}"
    age=$(hours_since_success)
    if $scheduled && [ "$age" -lt "$ALERT_AFTER_HOURS" ]; then
        log "=== skipped; will retry next run (last success ${age}h ago)"
        exit 0
    fi
    last="last success ${age}h ago"
    [ -f "$STAMP_FILE" ] || last="no successful sync recorded"
    log "=== sync FAILED: NAS unreachable, $last"
    echo "Journal sync failed: can't reach $host (${probe:-no output}); $last. Log: $PWD/$LOG_FILE" >&2
    exit 255
fi

# Rsync options
RSYNC_OPTIONS=(-avzs --size-only --exclude-from=./exclude.txt -e "$SSH_CMD")

# Check if --dry-run option is provided
if [[ "$1" == "--dry-run" ]]; then
    RSYNC_OPTIONS+=(--dry-run)
    log "dry run: no files will be copied"
fi

# Perform the rsync operation
/opt/homebrew/bin/rsync "${RSYNC_OPTIONS[@]}" "$localdir" "$user@$host:$remotedir" 2>&1 | log_stream
status=${PIPESTATUS[0]}

elapsed=$(( $(date +%s) - START ))
if [ "$status" -eq 0 ]; then
    [[ "$1" == "--dry-run" ]] || touch "$STAMP_FILE"
    log "=== sync finished OK in ${elapsed}s"
else
    # Common codes: 12 = protocol/stream error, 23 = partial transfer, 255 = ssh failed
    log "=== sync FAILED (rsync exit $status) after ${elapsed}s; see $PWD/$LOG_FILE"
    # Automator's error dialog shows only stderr, so summarize the failure there
    cause=$(tail -n 20 "$LOG_FILE" | grep -m1 -E 'ssh:|rsync error' | sed -E 's/^[0-9-]+ [0-9:]+ +//')
    echo "Journal sync failed (rsync exit $status): ${cause:-see log}. Log: $PWD/$LOG_FILE" >&2
fi
exit "$status"
