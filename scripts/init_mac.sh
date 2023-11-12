#!/bin/bash

# Function to display a message and exit when something fails
abort() {
	echo "$1"
	exit 1
}

# Initialize macOS
echo "Initializing macOS setup..."

# Install Homebrew
# home page: https://brew.sh/
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || abort "Failed to install Homebrew"

# Update Homebrew and install packages
echo "Updating and upgrading Homebrew..."
brew update && brew upgrade || abort "Failed to update and upgrade Homebrew"

# python3-pip
echo "Installing packages via Homebrew..."
brew_packages=("python3" "python-psutil" "neovim" "gpg" "paperkey" "zoxide" "tldr" "mpv" "autojump" "tmux" "wget" "lua" "tree" "git-delta" "fzf" "neofetch" "cmake" "highlight" "graphviz" "ffmpeg" "openssl" "figlet")
brew install "${brew_packages[@]}" || abort "Failed to install some Homebrew packages"

echo "Installing casks via Homebrew..."
brew tap homebrew/cask-fonts
brew_casks=("font-hack-nerd-font" "skim")
brew install --cask "${brew_casks[@]}" || abort "Failed to install some Homebrew casks"

# Install oh-my-zsh
echo "Installing Oh-My-Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || abort "Failed to install Oh-My-Zsh"

# Install Golang versions
echo "Installing Golang versions..."
go_versions=("1.16.15" "1.17.13" "1.18.10" "1.19.12" "1.20.7" "1.21.0")
for v in "${go_versions[@]}"; do
	echo "Deploying go$v"
	wget https://go.dev/dl/go"$v".darwin-arm64.tar.gz &&
		tar xzf go"$v".darwin-arm64.tar.gz &&
		sudo mv go /usr/local/go"$v" &&
		rm go"$v".darwin-arm64.tar.gz || abort "Failed to install go $v"
done

# Install Go tools
echo "Installing Go tools..."
go_tools=("github.com/jesseduffield/lazygit@latest" "github.com/rhysd/vim-startuptime@latest")
for tool in "${go_tools[@]}"; do
	go install "$tool" || abort "Failed to install $tool"
done

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || abort "Failed to install Rust"

# Install Rust tools
echo "Installing Rust tools..."
cargo install ripgrep zoxide || abort "Failed to install ripgrep"

# Install Python tools
echo "Installing Python tools..."
pip3 install ranger-fm || abort "Failed to install ranger-fm"

echo "Cloning conifg..."
git clone --recursive git@github.com:tr1v3r/.config.git || abort "Failed to clone .config"
# ln -s ../.config/ranger ~/.local/ || abort "Failed to soft link .local/ranger"
ln -s .config/zsh/work.mac.zsh ~/.zshrc.local || abort "Failed to soft link .zshrc.local"

echo "MacOS init done."
