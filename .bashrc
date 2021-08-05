# Shell Options

# Silence Bash deprecation warning in macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Notify bg task completion immediately
set -o notify

# Prevent mail notifications
unset MAILCHECK

# Default umask
umask 0022

# If the prompt variable is not set, then we're running in a
# non-interactive shell and should return early.
if [ -z "$PS1" ]; then
    return
fi

# Path

export PATH="/usr/local/bin:$HOME/bin:$PATH"
export MANPATH="/usr/local/man:$MANPATH"

# Aliases

alias ls='ls -G --color=auto'
alias ll='ls -la'
alias less='less -r'
export PAGER="less"
alias g='git'
alias e='emacsclient --no-wait'

# Emacs
if [[ `uname` == "Darwin" ]]; then
  alias emacsclient='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient'
fi

# Completion

# Autocomplete for 'g' as well
complete -o default -o nospace -F _git g

if [[ `uname` == "Darwin" ]]; then
  if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
  fi
fi

if [[ `uname` == "Linux" ]]; then
  source /usr/share/bash-completion/completions/git
fi

# tmux

alias tm='tmux'
alias tma='tmux attach -d -t'

function tmnp () {
  WORKDIR=$(cd "$1"; pwd)
  tmux new -s $(basename "$WORKDIR") -c "$WORKDIR"
}

# Prompt

# If in a Git repository, then print the current branchname
# appended with a space. Otherwise, print nothing.
function git_branch() {
  GIT_BRANCH=$(git branch 2>/dev/null|cut -f2 -d\* -s|tr -d ' ')
  if [[ -n "$GIT_BRANCH" ]]; then
    GIT_BRANCH+=" "
  fi
  echo -n "$GIT_BRANCH"
}

# [git_branch_name ]cwd ¢
function prompt_color() {
  # Purple
  PS1="\[$(tput setaf 183)\]\$(git_branch)\W \[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"
  # Orange
  #PS1="\[$(tput setaf 172)\]\$(git_branch)\[$(tput setaf 94)\]\W \[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"

  # Glue the prompt to the first column.
  # NOTE: This is disabled, as it screws with virtualenv prompt injection.
  # Source: http://jonisalonen.com/2012/your-bash-prompt-needs-this/
  PS1="\[\033[G\]$PS1"
}

# Shell environment

# Set default prompt if interactive
test -n "$PS1" && prompt_color

# Colorful bovine wisdom at login.
fortune -s | cowsay

export EDITOR="zile"
export RICH_EDITOR="emacsclient --no-wait"

# Increase max open fd limit.
ulimit -n 2048

complete -C '/usr/local/bin/aws_completer' aws

# SSH

if [[ `uname` == "Darwin" ]]; then
  SSH_ENV="$HOME/.ssh/environment"

  function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
  }

  # Source SSH settings, if applicable
  if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
      start_agent;
    }
  else
    start_agent;
  fi
fi

# Source all additional bashrc files.
# Inspiration: https://write.as/bpsylevc6lliaspe
BASHRC_D=~/.config/bash
for file in ${BASHRC_D}/*.sh; do
  [[ -r $file ]] && . $file
done
unset file
