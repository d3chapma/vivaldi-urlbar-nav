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

### Option B — the installer (requires granting a permission first)

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

- **After a Vivaldi update** the bundle is rebuilt and the mod is wiped. Redo
  the Finder steps (Option A) with the new version number — or, if you've
  granted the App Management permission, re-run `sudo ./install.sh`.
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
| `urlbar-nav.js` | The mod — the keydown listener injected into Vivaldi's UI.   |
| `install.sh`    | Copies the mod into the bundle and patches `window.html`.    |

## Caveats

Modifying the app bundle invalidates Vivaldi's code signature and is wiped by
updates — this is an unofficial mod, not a supported extension point. Tested on
Vivaldi 8.1 (macOS). Use at your own risk.
