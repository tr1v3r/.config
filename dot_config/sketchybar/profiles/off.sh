#!/bin/sh
# Minimal bar when neither window manager is selected.
set -eu
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --bar position=top height=32 color=0xff1e1e2e border_width=0 \
  padding_left=6 padding_right=6 margin=0 y_offset=0 blur_radius=20 sticky=on topmost=on
sketchybar --default updates=when_shown icon.font="Hack Nerd Font:Bold:14.0" \
  label.font="Hack Nerd Font:Semibold:13.0" icon.color=0xffcdd6f4 label.color=0xffcdd6f4 \
  background.color=0xff313244 background.corner_radius=7 background.height=24
sketchybar --add item wm left --set wm icon=󱂬 icon.color=0xff6c7086 label='WM off'
sketchybar --add item clock right --set clock icon=󰥔 icon.color=0xff89b4fa \
  background.drawing=off update_freq=10 script="$PLUGIN_DIR/clock.sh"
sketchybar --update
