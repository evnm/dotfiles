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
#
# Outside a git repo, shows the working directory. Inside one, shows
# "<repo name> ⌥ <branch>" instead, matching the tmux window title
# (see ~/.tmux/scripts/window-name.sh) so long worktree paths don't
# dominate the prompt.
__ps1_location() {
  local common_dir
  if common_dir=$(git rev-parse --git-common-dir 2>/dev/null); then
    basename "$(cd "$common_dir/.." && pwd)"
  else
    printf '%s' "${PWD/#$HOME/\~}"
  fi
}
__ps1_branch() {
  local branch
  branch=$(git branch --show-current 2>/dev/null)
  [ -n "$branch" ] && printf '⌥ %s ' "$branch"
}
# Evergarden lime (https://evergarden.moe/)
PS1="\[$(tput setaf 187)\]\$(__ps1_location) \[$(tput setaf 107)\]\$(__ps1_branch)\[$(tput setaf 250)\]¢ \[$(tput sgr0)\]"
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
# Probe the socket rather than the PID, which can be reused after a
# reboot. ssh-add exits 2 when it can't reach an agent.
ssh-add -l >/dev/null 2>&1; [ $? -eq 2 ] && start_agent
