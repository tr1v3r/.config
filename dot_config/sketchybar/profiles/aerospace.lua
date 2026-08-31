local colors = require("colors")
local settings = require("settings")

-- Full bar for AeroSpace. Native space items track the macOS spaces that
-- AeroSpace creates, so the item set is shared with the yabai profile.
require("bar")
require("default")
require("items")({
  focus = function(sid)
    sbar.exec(settings.paths.aerospace .. " workspace " .. sid)
  end,
  wm = { label = "AeroSpace", color = colors.blue },
})
