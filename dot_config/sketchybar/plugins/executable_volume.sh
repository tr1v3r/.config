#!/bin/sh
volume="${INFO:-$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)}"

case "${volume:-0}" in
  0) icon='󰖁' ;;
  *) icon='󰕾' ;;
esac

sketchybar --set "$NAME" icon="$icon" label="${volume:-?}%"
