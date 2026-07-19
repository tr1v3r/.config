-- Docs: https://yazi-rs.github.io/

-- https://github.com/llanosrocas/yaziline.yazi
-- require("yaziline"):setup({
-- 	separator_style = "curvy",
-- 	select_symbol = "",
-- 	yank_symbol = "󰆐",
-- 	filename_max_length = 24, -- trim when filename > 24
-- 	filename_trim_length = 6, -- trim 6 chars from both ends
-- })

require("starship"):setup({
	config_file = "~/.config/yazi/starship.toml",
})
require("git"):setup({})
require("gpg"):setup({
	recipient = "899318F5A4423B72DF6A166FE4AF5FF89222F261",
	signer = "C633910E8F351365DEAAF300046263C39890F916",
})

Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line({})
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		ui.Span(":"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		ui.Span(" "),
	})
end, 500, Status.RIGHT)

require("yamb"):setup({
	cli = "fzf",
})
