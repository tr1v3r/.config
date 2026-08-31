#!/bin/bash
# Outdated Homebrew packages, run as a classic sketchybar plugin script
# (idea from OkunaRei/dotfiles). brew itself goes through brew-wrapper.sh —
# see the comment there for why a plain `brew` call fails in this context.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

# Catppuccin Mocha
GREEN=0xffa6e3a1
YELLOW=0xfff9e2af
ORANGE=0xfffab387
WHITE=0xffcdd6f4

update() {
  COUNT="$("$CONFIG_DIR/plugins/brew-wrapper.sh" outdated 2>/dev/null | wc -l | tr -d ' ')"

  COLOR=$GREEN
  LABEL=󰄬
  case "$COUNT" in
    "") LABEL="…" ;;
    0) ;;
    [1-9]) COLOR=$WHITE; LABEL=$COUNT ;;
    [1-2][0-9]) COLOR=$YELLOW; LABEL=$COUNT ;;
    *) COLOR=$ORANGE; LABEL=$COUNT ;;
  esac

  sketchybar --set "$NAME" icon.color=$COLOR label="$LABEL"
}

case "$SENDER" in
  routine | forced | brew_update | system_woke) update ;;
esac
