#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
BOOTSTRAP_TEST_FILTER="${BOOTSTRAP_TEST_FILTER:-}"

have() { command -v "$1" >/dev/null 2>&1; }
have "$CONTAINER_ENGINE" || {
	printf 'Container engine not found: %s\n' "$CONTAINER_ENGINE" >&2
	exit 1
}

images=(
	"ubuntu-24.04|ubuntu:24.04|"
	"debian-12|debian:12-slim|"
	# The official Arch image has no arm64 manifest; OrbStack emulates amd64.
	"arch|archlinux:latest|linux/amd64"
)

tests_run=0
for item in "${images[@]}"; do
	IFS='|' read -r name image platform <<<"$item"
	if [[ -n "$BOOTSTRAP_TEST_FILTER" && "$name" != "$BOOTSTRAP_TEST_FILTER" ]]; then
		continue
	fi
	((tests_run += 1))
	docker_args=(run --rm)
	if [[ -n "$platform" ]]; then
		docker_args+=(--platform "$platform")
	fi
	docker_args+=(
		--name "dotfiles-bootstrap-$name"
		--volume "$REPO_ROOT:/workspace:ro"
		--entrypoint /bin/bash
	)
	printf '\n===== %s (%s%s) =====\n' "$name" "$image" "${platform:+, $platform}"

	# shellcheck disable=SC2016 # payload variables expand inside the container
	"$CONTAINER_ENGINE" "${docker_args[@]}" "$image" -lc '
set -Eeuo pipefail

# pacman 7 syscall sandboxing cannot nest under OrbStack amd64 emulation. This
# is isolated to the disposable test container; the bootstrap never changes it.
if [[ -f /etc/pacman.conf ]]; then
  sed -i "s/^#DisableSandboxSyscalls/DisableSandboxSyscalls/" /etc/pacman.conf
fi

bash -n /workspace/scripts/init.sh \
  /workspace/scripts/init_linux.sh \
  /workspace/scripts/init_common.sh \
  /workspace/scripts/init_debian.sh \
  /workspace/scripts/init_arch.sh \
  /workspace/scripts/init_mac.sh

/workspace/scripts/init.sh --help >/dev/null
invalid_status=0
/workspace/scripts/init.sh --invalid-option >/dev/null 2>&1 || invalid_status=$?
[[ "$invalid_status" -eq 2 ]] || {
  printf "invalid option returned %s instead of 2\n" "$invalid_status" >&2
  exit 1
}

# Exercise distro dispatch and every optional group without mutating the image.
dry_output="$(/workspace/scripts/init.sh --dry-run --with-all)"
grep -q "4 optional groups" <<<"$dry_output"

if [[ -d /etc/apt ]]; then
  cp -a /etc/apt /tmp/apt-before-bootstrap
fi

# Perform a real base install as root. Repeat as a NOPASSWD user to verify both
# sudo self-elevation and idempotent package installation.
BOOTSTRAP_RETRIES=2 BOOTSTRAP_RETRY_DELAY=1 /workspace/scripts/init.sh
useradd --create-home --shell /bin/bash bootstrap-test
printf "bootstrap-test ALL=(ALL) NOPASSWD: ALL\n" >/etc/sudoers.d/bootstrap-test
chmod 0440 /etc/sudoers.d/bootstrap-test
su -s /bin/bash bootstrap-test -c "BOOTSTRAP_RETRIES=1 /workspace/scripts/init.sh --skip-update"

if [[ -d /tmp/apt-before-bootstrap ]]; then
  diff -ru /tmp/apt-before-bootstrap /etc/apt
fi


for executable in bat curl dig fd fzf git git-crypt gpg nvim python3 rg tmux zoxide; do
  command -v "$executable" >/dev/null || {
    printf "missing expected command: %s\n" "$executable" >&2
    exit 1
  }
done
'
done

if ((tests_run == 0)); then
	printf 'No test image matched BOOTSTRAP_TEST_FILTER=%s\n' "$BOOTSTRAP_TEST_FILTER" >&2
	exit 2
fi

printf '\nAll Linux container bootstrap tests passed.\n'
