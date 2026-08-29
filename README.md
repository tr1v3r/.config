```
 _____ ____  _       _____      _
|_   _|  _ \/ |_   _|___ / _ __( )___
  | | | |_) | \ \ / / |_ \| '__|// __|
  | | |  _ <| |\ V / ___) | |    \__ \
  |_| |_| \_\_| \_/ |____/|_| |_| \___|
```

# dotfiles

Personal dotfiles monorepo, **chezmoi-managed**. Supports macOS plus Ubuntu,
Debian, and Arch Linux, with Linux home-server support and Colemak optimization.

## Highlights

- **chezmoi with `mode = "symlink"`** — targets are symlinks into the source
  repo; edit a file anywhere, it's the same file
- **Region-aware** mirrors, proxies, and AI endpoints — auto-detected, manually overridable
- **git-crypt** encrypted secrets — sensitive files encrypted at rest in the repo
- **Cross-distribution bootstrap** — Homebrew on macOS, APT on Ubuntu/Debian, and pacman on Arch
- **Self-hosted service stacks** — Docker Compose for DNS, media, bookmarks, and downloads
- **Submodule-based editors** — `.zsh/` and `.nvim/` live in their own repos

## Repository Structure

The checkout is the chezmoi **source** dir (`~/.local/share/chezmoi` after
`chezmoi init`):

- `dot_config/` → `~/.config/` — all XDG configs, plus the service stacks and `deploy/`
- `dot_zshenv.tmpl`, `dot_condarc`, `dot_cargo/`, `dot_gnupg/` → home-level dotfiles
- `scripts/`, `*.md` — repo-only; encrypted `age/` and `secrets/` live under `dot_config/`
- `.chezmoiignore` — per-machine exclusions (`machineRole`: `workstation` vs `home-server`)

## New Machine Bootstrap

Prerequisites: install `chezmoi` and `git` so the source repository can be cloned.
Then run the complete bootstrap flow:

```bash
# 1. clone via chezmoi + answer the questionnaire (host profile, machine role)
chezmoi init git@github.com:tr1v3r/dotfiles.git

cd ~/.local/share/chezmoi

# 2. install system packages when the machine is not provisioned yet. This is
#    explicit so chezmoi apply stays non-root and headless-safe.
./scripts/init.sh

# Linux-only optional package groups:
./scripts/init.sh --with-zsh      # one optional group
./scripts/init.sh --with-all      # Zsh + Go + Rust + ranger

# 3. unlock encrypted files (requires the GPG key) — BEFORE first apply
#    The base package bootstrap above includes git-crypt.
git-crypt unlock

# 4. deploy everything (never starts package installation)
chezmoi apply
```

The responsibilities are intentionally separated:

```text
chezmoi init -> scripts/init.sh -> git-crypt unlock -> chezmoi apply
clone source    install packages   decrypt secrets    deploy configuration
```

`scripts/` is part of the chezmoi source repository but is excluded from target
deployment by `.chezmoiignore`. Package installation is therefore explicit and
repeatable; `chezmoi apply` stays usable without root, a TTY, or package-manager
network access. After pulling bootstrap changes, rerun `./scripts/init.sh` manually.

## Linux bootstrap tests

Run the same installation twice in clean Ubuntu 24.04, Debian 12, and Arch
containers, then verify the expected commands. On arm64 hosts, the official Arch
image runs as linux/amd64 under the container engine's emulation:

```bash
./scripts/test_linux_containers.sh
# one image only (useful while iterating):
BOOTSTRAP_TEST_FILTER=arch ./scripts/test_linux_containers.sh
```

The bootstrap does not replace package mirrors, perform Debian/Ubuntu system
upgrades, clone configuration into root's home, or change the login shell. On
Linux, use `./scripts/init.sh --help` for optional groups, dry-run, and retry controls.

## Notes

- **Encrypted paths**: see `.gitattributes` (`secrets/**`, `dot_config/ssh/config`,
  `dot_config/aerc/accounts.conf`, various `*.env`).
- **Editing**: non-template targets are symlinks — edit in place. Templates
  (`*.tmpl`) are rendered copies; edit them with `chezmoi edit <target>`.
- **Submodules**: `.zsh/` and `.nvim/` are separate repos
  with their own docs — edit and commit there, then bump the pointer here.
- **SSH layering**: chezmoi renders `~/.ssh/config`; machine-local overrides live in
  unmanaged `~/.ssh/config.local`, macOS also includes OrbStack, and shared hosts
  remain in the encrypted `~/.config/ssh/config`.
- **Service stacks** deploy only with `machineRole = "home-server"`.

## License

GPL — see headers in individual files.
