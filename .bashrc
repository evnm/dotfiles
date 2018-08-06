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
  alias emacs='emacsclient --no-wait'
fi

alias e='emacs'
alias vag='vagrant'
alias g='git'

# Autocomplete for 'g' as well
complete -o default -o nospace -F _git g

# Colorized Maven
alias mvn="rainbow --config=/Users/evanm/workspace/rainbow/configs/mvn3.cfg -- \
time mvn -Dmaven.javadoc.skip=true \
-Dmaven.compile.fork=true \
-Dmaven.junit.fork=true \
-Dmaven.junit.jvmargs=-Xmx4096m \
-T 1C"

# tmux
alias tm='tmux'
alias tma='tmux attach -d -t'

function tmnp () {
  WORKDIR=$(cd "$1"; pwd)
  tmux new -s $(basename "$WORKDIR") -c "$WORKDIR"
}

#-------------------------------------------------------------------------------
# Prompt
#-------------------------------------------------------------------------------

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
  PS1="\[$(tput setaf 172)\]\$(git_branch)\[$(tput setaf 94)\]\W \[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"

  # Glue the prompt to the first column.
  # NOTE: This is disabled, as it screws with virtualenv prompt injection.
  # Source: http://jonisalonen.com/2012/your-bash-prompt-needs-this/
  #PS1="\[\033[G\]$PS1"
}

#-------------------------------------------------------------------------------
# Shell environment
#-------------------------------------------------------------------------------

# Homebrew
if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi

# EC2
export EC2_HOME="$HOME/.ec2"
export PATH="$PATH:$EC2_HOME/bin"

# Java
if [[ `uname` == "Darwin" ]]; then
  export JAVA_HOME=`/usr/libexec/java_home`
elif [[ `uname` == "Linux" ]]; then
  export JAVA_HOME="/usr/lib/jvm/java-6-sun/"
fi

export MAVEN_OPTS="-Xms4096m -Xmx4096m -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# Ruby
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# Python
export PATH=/Users/evanm/.python/CPython-2.7.10/bin:$PATH

# Set default prompt if interactive
test -n "$PS1" && prompt_color

# Colorful bovine wisdom at login.
fortune -s | cowsay

export EDITOR=`which zile`
export RICH_EDITOR="/Applications/Emacs.app/Contents/MacOS/bin/emacsclient --no-wait"

# Increase max open fd limit.
ulimit -n 2048

. /usr/local/etc/profile.d/z.sh

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# Ansible
export ANSIBLE_NOCOWS=1
alias ap='ansible-playbook'

# Dropbox
export DROPBOX_PATH=~/Dropbox

# AWS
complete -C '/usr/local/bin/aws_completer' aws

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
