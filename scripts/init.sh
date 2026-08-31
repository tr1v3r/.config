#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

case "$(uname -s)" in
	Darwin)
		exec "$SCRIPT_DIR/init_mac.sh" "$@"
		;;
	Linux)
		exec "$SCRIPT_DIR/init_linux.sh" "$@"
		;;
	*)
		printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
		exit 1
		;;
esac
