# Sioyek configuration

Sioyek 2.0.0 on macOS reads `prefs_user.config` and `keys_user.config` from
inside `/Applications/sioyek.app/Contents/MacOS/`. Chezmoi deploys the real
files here and `run_onchange_after_link-sioyek-config.sh.tmpl` repairs symlinks when either
config hash changes or Homebrew replaces the Sioyek app bundle.

Homebrew currently marks the 2.0.0 cask deprecated because it lacks a usable
Gatekeeper signature and plans to disable it on 2026-09-01. On this host the
quarantine attribute was removed only from `/Applications/sioyek.app`; global
Gatekeeper and SIP remain enabled. After a fresh install, if macOS reports that
the app is damaged, apply the same narrow workaround explicitly:

```sh
xattr -dr com.apple.quarantine /Applications/sioyek.app
```

Bindings add a Colemak navigation layer (`n/e/u/i`) while retaining Sioyek's
defaults. Press `F8` to toggle Catppuccin paper colors rather than forcing
figure inversion for every document.
