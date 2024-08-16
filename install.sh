#!/usr/bin/env bash

nix-build --version 2>/dev/null || (curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install)

#brew --version 2>/dev/null || ${SHELL} -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# https://www.jetify.com/devbox/docs/installing_devbox/
echo -n "devbox " && devbox version 2>/dev/null || curl -fsSL https://get.jetify.com/devbox | ${SHELL}

./scripts/nerdfonts.sh

if test -f /etc/lsb-release; then
  MYOS=$(cat /etc/os-release|grep ^ID= | cut -f2 -d'=')
  if [ "${MYOS}" = "pop" ]; then
    ./scripts/pop-os-tune.sh
  fi
fi

./sync.sh

# https://www.jetify.com/devbox/docs/devbox_global/
devbox global install

