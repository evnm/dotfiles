#!/usr/bin/env bash
#
# Records which Claude Code session is running in which tmux pane, so
# ~/.tmux/scripts/claude-resurrect.sh can resume it after a reboot.
#
# Usage (from Claude Code hooks, which pass the hook JSON on stdin):
#   tmux-pane-session.sh start   # SessionStart: tag the pane
#   tmux-pane-session.sh end     # SessionEnd: untag the pane
#
# The session ID and cwd are stored as pane-scoped tmux options
# (@claude_session_id, @claude_session_cwd), so they follow the pane
# around and vanish with it.

[ -n "$TMUX_PANE" ] || exit 0
command -v jq >/dev/null || exit 0

input=$(cat)
pane_pid=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}' 2>/dev/null) || exit 0

# Only track the Claude that the pane's shell started directly. A nested
# `claude -p` run inside a session inherits $TMUX_PANE and would otherwise
# overwrite the pane's real session ID. Find the nearest `claude` ancestor
# of this hook and require that its parent is the pane's shell.
p=$PPID
while [ -n "$p" ] && [ "$p" -gt 1 ]; do
  if [ "$(basename "$(ps -o comm= -p "$p")")" = claude ]; then
    [ "$(ps -o ppid= -p "$p" | tr -d ' ')" = "$pane_pid" ] || exit 0
    break
  fi
  p=$(ps -o ppid= -p "$p" | tr -d ' ')
done
[ -n "$p" ] && [ "$p" -gt 1 ] || exit 0

case "$1" in
  start)
    id=$(jq -r '.session_id // empty' <<<"$input")
    cwd=$(jq -r '.cwd // empty' <<<"$input")
    [ -n "$id" ] || exit 0
    tmux set-option -p -t "$TMUX_PANE" @claude_session_id "$id"
    tmux set-option -p -t "$TMUX_PANE" @claude_session_cwd "$cwd"
    ;;
  end)
    # /clear fires SessionEnd then SessionStart, so only clear the tag if
    # it still points at the session that is ending.
    id=$(jq -r '.session_id // empty' <<<"$input")
    current=$(tmux show-options -pqv -t "$TMUX_PANE" @claude_session_id)
    if [ -z "$id" ] || [ "$id" = "$current" ]; then
      tmux set-option -pu -t "$TMUX_PANE" @claude_session_id
      tmux set-option -pu -t "$TMUX_PANE" @claude_session_cwd
    fi
    ;;
esac
