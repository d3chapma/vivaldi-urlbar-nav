#!/bin/bash
# The install logic, run from inside the .app bundle (Contents/Resources).
# urlbar-nav.js sits next to this script. Invoked by installer.applescript
# with administrator privileges.
set -euo pipefail

APP="/Applications/Vivaldi.app"
SCRIPT="urlbar-nav.js"

# This script's own directory (Contents/Resources) holds the mod script.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Newest versioned resources dir (an update may leave old ones behind).
RES=$(ls -dt "$APP/Contents/Frameworks/Vivaldi Framework.framework/Versions/"*/Resources/vivaldi 2>/dev/null | head -1)
if [ -z "${RES:-}" ]; then
  echo "ERROR: could not find Vivaldi resources dir under $APP" >&2
  exit 1
fi

# Track whether we actually touched anything, so an automated re-apply that
# finds the mod already in place stays silent (no notification). Without this,
# each coalesced LaunchAgent fire would still post a confirmation.
changed=0

# 1. Copy the mod script into the bundle (only if it differs / is missing).
if ! cmp -s "$DIR/$SCRIPT" "$RES/$SCRIPT" 2>/dev/null; then
  cp "$DIR/$SCRIPT" "$RES/$SCRIPT"
  changed=1
fi

# 2. Add the <script> tag to window.html (idempotent).
WIN="$RES/window.html"
if ! grep -q "$SCRIPT" "$WIN"; then
  perl -0pi -e "s{</body>}{  <script src=\"$SCRIPT\"></script>\n</body>}" "$WIN"
  changed=1
fi

if [ "$changed" -eq 1 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] installed into: $RES"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] no change, already applied: $RES"
fi
