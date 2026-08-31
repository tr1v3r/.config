local colors = require("colors")

-- Equivalent to the --bar domain. Geometry matches the previous shell
-- profiles: y_offset=24 sits below the macOS menu bar (non-notch displays),
-- so yabairc's external_bar all:25:0 math stays valid.
sbar.bar({
  position = "top",
  height = 32,
  color = colors.bar.bg,
  border_width = 0,
  padding_left = 6,
  padding_right = 6,
  margin = 0,
  y_offset = 24,
  blur_radius = 20,
  sticky = true,
  topmost = true,
})
