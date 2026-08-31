# SketchyBar (SbarLua)

macOS status bar, configured in Lua on top of
[SbarLua](https://github.com/FelixKratz/SbarLua) — the same architecture as
the sketchybar author's [dotfiles](https://github.com/FelixKratz/dotfiles),
re-themed to Catppuccin Mocha + Hack Nerd Font.

## Layout

```
sketchybarrc            Lua entry: dispatcher (reads ~/.config/wm/active)
bar.lua / default.lua   bar geometry + item defaults
colors.lua              Catppuccin Mocha palette (+ with_alpha helper)
settings.lua            fonts, paddings, absolute tool paths
icons.lua               Nerd Font glyphs
profiles/               yabai.lua / aerospace.lua / off.lua (WM-specific bits)
items/                  one module per bar item
plugins/                classic shell plugin scripts (brew)
helpers/app_icons.lua   app name -> :ligature: icon (space labels)
helpers/event_providers/ vendored cpu_load C provider (posts cpu_update)
```

Items: native space items with per-space app icons and middle-click live
thumbnails, WM badge, front app, calendar (click opens Calendar), battery
(popup: remaining time), cpu graph, volume (popup: slider + output device
switching, scroll to adjust), now-playing media (hover to expand), GitHub
notifications bell (hover/click popup; needs `gh auth login`), outdated
Homebrew packages (color-graded count).

Zen mode: click the WM badge to toggle — hides front_app, all widgets,
media and github, keeps spaces + badge + clock.

## Known quirks

- **updates=when_shown gets stuck** right after the bar window is realized,
  leaving event-driven widgets blank; cpu/battery/volume/github/brew pin
  `updates=true` explicitly.
- **Homebrew inside sketchybar children**: plugin processes inherit
  `SIGCHLD=SIG_IGN`, so Homebrew's Ruby (`IO.popen("-")` + `$CHILD_STATUS`)
  dies with "undefined method 'success?' for nil". `plugins/brew-wrapper.sh`
  resets the disposition (`Signal.trap("CHLD","DEFAULT")`) before exec'ing
  brew — run brew through it in any plugin script. Go binaries (gh,
  nowplaying-cli) are unaffected.
- SBarLua `exec` forks and posts results back with a 60s alarm; slow
  commands (like a cold `brew outdated`) can hit it.

## Dependencies

```sh
brew install lua switchaudio-osx nowplaying-cli
brew install --cask font-sketchybar-app-font   # :app: ligature icons
gh auth login                                 # github notifications widget
```

SbarLua is built from source (installs `~/.local/share/sketchybar_lua/sketchybar.so`):

```sh
git clone https://github.com/FelixKratz/SbarLua /tmp/SbarLua
(cd /tmp/SbarLua && make install)
```

The cpu graph needs a C compiler; helpers are rebuilt automatically on bar
start (`helpers/makefile`) and degrade silently when absent.

## Bar geometry

`y_offset=24` keeps the bar below the macOS menu bar on non-notch displays
(bar occupies y 24..56). `dot_config/yabai/yabairc` sets
`external_bar all:25:0` + `top_padding 8` so tiled windows start at y=64.

## Reload / restart

```sh
sketchybar --reload                       # re-exec sketchybarrc (re-dispatches)
~/.config/wm/use yabai                    # switch WM, restarts the bar
sketchybar --trigger brew_update          # refresh the brew count on demand
```

Optional zsh hook after `brew update`/`brew upgrade`:
`sketchybar --trigger brew_update` — add a wrapper function in `~/.config/zsh`
if wanted.
