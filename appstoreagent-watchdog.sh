#!/bin/sh
set -eu

# Kills appstoreagent only when its reported CPU usage stays above the threshold
# at the moment this script is run. Intended to be triggered periodically by launchd.

PROCESS_NAME="${APPSTOREAGENT_PROCESS_NAME:-appstoreagent}"
CPU_THRESHOLD="${APPSTOREAGENT_CPU_THRESHOLD:-80}"
TERM_WAIT_SECONDS="${APPSTOREAGENT_TERM_WAIT_SECONDS:-5}"
DRY_RUN="${APPSTOREAGENT_DRY_RUN:-0}"
LOG_FILE="${APPSTOREAGENT_LOG_FILE:-$HOME/Library/Logs/appstoreagent-watchdog.log}"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*" >> "$LOG_FILE"
}

cpu_is_over_threshold() {
  awk -v cpu="$1" -v threshold="$2" 'BEGIN { exit !((cpu + 0) >= (threshold + 0)) }'
}

found_any=0

for pid in $(pgrep -x "$PROCESS_NAME" 2>/dev/null || true); do
  found_any=1
  cpu="$(LC_ALL=C ps -p "$pid" -o %cpu= | awk '{print $1}')"

  if [ -z "$cpu" ]; then
    continue
  fi

  if cpu_is_over_threshold "$cpu" "$CPU_THRESHOLD"; then
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    log "cpu=${cpu}% threshold=${CPU_THRESHOLD}% pid=${pid} action=terminate command=${command_line}"

    if [ "$DRY_RUN" = "1" ]; then
      log "dry_run=1 pid=${pid} action=skipped"
      continue
    fi

    if ! kill -TERM "$pid" 2>/dev/null; then
      log "pid=${pid} action=term_failed"
      continue
    fi

    sleep "$TERM_WAIT_SECONDS"

    if kill -0 "$pid" 2>/dev/null; then
      command_line_after="$(ps -p "$pid" -o command= 2>/dev/null || true)"
      case "$command_line_after" in
        "$PROCESS_NAME"|"$PROCESS_NAME "*|*"/$PROCESS_NAME"|*"/$PROCESS_NAME "*)
          log "pid=${pid} action=force_kill"
          kill -KILL "$pid" 2>/dev/null || log "pid=${pid} action=force_kill_failed"
          ;;
        *)
          log "pid=${pid} action=force_kill_skipped reason=process_changed command=${command_line_after}"
          ;;
      esac
    else
      log "pid=${pid} action=terminated"
    fi
  fi
done

if [ "$found_any" -eq 0 ]; then
  exit 0
fi
