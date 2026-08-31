#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/init_common.sh
. "$SCRIPT_DIR/init_common.sh"
parse_options "$@"
require_privilege

[[ "$DRY_RUN" == true ]] || have apt-get || die "apt-get is required for Debian/Ubuntu initialization"

base_packages=(
	atool bat build-essential ca-certificates cmake curl dnsutils fd-find fzf
	git git-crypt gnupg highlight iputils-ping neovim net-tools nftables
	openssl python3 python3-pip python3-pynvim ripgrep sudo tmux wget zoxide
)
optional_packages=()
optional_group_count=0
if [[ "$INSTALL_ZSH" == true ]]; then optional_packages+=(zsh); ((optional_group_count += 1)); fi
if [[ "$INSTALL_GO" == true ]]; then optional_packages+=(golang-go); ((optional_group_count += 1)); fi
if [[ "$INSTALL_RUST" == true ]]; then optional_packages+=(cargo rustc); ((optional_group_count += 1)); fi
if [[ "$INSTALL_PYTHON_TOOLS" == true ]]; then optional_packages+=(ranger); ((optional_group_count += 1)); fi

log "Detected ${PRETTY_NAME:-Debian-family Linux}; using apt-get"
if [[ "$SKIP_UPDATE" != true ]]; then
	log "Refreshing the APT package index"
	retry run_root env DEBIAN_FRONTEND=noninteractive apt-get update
fi

log "Installing ${#base_packages[@]} base packages and ${#optional_packages[@]} packages from $optional_group_count optional groups"
retry run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	"${base_packages[@]}" "${optional_packages[@]}"

if [[ "$DRY_RUN" != true ]]; then
	# Debian-family packages expose these as batcat/fdfind to avoid name clashes.
	ensure_command_alias bat batcat
	ensure_command_alias fd fdfind
fi

log "Linux package initialization complete"
