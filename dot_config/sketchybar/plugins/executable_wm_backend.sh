#!/bin/sh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if command -v aerospace >/dev/null 2>&1 && pgrep -x AeroSpace >/dev/null 2>&1; then
  echo aerospace
elif command -v yabai >/dev/null 2>&1 && yabai -m query --spaces >/dev/null 2>&1; then
  echo yabai
else
  echo none
fi
