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

START=$(date +%s)
log "=== sync started${1:+ ($1)}"

# Load configuration from config.txt
CONFIG_FILE="config.txt"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    log "ERROR: configuration file not found: $CONFIG_FILE"
    exit 1
fi

log "source: $localdir"
log "target: $user@$host:$remotedir"

# Build SSH command
SSH_CMD="ssh -o ConnectTimeout=30"

# If NAS is not directly reachable and a jump host is configured, use ProxyJump
if [ -n "$jump_host" ]; then
    if probe=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "$user@$host" true 2>&1); then
        log "route: direct"
    else
        log "direct ssh to $host failed: ${probe:-no output}"
        log "route: jumping through $jump_host"
        SSH_CMD="$SSH_CMD -o ProxyCommand='ssh $jump_host nc %h %p'"
    fi
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
    log "=== sync finished OK in ${elapsed}s"
else
    # Common codes: 12 = protocol/stream error, 23 = partial transfer, 255 = ssh failed
    log "=== sync FAILED (rsync exit $status) after ${elapsed}s; see $PWD/$LOG_FILE"
fi
exit "$status"
