SCRIPT_PATH="$HOME/.local/share/devbox/global/current"

if [ -n "$ZSH_VERSION" ]; then
  . $DEVBOX_GLOBAL_ROOT/zsh/.zshrc
elif [ -n "$BASH_VERSION" ]; then
  . $DEVBOX_GLOBAL_ROOT/bash/.bashrc
fi

# bat
# bat --plain for unformatted cat
alias catp='bat -P'
# replace cat with bat
alias cat='bat'
# zoxide
# zoxide for smart cd
alias cd='z'
# devbox helpers
alias dbr='devbox run'
alias cddevbox='cd $DEVBOX_GLOBAL_ROOT'

