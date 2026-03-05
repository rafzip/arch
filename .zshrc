if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  sudo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
# aliases
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons'
  alias ll='eza -lah --group-directories-first --icons'
  alias la='eza -a --group-directories-first --icons'
  alias lt='eza -T --level=2 --group-directories-first --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
  alias la='ls -A --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat --paging=always'
fi

alias rg='rg --smart-case'
alias grep='grep --color=auto'

alias g='git'
alias ga='git add'
alias gaa='git add -A'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gc='git commit'
alias gcm='git commit -m'
alias gst='git status'
alias gl='git pull'
alias gp='git push'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --graph --decorate --all'

alias pac='sudo pacman'
alias pacs='pacman -Ss'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacc='sudo pacman -Sc'

if command -v yay >/dev/null 2>&1; then
  alias yays='yay -Ss'
  alias yayi='yay -S'
  alias yayu='yay -Syu'
fi

alias sctl='systemctl'
alias usctl='systemctl --user'
alias jctl='journalctl -xe'
alias jctlf='journalctl -f'

alias ipi='ip -c a'
alias ports='ss -tulpn'
alias myip='curl -s https://ifconfig.me && echo'
alias nas='ping -c 4 10.0.0.10'

alias v='nvim'
alias t='tmux'
alias weather='curl -s "wttr.in?0"'
alias c='clear'
alias zshre='exec zsh'



[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
