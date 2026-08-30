#!/bin/sh
# Shared Tokyo Night renderers for Yazi's piper previewer.
set -eu

mode=${1:?preview mode is required}
path=${2:?preview path is required}
width=${3:-80}
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}

# This renderer is explicitly colorized; inherited NO_COLOR must not suppress Glow/Bat/Eza.
unset NO_COLOR

# Keep tree connectors quiet while file roles carry saturated semantic colors.
tokyo_eza_colors='di=1;38;2;122;162;247:fi=38;2;192;202;245:ln=38;2;125;207;255:ex=1;38;2;158;206;106:pi=38;2;224;175;104:so=38;2;187;154;247:bd=38;2;247;118;142:cd=38;2;247;118;142:or=1;38;2;247;118;142:sp=38;2;255;158;100:xx=38;2;65;72;104:*.md=1;38;2;125;207;255:*.toml=38;2;224;175;104:*.yaml=38;2;187;154;247:*.yml=38;2;187;154;247:*.json=38;2;224;175;104:*.lua=38;2;122;162;247:*.sh=38;2;158;206;106:*.zsh=38;2;158;206;106:*.rs=38;2;255;158;100:*.go=38;2;125;207;255:*.py=38;2;224;175;104:*.js=38;2;224;175;104:*.jsx=38;2;224;175;104:*.ts=38;2;122;162;247:*.tsx=38;2;122;162;247:*.css=38;2;42;195;222:*.html=38;2;247;118;142:*.zip=38;2;255;158;100:*.gz=38;2;255;158;100:*.xz=38;2;255;158;100:*.bz2=38;2;255;158;100:*.7z=38;2;255;158;100:*.rar=38;2;255;158;100'

case $mode in
	markdown)
		CLICOLOR_FORCE=1 exec glow \
			--width "$width" \
			--style "$config_home/yazi/glow-tokyo-night.json" \
			"$path"
		;;
	tree)
		EZA_COLORS=$tokyo_eza_colors exec eza \
			--tree \
			--level=3 \
			--color=always \
			--icons=always \
			--group-directories-first \
			--no-quotes \
			"$path"
		;;
	csv | text)
		exec bat \
			--paging=never \
			--style=plain \
			--color=always \
			--theme=tokyonight_night \
			--terminal-width "$width" \
			"$path"
		;;
	archive)
		exec tar tf "$path"
		;;
	*)
		printf 'Unknown Tokyo Night preview mode: %s\n' "$mode" >&2
		exit 2
		;;
esac
