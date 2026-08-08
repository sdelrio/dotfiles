
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

# Git Aliases

## Historic view from a file, with commit, date, user, message and diff lines
ghist() {
  local count="${2:-5}"
  git log "-$count" --format="%h %ad %an | %s" -p --diff-filter=M --follow -- "$1" | grep -E "^([a-f0-9]+ |^[+-][^+-])" | while IFS= read -r line; do
    case "$line" in
      [a-f0-9]*)
        hash="${line%% *}"
        rest="${line#* }"
        msg="${rest##* | }"
        rest="${rest% | *}"
        user="${rest##* }"
        date="${rest% $user}"
        echo -e "\033[33m$hash\033[0m \033[90m$date\033[0m \033[36m$user\033[0m | \033[37m$msg\033[0m"
        ;;
      +*)
        echo -e "\033[32m$line\033[0m"
        ;;
      -*)
        echo -e "\033[31m$line\033[0m"
        ;;
      *)
        echo "$line"
        ;;
    esac
  done
}

alias glo='git log --decorate --oneline --graph'
alias lg='lazygit'
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'

# Kubernetes Aliases
alias k='kubectl'
alias ka="kubectl apply -f"
alias kg="kubectl get"
alias kd="kubectl describe"
alias kdel="kubectl delete"
alias kl="kubectl logs"
alias kgpo="kubectl get pod"
alias kgd="kubectl get deployments"
alias kc="kubectx"
alias kns="kubens"
alias kl="kubectl logs -f"
alias ke="kubectl exec -it"
alias kcns='kubectl config set-context --current --namespace'

# Aliases
alias ls='ls --color=auto -F'
alias l='ls -lah'
alias ll='ls -lh'
alias cat='bat --paging never --theme DarkNeon --style plain'
alias zssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
alias dr='eval "$(devbox global shellenv --recompute)";refresh-global'

# ENV files

# User configuration (Done here to allow for overriding oh-my-zsh configuration)

if [ -e $HOME/.zshrc-env-config ]; then
   source $HOME/.zshrc-env-config
fi

# PATH
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# To be able to install NPM packages globally with nix
# $ cat  ~/.npmrc
# prefix=~/.npm-packages
export PATH="$HOME/.npm-packages/bin:$PATH"
export NODE_PATH="$HOME/.npm-packagges/lib/node_modules"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
# End of LM Studio CLI section

