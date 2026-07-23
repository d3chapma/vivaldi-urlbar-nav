-- Double-clickable installer for the urlbar-nav Vivaldi mod.
--
-- Why an .app? When you run install.sh from a terminal, macOS attributes the
-- write to /Applications to the *terminal*, so the terminal needs the App
-- Management permission. A compiled AppleScript .app launched from Finder is
-- its own responsible process: macOS prompts for App Management once, for THIS
-- app, and the grant persists. Because this app lives outside the Vivaldi
-- bundle, updates don't wipe it -- re-installing after an update is just a
-- double-click + admin password.
--
-- The actual install logic and urlbar-nav.js are bundled in Contents/Resources
-- by build-installer.sh.

-- NOTE: we deliberately do NOT use `with administrator privileges`. That runs
-- the shell via a root helper (security_authtrampoline) which macOS attributes
-- to the system, not to this app -- so this app never gets the App Management
-- grant, and root without App Management is still blocked ("Operation not
-- permitted"). Running the shell directly makes THIS app the responsible
-- process, so macOS prompts for App Management for the app. The Vivaldi bundle
-- files are owned by the user, so no root is needed anyway.

-- When launched by the LaunchAgent (see install-autowatch.sh) the app is
-- opened via `open -a … --args --auto`. In that mode we skip the modal dialog,
-- post a notification instead, and log to ~/Library/Logs/vivaldi-urlbar-nav.log
-- so an automated run is auditable. (URLBAR_NAV_AUTO env is also honored as a
-- fallback.) Launching via `open` -- rather than exec'ing the binary from
-- launchd -- matters: it runs the app in the GUI session as its own responsible
-- process, so its App Management grant applies. A direct launchd exec is
-- attributed to launchd and gets "Operation not permitted".
on run argv
	set autoMode to false
	try
		if argv contains "--auto" then set autoMode to true
	end try
	try
		if (system attribute "URLBAR_NAV_AUTO") is "1" then set autoMode to true
	end try

	set myPath to POSIX path of (path to me)
	set installer to myPath & "Contents/Resources/do-install.sh"
	set logCmd to " >> ~/Library/Logs/vivaldi-urlbar-nav.log 2>&1"
	try
		set out to do shell script "/bin/bash " & quoted form of installer & logCmd & " && tail -n1 ~/Library/Logs/vivaldi-urlbar-nav.log"
		if autoMode then
			display notification "Re-applied after a Vivaldi change. Quit (Cmd+Q) & relaunch Vivaldi." with title "Vivaldi urlbar-nav"
		else
			display dialog "urlbar-nav installed." & return & return & out & return & return & "Fully quit Vivaldi (Cmd+Q) and relaunch." buttons {"OK"} default button "OK"
		end if
	on error errMsg number errNum
		if errNum is -128 then
			-- user cancelled a prompt
			return
		end if
		if autoMode then
			display notification "Install failed: " & errMsg with title "Vivaldi urlbar-nav"
		else
			display dialog "Install failed:" & return & return & errMsg buttons {"OK"} default button "OK" with icon stop
		end if
	end try
end run
