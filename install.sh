#!/bin/bash
# Install (or re-apply after a Vivaldi update) the urlbar-nav UI mod.
# Run with: sudo ~/.vivaldi-mods/install.sh
set -euo pipefail

APP="/Applications/Vivaldi.app"
SCRIPT="urlbar-nav.js"

# Resolve the mods dir from this script's own location, so it works
# correctly even when invoked via sudo (where $HOME is /var/root).
MODS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Newest versioned resources dir (an update may leave old ones behind).
RES=$(ls -dt "$APP/Contents/Frameworks/Vivaldi Framework.framework/Versions/"*/Resources/vivaldi 2>/dev/null | head -1)
if [ -z "${RES:-}" ]; then
  echo "ERROR: could not find Vivaldi resources dir under $APP" >&2
  exit 1
fi
echo "Target: $RES"

# 1. Copy the mod script into the bundle.
cp "$MODS_DIR/$SCRIPT" "$RES/$SCRIPT"
echo "Copied $SCRIPT"

# 2. Add the <script> tag to window.html (idempotent).
WIN="$RES/window.html"
if grep -q "$SCRIPT" "$WIN"; then
  echo "window.html already references $SCRIPT — skipping patch"
else
  perl -0pi -e "s{</body>}{  <script src=\"$SCRIPT\"></script>\n</body>}" "$WIN"
  echo "Patched window.html"
fi

echo
echo "Done. Fully quit Vivaldi (Cmd+Q) and relaunch for the mod to load."
