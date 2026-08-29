-- Zen mode (idea from OkunaRei/dotfiles): hide the noisy widgets and keep
-- spaces + WM badge + clock. Toggled by clicking the WM badge.
sbar.add("event", "zen_toggle")

local zen_controller = sbar.add("item", {
  drawing = false,
  updates = true,
})

local zen_on = false

local function apply(drawing)
  sbar.set("front_app", { drawing = drawing })
  sbar.set("/widgets\\..*/", { drawing = drawing })
  sbar.set("/media\\..*/", { drawing = drawing })
  sbar.set("/github\\..*/", { drawing = drawing })
end

zen_controller:subscribe("zen_toggle", function()
  zen_on = not zen_on
  apply(not zen_on)
end)
