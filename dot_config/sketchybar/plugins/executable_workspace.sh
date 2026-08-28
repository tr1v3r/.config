#!/bin/sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

sid="$1"
backend="$2"
current=''

case "$backend" in
  aerospace)
    current="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null | head -n 1)}"
    ;;
  yabai)
    current="$(yabai -m query --spaces --space 2>/dev/null | /usr/bin/jq -r '.index // empty')"
    ;;
esac

if [ "$sid" = "$current" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0xff45475a \
    icon.color=0xffcba6f7
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color=0xffa6adc8
fi
