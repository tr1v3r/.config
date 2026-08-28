#!/bin/sh
battery="$(pmset -g batt)"
percent="$(printf '%s\n' "$battery" | sed -n 's/.*\([0-9][0-9]*%\).*/\1/p' | head -n 1)"

case "$battery" in
  *charging*|*AC\ Power*) icon='󰂄' ;;
  *) icon='󰁹' ;;
esac

sketchybar --set "$NAME" icon="$icon" label="${percent:-?}"
