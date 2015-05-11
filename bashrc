#-------------------------------------------------------------------------------
# Shell Options
#-------------------------------------------------------------------------------

# Notify bg task completion immediately
set -o notify

# Prevent mail notifications
unset MAILCHECK

# Default umask
umask 0022

#-------------------------------------------------------------------------------
# Path
#-------------------------------------------------------------------------------

export PATH="/usr/local/bin:$HOME/bin:$PATH"
export MANPATH="/usr/local/man:$MANPATH"

#-------------------------------------------------------------------------------
# Aliases
#-------------------------------------------------------------------------------

alias ls='ls -G'
alias ll='ls -la'

# Emacs
if [[ `uname` == "Darwin" ]]; then
    alias emacsclient='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient'
fi
alias emacs='emacsclient --no-wait'
alias e='emacs'

# Git
alias g='git'

# Autocomplete for 'g' as well
complete -o default -o nospace -F _git g

# Vagrant
alias vag='vagrant'

#-------------------------------------------------------------------------------
# Prompt
#-------------------------------------------------------------------------------

# user@hostcwd[ (git branch)]$
function prompt_color() {
    # NOTE: Used to prepend with "\u@\h".
    PS1="\[$(tput setaf 7)\]\W\[$(tput setaf 1)\]\$(git branch 2>/dev/null|cut -f2 -d\* -s)\[$(tput setaf 7)\] ¢ \[$(tput sgr0)\]"
}

# Glue the prompt to the first column.
# Source: http://jonisalonen.com/2012/your-bash-prompt-needs-this/
PS1="\[\033[G\]$PS1"

#-------------------------------------------------------------------------------
# Shell environment
#-------------------------------------------------------------------------------

# Homebrew
if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi

# EC2 stuff.
export EC2_HOME="$HOME/.ec2"
export PATH="$PATH:$EC2_HOME/bin"

# Set java home
if [[ `uname` == "Darwin" ]]; then
  export JAVA_HOME=`/usr/libexec/java_home`
elif [[ `uname` == "Linux" ]]; then
  export JAVA_HOME="/usr/lib/jvm/java-6-sun/"
fi

# RVM
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# Scala stuff
SCALA_HOME=~/.scala
PATH=$SCALA_HOME/bin:$PATH

# Set default prompt if interactive
test -n "$PS1" && prompt_color

# Colorful bovine wisdom at login.
fortune -s | lolcat

export EDITOR=`which zile`

# Increase max open fd limit.
ulimit -n 2048

# autojump
[[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

#-------------------------------------------------------------------------------
# SSH
#-------------------------------------------------------------------------------

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
