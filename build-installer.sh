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
cp "$DIR/autowatch-run.sh" "$RES/autowatch-run.sh"
chmod +x "$RES/do-install.sh" "$RES/autowatch-run.sh"

# osacompile emits no CFBundleIdentifier. Without one, LaunchServices can't
# register the bundle, so tccd logs "resolves to attributed bundle: (null)" and
# attributes the App Management request to the bare binary path
# (Contents/MacOS/applet) instead of to the app. The System Settings grant then
# never matches and the request is denied *without prompting* -- do-install.sh
# just gets "Operation not permitted" from cp.
/usr/libexec/PlistBuddy -c \
  "Add :CFBundleIdentifier string com.dc.vivaldi-urlbar-nav.installer" \
  "$OUT/Contents/Info.plist" >/dev/null

# Copying files into Contents/Resources invalidates the ad-hoc signature that
# osacompile applied ("a sealed resource is missing or invalid"), which also
# breaks TCC attribution. Re-seal the bundle now that its contents are final.
codesign --force --sign - --timestamp=none "$OUT"

codesign --verify --strict "$OUT"

echo "Built: $OUT"
echo "Double-click it in Finder to install."
echo
echo "NOTE: this is an ad-hoc signature, so its identity is the code hash --"
echo "rebuilding produces a new identity. After a rebuild you must re-grant"
echo "App Management: System Settings > Privacy & Security > App Management."
echo "Remove any stale 'Install urlbar-nav' entry there first."
