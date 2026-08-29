-- Shared item assembly. Returns a builder so each WM profile can inject its
-- space-focus command and badge; every item module is required exactly once.
return function(opts)
  opts = opts or {}

  require("items.spaces")(opts.focus)
  require("items.wm_badge")(opts.wm)
  require("items.front_app")
  require("items.calendar")
  require("items.widgets")
  require("items.media")
end
