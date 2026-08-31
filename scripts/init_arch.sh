#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/init_common.sh
. "$SCRIPT_DIR/init_common.sh"
parse_options "$@"
require_privilege

[[ "$DRY_RUN" == true ]] || have pacman || die "pacman is required for Arch Linux initialization"

base_packages=(
	atool base-devel bat bind ca-certificates cmake curl fd fzf git git-crypt
	gnupg highlight iputils neovim net-tools nftables openssl python python-pip
	python-pynvim ripgrep sudo tmux wget zoxide
)
optional_packages=()
optional_group_count=0
if [[ "$INSTALL_ZSH" == true ]]; then optional_packages+=(zsh); ((optional_group_count += 1)); fi
if [[ "$INSTALL_GO" == true ]]; then optional_packages+=(go); ((optional_group_count += 1)); fi
if [[ "$INSTALL_RUST" == true ]]; then optional_packages+=(rust); ((optional_group_count += 1)); fi
if [[ "$INSTALL_PYTHON_TOOLS" == true ]]; then optional_packages+=(ranger); ((optional_group_count += 1)); fi

log "Detected ${PRETTY_NAME:-Arch Linux}; using pacman"
pacman_mode=(-S)
if [[ "$SKIP_UPDATE" != true ]]; then
	# Arch does not support partial upgrades: refresh and upgrade together.
	pacman_mode=(-Syu)
fi

log "Installing ${#base_packages[@]} base packages and ${#optional_packages[@]} packages from $optional_group_count optional groups"
retry run_root pacman "${pacman_mode[@]}" --needed --noconfirm \
	"${base_packages[@]}" "${optional_packages[@]}"

log "Linux package initialization complete"
