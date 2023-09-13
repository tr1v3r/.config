#!/bin/bash

# 需要 root 权限执行此脚本
if [[ $EUID -ne 0 ]]; then
	echo "Please run this script as root"
	exit 1
fi

abort() {
	echo "abort: $1"
	exit 1
}

deploy() {
	# clone .config repo
	if [ ! -d ~/.config ]; then
		echo "git clone git@github.com:tr1v3r/.config.git ~/.config"
		git clone git@github.com:tr1v3r/.config.git ~/.config || abort "git clone .config fail."
	fi

	# link symbol
	echo "linking .zshrc.local"
	rm -f ~/.zshrc.local && ln -s ~/.config/zsh/work.mac.zsh ~/.zshrc.local || abort "link to ~/.zshrc.local fail."
	echo "linking lazygit"
	rm -f ~/Library/Application\ Support/lazygit && ln -s ~/.config/lazygit ~/Library/Application\ Support/lazygit || abort "link to ~/.zshrc.local fail."
	echo "linking cargo config"
	rm -f ~/.cargo/config && ln -s ~/.config/cargo/config ~/.cargo/config || abort "link to ~/.cargo/config fail."
	echo "linking gpg agent config"
	rm -f ~/.gnupg/gpg-agent.conf && ln -s ~/.config/gpg/gpg-agent.conf ~/.gnupg/gpg-agent.conf || abort "link to ~/.gnupg/gpg-agent.conf fail."
	echo "linking condarc"
	rm -f ~/.condarc && ln -s ~/.config/conda/condarc ~/.condarc || abort "link to ~/.condarc fail."
	echo "linking /etc/iterm2"
	rm -f /etc/iterm2 && ln -s ~/.config/iterm2 /etc/iterm2 || abort "link to /etc/iterm2 fail."
}

SYS_TYPE=$(uname -s)

case $SYS_TYPE in
"Darwin")
	echo "deploying config on Darwin"
	deploy
	;;
"Linux")
	echo "deploying config on Linux"
	deploy
	;;
*)
	echo "Unknown SYS type: $SYS_TYPE"
	;;
esac

echo "deploy done"
