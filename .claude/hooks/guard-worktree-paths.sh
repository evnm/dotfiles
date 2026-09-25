#!/usr/bin/env bash
# Blocks Read/Edit/Write/Bash calls that reference an absolute path rooted
# at a repo's *main* checkout when the current Claude Code session is
# actually operating inside a different linked git worktree.
#
# Why this exists: a git worktree (e.g. .claude/worktrees/<branch>/) is a
# full, separate checkout of the same tracked tree as the main repo. A path
# like /Users/x/co/main/go/foo.go resolves and reads/writes successfully
# even when the active session's real root is
# .../main/.claude/worktrees/<branch>/ — there is no error, just silent
# access to the wrong repo's copy of the file. This has repeatedly caused
# Claude Code sessions to read another worktree's in-progress state, or
# worse, write changes there instead of the intended branch. Passive
# instructions (CLAUDE.md, memory) were not sufficient to prevent this, so
# it is enforced mechanically here instead.
#
# Approach: use `git rev-parse --show-toplevel` to find the *actual*
# worktree root for this session (git resolves this correctly regardless of
# which worktree cwd is inside), and `git rev-parse --git-common-dir` to
# find the shared .git dir, whose parent is the main checkout's root. If a
# tool call's path is rooted at the main checkout but NOT at the actual
# worktree root, block it.

set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"

# Only meaningful inside a git working tree; fail open otherwise.
if ! WORKTREE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  exit 0
fi

# --path-format=absolute: without it, git prints this path relative to the
# *cwd* (e.g. "../../.git" from a subdirectory), and resolving that against
# WORKTREE_ROOT below walks out of the repo, making MAIN_ROOT a parent
# directory like $HOME and flagging every path under it.
GIT_COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [[ -z "$GIT_COMMON_DIR" ]]; then
  exit 0
fi
# --git-common-dir may be relative to cwd; resolve to an absolute path.
if [[ "$GIT_COMMON_DIR" != /* ]]; then
  GIT_COMMON_DIR="$WORKTREE_ROOT/$GIT_COMMON_DIR"
fi
MAIN_ROOT="$(cd "$(dirname "$GIT_COMMON_DIR")" && pwd)"

# Not a linked worktree (this IS the main checkout) — nothing to guard.
if [[ -z "$MAIN_ROOT" || "$MAIN_ROOT" == "$WORKTREE_ROOT" ]]; then
  exit 0
fi

is_violation() {
  local path="$1"
  [[ "$path" == "$MAIN_ROOT"/* ]] || return 1
  [[ "$path" == "$WORKTREE_ROOT"/* || "$path" == "$WORKTREE_ROOT" ]] && return 1
  # Paths git-ignored in the main checkout (e.g. plans/) are untracked, so
  # they can never exist in any worktree either — referencing them via
  # MAIN_ROOT isn't worktree confusion, it's the only way to reach them.
  if git -C "$MAIN_ROOT" check-ignore -q -- "$path" 2>/dev/null; then
    return 1
  fi
  return 0
}

VIOLATION_PATH=""

case "$TOOL_NAME" in
  Read|Edit|Write)
    FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
    if [[ -n "$FILE_PATH" ]] && is_violation "$FILE_PATH"; then
      VIOLATION_PATH="$FILE_PATH"
    fi
    ;;
  Bash)
    CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
    if [[ -n "$CMD" ]]; then
      STRIPPED="${CMD//$WORKTREE_ROOT/__WORKTREE__}"
      if [[ "$STRIPPED" == *"$MAIN_ROOT/"* ]]; then
        # Extract each MAIN_ROOT-prefixed token and only flag if at least
        # one isn't git-ignored (see is_violation's plans/-style exception).
        while IFS= read -r candidate; do
          [[ -z "$candidate" ]] && continue
          if ! git -C "$MAIN_ROOT" check-ignore -q -- "$candidate" 2>/dev/null; then
            VIOLATION_PATH="(embedded in Bash command: $CMD)"
            break
          fi
        done < <(grep -oE "${MAIN_ROOT}/[^[:space:]\"'|&;]*" <<< "$STRIPPED")
      fi
    fi
    ;;
esac

if [[ -n "$VIOLATION_PATH" ]]; then
  REASON="Path is rooted at the main checkout ($MAIN_ROOT) but this session's actual worktree root is ($WORKTREE_ROOT). Re-root the path under $WORKTREE_ROOT before retrying. Offending path: $VIOLATION_PATH"
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

exit 0
