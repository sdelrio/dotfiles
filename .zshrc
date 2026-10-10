setopt HIST_IGNORE_ALL_DUPS

# Devbox prompt
DEVBOX_no_prompt=TRUE

# Devbox global already in 
#eval "$(devbox global shellen --init-hook)"

# Fix for slow startup cache when opening multiple tabs/terminals, based on:
# https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=5224370#gistcomment-5224370
# Runs AFTER the devbox eval so $fpath is final: this is the shell's single
# compinit (NOSYSZSHRC skips /etc/zshrc's, devbox's zshrc no longer runs one).
() {
  emulate -L zsh
  setopt extendedglob
  autoload -Uz compinit complist
  local zcd=$1                # compdump
  local zcdc=$1.zwc           # compiled compdump
  local zcda=$1.last          # last compilation
  local zcdl=$1.lock          # lock file
  local attempts=30
  [[ -e $zcd ]] || : > $zcd
  while (( attempts-- > 0 )) && ! ln $zcd $zcdl 2> /dev/null; do sleep 0.1; done
  {
    if [[ ! -e $zcda || ! -s $zcd || -n $zcda(#qN.mh+24) ]]; then
      compinit -i -d $zcd
      : > $zcda
    else
      compinit -C -d $zcd
    fi
    [[ ! -f $zcdc || $zcd -nt $zcdc ]] && rm -f $zcdc && zcompile $zcd &!
  } always {
    rm -f $zcdl
  }
} ${ZDOTDIR:-$HOME}/.zcompdump

# Completions: generated once to disk and sourced from cache afterwards.
# Each generator is an external binary (~0.1-0.3s); spawning them on every
# shell was the second biggest startup cost. A cache older than 24h is
# regenerated in the background and picked up by the next shell.
_cached_completion() {
  emulate -L zsh
  setopt extendedglob
  local name=$1; shift
  local dir=${ZDOTDIR:-$HOME}/.zsh-completions
  local cache=$dir/$name.zsh
  [[ -d $dir ]] || mkdir -p $dir
  if [[ ! -s $cache ]]; then
    "$@" >| $cache 2>/dev/null
  elif [[ -n $cache(#qN.mh+24) ]]; then
    ( "$@" >| $cache 2>/dev/null ) &!
  fi
  [[ -s $cache ]] && source $cache
}
command -v devbox >/dev/null 2>&1 && _cached_completion devbox devbox completion zsh
command -v docker >/dev/null 2>&1 && _cached_completion docker docker completion zsh
_kubectl_completion() {
  kubectl completion zsh | sed 's#${requestComp} 2>/dev/null#${requestComp} 2>/dev/null | head -n -1 | fzf  --multi=0 #g'
}
command -v kubectl >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && _cached_completion kubectl _kubectl_completion
unfunction _kubectl_completion _cached_completion 2>/dev/null

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
#export PATH="$HOME/.npm-packages/bin:$PATH"
#export NODE_PATH="$HOME/.npm-packagges/lib/node_modules"
# NOTE: PATH/NODE_PATH for npm-packages now live in ~/.zshenv so that
# non-interactive shells (Claude Code hooks via /bin/sh) inherits them too.

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
# End of LM Studio CLI section

