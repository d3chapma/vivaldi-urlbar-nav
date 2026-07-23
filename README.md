# vivaldi-urlbar-nav

A tiny Vivaldi UI mod for macOS that lets you navigate the address-bar
suggestion list with **Ctrl+N / Ctrl+P** (down / up), the way you would in a
terminal, Emacs, or `fzf`.

## The problem

On macOS, text inputs inherit Emacs-style key bindings from the system text
layer, and Chromium (which Vivaldi is built on) honours them. In a single-line
field like the address bar, `Ctrl+N` / `Ctrl+P` collapse to "move caret to
end / start" instead of moving through the suggestion dropdown. The input
swallows the keystroke before the suggestion list ever sees it.

## How it works

`urlbar-nav.js` installs a capture-phase `keydown` listener on Vivaldi's UI
document. When it sees a bare `Ctrl+N` / `Ctrl+P` while focus is in an
autocomplete field (address bar or search field), it:

1. `preventDefault()`s the macOS caret-jump, and
2. re-dispatches a synthetic `ArrowDown` / `ArrowUp` to drive Vivaldi's
   existing suggestion navigation.

`Ctrl+N` still works as "New Window" everywhere else — the listener only acts
when an autocomplete field is focused.

The field is identified by version-resilient ARIA signals
(`role="combobox"`, `aria-autocomplete`, `aria-controls`) with a fallback that
walks up the DOM looking for a container named like `url` / `address`.

## Installing

Vivaldi's UI lives in `window.html` inside the app bundle. The mod is a JS file
dropped next to it, loaded by one added `<script>` tag. There's no
outside-the-bundle way to inject into the browser chrome — CSS mods can't run
JS, and content extensions (Tampermonkey etc.) can't reach the address bar.

Because the bundle sits in `/Applications`, macOS **App Management** protection
guards it — even `sudo` can't write there unless the process doing the write
holds the App Management (or Full Disk Access) permission.

### Option A — Finder (recommended, no permission grants)

Finder is already system-trusted to modify app bundles, so it only needs your
admin password. **This is the method to use if you don't want to grant your
terminal broad permissions.**

1. Finder → **⌘⇧G**, paste (adjust the version number to match yours):
   ```
   /Applications/Vivaldi.app/Contents/Frameworks/Vivaldi Framework.framework/Versions/<VERSION>/Resources/vivaldi
   ```
2. Copy **`urlbar-nav.js`** from this repo into that folder (enter admin
   password when prompted).
3. Open **`window.html`** in that folder and add this line just before
   `</body>`, then save:
   ```html
   <script src="urlbar-nav.js"></script>
   ```
4. Fully quit Vivaldi (**⌘Q**) and relaunch.

### Option B — double-clickable app (grant a permission once, then re-run by double-clicking)

This is the low-friction option if you update Vivaldi often. Instead of running
`install.sh` from a terminal — which forces your *terminal* to hold the App
Management permission — you double-click a small `.app` in Finder. Because a
Finder-launched app is its own responsible process, macOS prompts for App
Management **for that app**, once. The app lives outside the Vivaldi bundle, so
updates never wipe it: after the first grant, every re-install is just a
double-click plus your admin password.

1. Build the app (once, and again whenever you edit `urlbar-nav.js`):
   ```sh
   ./build-installer.sh
   ```
   This produces **`Install urlbar-nav.app`** with `urlbar-nav.js` bundled
   inside. Move it wherever you like (Desktop, Applications…).
2. Double-click it. The first run pops a one-time **App Management** prompt
   for the app — click **Allow**. (System Settings → Privacy & Security →
   App Management will list `Install urlbar-nav` afterward.) No admin password
   is needed: the bundle files are owned by your user, so the App Management
   grant is the only gate.
3. It reports the target folder and reminds you to fully quit Vivaldi
   (**⌘Q**) and relaunch.

**After a future Vivaldi update:** just double-click the app again. No
re-granting, no terminal, no manual file moves.

> The app deliberately does *not* elevate with `sudo`/admin rights. Elevating
> would route the write through a root helper that macOS attributes to the
> system rather than to the app, so the app would never receive the App
> Management grant — and root without that grant is still blocked. Writing as
> your own user is what lets the grant stick to the app.

#### Fully automatic: re-apply on every Vivaldi update

Once you've granted the app App Management (double-click it once), you can have
it re-run itself whenever Vivaldi updates — no clicking at all:

```sh
./install-autowatch.sh
```

This installs a launchd **LaunchAgent** that watches Vivaldi's `Versions`
directory. An update drops a new version folder there, which fires the agent.
The agent doesn't run the app's binary directly — it `open`s the app, so it
launches in your GUI session as its own responsible process and its App
Management grant applies. (Running the binary straight from launchd fails with
`Operation not permitted`: launchd, not your app, is the responsible process,
and it has no grant.) It runs in quiet mode — a notification instead of a
dialog — and logs to `~/Library/Logs/vivaldi-urlbar-nav.log`. Remove it with
`./uninstall-autowatch.sh`.

Caveats:

- The run **reuses** the App Management grant you gave the app by double-clicking
  it — so you must double-click the app successfully **once first**.
- **If you rebuild the app** (`./build-installer.sh`), its code identity
  changes and the grant is invalidated — double-click it once more to re-grant.
  If the grant is missing the run fails silently; check the log.
- You still need to quit (**⌘Q**) and relaunch Vivaldi for the freshly
  re-applied mod to load; the agent only rewrites the files.

### Option C — the installer script (requires granting a permission first)

`install.sh` does the same two steps from the command line, but **only works if
the terminal running it has the App Management permission** — otherwise it
fails with `Operation not permitted` (App Management blocks it even under
`sudo`). If you're fine granting that:

1. System Settings → Privacy & Security → **App Management** → enable your
   terminal app, then restart the terminal. App Management is scoped only to
   modifying apps — much narrower than Full Disk Access (which also works but
   grants far more).
2. Run it:
   ```sh
   sudo ./install.sh
   ```

It's idempotent and auto-detects the current version folder. Fully quit Vivaldi
(**⌘Q**) and relaunch.

## Verifying

Click the address bar, type a few letters, and press **Ctrl+N** / **Ctrl+P** —
the highlight should move through the suggestions instead of the caret jumping.

## Managing / troubleshooting

- **After a Vivaldi update** the bundle is rebuilt and the mod is wiped. Just
  double-click `Install urlbar-nav.app` again (Option B) — or redo the Finder
  steps (Option A) with the new version number, or re-run `sudo ./install.sh`
  (Option C) if your terminal holds the App Management permission.
- **Nothing happens after relaunch?** Enable Vivaldi's UI devtools
  (`vivaldi://experiments` → allow UI modding), open its console, run
  `window.__urlbarNavDebug = true`, then type in the address bar and press
  Ctrl+N. The console logs whether the field is matched; if `match=false`,
  the field selector needs adjusting for your Vivaldi version.
- **Vivaldi won't launch** after modifying the bundle (Gatekeeper): re-sign it
  ad-hoc:
  ```sh
  sudo codesign --force --deep --sign - /Applications/Vivaldi.app
  ```

## Files

| File            | Purpose                                                      |
| --------------- | ------------------------------------------------------------ |
| `urlbar-nav.js`       | The mod — the keydown listener injected into Vivaldi's UI.        |
| `install.sh`          | Copies the mod into the bundle and patches `window.html`.         |
| `build-installer.sh`  | Builds `Install urlbar-nav.app`, the double-click Finder installer.|
| `installer.applescript` | Source for the app — runs `do-install.sh` as the current user.  |
| `do-install.sh`       | Install logic bundled inside the app (mirrors `install.sh`).      |
| `install-autowatch.sh`| Installs a LaunchAgent to re-apply the mod on every Vivaldi update.|
| `uninstall-autowatch.sh` | Removes that LaunchAgent.                                      |

## Caveats

Modifying the app bundle invalidates Vivaldi's code signature and is wiped by
updates — this is an unofficial mod, not a supported extension point. Tested on
Vivaldi 8.1 (macOS). Use at your own risk.
