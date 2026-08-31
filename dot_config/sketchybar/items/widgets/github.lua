local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- GitHub notifications bell (idea from OkunaRei/dotfiles): unread count in
-- the label, hover/click pops the list; rows are colored per subject type and
-- turn red on deprecat*/break* titles. Clicking a row opens it in the browser.
-- `gh` must be authenticated (`gh auth login`).

local max_rows = 10

local type_colors = {
  Issue = colors.green,
  PullRequest = colors.magenta,
  Discussion = colors.blue,
  Commit = colors.subtext,
}

local bell = sbar.add("item", "github.bell", {
  position = "right",
  icon = {
    string = icons.github,
    color = colors.grey,
    font = { size = 16.0 },
  },
  label = { string = "…", color = colors.subtext },
  update_freq = 180,
  popup = { align = "right" },
  updates = true,
})

local previous = -1

local function unescape(s)
  return (s:gsub("\\t", " "):gsub("\\n", " "):gsub("\\r", " ")
             :gsub('\\"', '"'):gsub("\\\\", "\\"))
end

local function update()
  local cmd = settings.paths.gh .. [[ api notifications 2>/dev/null | ]]
    .. settings.paths.jq
    .. [[ -r '.[] | [.repository.name, .subject.type, .subject.title, (.subject.url // "" | gsub("api\\.github\\.com/repos/"; "github.com/"))] | @tsv' ]]
  sbar.exec(cmd, function(out)
    sbar.remove("/github\\.notification\\..*/")

    local count = 0
    local extra = 0
    local important = false

    for line in string.gmatch(out or "", "[^\r\n]+") do
      count = count + 1
      if count > max_rows then
        extra = extra + 1
      else
        local repo, typ, title, url = line:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)")
        repo = unescape(repo or "")
        title = unescape(title or "")
        local lower = title:lower()
        local color = type_colors[typ] or colors.subtext
        if lower:find("deprecat") or lower:find("break") then
          color = colors.red
          important = true
        end
        if not url or url == "" then
          url = "https://github.com/notifications"
        end
        sbar.add("item", "github.notification." .. count, {
          position = "popup." .. bell.name,
          icon = { string = "●", color = color, padding_right = 6 },
          label = { string = repo .. ": " .. title, color = colors.white },
          click_script = 'open "' .. url .. '"; sketchybar --set '
            .. bell.name .. " popup.drawing=off",
        })
      end
    end

    if extra > 0 then
      sbar.add("item", "github.notification.more", {
        position = "popup." .. bell.name,
        icon = { drawing = false },
        label = { string = "+ " .. extra .. " more (github.com/notifications)", color = colors.subtext },
      })
    end

    local bell_color = colors.grey
    if count > 0 then bell_color = colors.yellow end
    if important then bell_color = colors.red end

    bell:set({
      icon = { color = bell_color },
      label = {
        string = count > 0 and tostring(count) or icons.check,
        color = colors.subtext,
      },
    })

    if count > previous and previous >= 0 then
      sbar.animate("tanh", 15, function()
        bell:set({ label = { y_offset = 5, y_offset = 0 } })
      end)
    end
    previous = count
  end)
end

bell:subscribe({ "routine", "forced" }, update)
bell:subscribe("system_woke", function()
  sbar.delay(10, update) -- wait for the network to come up
end)
bell:subscribe("mouse.entered", function()
  bell:set({ popup = { drawing = true } })
end)
bell:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
  bell:set({ popup = { drawing = false } })
end)
bell:subscribe("mouse.clicked", function()
  bell:set({ popup = { drawing = "toggle" } })
end)

sbar.add("bracket", "github.bracket", { bell.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "github.padding", {
  position = "right",
  width = settings.group_paddings,
})
