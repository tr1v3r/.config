local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Outdated Homebrew packages (idea from OkunaRei/dotfiles), color-graded by
-- count. The logic lives in plugins/brew.sh because brew (Ruby) fails inside
-- the SBarLua exec fork child ("undefined method 'exitstatus' for nil").
-- Optionally triggered on demand from the shell after brew update/upgrade:
--   sketchybar --trigger brew_update
local brew = sbar.add("item", "widgets.brew", {
  position = "right",
  icon = { string = icons.brew, color = colors.grey },
  label = { string = "…", color = colors.subtext },
  update_freq = 1800,
  updates = true,
  script = "$CONFIG_DIR/plugins/brew.sh",
})

-- The shell script handles the events itself; register the custom trigger
-- through the CLI so it reaches the script (a Lua subscribe would not).
sbar.exec(
  "/opt/homebrew/bin/sketchybar --add event brew_update"
    .. " --subscribe widgets.brew brew_update 2>/dev/null"
)

sbar.add("bracket", "widgets.brew.bracket", { brew.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.brew.padding", {
  position = "right",
  width = settings.group_paddings,
})
