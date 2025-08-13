
# https://stackoverflow.com/questions/66338988/complete13-command-not-found-compdef 
autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS

# Devbox prompt
DEVBOX_no_prompt=TRUE

# Devbox global
eval "$(devbox global shellenv --init-hook)"

# Completions
which devbox >/dev/null && source <(devbox completion zsh)
which docker >/dev/null && source <(docker completion zsh)
#which kubectl >/dev/null && source <(kubectl completion zsh)
## https://github.com/junegunn/fzf/wiki/examples#kubectl
command -v fzf >/dev/null 2>&1 && {
	source <(kubectl completion zsh | sed 's#${requestComp} 2>/dev/null#${requestComp} 2>/dev/null | head -n -1 | fzf  --multi=0 #g')
}

# Aliases
alias glo='git log --decorate --oneline --graph'
alias ls='ls --color=auto -F'
alias l='ls -lah'
alias ll='ls -lh'
alias lg='lazygit'
alias cat='bat --paging never --theme DarkNeon --style plain'
alias zssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
alias dr='eval "$(devbox global shellenv --recompute)";refresh-global'
alias k='kubectl'

# ENV files

# User configuration (Done here to allow for overriding oh-my-zsh configuration)

if [ -e $HOME/.zshrc-env-config ]; then
   source $HOME/.zshrc-env-config
fi

# PATH
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"


# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
# End of LM Studio CLI section

