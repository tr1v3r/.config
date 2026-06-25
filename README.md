```
 _____ ____  _       _____      _
|_   _|  _ \/ |_   _|___ / _ __( )___
  | | | |_) | \ \ / / |_ \| '__|// __|
  | | |  _ <| |\ V / ___) | |    \__ \
  |_| |_| \_\_| \_/ |____/|_|    |___/

  ____             __ _                       _   _
 / ___|___  _ __  / _(_) __ _ _   _ _ __ __ _| |_(_) ___  _ __
| |   / _ \| '_ \| |_| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
| |__| (_) | | | |  _| | (_| | |_| | | | (_| | |_| | (_) | | | |
 \____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
                        |___/
```

# .config

Personal dotfiles + self-hosting monorepo. macOS-first with Linux home-server support, Colemak-optimized.

## Highlights

- **Region-aware** mirrors, proxies, and AI endpoints — auto-detected, manually overridable
- **git-crypt** encrypted secrets — sensitive files encrypted at rest in the repo
- **Declarative package management** — Homebrew / Cargo / Go arrays with one-command upgrades
- **Self-hosted service stacks** — Docker Compose for DNS, media, bookmarks, and downloads
- **Submodule-based editors** — `zsh/` and `nvim/` live in their own repos

## Repository Structure

**Shells & editors** — `zsh/`, `nvim/`, `aerc/` (email), `kitty/`, `iterm2/`, `tmux/`, `ranger/`, `yazi/`, `lazygit/`

**Self-hosted services** (Docker Compose, each with its own `README.md`) — `adguard-home/`, `pihole/` (DNS), `emby/` (media), `karakeep/` (bookmarks), `bt/` (downloads)

**Infra & scripts** — `scripts/` (bootstrap), `deploy/` (k8s manifests), `secrets/` (git-crypt), `ai/`

**App configs** — `git/`, `gpg/`, `ssh/`, `cargo/`, `conda/`, `karabiner/`, `raycast/`, `starship.toml`, `picom.conf`, and more

## Bootstrap

```bash
# 1. clone with submodules
git clone --recurse-submodules git@github.com:tr1v3r/.config.git ~/.config && cd ~/.config

# 2. unlock encrypted files (requires the GPG key)
git-crypt unlock

# 3. install system packages (root)
sudo scripts/init.sh

# 4. symlink configs into place (root)
sudo scripts/deploy_config.sh
```

## Notes

- **Encrypted paths**: files under `secrets/**`, `ssh/config`, `aerc/accounts.conf`, and various `*.env` are git-crypt encrypted — see `.gitattributes`.
- **Whitelist `.gitignore`**: the `/*` pattern ignores every top-level entry by default; a new top-level dir needs a `!/dir/` line to be tracked.
- **Submodules**: `zsh/` and `nvim/` are separate repos with their own docs — edit and commit there, then bump the pointer here.

## License

GPL — see headers in individual files.
