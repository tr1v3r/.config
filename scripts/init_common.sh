#!/usr/bin/env bash
# Shared helpers for Linux package-manager backends. This file is sourced.
# shellcheck disable=SC2034 # option globals are consumed by the sourcing backend

INSTALL_ZSH=false
INSTALL_GO=false
INSTALL_RUST=false
INSTALL_PYTHON_TOOLS=false
SKIP_UPDATE=false
DRY_RUN=false

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}
usage_error() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 2
}
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
	cat <<'EOF'
Usage: ./scripts/init.sh [OPTIONS]

Install system packages for this dotfiles environment. Configuration deployment
is handled separately by chezmoi.

Options:
  --with-zsh           Install Zsh (does not change the login shell)
  --with-go            Install the distribution's Go toolchain
  --with-rust          Install the distribution's Rust toolchain
  --with-python-tools  Install ranger
  --with-all           Enable all optional groups above
  --skip-update        Skip package-index refresh (useful for controlled reruns)
  --dry-run            Print privileged package-manager commands without running them
  -h, --help           Show this help

Environment:
  BOOTSTRAP_RETRIES     Package-manager attempts (default: 3)
  BOOTSTRAP_RETRY_DELAY Initial retry delay in seconds (default: 2)
EOF
}

parse_options() {
	local install_all=false
	while (($#)); do
		case "$1" in
			--with-zsh) INSTALL_ZSH=true ;;
			--with-go) INSTALL_GO=true ;;
			--with-rust) INSTALL_RUST=true ;;
			--with-python-tools) INSTALL_PYTHON_TOOLS=true ;;
			--with-all) install_all=true ;;
			--skip-update) SKIP_UPDATE=true ;;
			--dry-run) DRY_RUN=true ;;
			-h|--help)
				usage
				exit 0
				;;
			--)
				shift
				(($# == 0)) || usage_error "Unexpected positional arguments: $*"
				break
				;;
			*) usage_error "Unknown option: $1 (use --help)" ;;
		esac
		shift
	done

	if [[ "$install_all" == true ]]; then
		INSTALL_ZSH=true
		INSTALL_GO=true
		INSTALL_RUST=true
		INSTALL_PYTHON_TOOLS=true
	fi
}

print_command() {
	printf 'DRY-RUN:'
	printf ' %q' "$@"
	printf '\n'
}

require_privilege() {
	if [[ "$DRY_RUN" == true || "$EUID" -eq 0 ]]; then
		return
	fi
	have sudo || die "Root privileges are required and sudo is not installed"
	sudo -v
}

run_root() {
	local -a command
	if [[ "$EUID" -eq 0 ]]; then
		command=("$@")
	else
		command=(sudo "$@")
	fi

	if [[ "$DRY_RUN" == true ]]; then
		print_command "${command[@]}"
	else
		"${command[@]}"
	fi
}

retry() {
	local _retry_max="${BOOTSTRAP_RETRIES:-3}"
	local _retry_delay="${BOOTSTRAP_RETRY_DELAY:-2}"
	local _retry_attempt=1
	local _retry_status
	[[ "$_retry_max" =~ ^[1-9][0-9]*$ ]] || die "BOOTSTRAP_RETRIES must be a positive integer"
	[[ "$_retry_delay" =~ ^(0|[1-9][0-9]*)$ ]] || die "BOOTSTRAP_RETRY_DELAY must be a non-negative integer without leading zeros"

	until "$@"; do
		_retry_status=$?
		if ((_retry_attempt >= _retry_max)); then
			return "$_retry_status"
		fi
		warn "Command failed (attempt $_retry_attempt/$_retry_max); retrying in ${_retry_delay}s"
		sleep "$_retry_delay"
		((_retry_attempt += 1))
		_retry_delay=$((_retry_delay * 2))
	done
}

ensure_command_alias() {
	local desired="$1"
	local packaged_name="$2"
	local source_path
	have "$desired" && return
	source_path="$(command -v "$packaged_name" 2>/dev/null || true)"
	[[ -n "$source_path" ]] || die "Neither $desired nor $packaged_name is available after package installation"
	run_root install -d /usr/local/bin
	run_root ln -sfn "$source_path" "/usr/local/bin/$desired"
}
