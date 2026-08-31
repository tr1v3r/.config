#!/bin/sh
# Rebuild the focused managed space into a Tall/master-stack BSP:
# focused window -> left master; all other tiled windows -> right column.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

focused="$(yabai -m query --windows --window)" || exit 1
master="$(printf '%s\n' "$focused" | jq -r '.id')"
spid="$(printf '%s\n' "$focused" | jq -r '.space')"

space_type="$(yabai -m query --spaces --space "$spid" | jq -r '.type')"
if [ "$space_type" != bsp ]; then
  printf 'master-stack: space %s is %s, not a managed bsp space\n' "$spid" "$space_type" >&2
  exit 1
fi

ids="$(yabai -m query --windows --space "$spid" | jq -r '
  .[]
  | select(.["subrole"] == "AXStandardWindow"
      and .["is-floating"] == false
      and .["is-minimized"] == false)
  | .id')"
[ -n "$ids" ] || exit 0

# The focused window must be one of the tiled standard windows.
printf '%s\n' "$ids" | grep -qx "$master" || {
  printf 'master-stack: focused window is not a managed standard window\n' >&2
  exit 1
}

# Detach every tiled window to destroy the old BSP tree.
for id in $ids; do
  yabai -m window "$id" --toggle float || exit 1
done

# Reattach in a controlled order. Keeping the latest right leaf focused makes
# split_type=auto build a right-side vertical column on a wide display.
yabai -m window "$master" --toggle float || exit 1
yabai -m window --focus "$master" || true
for id in $ids; do
  [ "$id" = "$master" ] && continue
  yabai -m window "$id" --toggle float || continue
  yabai -m window --focus "$id" || true
done

# Equalize the right column vertically, then keep master vs. stack at 1:1.
yabai -m space "$spid" --balance y-axis 2>/dev/null || true
yabai -m window --focus "$master" || true
yabai -m window --ratio abs:0.5 2>/dev/null || true
