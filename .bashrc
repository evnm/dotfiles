# Notify immediately on background task completion.
set -o notify

# Disable mail checking.
unset MAILCHECK

# Default permission mask.
umask 0022

# If the prompt variable is not set, then we're running in a
# non-interactive shell and should return early.
if [ -z "$PS1" ]; then
    return
fi

export PATH="/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export PAGER="less"

alias ls='ls -G --color=auto'
alias ll='ls -la'
alias less='less -r'
alias g='git'
alias e='emacsclient --no-wait'
alias tm='tmux'
alias tma='tmux attach -d -t'

# Bovine oblique strategies at login.
if command -v fortune > /dev/null 2>&1 && \
   command -v cowsay > /dev/null 2>&1 && \
   fortune oblique > /dev/null 2>&1; then
  fortune oblique | cowsay
fi

if command -v zile > /dev/null 2>&1; then
  export EDITOR="zile"
fi
if command -v emacsclient > /dev/null 2>&1; then
  export RICH_EDITOR="emacsclient --no-wait"
fi

# Source all additional bashrc files.
# Inspiration: https://write.as/bpsylevc6lliaspe
BASHRC_D=~/.config/bash
for file in ${BASHRC_D}/*.sh; do
  [[ -r $file ]] && . $file
done
unset file
