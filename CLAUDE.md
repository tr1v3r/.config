# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles + self-hosting monorepo at `~/.config` (git user: `tr1v3r`; main branch `master`, active work on `dev`). Three groups: **dev/editor/shell configs**, **self-hosted service stacks** (Docker Compose), and **bootstrap/deploy scripts + secrets**. macOS-first, with Linux home-server support.

Some subdirectories are **git submodules that are separate repos** with their own context — most notably `zsh/` (has its own `zsh/CLAUDE.md`; read it for shell module architecture) and `nvim/`. Always check for a nested `CLAUDE.md` before assuming.

## Critical: git-crypt encrypted files

This repo uses **git-crypt**. Files matching `.gitattributes` (`secrets/**`, `ssh/config`, `aerc/accounts.conf`, `deploy/k8s/mysql/*.yaml`, `deploy/k8s/redis/*.yaml`, `iterm2/com.googlecode.iterm2.plist`, `adguard-home/conf/**`, `pihole/.pihole.env`, `emby/.env`, `karakeep/.env`) are encrypted at rest in git.

- The GPG-wrapped key lives in `.git-crypt/`; run `git-crypt unlock` (once per clone) to read/edit encrypted paths.
- Never paste secret values into plaintext. New secrets go under `secrets/**` (already encrypted) or a git-crypt-encrypted `.env`.
- If a file shows as binary/ciphertext, it's locked — don't "fix" it by overwriting with plaintext.

## Critical: whitelist `.gitignore`

The root `.gitignore` uses a `/*` whitelist: **everything top-level is ignored by default**, then specific entries are re-included with `!/path/`. Consequence: **a new top-level directory is NOT tracked until you add a `!/newdir/` line to `.gitignore`**. Runtime state (caches, container data) is pruned at the root so git never descends into it.

## Submodules

See `.gitmodules`. After cloning: `git submodule update --init --recursive`. Known submodules: `zsh`, `nvim`, `firefox` (tracks a `custom` branch), `ai/llm-wiki` (a gist fork), and two `ranger/plugins/*`.

## Bootstrap

- `scripts/init.sh` — root-only, OS-dispatches to `init_mac.sh` / `init_linux.sh` → `init_debian.sh`. Installs system packages.
- `scripts/deploy_config.sh` — root-only, clones this repo to `~/.config` and symlinks configs into place (lazygit, Firefox `chrome/`, `~/.cargo/config`, `~/.zshrc.local`).
- `zsh/init_new_device.sh` — non-root, appends `ZDOTDIR` + `HOST_PROFILE` to `~/.zshenv` for a new shell host.

## Directory Map

**Shells / editors / CLI tools** (mostly symlinked from `$HOME`): `zsh/`, `nvim/`, `aerc/` (email), `kitty/`, `iterm2/`, `tmux/`, `ranger/`, `yazi/`, `lazygit/`, `git/`, `gh/`, `gpg/`, `ssh/`, `cargo/`, `conda/`, `karabiner/`, `raycast/` (only `diy_plugins/` + `scripts/` tracked), `op/` (1Password), `opencode/`, `github-copilot/`, `neofetch/`, `snipaste/`, `bashtop/`.

**Self-hosted service stacks** (each has a `README.md`): `adguard-home/`, `pihole/` (DNS), `emby/` (media), `karakeep/` (bookmarks), `bt/` (qBittorrent-Enhanced, PT/BT). See compose pattern below.

**Infra / scripts / secrets**: `scripts/`, `deploy/` (`deploy/k8s/` manifests: redis, nginx, mysql, demo, dev), `secrets/` (git-crypt; e.g. `bd_router.yaml`, `bookmarks/` JSON snapshots), `ai/` (`SKILL_INVENTORY.md`, `skill-lock.json`, `llm-wiki` submodule).

**Root files**: `starship.toml`, `picom.conf`, `reasonix.toml` (tool config; secrets via `api_key_env`, never inline), `data.yaml`.

## Service stack compose pattern

Each service dir ships a **base** `docker-compose.yml` (macOS-local default) plus an optional `docker-compose.home.yml` override for a Linux home host that serves the whole LAN (e.g. `network_mode: host`). Runtime state is gitignored per-dir; `*.env` files are git-crypt encrypted.

```bash
# macOS local
docker compose -f docker-compose.yml up -d
# Linux home host (LAN-facing)
docker compose -f docker-compose.yml -f docker-compose.home.yml up -d
```

## Conventions

- Secrets via 1Password CLI (`op item get`) or git-crypt — never hardcoded.
- Configs are symlinked into `$HOME` by `deploy_config.sh`, not copied.
- Prefer editing the submodule repo in place (`zsh/`, `nvim/`) and committing there, then bumping the submodule pointer in this repo.
- Rust-modern CLI tools are the default (`bat`, `rg`, `eza`, `fd`, `zoxide`) — see `zsh/CLAUDE.md`.
