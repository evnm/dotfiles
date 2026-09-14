#!/bin/bash
# Sets the tmux @claude_status pane var to '?' only for Notification events
# that mean Claude is genuinely blocked on user input — not the full set of
# Notification types (which also includes agent_completed, auth_success,
# quota_*, elicitation_*, etc).
set -uo pipefail

input=$(cat)
notification_type=$(jq -r '.notification_type // empty' <<<"$input" 2>/dev/null)

case "$notification_type" in
  idle_prompt|permission_prompt|agent_needs_input)
    tmux set-option -w -t "$TMUX_PANE" @claude_status '?'
    ;;
esac
