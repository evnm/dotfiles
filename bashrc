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

export PATH=/usr/local/bin:/Users/evan/bin:$PATH
export MANPATH=/usr/local/man:$MANPATH

#-------------------------------------------------------------------------------
# Aliases
#-------------------------------------------------------------------------------

alias ls='ls -G'
alias ll='ls -la'
alias attu='ssh meagher@attu.cs.washington.edu'

# Emacs
alias emacs='emacsclient --no-wait'
alias e='emacs'

# Git
alias git='hub'
alias g='git'

# t (Python todo list program)
alias t='python ~/.t/t.py --task-dir ~/Dropbox/tasks --list tasks'
alias tw='python ~/.t/t.py --task-dir ~/Dropbox/tasks --list work'

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
    PS1="\[$(tput setaf 7)\]\W\[$(tput setaf 1)\]\$(git branch 2>/dev/null|cut -f2 -d\* -s)\[$(tput setaf 7)\] $ \[$(tput sgr0)\]"
}

# Glue the prompt to the first column.
# Source: http://jonisalonen.com/2012/your-bash-prompt-needs-this/
PS1="\[\033[G\]$PS1"

#-------------------------------------------------------------------------------
# Shell environment
#-------------------------------------------------------------------------------

# Homebrew
[[ -f `brew --prefix`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion

# EC2 stuff.
export EC2_HOME="$HOME/.ec2"
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=$EC2_HOME/pk-4MUJK6KEEQRYEM6JOBBE7K366LEJSROD.pem
export EC2_CERT=$EC2_HOME/cert-4MUJK6KEEQRYEM6JOBBE7K366LEJSROD.pem

# Set java home
if [[ `uname` == "Darwin" ]]; then
JAVA_HOME=`/usr/libexec/java_home`
elif [[ `uname` == "Linux" ]]; then
JAVA_HOME="/usr/lib/jvm/java-6-sun/"
fi
export JAVA_HOME

# RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# Node.js stuff
[[ -s "$HOME/.node_libraries/.npm/npm/active/package/npm-completion.sh" ]] &&
. "$HOME/.node_libraries/.npm/npm/active/package/npm-completion.sh"
[[ -s "$HOME/.nvm/nvm.sh" ]] && . "$HOME/.nvm/nvm.sh"

# Scala stuff
SCALA_HOME=~/.scala
PATH=$SCALA_HOME/bin:$PATH

# Set default prompt if interactive
test -n "$PS1" && prompt_color

# Colorful wisdom at login
fortune -s | cowsay | lolcat
