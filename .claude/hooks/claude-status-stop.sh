#!/bin/bash
# Runs on the Stop event. Shows the ellipsis glyph instead of the checkmark
# if the per-pane subagent counter (see claude-status-subagent.sh) is still
# above zero, i.e. one or more background subagents haven't reported back.
set -uo pipefail

pane="${TMUX_PANE:-}"
[ -n "$pane" ] || exit 0

safe_pane=$(printf '%s' "$pane" | tr -c 'a-zA-Z0-9_-' '_')
count_file="/tmp/claude-bg-count-${safe_pane}"
count=$(cat "$count_file" 2>/dev/null || echo 0)

if [ "$count" -gt 0 ]; then
  tmux set-option -w -t "$pane" @claude_status '…'
else
  tmux set-option -w -t "$pane" @claude_status '✓'
fi
