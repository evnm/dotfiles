#!/usr/bin/env bash
#
# Saves and restores Claude Code sessions alongside tmux-resurrect.
#
#   claude-resurrect.sh save     # @resurrect-hook-post-save-all
#   claude-resurrect.sh restore  # @resurrect-hook-post-restore-all
#
# `save` snapshots every pane tagged by ~/.claude/hooks/tmux-pane-session.sh
# into a file next to resurrect's own save. `restore` runs
# `claude --resume <id>` in each of those panes once resurrect has rebuilt
# the layout. Panes are matched by session name, window index and pane
# index, which resurrect restores exactly.

resurrect_dir() {
  local dir
  dir=$(tmux show-option -gqv @resurrect-dir)
  if [ -z "$dir" ]; then
    # Same default as tmux-resurrect.
    if [ -d "$HOME/.tmux/resurrect" ]; then
      dir="$HOME/.tmux/resurrect"
    else
      dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
    fi
  fi
  dir=${dir/#\~/$HOME}
  echo "${dir//\$HOME/$HOME}"
}

file="$(resurrect_dir)/claude-sessions.tsv"
shells=" bash zsh sh fish dash -bash -zsh "

case "$1" in
  save)
    mkdir -p "$(dirname "$file")"
    tmux list-panes -a -F \
      '#{session_name}:#{window_index}.#{pane_index}	#{pane_current_command}	#{@claude_session_id}	#{@claude_session_cwd}' |
    while IFS=$'\t' read -r target cmd id cwd; do
      [ -n "$id" ] || continue
      # Skip panes where Claude has exited without firing SessionEnd
      # (e.g. it was killed) and the pane is back at a shell prompt.
      case "$shells" in *" $cmd "*) continue ;; esac
      printf '%s\t%s\t%s\n' "$target" "$id" "$cwd"
    done >"$file.tmp" && mv "$file.tmp" "$file"
    ;;
  restore)
    [ -f "$file" ] || exit 0
    while IFS=$'\t' read -r target id cwd; do
      cmd=$(tmux display-message -p -t "$target" '#{pane_current_command}' 2>/dev/null) || continue
      # Only type into panes sitting at a shell prompt.
      case "$shells" in *" $cmd "*) ;; *) continue ;; esac
      line="claude --resume $id"
      [ -n "$cwd" ] && line="cd $(printf '%q' "$cwd") && $line"
      tmux send-keys -t "$target" "$line" Enter
    done <"$file"
    ;;
  *)
    echo "usage: $0 save|restore" >&2
    exit 1
    ;;
esac
