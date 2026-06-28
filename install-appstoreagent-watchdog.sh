#!/bin/sh
set -eu

LABEL="com.local.appstoreagent-watchdog"
THRESHOLD="${1:-80}"
INTERVAL_SECONDS="${2:-60}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEST_DIR="$HOME/.local/bin"
DEST_SCRIPT="$DEST_DIR/appstoreagent-watchdog.sh"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
WATCHDOG_LOG="$HOME/Library/Logs/appstoreagent-watchdog.log"
STDOUT_LOG="$HOME/Library/Logs/appstoreagent-watchdog.launchd.out.log"
STDERR_LOG="$HOME/Library/Logs/appstoreagent-watchdog.launchd.err.log"

case "$THRESHOLD" in
  ''|*[!0-9.]*)
    echo "CPU threshold must be a number, got: $THRESHOLD" >&2
    exit 2
    ;;
esac

case "$INTERVAL_SECONDS" in
  ''|*[!0-9]*)
    echo "Interval seconds must be a positive integer, got: $INTERVAL_SECONDS" >&2
    exit 2
    ;;
esac

if [ "$INTERVAL_SECONDS" -lt 10 ]; then
  echo "Interval seconds must be at least 10." >&2
  exit 2
fi

mkdir -p "$DEST_DIR" "$LAUNCH_AGENTS_DIR" "$HOME/Library/Logs"
cp "$SCRIPT_DIR/appstoreagent-watchdog.sh" "$DEST_SCRIPT"
chmod 755 "$DEST_SCRIPT"

tmp_plist="$PLIST.tmp"
cat > "$tmp_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>$DEST_SCRIPT</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>$INTERVAL_SECONDS</integer>

  <key>EnvironmentVariables</key>
  <dict>
    <key>APPSTOREAGENT_CPU_THRESHOLD</key>
    <string>$THRESHOLD</string>
    <key>APPSTOREAGENT_LOG_FILE</key>
    <string>$WATCHDOG_LOG</string>
  </dict>

  <key>StandardOutPath</key>
  <string>$STDOUT_LOG</string>

  <key>StandardErrorPath</key>
  <string>$STDERR_LOG</string>
</dict>
</plist>
EOF

mv "$tmp_plist" "$PLIST"
plutil -lint "$PLIST" >/dev/null

launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true

echo "Installed $LABEL"
echo "CPU threshold: ${THRESHOLD}%"
echo "Check interval: ${INTERVAL_SECONDS}s"
echo "Script: $DEST_SCRIPT"
echo "LaunchAgent: $PLIST"
echo "Log: $WATCHDOG_LOG"

