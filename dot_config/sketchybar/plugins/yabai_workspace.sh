#!/bin/sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
sid="$1"
current="$(yabai -m query --spaces --space 2>/dev/null | /opt/homebrew/bin/jq -r '.index // empty')"

if [ "$sid" = "$current" ]; then
  sketchybar --set "$NAME" background.drawing=on \
    background.color=0xff45475a icon.color=0xffcba6f7
else
  sketchybar --set "$NAME" background.drawing=off icon.color=0xffa6adc8
fi
