#!/bin/sh
# Standalone SketchyBar profile for yabai.
set -eu
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
PLUGIN_DIR="$CONFIG_DIR/plugins"

BASE=0xff1e1e2e
SURFACE0=0xff313244
SURFACE1=0xff45475a
TEXT=0xffcdd6f4
SUBTEXT=0xffa6adc8
MAUVE=0xffcba6f7
BLUE=0xff89b4fa
GREEN=0xffa6e3a1
YELLOW=0xfff9e2af

sketchybar --bar position=top height=32 color=$BASE border_width=0 \
  padding_left=6 padding_right=6 margin=0 y_offset=0 blur_radius=20 sticky=on topmost=on
sketchybar --default updates=when_shown \
  icon.font="Hack Nerd Font:Bold:14.0" label.font="Hack Nerd Font:Semibold:13.0" \
  icon.color=$TEXT label.color=$TEXT icon.padding_left=7 icon.padding_right=7 \
  label.padding_left=5 label.padding_right=7 background.color=$SURFACE0 \
  background.corner_radius=7 background.height=24

sketchybar --add event yabai_space_change
workspace_ids="$(yabai -m query --spaces 2>/dev/null | /opt/homebrew/bin/jq -r '.[].index')"
for sid in $workspace_ids; do
  sketchybar --add item "yabai.space.$sid" left \
    --set "yabai.space.$sid" updates=on icon="$sid" label.drawing=off \
      background.color=$SURFACE1 background.drawing=off \
      click_script="/opt/homebrew/bin/yabai -m space --focus $sid" \
      script="$PLUGIN_DIR/yabai_workspace.sh $sid" \
    --subscribe "yabai.space.$sid" yabai_space_change system_woke
done

sketchybar --add item wm left \
  --set wm icon=󱂬 icon.color=$GREEN label=yabai label.color=$SUBTEXT
sketchybar --add item front_app left \
  --set front_app icon.drawing=off label.color=$SUBTEXT background.drawing=off \
    script="$PLUGIN_DIR/front_app.sh" \
  --subscribe front_app front_app_switched
sketchybar --add item clock right \
  --set clock icon=󰥔 icon.color=$BLUE background.drawing=off update_freq=10 \
    script="$PLUGIN_DIR/clock.sh"
sketchybar --add item battery right \
  --set battery icon.color=$GREEN background.drawing=off update_freq=120 \
    script="$PLUGIN_DIR/battery.sh" \
  --subscribe battery system_woke power_source_change
sketchybar --add item volume right \
  --set volume icon.color=$YELLOW background.drawing=off script="$PLUGIN_DIR/volume.sh" \
  --subscribe volume volume_change

sketchybar --update
sketchybar --trigger yabai_space_change
