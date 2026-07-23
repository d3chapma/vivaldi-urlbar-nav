#!/bin/bash
# Remove the auto-reinstall LaunchAgent created by install-autowatch.sh.
set -euo pipefail

LABEL="com.dc.vivaldi-urlbar-nav"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
echo "Removed LaunchAgent: $LABEL"
