#!/bin/bash
# Debounce the launchd WatchPaths storm a single Vivaldi update produces.
#
# WatchPaths fires the LaunchAgent once per *filesystem event*, and one update
# writes/deletes many files under the watched Versions dir -- so the agent used
# to fire 5-6 times in a row, each launching the installer and each posting a
# confirmation. This wrapper coalesces that burst.
#
# How the coalescing works: launchd never runs two instances of the same job at
# once. By sleeping here through the update, the first fire absorbs the whole
# storm; launchd queues the remaining events and, at most, runs this job once
# more after we exit. That single follow-up is harmless because do-install.sh
# only reports a change (and the app only notifies) when it actually modifies
# the bundle -- by then the mod is already re-applied, so it's a silent no-op.
set -euo pipefail

APP="${1:?usage: autowatch-run.sh <installer.app>}"

# Let the update settle so we act on the final, complete Versions layout
# (an update may still be copying files when the first event fires).
sleep 10

# Re-open the installer in quiet mode. Launching via `open` -- not exec'ing from
# launchd -- runs the app in the GUI session as its own responsible process, so
# its App Management grant applies. (A direct launchd exec is attributed to
# launchd and gets "Operation not permitted".)
exec /usr/bin/open -a "$APP" --args --auto
