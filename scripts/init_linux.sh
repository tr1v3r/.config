#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OS_RELEASE="${BOOTSTRAP_OS_RELEASE:-/etc/os-release}"

if [[ ! -r "$OS_RELEASE" ]]; then
	printf 'Unable to detect the Linux distribution: %s is not readable\n' "$OS_RELEASE" >&2
	exit 1
fi

# shellcheck disable=SC1090
. "$OS_RELEASE"
distro_id="${ID:-}"
distro_like=" ${ID_LIKE:-} "

case "$distro_id" in
	debian|ubuntu|linuxmint|pop)
		exec "$SCRIPT_DIR/init_debian.sh" "$@"
		;;
	arch|manjaro|endeavouros)
		exec "$SCRIPT_DIR/init_arch.sh" "$@"
		;;
	*)
		if [[ "$distro_like" == *" debian "* ]]; then
			exec "$SCRIPT_DIR/init_debian.sh" "$@"
		elif [[ "$distro_like" == *" arch "* ]]; then
			exec "$SCRIPT_DIR/init_arch.sh" "$@"
		fi
		printf 'Unsupported Linux distribution: %s (ID=%s, ID_LIKE=%s)\n' \
			"${PRETTY_NAME:-unknown}" "${ID:-unknown}" "${ID_LIKE:-none}" >&2
		exit 1
		;;
esac
