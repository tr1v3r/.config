# macOS window-manager profiles

AeroSpace and yabai are alternatives, not a stack. The `use` helper stops the
other backend before starting the selected one and reloads the matching
SketchyBar profile.

The two bars are intentionally independent:

- `~/.config/sketchybar/profiles/aerospace.sh`
- `~/.config/sketchybar/profiles/yabai.sh`

The root `sketchybarrc` is only a dispatcher. The runtime selection is stored
in `~/.config/wm/active` (host-local state, not part of the repository).

## Install

```sh
brew install --cask nikitabobko/tap/aerospace
brew install asmvik/formulae/yabai asmvik/formulae/skhd jq
brew install FelixKratz/formulae/sketchybar FelixKratz/formulae/borders
```

Grant Accessibility permission to AeroSpace, yabai, and skhd when macOS
prompts. skhd also requires Secure Keyboard Entry to be disabled. The yabai
configuration deliberately avoids scripting-addition-only features, so SIP can
remain enabled during the comparison.

## Switch

```sh
~/.config/wm/use aerospace
~/.config/wm/use yabai
~/.config/wm/use off
~/.config/wm/use status
```

Both profiles use equivalent Colemak bindings for a fair comparison:
`n/e/u/i` means left/down/up/right, `Alt+1..9` changes workspace, and
`Alt+Shift+1..9` moves the window and follows it.

While comparing, AeroSpace keeps `start-at-login = false`. Selecting yabai
installs/enables its launchd services; selecting AeroSpace or `off` stops and
uninstalls the yabai/skhd services so they cannot both start at the next login.
After choosing a winner, its login behavior can be made permanent.

## Pause SketchyBar

To park the bar while keeping the configuration (e.g. while comparing the
window managers without it):

```sh
touch ~/.config/wm/bar.disabled
brew services stop sketchybar
```

`bar.disabled` is host-local state like `active`, not part of the repository.
While it exists, `use` never auto-starts the bar, and the yabai layout tiles
windows 8px below the menu bar (`external_bar off`, `top_padding 1`).
AeroSpace's `gaps.outer.top` is static — `~/.aerospace.toml` documents the
value to restore when the bar returns. To bring the bar back:

```sh
rm ~/.config/wm/bar.disabled
brew services start sketchybar
yabai --restart-service   # re-reads yabairc layout for the bar
```
