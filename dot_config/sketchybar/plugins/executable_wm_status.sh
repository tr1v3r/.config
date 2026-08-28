#!/bin/sh
backend="$("$CONFIG_DIR"/plugins/wm_backend.sh)"

case "$backend" in
  aerospace) label='AeroSpace'; color=0xff89b4fa ;;
  yabai) label='yabai'; color=0xffa6e3a1 ;;
  *) label='WM off'; color=0xff6c7086 ;;
esac

sketchybar --set "$NAME" label="$label" icon.color="$color"
