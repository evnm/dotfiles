#!/bin/bash
# Sets the tmux @claude_status pane var to '?' only for Notification events
# where Claude is stuck on an actual question/decision — not merely idle.
# idle_prompt (no activity for a while) is deliberately excluded: a finished
# session should keep showing the Stop hook's checkmark until the next
# prompt, not flip to '?' just because the user hasn't responded yet.
set -uo pipefail

input=$(cat)
notification_type=$(jq -r '.notification_type // empty' <<<"$input" 2>/dev/null)

case "$notification_type" in
  permission_prompt|elicitation_dialog|elicitation_url_dialog)
    tmux set-option -w -t "$TMUX_PANE" @claude_status '?'
    ;;
esac
