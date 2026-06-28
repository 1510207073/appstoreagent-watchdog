#!/bin/sh
set -eu

LABEL="com.local.appstoreagent-watchdog"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DEST_SCRIPT="$HOME/.local/bin/appstoreagent-watchdog.sh"

launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
rm -f "$PLIST" "$DEST_SCRIPT"

echo "Uninstalled $LABEL"
echo "Logs were left in $HOME/Library/Logs/appstoreagent-watchdog*.log"
