return {
  paddings = 3,
  group_paddings = 5,

  font = {
    text = "Hack Nerd Font", -- used for text
    numbers = "Hack Nerd Font", -- used for numbers
    -- Hack ships Regular/Bold(+italics) only; emulate the weights the item
    -- configs ask for.
    style_map = {
      ["Regular"] = "Regular",
      ["Semibold"] = "Bold",
      ["Bold"] = "Bold",
      ["Heavy"] = "Bold",
      ["Black"] = "Bold",
    },
  },

  -- Ligature font that renders :app_name: as real app icons (space labels).
  app_font = "sketchybar-app-font",

  paths = {
    yabai = "/opt/homebrew/bin/yabai",
    aerospace = "/opt/homebrew/bin/aerospace",
    osascript = "/usr/bin/osascript",
    pmset = "/usr/bin/pmset",
    switch_audio = "/opt/homebrew/bin/SwitchAudioSource",
    nowplaying = "/opt/homebrew/bin/nowplaying-cli",
  },
}
