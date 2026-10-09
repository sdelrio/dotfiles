---
title: Speed up zsh startup (single cached compinit, completion cache)
date: 2026-10-08
---

# Plan: Speed up zsh startup (single cached compinit, completion cache)

## Context

Opening a new terminal/tab takes ~2.7-3.5s on mbp19i1 (Intel macOS). The repo's
`.zshrc` already has a cached-compinit block (commit `d35f2e8`) but startup is
still slow because `compinit` runs **four times per shell**, and the `.zshrc`
block runs *third/fourth* — the expensive work is already done before it gets a
chance.

Relevant files:

- `~/dotfiles/.zshrc` — dotfiles zsh config, stowed to `~/.zshrc`, sourced by
  home-manager's `~/.config/zsh/.zshrc` at its end
- `~/dotfiles/.local/share/devbox/global/default/zsh/.zshrc` — sourced via
  `init.sh` when `.zshrc` evals `devbox global shellenv --init-hook` (this path
  is symlinked into `~/.local/share/devbox/global/default/zsh/.zshrc`)
- `~/.zshenv` — unmanaged file (not in repo; already holds npm PATH exports),
  sourced before `/etc/zshrc`
- Generated (read-only for this plan): `/etc/zshrc` (nix-darwin),
  `~/.config/zsh/.zshrc` (home-manager)

## Findings (already researched — do not re-research)

Startup budget (measured on mbp19i1, warm cache, `zsh -i -c true` ≈ 2.78s,
`zsh -il -c true` ≈ 2.73s, first measured run up to 3.5s):

| # | Cost | Source |
|---|------|--------|
| 1 | ~0.65s | `/etc/zshrc` (nix-darwin): `promptinit && prompt suse` (~76ms) + **full `compinit`** + `bashcompinit` (~13ms) |
| 2 | ~0.6s | `~/.config/zsh/.zshrc` (home-manager): **full `compinit`** again (`autoload -U compinit && compinit`) |
| 3 | ~0.5s | `.zshrc` devbox eval → `init.sh` → `.local/share/devbox/global/default/zsh/.zshrc`: **full `compinit`** #3, plus starship/zoxide/direnv/atuin inits (~190ms) |
| 4 | ~0.6s | `.zshrc` lines 36-42: three `source <(…completion…)` binary spawns — `devbox completion zsh` ~0.27s, `kubectl completion zsh \| sed` ~0.24s, `docker completion zsh` ~0.12s |
| 5 | ~0.05s | the `.zshrc` cached-compinit block (warm) — correct but redundant, and runs before devbox extends `fpath` |

zprof evidence (`zsh -c 'zmodload zsh/zprof; source ~/.config/zsh/.zshrc'`):
`compinit` 3 calls / 2194ms, `compdump` 2 calls / 906ms, `compdef` 1677 calls /
534ms, `compaudit` 4 calls / 190ms. Each extra full `compinit` re-scans `fpath`,
rewrites the dump and re-registers ~1700 completions.

Other facts:

- The dump path `${ZDOTDIR:-$HOME}/.zcompdump` is correct — `ZDOTDIR` is set
  (`~/.config/zsh` by home-manager) and compinit itself defaults there
  (`_comp_dumpfile` in traces shows exactly that path).
- The TTL glob `(#qN.mh+24)` works as intended: "older than 24 hours" (verified:
  a 25h-old marker matches, a fresh one does not).
- The `ln`-based lock is fine now (dump pre-created), no `.lock` files left
  behind; the earlier 3s stall is gone.
- `~/.zshenv` is read before `/etc/zshrc` (verified with `env -i zsh -lc`), so
  `NOSYSZSHRC` set there takes effect. `/etc/zshrc` honors it and returns early.
- Skipping `/etc/zshrc` is safe here: home-manager re-sets history options
  (HISTSIZE/SAVEHIST/HISTFILE/setopts), `bindkey -e` is zsh's default keymap,
  `prompt suse` is replaced by starship anyway, `bashcompinit` is unused (all
  completions in use are `compdef`-based).
- `init.sh` spawns `ps | awk | sed` every shell just to detect the shell name;
  `$ZSH_VERSION`/`$BASH_VERSION` do it for free.
- Stale `~/.config/zsh/.zcompdump.mbp19i1.local.*` files (4 × ~40KB) are debris
  from the pre-`d35f2e8` naming scheme — safe to delete.
- Remaining after this plan: home-manager's compinit #2 (~0.6s; needs the
  nix-darwin/home-manager flake — `~/src/system-config` does not exist on this
  machine) and the devbox shellenv spawn (~0.5s; cacheable later the same way).

## Design

Kill duplicate compinits and the completion spawns from the repo side, with a
`NOSYSZSHRC` stopgap for the nix-darwin-generated `/etc/zshrc`:

1. `NOSYSZSHRC=1` in `~/.zshenv` (unmanaged, like its existing exports).
2. Remove `autoload -U compinit && compinit` from devbox's `zsh/.zshrc` (keep
   its `fpath+=(…)` line).
3. Move the `.zshrc` cached-compinit block to *after* the devbox eval so `fpath`
   is final and this block is the single authoritative compinit.
4. Replace the three `source <(…)` completion spawns with file-backed caches in
   `${ZDOTDIR:-$HOME}/.zsh-completions/` — generated synchronously when missing,
   refreshed in the background (`&!`) when >24h old, sourced either way. Same
   idiom as the compdump block. The kubectl sed/fzf transform is preserved; the
   sed *output* is what gets cached.

## Steps

1. `~/.zshenv`: add `export NOSYSZSHRC=1` (top of file, with a one-line comment).
2. `.local/share/devbox/global/default/zsh/.zshrc`: delete the
   `autoload -U compinit && compinit` line; keep `fpath+=(…)`.
3. `.local/share/devbox/global/default/init.sh`: replace the
   `ps | awk | sed` shell detection with `$ZSH_VERSION` / `$BASH_VERSION` checks.
4. `.zshrc`:
   a. Move the whole compinit cache block (the `() {…} ${ZDOTDIR:-$HOME}/.zcompdump`
      snippet) from the top of the file to immediately after the
      `eval "$(devbox global shellenv --init-hook)"` line.
   b. Replace the three completion `source <(…)` lines with a cached loader:
      - helper writes `${ZDOTDIR:-$HOME}/.zsh-completions/<name>.zsh`;
      - if the cache file is missing → generate synchronously (first run);
      - else if older than 24h (`(#qN.mh+24)`) → regenerate in background (`&!`);
      - source the cache file when it exists;
      - keep the existing `command -v` guards for devbox/docker/kubectl+fzf.
5. Housekeeping: delete stale `~/.config/zsh/.zcompdump.mbp19i1.local.*`.
6. `./sync.sh` (repo convention to apply; these paths are already symlinked so
   it should be a no-op for them).

## Verification

- `zsh -n .zshrc` and `zsh -n .local/share/devbox/global/default/zsh/.zshrc` —
  no syntax errors.
- `time zsh -i -c true` before/after — expect ~2.8s → ~1.0-1.4s.
- `zsh -c 'zmodload zsh/zprof; source ~/.config/zsh/.zshrc; zprof'` — the only
  `compinit` calls left are home-manager's (Phase 2 residual) and the cached
  one in `.zshrc`; `compdump` 0-1.
- Open a real terminal tab: no error output; `devbox`, `docker`, `kubectl`
  tab-completion still works (e.g. `kubectl <TAB>`).
- First shell after cache deletion regenerates completion caches synchronously;
  second shell sources them (check `~/.zsh-completions/` contents).
- `.zsh-completions/` files are >24h-old-refreshed on a later shell (spot-check
  by `touch`ing one old and opening a shell).

- Measured on mbp19i1 in a simulated fresh-terminal env (`env -i` with
  HOME/USER/LOGNAME/SHELL/TERM/TMPDIR/PATH, `zsh -ilc 'true'`): **2.80s before
  → 0.47-0.49s warm after** (1.7s on the first shell while caches generate).
  Beware: `env -i` without USER/LOGNAME breaks `/etc/profiles/per-user/` lookups
  and makes devbox fail early, producing fake-fast timings.

## Notes / trade-offs

- `NOSYSZSHRC` is a stopgap: it skips *all* of `/etc/zshrc`, not just its
  compinit. When the nix-darwin/home-manager flake is reachable again
  (`~/src/system-config`), the proper fix is `programs.zsh.enableCompletion =
  false` in both nix-darwin and home-manager plus `programs.zsh.promptInit =
  ""`, and then drop the `NOSYSZSHRC` line. That is Phase 2 (~0.6s more).
- The completion cache trades freshness for speed: a tool upgrade ships new
  completions within 24h (or on the next manual cache delete). Acceptable.
- `devbox global shellenv --init-hook` (~0.5s incl. spawn) is intentionally left
  uncached: its output depends on devbox state and the `dr`/`refresh-global`
  aliases recompute it; caching it is a separate, riskier change.
- Starship init runs twice (devbox's zshrc + home-manager) — kept as-is, it
  costs ~15ms and devbox's zshrc must keep working on machines without
  home-manager.
