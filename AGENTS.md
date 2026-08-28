# AGENTS.md

Guidance for coding agents working in this repository. `CLAUDE.md` is a symlink
to this file, so Claude Code and other tools share this single copy.

## Repository Overview

Personal dotfiles monorepo (git user: `tr1v3r`; main branch `master`, active
work on `dev`), **managed by chezmoi**. The git checkout lives at
`~/.local/share/chezmoi` — this is the only source of truth. `~/.config` and
the home-level dotfiles it deploys are **targets**: with `mode = "symlink"`
most files there are symlinks into the source repo, so editing a target file
edits the repo directly. Only `.tmpl` templates are rendered copies — edit
those with `chezmoi edit <target>`.

`~/.config/.git.retired` is the frozen `.git` of the pre-chezmoi era (kept
temporarily as a rollback hatch; safe to delete once stable). `~/.config` also
contains plenty of host-local, untracked state (caches, app data) — that is
normal and not part of the repo.

## Critical: git-crypt encrypted files

This repo uses **git-crypt**. Paths in `.gitattributes` (all under `dot_config/`) are encrypted at rest in git:

`dot_config/secrets/**`, `dot_config/age/keys.txt`, `dot_config/age/keys-pq.txt`, `dot_config/ssh/config`,
`dot_config/aerc/accounts.conf`,
`dot_config/deploy/k8s/mysql/deploy-mysql-singleton.yaml`,
`dot_config/deploy/k8s/redis/redis-config.yaml`,
`dot_config/iterm2/com.googlecode.iterm2.plist`,
`dot_config/adguard-home/conf/**`, `dot_config/pihole/.pihole.env`,
`dot_config/emby/.env`, `dot_config/karakeep/.env`,
`dot_config/himalaya/config.toml`, `dot_config/ortie/config.toml`.

- After a fresh clone: `git-crypt unlock` (once per clone) before any
  `chezmoi apply`, otherwise chezmoi would deploy ciphertext.
- Never paste secret values into plaintext. New secrets go under `dot_config/secrets/**`
  or become git-crypt-encrypted paths.
- If a file shows as binary/ciphertext, the clone is locked — unlock it, don't
  overwrite with plaintext.

## Source layout (curated root)

There is **no whitelist `.gitignore` anymore** — the root contains exactly
what is tracked:

```
~/.local/share/chezmoi/
├── dot_config/          # → ~/.config/ (all XDG configs, service stacks, deploy/)
├── dot_zshenv.tmpl      # → ~/.zshenv (renders HOST_PROFILE from chezmoi data)
├── dot_condarc          # → ~/.condarc
├── dot_cargo/           # → ~/.cargo/
├── dot_gnupg/           # → ~/.gnupg/ (gpg-agent.conf is a darwin/linux template)
├── scripts/             # bootstrap scripts — NOT deployed (see .chezmoiignore)
├── .chezmoi.toml.tmpl   # init questionnaire → hostProfile / machineRole / firefoxProfile
├── .chezmoiignore       # per-machine exclusions (template)
└── .chezmoiscripts/     # run_once_install-packages, run_onchange_after_darwin-links
```

## Bootstrap (new machine)

```bash
chezmoi init git@github.com:tr1v3r/dotfiles.git   # clone + answer the questionnaire
cd ~/.local/share/chezmoi && git-crypt unlock     # decrypt secrets (needs the GPG key)
chezmoi apply                                     # deploy everything
sudo dot_config/scripts/init.sh                   # optional: system packages
```

`chezmoi apply --exclude scripts` skips the `.chezmoiscripts/` hooks (useful
when you don't want package installs to fire).

## Submodules

See `.gitmodules`. After cloning: `git submodule update --init`. Known
submodules: `dot_config/zsh`, `dot_config/nvim`, `dot_config/firefox`
(custom branch), `dot_config/ai/llm-wiki`. The old
`ranger/plugins/{ranger_devicons,ranger-gpg}` submodules are **vendored**
(pinned commits, plain files now).

## Directory Map

**Shells / editors / CLI tools** (under `dot_config/`): `zsh/` (submodule, has
its own CLAUDE.md/AGENTS.md), `nvim/` (submodule), `aerc/`, `himalaya/`,
`kitty/`, `iterm2/`, `tmux/`, `tmux-powerline/`, `ranger/`, `yazi/`,
`lazygit/`, `gnupg/`→promoted, `ssh/`, `git/`, `raycast/`, `neofetch/`,
`snipaste/`, `bashtop/`, `herdr/`, `dsh/`, `skills/`, `ai/`, `ortie/` (ortie contains credentials — git-crypt encrypted).

**Self-hosted service stacks** (under `dot_config/`, each with a README):
`adguard-home/`, `pihole/`, `emby/`, `karakeep/`, `bt/`. Applied **only** on
machines whose `machineRole` is `home-server` (see `.chezmoiignore`).

**Infra / secrets**: `deploy/`, `secrets/`, `age/` (git-crypt-protected, under `dot_config/`),
`scripts/` (root-only bootstrap dispatchers, NOT deployed).

## Multi-machine model

Two independent axes, both answered at `chezmoi init`:

- `hostProfile` (`work` | `personal`) — rendered into `~/.zshenv` as
  `HOST_PROFILE`, consumed at runtime by `zsh/.zshrc` (sources `work.zsh`).
- `machineRole` (`workstation` | `home-server`) — gates service-stack
  deployment via `.chezmoiignore`.

Do not invent a third mechanism; extend these.

## Conventions

- Secrets via git-crypt (or 1Password CLI `op item get`) — never hardcoded.
- Prefer editing the submodule repos in place (`dot_config/zsh/`,
  `dot_config/nvim/`) and committing there, then bumping the pointer here.
- Rust-modern CLI tools are the default (`bat`, `rg`, `eza`, `fd`, `zoxide`).
- Dependabot alerts on the stale `master` default branch (default-branch switch pending).
