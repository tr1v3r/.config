local colors = require("colors")
local settings = require("settings")

-- Full bar for yabai. Space focus goes through yabai so the WM state stays
-- consistent with skhd bindings.
require("bar")
require("default")
require("items")({
  focus = function(sid)
    sbar.exec(settings.paths.yabai .. " -m space --focus " .. sid)
  end,
  wm = { label = "yabai", color = colors.green },
})
