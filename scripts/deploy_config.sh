#!/bin/bash

abort() {
	echo "abort: $1"
	exit 1
}

link_config() {
	local source_path="$1"
	local target_path="$2"
	local backup_path

	if [ ! -e "$source_path" ]; then
		abort "link source does not exist: $source_path"
	fi

	if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
		echo "already linked: $target_path"
		return
	fi

	if [ -e "$target_path" ] || [ -L "$target_path" ]; then
		backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
		mv "$target_path" "$backup_path" || abort "backup $target_path fail."
		echo "backed up $target_path to $backup_path"
	fi

	ln -s "$source_path" "$target_path" || abort "link $target_path fail."
}

link_system_config() {
	local source_path="$1"
	local target_path="$2"
	local backup_path

	if [ ! -e "$source_path" ]; then
		abort "link source does not exist: $source_path"
	fi

	if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
		echo "already linked: $target_path"
		return
	fi

	if [ -e "$target_path" ] || [ -L "$target_path" ]; then
		backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
		sudo mv "$target_path" "$backup_path" || abort "backup $target_path fail."
		echo "backed up $target_path to $backup_path"
	fi

	sudo ln -s "$source_path" "$target_path" || abort "link $target_path fail."
}

deploy_common() {
	# clone .config repo
	if [ ! -d "$HOME/.config" ]; then
		echo "git clone git@github.com:tr1v3r/.config.git $HOME/.config"
		git clone git@github.com:tr1v3r/.config.git "$HOME/.config" || abort "git clone .config fail."
	fi

	# link symbol
	echo "linking .zshrc.local"
	link_config "$HOME/.config/zsh/work.mac.zsh" "$HOME/.zshrc.local"
	echo "linking lazygit"
	link_config "$HOME/.config/lazygit" "$HOME/Library/Application Support/lazygit"
	echo "linking Firefox chrome dir"
	FIREFOX_PROFILE="$HOME/Library/Application Support/Firefox/Profiles/wwg09b6h.default-release"
	link_config "$HOME/.config/firefox" "$FIREFOX_PROFILE/chrome"
	echo "linking cargo config"
	link_config "$HOME/.config/cargo/config" "$HOME/.cargo/config"
	echo "linking GnuPG shared config"
	mkdir -p "$HOME/.gnupg" || abort "create $HOME/.gnupg fail."
	chmod 700 "$HOME/.gnupg" || abort "chmod $HOME/.gnupg fail."
	link_config "$HOME/.config/gpg/gpg.conf" "$HOME/.gnupg/gpg.conf"
	link_config "$HOME/.config/gpg/common.conf" "$HOME/.gnupg/common.conf"
	echo "linking condarc"
	link_config "$HOME/.config/conda/condarc" "$HOME/.condarc"
}

deploy_macos() {
	echo "linking macOS GPG agent config"
	link_config "$HOME/.config/gpg/gpg-agent.macos.conf" "$HOME/.gnupg/gpg-agent.conf"
	echo "linking /etc/iterm2"
	link_system_config "$HOME/.config/iterm2" "/etc/iterm2"
}

SYS_TYPE=$(uname -s)

case $SYS_TYPE in
"Darwin")
	echo "deploying config on Darwin"
	deploy_common
	deploy_macos
	;;
"Linux")
	echo "deploying config on Linux"
	deploy_common
	echo "skipping macOS-specific GPG agent and iTerm2 configs"
	;;
*)
	echo "Unknown SYS type: $SYS_TYPE"
	;;
esac

echo "deploy done"
