#!/usr/bin/env bash

# teller env > .config/fabric/.env

# stow won't overwrite existing files
test -L ~/.zshrc || rm -f ~/.zshrc

checkdir=(~/.local/bin
  ~/.local/share/devbox/global/default
  ~/.local/share/devbox/global/default/bash
  ~/.local/share/devbox/global/default/zsh
  ~/.config/herdr
  ~/.config/kitty
  ~/.config/tig
  ~/.config/direnv
  ~/.config/wezterm)

for mydir in "${checkdir[@]}"; do
  echo ${mydir}
  test -d ${mydir} || mkdir -p ${mydir}
done

ln -s $(pwd)/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua  2>/dev/null || echo "[warn] ~/.config/wezterm/wezterm.lua already exists"

# devbox global config: platform-aware rendering.
# Intel macOS is pinned to nixpkgs 26.05 (last release with x86_64-darwin) via the
# legacy nixpkgs.commit field; package versions are stripped so the pinned channel
# decides. Linux and Apple Silicon symlink the canonical repo file unchanged.
# To pick up 26.05 fixes, bump NIXOS_2605_COMMIT to the branch's current head:
#   git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixos-26.05
NIXOS_2605_COMMIT=4feb8eb8bf30f323a8a5d285f14ee51d6a7197b1
DEVBOX_JSON=~/.local/share/devbox/global/default/devbox.json
REPO_DEVBOX_JSON=$(pwd)/.local/share/devbox/global/default/devbox.json

# devbox parses devbox.json as JSONC (// and /* */ comments are allowed and used
# for one-line package descriptions), but jq and python's json module are strict.
# Strip comments first so the render below sees plain JSON.
STRIPPED_JSON=$(mktemp "${TMPDIR:-/tmp}/devbox-json.XXXXXX")
strip_jsonc() {
  python3 - "$1" <<'PY'
import sys

src = open(sys.argv[1], encoding="utf-8").read()
out, i, n, in_string = [], 0, len(src), False
while i < n:
    ch = src[i]
    if in_string:
        out.append(ch)
        if ch == "\\" and i + 1 < n:
            out.append(src[i + 1])
            i += 2
            continue
        if ch == '"':
            in_string = False
        i += 1
        continue
    if ch == '"':
        in_string = True
        out.append(ch)
        i += 1
        continue
    if src.startswith("//", i):
        while i < n and src[i] != "\n":
            i += 1
        continue
    if src.startswith("/*", i):
        end = src.find("*/", i + 2)
        i = n if end < 0 else end + 2
        continue
    out.append(ch)
    i += 1
sys.stdout.write("".join(out))
PY
}

if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
  echo "[info] Intel macOS detected - pinning devbox global packages to nixos-26.05 ($NIXOS_2605_COMMIT)"
  if strip_jsonc "$REPO_DEVBOX_JSON" > "$STRIPPED_JSON"; then
    :
  else
    echo "[warn] could not strip comments from devbox.json - using it as-is" >&2
    cp "$REPO_DEVBOX_JSON" "$STRIPPED_JSON"
  fi
  if command -v jq >/dev/null 2>&1; then
    if jq --arg commit "$NIXOS_2605_COMMIT" \
      '.packages |= with_entries(.key |= sub("@.*$"; "")) | .nixpkgs = {commit: $commit}' \
      "$STRIPPED_JSON" > "$DEVBOX_JSON.tmp"; then
      mv "$DEVBOX_JSON.tmp" "$DEVBOX_JSON"
    else
      rm -f "$DEVBOX_JSON.tmp"
      echo "[error] devbox.json render failed - keeping existing file" >&2
    fi
  else
    if python3 - "$STRIPPED_JSON" "$DEVBOX_JSON.tmp" "$NIXOS_2605_COMMIT" <<'PY'
import json, sys
src, dst, commit = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    data = json.load(f)
pkgs = data.get("packages", {})
if isinstance(pkgs, dict):
    data["packages"] = {k.split("@", 1)[0]: v for k, v in pkgs.items()}
else:
    data["packages"] = [p.split("@", 1)[0] for p in pkgs]
data["nixpkgs"] = {"commit": commit}
with open(dst, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    then
      mv "$DEVBOX_JSON.tmp" "$DEVBOX_JSON"
    else
      rm -f "$DEVBOX_JSON.tmp"
      echo "[error] devbox.json render failed - keeping existing file" >&2
    fi
  fi
  rm -f "$STRIPPED_JSON"
else
  rm -f "$DEVBOX_JSON"
  ln -s "$REPO_DEVBOX_JSON" "$DEVBOX_JSON"
fi

# perl lang so it doesn't pop up when using es_ES.UTF-8 on first call
export LC_ALL=C
# symlinks to parent folder, '--target=dir' if want to change
stow . --verbose=1

