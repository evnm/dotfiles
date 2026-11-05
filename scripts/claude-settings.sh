#!/usr/bin/env bash
#
# Merges the tracked .claude/settings.base.json into ~/.claude/settings.json.
#
#   claude-settings.sh apply   # merge, but stop if a tracked key was changed locally
#   claude-settings.sh force   # merge, overwriting local changes to tracked keys
#   claude-settings.sh pull    # copy local changes to tracked keys into the base file
#
# ~/.claude/settings.json stays a regular file that Claude Code is free to
# write to. Only the keys in the base file are managed; everything else
# (autoMode, keys Claude Code adds later, ...) is left alone and never
# reaches git.
#
# "Changed locally" is decided against a snapshot of the base file as last
# applied, so a base value that changed in the repo (e.g. after a git pull)
# is applied without complaint. Only a live value that differs from both the
# snapshot and the new base value counts as a conflict.
#
# Objects are merged key by key. Anything else, including arrays such as
# hooks.SessionStart, is compared and replaced as a whole.

set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
base="$repo/.claude/settings.base.json"
live="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
snap="$(dirname "$live")/.settings.base.applied.json"
mode=${1:-apply}

# Earlier versions of these dotfiles symlinked the whole file into the repo.
if [ -L "$live" ]; then
  tmp=$(mktemp "$live.XXXXXX")
  cat "$live" >"$tmp" 2>/dev/null || echo '{}' >"$tmp"
  mv "$tmp" "$live"
  echo "Replaced symlink $live with a regular file."
fi
[ -s "$live" ] || echo '{}' >"$live"
[ -s "$snap" ] || cp "$base" "$snap"

jq_lib='
  # Paths to every non-object value, treating arrays as single values.
  def leaves: if type == "object" and length > 0
    then to_entries[] | [.key] + (.value | leaves)
    else [] end;
  def get($p): try getpath($p) catch null;
  def conflicts($base; $live; $snap):
    [ $base | leaves | . as $p
      | ($live | get($p)) as $l
      | select($l != null
               and $l != ($snap | get($p))
               and $l != ($base | get($p)))
      | $p ];
'

conflicts=$(jq -nc --slurpfile b "$base" --slurpfile l "$live" --slurpfile s "$snap" \
  "$jq_lib"' conflicts($b[0]; $l[0]; $s[0]) | .[]')

if [ -n "$conflicts" ] && [ "$mode" = pull ]; then
  tmp=$(mktemp "$base.XXXXXX")
  chmod 644 "$tmp"
  jq --indent 2 --slurpfile l "$live" --slurpfile s "$snap" "$jq_lib"'
    . as $b | reduce conflicts($b; $l[0]; $s[0])[] as $p
      (.; setpath($p; $l[0] | getpath($p)))' "$base" >"$tmp"
  mv "$tmp" "$base"
  while IFS= read -r p; do
    echo "Pulled $(jq -r 'join(".")' <<<"$p") into $(basename "$base")"
  done <<<"$conflicts"
  echo "Review with: git -C $repo diff"
  conflicts=
fi

if [ -n "$conflicts" ] && [ "$mode" != force ]; then
  echo "These settings in $live were changed outside the repo:"
  echo
  while IFS= read -r p; do
    echo "  $(jq -r 'join(".")' <<<"$p")"
    diff -u --label "repo ($(basename "$base"))" --label "local ($live)" \
      <(jq --argjson p "$p" 'getpath($p)' "$base") \
      <(jq --argjson p "$p" 'getpath($p)' "$live") | sed 's/^/    /' || true
    echo
  done <<<"$conflicts"
  echo "Nothing was changed. Resolve by either:"
  echo "  make claude-settings-pull     # keep the local values (copies them into the repo)"
  echo "  make claude-settings FORCE=1  # discard the local values (repo wins)"
  echo "or edit $base by hand and rerun make claude-settings."
  exit 1
fi

# Merge: set every base value, and drop keys that were removed from the base
# file since the last apply, unless they've been changed locally since.
merged=$(jq --indent 2 --slurpfile b "$base" --slurpfile s "$snap" "$jq_lib"'
  . as $l
  | reduce ($s[0] | leaves) as $p (.;
      if ($b[0] | get($p)) == null and ($l | get($p)) == ($s[0] | get($p))
      then delpaths([$p])
        # Also drop parent objects that the deletion left empty.
        | reduce range($p | length - 1; 0; -1) as $i (.;
            if get($p[:$i]) == {} then delpaths([$p[:$i]]) else . end)
      else . end)
  | reduce ($b[0] | leaves) as $p (.; setpath($p; $b[0] | getpath($p)))' "$live")

if [ "$merged" = "$(jq --indent 2 . "$live")" ]; then
  echo "$live is up to date."
else
  diff -u --label "$live (before)" --label "$live (after)" \
    <(jq --indent 2 . "$live") <(printf '%s\n' "$merged") || true
  tmp=$(mktemp "$live.XXXXXX")
  printf '%s\n' "$merged" >"$tmp"
  mv "$tmp" "$live"
  echo "Updated $live."
fi
cp "$base" "$snap"
