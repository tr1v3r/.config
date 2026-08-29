local colors = require("colors")
local icons = require("icons")

-- WM badge: which window manager owns this bar. wmo = { label, color },
-- injected by the profile module.
return function(wmo)
  wmo = wmo or { label = "off", color = colors.grey }

  local badge = sbar.add("item", "wm_badge", {
    icon = {
      string = icons.wm,
      color = wmo.color,
      padding_left = 8,
    },
    label = {
      string = wmo.label,
      color = colors.subtext,
      padding_right = 8,
    },
  })

  sbar.add("bracket", { badge.name }, {
    background = { color = colors.bg1 },
  })
end
