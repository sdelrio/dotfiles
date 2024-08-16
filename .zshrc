
# https://stackoverflow.com/questions/66338988/complete13-command-not-found-compdef 
autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS

# Devbox prompt
DEVBOX_no_prompt=TRUE

# Devbox global
#eval "$(devbox global shellenv --init-hook)"

# Completions
which devbox >/dev/null && source <(devbox completion zsh)
which docker >/dev/null && source <(docker completion zsh)
which kubectl >/dev/null && source <(kubectl completion zsh)

# Starship
eval "$(starship init zsh)"

# Zoxide: a smarter cd command
eval "$(zoxide init --cmd cd zsh)"

# Aliases
alias glo='git log --decorate --oneline --graph'
alias ls='ls --color=auto -F'
alias l='ls -lah'
alias ll='ls -lh'
alias cat='bat --paging never --theme DarkNeon --style plain'
alias zssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'


# PATH
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

