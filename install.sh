#!/usr/bin/env bash
# Install every skill in this repo into a tool's skill root.
#
#   ./install.sh                       # copy into ~/.agents/skills
#   ./install.sh --link                # symlink instead (repo stays the single source)
#   ./install.sh --target DIR          # different root (e.g. ~/.claude/skills)
#   ./install.sh --dry-run             # show what would happen
#   ./install.sh --force               # overwrite existing entries
#
# Discovery rule: a skill is any directory `skills/<category>/<name>/` that
# contains SKILL.md. Nested SKILL.md files are ignored on purpose — tools
# only scan one level deep.
set -euo pipefail
shopt -s nullglob

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SKILLS_DIR:-$HOME/.agents/skills}"
MODE="copy"
FORCE=0
DRY=0

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# *//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --link) MODE="link" ;;
    --copy) MODE="copy" ;;
    --target) TARGET="$2"; shift ;;
    --target=*) TARGET="${1#*=}" ;;
    --force) FORCE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done

mkdir -p "$TARGET"
# Canonicalize so verification globs work even when the path came in with
# Windows separators (Git Bash / MSYS).
TARGET="$(cd "$TARGET" && pwd)"
installed=0
skipped=0

for skill_md in "$REPO_ROOT"/skills/*/*/SKILL.md; do
  [ -e "$skill_md" ] || continue
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  dest="$TARGET/$name"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" -eq 0 ]; then
      echo "skip   $name (already exists; use --force to replace)"
      skipped=$((skipped + 1))
      continue
    fi
    echo "remove $dest"
    [ "$DRY" -eq 1 ] || rm -rf "$dest"
  fi

  if [ "$MODE" = "link" ]; then
    echo "link   $name -> $src"
    if [ "$DRY" -eq 1 ]; then
      : # nothing to do
    elif ln -s "$src" "$dest" 2>/dev/null; then
      :
    else
      echo "       link not permitted here; copying instead"
      cp -R "$src" "$dest"
    fi
  else
    echo "copy   $name -> $dest"
    [ "$DRY" -eq 1 ] || cp -R "$src" "$dest"
  fi
  installed=$((installed + 1))
done

if [ "$DRY" -eq 1 ]; then
  echo "dry run: would install $installed, skip $skipped into $TARGET"
  exit 0
fi

echo
ver=0
for skill_md in "$TARGET"/*/SKILL.md; do
  if [ -e "$skill_md" ]; then
    echo "ok     $skill_md"
    ver=$((ver + 1))
  fi
done
echo "installed $installed, skipped $skipped into $TARGET (verified $ver)"
