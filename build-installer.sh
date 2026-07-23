#!/bin/bash
# Build "Install urlbar-nav.app" -- a double-clickable Finder installer.
#
# Run this once (or after editing urlbar-nav.js) to (re)generate the app:
#   ./build-installer.sh
# Then double-click the resulting app in Finder. The first run prompts for the
# App Management permission for the app itself; grant it once and it persists
# across Vivaldi updates.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Install urlbar-nav.app"
OUT="$DIR/$APP_NAME"

rm -rf "$OUT"
osacompile -o "$OUT" "$DIR/installer.applescript"

RES="$OUT/Contents/Resources"
cp "$DIR/urlbar-nav.js" "$RES/urlbar-nav.js"
cp "$DIR/do-install.sh" "$RES/do-install.sh"
chmod +x "$RES/do-install.sh"

echo "Built: $OUT"
echo "Double-click it in Finder to install."
