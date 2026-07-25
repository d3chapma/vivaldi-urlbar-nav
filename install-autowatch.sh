#!/bin/bash
# Install a LaunchAgent that re-applies the urlbar-nav mod automatically
# whenever Vivaldi updates.
#
# How it works: launchd watches Vivaldi's `Versions` directory. An update drops
# a new `Versions/<new-version>` folder in there, which fires the agent. The
# agent runs autowatch-run.sh (bundled in the app), which debounces the burst
# of filesystem events an update produces -- WatchPaths fires once per event,
# so without debouncing you'd get 5-6 back-to-back installs -- then runs
# "Install urlbar-nav.app" once in quiet (--auto) mode.
#
# IMPORTANT: This only works if you have ALREADY double-clicked
# "Install urlbar-nav.app" once and granted it App Management. The background
# run reuses that grant (it can't pop a consent prompt itself). If you rebuild
# the app (./build-installer.sh) its code identity changes and you must grant
# it again by double-clicking once.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-$DIR/Install urlbar-nav.app}"
LABEL="com.dc.vivaldi-urlbar-nav"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
WATCH="/Applications/Vivaldi.app/Contents/Frameworks/Vivaldi Framework.framework/Versions"

if [ ! -d "$APP" ]; then
  echo "ERROR: can't find the app at:" >&2
  echo "  $APP" >&2
  echo "Build it first with ./build-installer.sh, or pass the app path as an argument." >&2
  exit 1
fi

if [ ! -f "$APP/Contents/Resources/autowatch-run.sh" ]; then
  echo "ERROR: the app is missing autowatch-run.sh (built by an older" >&2
  echo "build-installer.sh). Rebuild it first: ./build-installer.sh" >&2
  exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$APP/Contents/Resources/autowatch-run.sh</string>
        <string>$APP</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>$WATCH</string>
    </array>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/vivaldi-urlbar-nav.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/vivaldi-urlbar-nav.log</string>
</dict>
</plist>
PLIST

# Reload cleanly (ignore "not loaded" on first run).
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Loaded LaunchAgent: $LABEL"
echo "  watching: $WATCH"
echo "  opens:    $APP"
echo "  log:      ~/Library/Logs/vivaldi-urlbar-nav.log"
echo
echo "It fires whenever that Versions directory changes (i.e. on a Vivaldi update)."
echo "Remove it with ./uninstall-autowatch.sh"
