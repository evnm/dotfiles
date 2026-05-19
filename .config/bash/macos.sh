# macOS-specific bash configuration.

# Silence Bash deprecation warning in macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

eval "$($(brew --prefix)/bin/brew shellenv)"

export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

alias emacsclient="$(brew --prefix)/bin/emacsclient"

# Bash completion
if [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
  . "$(brew --prefix)/etc/profile.d/bash_completion.sh"
fi

if [ -r "$(brew --prefix)/etc/bash_completion.d/git-completion.bash" ]; then
  . "$(brew --prefix)/etc/bash_completion.d/git-completion.bash"
  # Complete git commands for the alias `g`.
  __git_complete g git
fi

# Terminal prompt setup.
. "$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
# Purple
#PS1="\[$(tput setaf 183)\]\w \$(__git_ps1 '%s ')\[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"
# Orange
PS1="\[$(tput setaf 94)\]\w \[$(tput setaf 172)\]\$(__git_ps1 '%s ')\[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"

# Glue the prompt to the first column.
# NOTE: This is disabled, as it screws with virtualenv prompt injection.
# Source: http://jonisalonen.com/2012/your-bash-prompt-needs-this/
PS1="\[\033[G\]$PS1"

# Ensure ssh-agent is run at most once per boot.
SSH_ENV="$HOME/.ssh/environment"

start_agent() {
  /usr/bin/ssh-agent | sed '/^echo/d' > "${SSH_ENV}"
  chmod 600 "${SSH_ENV}"
  . "${SSH_ENV}" > /dev/null
  /usr/bin/ssh-add
}

[ -f "${SSH_ENV}" ] && . "${SSH_ENV}" > /dev/null
kill -0 "${SSH_AGENT_PID}" 2>/dev/null || start_agent
