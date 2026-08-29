local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Native space items: clicking focuses the space (via the injected WM
-- command), the label shows the icons of the apps living in that space
-- (sketchybar-app-font ligatures), and middle-click pops a live thumbnail.
return function(focus)
  local spaces = {}

  for i = 1, 10, 1 do
    local space = sbar.add("space", "space." .. i, {
      space = i,
      icon = {
        font = { family = settings.font.numbers },
        string = i,
        padding_left = 15,
        padding_right = 8,
        color = colors.white,
        highlight_color = colors.magenta,
      },
      label = {
        padding_right = 20,
        color = colors.grey,
        highlight_color = colors.white,
        font = settings.app_font .. ":Regular:16.0",
        y_offset = -1,
      },
      padding_right = 1,
      padding_left = 1,
      background = {
        color = colors.bg1,
        border_width = 1,
        height = 26,
        border_color = colors.black,
      },
      popup = { background = { border_width = 5, border_color = colors.black } },
    })

    spaces[i] = space

    -- Single item bracket to achieve the double border on highlight
    local space_bracket = sbar.add("bracket", { space.name }, {
      background = {
        color = colors.transparent,
        border_color = colors.bg2,
        height = 28,
        border_width = 2,
      },
    })

    -- Padding space
    sbar.add("space", "space.padding." .. i, {
      space = i,
      script = "",
      width = settings.group_paddings,
    })

    local space_popup = sbar.add("item", {
      position = "popup." .. space.name,
      padding_left = 5,
      padding_right = 0,
      background = {
        drawing = true,
        image = {
          corner_radius = 9,
          scale = 0.2,
        },
      },
    })

    space:subscribe("space_change", function(env)
      local selected = env.SELECTED == "true"
      local color = selected and colors.grey or colors.bg2
      space:set({
        icon = { highlight = selected },
        label = { highlight = selected },
        background = { border_color = color },
      })
      space_bracket:set({
        background = { border_color = selected and colors.grey or colors.bg2 },
      })
    end)

    space:subscribe("mouse.clicked", function(env)
      if env.BUTTON == "other" then
        -- Middle click: live thumbnail of the space
        space_popup:set({ background = { image = "space." .. env.SID } })
        space:set({ popup = { drawing = "toggle" } })
      elseif focus then
        focus(env.SID)
      end
    end)

    space:subscribe("mouse.exited", function(_)
      space:set({ popup = { drawing = false } })
    end)
  end

  local space_window_observer = sbar.add("item", {
    drawing = false,
    updates = true,
  })

  space_window_observer:subscribe("space_windows_change", function(env)
    local icon_line = ""
    local no_app = true
    for app, _ in pairs(env.INFO.apps) do
      no_app = false
      local lookup = app_icons[app]
      local icon = ((lookup == nil) and app_icons["Default"] or lookup)
      icon_line = icon_line .. icon
    end

    if no_app then
      icon_line = " —"
    end

    sbar.animate("tanh", 10, function()
      spaces[env.INFO.space]:set({ label = icon_line })
    end)
  end)
end
