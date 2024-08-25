# add devbox bits to zsh
fpath+=($DEVBOX_GLOBAL_PREFIX/share/zsh/site-functions $DEVBOX_GLOBAL_PREFIX/share/zsh/$ZSH_VERSION/functions $DEVBOX_GLOBAL_PREFIX/share/zsh/vendor-completions)
autoload -U compinit && compinit
# initialize apps
# starship
eval "$(starship init zsh)"
# zoxide: a smarter cd command
eval "$(zoxide init zsh)"
# direnv
eval "$(direnv hook zsh)"
# atuin: history list
if [[ $options[zle] = on ]]; then
  eval "$(atuin init zsh )"
fi
