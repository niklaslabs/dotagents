#!/usr/bin/env bash
# Link this repo's Claude Code config into one or more Claude config dirs.
# Safe to re-run: it only creates or refreshes symlinks and never touches
# real files or dirs (so each install's skills/synced bucket is left alone).
#
# Targets come from claude-dirs.local (one path per line, ~ allowed,
# # comments ok). If that file is missing, ~/.claude is used.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
list="$repo/claude-dirs.local"

targets=()
if [[ -f "$list" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    targets+=("${line/#\~/$HOME}")
  done < "$list"
else
  targets=("$HOME/.claude")
fi

# link <source> <dest>: create/refresh a symlink, refuse to clobber real files.
link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  skip  $dst (real file/dir exists, not a symlink)"
    return
  fi
  ln -sfn "$src" "$dst"
  echo "  link  $dst -> $src"
}

for dir in "${targets[@]}"; do
  echo "==> $dir"
  if [[ ! -d "$dir" ]]; then
    echo "  skip  (directory does not exist)"; continue
  fi

  link "$repo/claude/CLAUDE.md"     "$dir/CLAUDE.md"
  link "$repo/claude/settings.json" "$dir/settings.json"

  # skills/ must be a real dir: Claude Code writes its own synced/ bucket here.
  if [[ -L "$dir/skills" ]]; then
    echo "  error $dir/skills is a symlink; replace it with a real dir first" >&2
    continue
  fi
  mkdir -p "$dir/skills"

  # One symlink per skill (Claude Code only reads skills/<name>/SKILL.md).
  for skill in "$repo"/skills/*/; do
    skill="${skill%/}"
    [[ -f "$skill/SKILL.md" ]] || continue
    link "$skill" "$dir/skills/$(basename "$skill")"
  done

  # Drop symlinks that point into this repo but no longer resolve (removed skills).
  for entry in "$dir"/skills/*; do
    [[ -L "$entry" ]] || continue
    if [[ "$(readlink "$entry")" == "$repo/skills/"* && ! -e "$entry" ]]; then
      rm "$entry"; echo "  prune $entry"
    fi
  done
done
