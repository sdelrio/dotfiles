#!/usr/bin/env bash

# teller env > .config/fabric/.env

# stow won't overwrite existing files
test -L ~/.zshrc || rm -f ~/.zshrc

checkdir=(~/.local/bin
  ~/.local/share/devbox/global/default
  ~/.local/share/devbox/global/default/bash
  ~/.local/share/devbox/global/default/zsh
  ~/.config/kitty
  ~/.config/tig
  ~/.config/direnv)

for mydir in "${checkdir[@]}"; do
  echo ${mydir}
  test -d ${mydir} || mkdir -p ${mydir}
done

# perl lang so it doesn't pop up when using es_ES.UTF-8 on first call
export LC_ALL=C
# symlinks to parent folder, '--target=dir' if want to change
stow .

