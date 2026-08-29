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
helpers/app_icons.lua   app name -> :ligature: icon (space labels)
helpers/event_providers/ vendored cpu_load C provider (posts cpu_update)
```

Items: native space items with per-space app icons and middle-click live
thumbnails, WM badge, front app, calendar (click opens Calendar), battery
(popup: remaining time), cpu graph, volume (popup: slider + output device
switching, scroll to adjust), now-playing media (hover to expand).

## Dependencies

```sh
brew install lua switchaudio-osx nowplaying-cli
brew install --cask font-sketchybar-app-font   # :app: ligature icons
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
```
