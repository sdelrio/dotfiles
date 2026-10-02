---
title: Platform-aware global devbox config (pin Intel macOS to nixpkgs 26.05)
date: 2026-10-02
---

# Plan: Platform-aware global devbox config (pin Intel macOS to nixpkgs 26.05)

## Context

This repo controls dotfiles on 3 machines: 1 Linux, 1 Intel macOS, 1 Apple
Silicon macOS. Managed with GNU Stow (symlinks into `$HOME` via `sync.sh`) and
Nix/Devbox (global CLI packages).

Problem: nixpkgs **26.11 dropped `x86_64-darwin` support**; **26.05 is the last
release with Intel macOS binaries** (maintained until end of 2026, then frozen
forever). Devbox's `@latest`/pinned-version resolution maps to the newest
nixpkgs commits, so Renovate version bumps (e.g. `atuin@18.18.1`) break the
Intel Mac — a manual rollback commit already happened once
(`b291f7a fix(devbox): rollback versions to 26.05 - intel osx support`).

Goal: Intel Mac pinned to nixpkgs 26.05 and never updated; Linux + Apple
Silicon machines keep latest versions.

## Findings (already researched — do not re-research)

- devbox global is a **single profile** at
  `~/.local/share/devbox/global/default/devbox.json` — no named profiles, no
  conditionals in devbox.json. Per-machine divergence must be handled at the
  repo/sync layer.
- The old `nixpkgs.commit` devbox.json field is **deprecated**. Documented
  pinning: per-package flake refs like `"github:nixos/nixpkgs/nixos-26.05#bat"`
  (branch or commit hash).
- `include:` in devbox.json only works for plugins, not for composing
  devbox.json files.
- The global devbox.json is currently **symlinked from the repo** into
  `~/.local/share/devbox/global/default/devbox.json` by stow.
- `/.local` is listed in `.stow-local-ignore` yet stow DOES link into
  `~/.local/...` — the ignore pattern is not matching as expected. Verify with
  `stow --verbose=2 --simulate` before relying on it.
- Renovate (`renovate.json`) manages the repo's global devbox.json; package
  bumps are the source of Intel breakage.

## Design (chosen: Option A — sync.sh renders per platform)

- The repo's `.local/share/devbox/global/default/devbox.json` stays the single
  canonical file (Renovate manages it as today).
- `sync.sh` takes ownership of that file (same pattern as the existing manual
  wezterm `ln -s`): it removes whatever is at
  `~/.local/share/devbox/global/default/devbox.json` and writes the right thing:
  - **Darwin + arm64** or **Linux** → symlink the repo file (behavior identical
    to today).
  - **Darwin + x86_64 (Intel)** → generate the file, rewriting every package
    entry `"name@version"` or `"name@latest"` →
    `"github:nixos/nixpkgs/nixos-26.05#name"`. Versions come from the frozen
    26.05 channel; `env`, `shell`, scripts pass through unchanged. Also drop
    the deprecated `"nixpkgs": {}` key from the generated output.
- Render tool: `jq` (already in the global profile), fallback to `python3`
  (stdlib `json`) so sync never depends on a broken env.

Rejected alternatives: host-based stow tree (too much restructure for one
need); lockfile freeze on Intel (fragile — Renovate bumps re-resolve and break).

## Steps

1. **`sync.sh`** — add platform detection and render/replace block:
   - `OS=$(uname -s); ARCH=$(uname -m)`
   - `rm -f ~/.local/share/devbox/global/default/devbox.json`
   - Intel (`Darwin` + `x86_64`): generate via
     `jq '.packages |= map(capture("^(?<p>[^@]+)") | "github:nixos/nixpkgs/nixos-26.05#\(.p)") | del(.nixpkgs)' <repo_file> > ~/.local/share/devbox/global/default/devbox.json`
     (python3 fallback equivalent if jq missing).
   - Others: `ln -s` repo file → target (as today).
2. **`.stow-local-ignore`** — make sure the global devbox.json path is never
   stowed directly (sync.sh owns it). Verify actual stow ignore behavior with
   `stow --verbose=2 --simulate .` and add an explicit pattern if needed.
3. **Stale artifact** — remove `~/.local/share/devbox/global/default/devbox.json_bak`
   (leftover backup; confirm with user if unsure).
4. **Docs** — update `AGENTS.md` / `README.md`: edit the repo file, run
   `./sync.sh`, then `devbox global install`; note the Intel/26.05 rule and
   current focus. Keep AGENTS.md under ~50 lines.
5. **Roll out** — Intel Mac first: `git pull && ./sync.sh && devbox global
   install`; confirm the generated lock records `github:nixos/nixpkgs/nixos-26.05`
   inputs. Then the Apple Silicon and Linux machines (no behavior change; same
   symlink, same file).
6. **Commit** (Conventional Commits):
   `feat(sync): render global devbox.json per platform, pin intel to nixos-26.05`

## Verification

- On Intel Mac: after `./sync.sh`, the target is a regular (generated) file,
  not a symlink; `devbox global install` resolves cleanly from 26.05; spot-check
  `bat`, `fzf`, `eza` versions.
- Simulate non-Intel branch locally (force the condition) → target is a symlink
  identical to today.
- `git status` shows no plans/ or generated files as tracked changes.

## Notes / trade-offs

- Version pins in the canonical file (e.g. `bat@0.26.1`) are **ignored on
  Intel** — the 26.05 channel decides. Expected: Intel may get slightly older
  versions than the pin. That IS the desired "fix and never update" behavior.
- Branch pin (`nixos-26.05`) receives fixes until end of 2026, then freezes.
  For an absolute freeze later, swap the branch ref for the branch's final
  commit hash — one-line change.
- Project-local `devbox.json` (wget/teller/stow) left as-is; if it ever breaks
  on Intel, the same rewrite technique applies (out of scope).
