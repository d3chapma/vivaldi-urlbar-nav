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

# 1. Copy the mod script into the bundle.
cp "$DIR/$SCRIPT" "$RES/$SCRIPT"

# 2. Add the <script> tag to window.html (idempotent).
WIN="$RES/window.html"
if ! grep -q "$SCRIPT" "$WIN"; then
  perl -0pi -e "s{</body>}{  <script src=\"$SCRIPT\"></script>\n</body>}" "$WIN"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] installed into: $RES"
