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
rm -f "$DEVBOX_JSON"
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
  echo "[info] Intel macOS detected - pinning devbox global packages to nixos-26.05 ($NIXOS_2605_COMMIT)"
  if command -v jq >/dev/null 2>&1; then
    jq --arg commit "$NIXOS_2605_COMMIT" \
      '.packages |= map(sub("@.*$"; "")) | .nixpkgs = {commit: $commit}' \
      "$REPO_DEVBOX_JSON" > "$DEVBOX_JSON"
  else
    python3 - "$REPO_DEVBOX_JSON" "$DEVBOX_JSON" "$NIXOS_2605_COMMIT" <<'PY'
import json, sys
src, dst, commit = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    data = json.load(f)
data["packages"] = [p.split("@", 1)[0] for p in data.get("packages", [])]
data["nixpkgs"] = {"commit": commit}
with open(dst, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
  fi
else
  ln -s "$REPO_DEVBOX_JSON" "$DEVBOX_JSON"
fi

# perl lang so it doesn't pop up when using es_ES.UTF-8 on first call
export LC_ALL=C
# symlinks to parent folder, '--target=dir' if want to change
stow . --verbose=1

