```
 _____ ____  _       _____      _
|_   _|  _ \/ |_   _|___ / _ __( )___
  | | | |_) | \ \ / / |_ \| '__|// __|
  | | |  _ <| |\ V / ___) | |    \__ \
  |_| |_| \_\_| \_/ |____/|_| |_| \___|
```

# dotfiles

Personal dotfiles monorepo, **chezmoi-managed**. macOS-first with Linux
home-server support, Colemak-optimized.

## Highlights

- **chezmoi with `mode = "symlink"`** — targets are symlinks into the source
  repo; edit a file anywhere, it's the same file
- **Region-aware** mirrors, proxies, and AI endpoints — auto-detected, manually overridable
- **git-crypt** encrypted secrets — sensitive files encrypted at rest in the repo
- **Declarative package management** — Homebrew / Cargo / Go arrays with one-command upgrades
- **Self-hosted service stacks** — Docker Compose for DNS, media, bookmarks, and downloads
- **Submodule-based editors** — `dot_config/zsh/` and `dot_config/nvim/` live in their own repos

## Repository Structure

The checkout is the chezmoi **source** dir (`~/.local/share/chezmoi` after
`chezmoi init`):

- `dot_config/` → `~/.config/` — all XDG configs, plus the service stacks and `deploy/`
- `dot_zshenv.tmpl`, `dot_condarc`, `dot_cargo/`, `dot_gnupg/` → home-level dotfiles
- `scripts/`, `secrets/`, `age/`, `*.md` — repo-only, not deployed (see `.chezmoiignore`)
- `.chezmoiignore` — per-machine exclusions (`machineRole`: `workstation` vs `home-server`)

## Bootstrap

```bash
# 1. clone via chezmoi + answer the questionnaire (host profile, machine role)
chezmoi init git@github.com:tr1v3r/dotfiles.git

# 2. unlock encrypted files (requires the GPG key) — BEFORE first apply
cd ~/.local/share/chezmoi && git-crypt unlock

# 3. deploy everything
chezmoi apply

# 4. optional: system packages (root)
sudo dot_config/scripts/init.sh
```

## Notes

- **Encrypted paths**: see `.gitattributes` (`secrets/**`, `dot_config/ssh/config`,
  `dot_config/aerc/accounts.conf`, various `*.env`).
- **Editing**: non-template targets are symlinks — edit in place. Templates
  (`*.tmpl`) are rendered copies; edit them with `chezmoi edit <target>`.
- **Submodules**: `dot_config/zsh/` and `dot_config/nvim/` are separate repos
  with their own docs — edit and commit there, then bump the pointer here.
- **Service stacks** deploy only with `machineRole = "home-server"`.

## License

GPL — see headers in individual files.
