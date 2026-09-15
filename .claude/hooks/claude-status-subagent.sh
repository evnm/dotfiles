#!/bin/bash
# Tracks a per-pane count of in-flight subagents (including ones launched to
# run in the background) so the Stop hook can tell "fully done" apart from
# "main loop stopped but background agents are still working". SubagentStart
# and SubagentStop bracket each subagent's own lifecycle independently of
# when the main loop's Stop event fires, which is what lets this work for
# background/async agent launches.
set -uo pipefail

mode="${1:?usage: claude-status-subagent.sh start|stop|reset}"
pane="${TMUX_PANE:-}"
[ -n "$pane" ] || exit 0

safe_pane=$(printf '%s' "$pane" | tr -c 'a-zA-Z0-9_-' '_')
count_file="/tmp/claude-bg-count-${safe_pane}"
lock_dir="${count_file}.lock"

for _ in $(seq 1 50); do
  mkdir "$lock_dir" 2>/dev/null && break
  sleep 0.02
done

count=$(cat "$count_file" 2>/dev/null || echo 0)
case "$mode" in
  start) count=$((count + 1)) ;;
  stop)  count=$((count > 0 ? count - 1 : 0)) ;;
  reset) count=0 ;;
esac
printf '%s' "$count" >"$count_file"

rmdir "$lock_dir" 2>/dev/null

case "$mode" in
  start)
    tmux set-option -w -t "$pane" @claude_status '…'
    ;;
  stop)
    if [ "$count" -le 0 ]; then
      tmux set-option -w -t "$pane" @claude_status '✓'
    fi
    ;;
esac
