# AGENTS.md

## Project Overview

Personal dotfiles for a cross-platform dev setup (macOS Intel + Pop!_OS Linux),
managed with **GNU Stow** (symlinks into `$HOME`) and **Nix/Devbox** (packages).
Goal: one repo that fully provisions terminal, shell, and CLI tooling on any machine.

## Structure

- `sync.sh` – stow symlinks repo into `$HOME` (run after edits to apply them)
- `install.sh` – bootstrap: Determinate Nix, devbox, nerdfonts, Pop!_OS tunes, `sync.sh`, `devbox global install`
- `.zshrc` – shell config: devbox global env, completions, git/k8s/ls aliases
- `.config/` – kitty, wezterm (symlinked manually in sync.sh), tig, direnv, starship, herdr
- `.local/bin/` – user scripts (`pick-emoji`, `screenshot-wayland`)
- `.local/share/devbox/global/default/devbox.json` – **global CLI packages** (kubectl, gh, fzf, bat, go, node, etc.); canonical file, rendered/symlinked into `$HOME` by `sync.sh`
- `devbox.json` – project-local packages: wget, teller, stow
- `scripts/` – `nerdfonts.sh`, `pop-os-tune.sh` (not stowed; see `.stow-local-ignore`)
- `renovate.json` – automated dependency PRs
- `plans/` – agent execution plans (committed to git, not stowed; see `plans/README.md`)

## Key Workflow

- Edit files **in this repo**, never in `$HOME` (stow symlinks make $HOME point here).
- Apply changes: `./sync.sh` (stow won't overwrite existing files; it removes `~/.zshrc` first).
- Update global CLI tools: edit `.local/share/devbox/global/default/devbox.json`, run `./sync.sh`, then `devbox global install`.
- **Intel macOS** is pinned to nixpkgs **26.05** (last release with `x86_64-darwin`); `sync.sh` renders a generated `devbox.json` (base `nixpkgs.commit` = `NIXOS_2605_COMMIT`, versions stripped) for `Darwin + x86_64` and symlinks the canonical file elsewhere. Bump that constant to refresh 26.05 fixes.

## Commands

- Execute pending plans one by one: `/plans` (opencode command, `.opencode/command/plans.md`)
- Enter project env: `direnv allow` (uses `.envrc` -> devbox)
- Run shell in project env: `devbox shell`
- No tests, lint, or build — this is config only. Validate edits by re-running `./sync.sh` and opening a new shell.

## Conventions

- Commits follow Conventional Commits with scope: `feat(zshrc):`, `fix(herdr):`, `chore(deps):` (deps handled by Renovate).
- `devbox.lock` and `.devbox/` are gitignored — don't commit them.
- Personal/unstowed files belong in `.stow-local-ignore`.

## Current Focus

- `herdr` config shortcuts (`herdr/config.toml`) and theming
- Wezterm font config improvements
- Keeping nixpkgs versions compatible with Intel macOS
