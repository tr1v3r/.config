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

local function fingerprints_from_env(name)
	local value = os.getenv(name)
	assert(value and value:match("%S"), name .. " must be set")

	local fingerprints = {}
	for fingerprint in value:gmatch("[^,%s]+") do
		fingerprints[#fingerprints + 1] = fingerprint
	end
	return fingerprints
end

require("gpg"):setup({
	recipients = fingerprints_from_env("YAZI_GPG_RECIPIENTS"),
	signers = fingerprints_from_env("YAZI_GPG_SIGNERS"),
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
