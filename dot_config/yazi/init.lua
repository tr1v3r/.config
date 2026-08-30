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
require("full-border"):setup({ type = ui.Border.ROUNDED })

-- CLI Pointer：主题在无背景/非 reversed 模式下不会渲染 indicator padding，
-- 因此替换默认 Entity padding child，直接绘制无背景的当前项指针。
-- 备选 Cursor Rail：将下方 " " 改为 "▎ "。
Entity:children_remove(1)
Entity:children_add(function(self)
	if not self._file.is_hovered then
		return "  "
	end
	local color = self._file.in_current and "#7dcfff" or "#565f89"
	return ui.Span(" "):fg(color)
end, 1000)

-- vim 式位置指示：hovered 文件在当前目录的百分比
Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil then
		return ui.Span("")
	end
	local total = #cx.active.current.files
	if total == 0 then
		return ui.Span("")
	end
	local position = cx.active.current.cursor + 1
	local percent = math.floor((position / total) * 100 + 0.5)
	return ui.Span(string.format(" %d%% ", percent)):fg("#7dcfff")
end, 90, Status.RIGHT)

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
