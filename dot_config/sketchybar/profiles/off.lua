local colors = require("colors")
local icons = require("icons")

-- Minimal bar when neither window manager is selected (same as the previous
-- off.sh profile).
require("bar")
require("default")

local wm = sbar.add("item", "off.wm", {
  icon = { string = icons.wm, color = colors.grey },
  label = { string = "WM off", color = colors.subtext },
})

local clock = sbar.add("item", "off.clock", {
  position = "right",
  icon = { string = icons.clock, color = colors.blue },
  label = { font = { family = require("settings").font.numbers } },
  background = { drawing = false },
  update_freq = 10,
})

clock:subscribe({ "forced", "routine", "system_woke" }, function()
  clock:set({ label = os.date("%a %m-%d %H:%M") })
end)
