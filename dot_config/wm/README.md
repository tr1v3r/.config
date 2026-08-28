# macOS window manager profiles

AeroSpace and yabai are alternatives, not a stack. The `use` helper stops the
other backend before starting the selected one. Neither backend is enabled by
the dotfiles alone.

## Install

Common bar:

```sh
brew install FelixKratz/formulae/sketchybar
```

AeroSpace (SIP remains enabled):

```sh
brew install --cask nikitabobko/tap/aerospace
~/.config/wm/use aerospace
```

yabai + skhd (core configuration works with SIP enabled):

```sh
brew install asmvik/formulae/yabai asmvik/formulae/skhd
~/.config/wm/use yabai
```

Grant Accessibility permission when macOS prompts. skhd also requires Secure
Keyboard Entry to be disabled. The yabai config deliberately avoids features
that need its scripting addition; do not disable SIP unless those features are
explicitly needed.

## Commands

```sh
~/.config/wm/use aerospace
~/.config/wm/use yabai
~/.config/wm/use off
~/.config/wm/use status
```

Both profiles use Colemak navigation: `n/e/u/i` means left/down/up/right.
`Alt+1..9` changes workspace; `Alt+Shift+1..9` moves the window and follows it.
SketchyBar detects the running backend when it reloads.
