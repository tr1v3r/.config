#!/usr/bin/env bash
set -Eeuo pipefail

# macOS bootstrap — installs packages only.
# Config deployment is handled by chezmoi (chezmoi init + git-crypt unlock + chezmoi apply).
# Idempotent: every step is skipped when its tool is already present,
# so this is safe to run on an already-provisioned machine.

abort() {
	echo "$1"
	exit 1
}

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
	cat <<'EOF'
Usage: ./scripts/init.sh

Install the complete macOS package set. Linux-only package-group options are not
supported on macOS. Configuration deployment is handled separately by chezmoi.
EOF
}

if (($#)); then
	case "$1" in
		-h|--help) usage; exit 0 ;;
		*) printf 'ERROR: Unknown macOS option: %s (use --help)\n' "$1" >&2; exit 2 ;;
	esac
fi

echo "Initializing macOS setup..."

# Homebrew (https://brew.sh/) — skipped when already installed
if have brew; then
	echo "Homebrew already installed, refreshing index..."
	brew update || echo "WARN: brew update failed (continuing with stale index)"
else
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || abort "Failed to install Homebrew"
fi

# A fresh Apple Silicon install is not on PATH in the current process yet.
if ! have brew; then
	for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [[ -x "$brew_path" ]]; then
			eval "$("$brew_path" shellenv)"
			break
		fi
	done
fi
have brew || abort "Homebrew was installed but could not be added to PATH"

# Formulae (brew itself skips the ones already installed; go included)
# NOTE: per-package loop so one bad/renamed formula doesn't kill the rest.
echo "Installing packages via Homebrew..."
brew_packages=("python3" "neovim" "gpg" "paperkey" "zoxide" "tldr" "mpv" "autojump" "tmux" "wget" "lua" "tree" "git-delta" "git-crypt" "fzf" "neofetch" "cmake" "highlight" "graphviz" "ffmpeg" "openssl" "sops" "figlet" "go")
for pkg in "${brew_packages[@]}"; do
	brew install "$pkg" || echo "WARN: brew install $pkg failed (continuing)"
done

# Casks — the homebrew/cask-fonts tap is deprecated; fonts live in homebrew/cask now
echo "Installing casks via Homebrew..."
brew_casks=("font-hack-nerd-font" "skim" "sioyek")
for cask in "${brew_casks[@]}"; do
	brew install --cask "$cask" || echo "WARN: brew install --cask $cask failed (continuing)"
done

# Go tools (go itself comes from brew above; no more legacy multi-version tarball zoo)
if have go; then
	echo "Installing Go tools..."
	go_tools=("github.com/jesseduffield/lazygit@latest" "github.com/rhysd/vim-startuptime@latest")
	for tool in "${go_tools[@]}"; do
		cmd="${tool##*/}"; cmd="${cmd%%@*}"
		if ! have "$cmd"; then
			go install "$tool" || abort "Failed to install $tool"
		fi
	done
else
	echo "WARN: go not found, skipping Go tools"
fi

# Rust toolchain — skipped when already installed
if ! have cargo; then
	echo "Installing Rust..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || abort "Failed to install Rust"
fi
if [[ -f "$HOME/.cargo/env" ]]; then
	# shellcheck source=/dev/null
	. "$HOME/.cargo/env"
fi
if have cargo; then
	echo "Installing Rust tools..."
	have ripgrep || cargo install ripgrep || abort "Failed to install ripgrep"
	have zoxide || cargo install zoxide || abort "Failed to install zoxide"
else
	echo "WARN: cargo not found, skipping Rust tools"
fi

# Python tools — ranger only when neither ranger nor yazi is present
if ! have ranger && ! have yazi; then
	echo "Installing Python tools..."
	pip3 install ranger-fm || echo "WARN: pip3 install ranger-fm failed (continuing)"
fi

echo "Config deployment is handled by chezmoi (chezmoi init + git-crypt unlock + chezmoi apply)."
echo "MacOS init done."
