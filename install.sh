#!/usr/bin/env bash
# Install the AI agent workflow starter (AGENTS.md, skills, feature templates)
# into another repository.
#
# AGENTS.md is the primary, agent-agnostic instruction file. CLAUDE.md only
# imports it (@AGENTS.md), and .claude/skills/ only contains symlinks to the
# canonical skills in .agents/skills/.
#
# By default the installed files are ignored privately via .git/info/exclude
# (never committed, never written to .gitignore).
#
# Usage: ./install.sh [--force] [--dry-run] [--no-exclude] <target-repo>

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
DRY_RUN=0
EXCLUDE=1
TARGET=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--dry-run] [--no-exclude] <target-repo>

Copies AGENTS.md, CLAUDE.md, .agents/skills/ and features/_templates/ into
<target-repo> and links each skill into .claude/skills/.

When a file already exists and differs, you are asked whether to overwrite
it. Without a terminal (e.g. CI), conflicting files are skipped.

The installed files are added to the private .git/info/exclude of the target
repository, so they stay out of git without touching .gitignore.

Options:
  --force     Overwrite files that differ without asking (originals moved to .ai-workflow-backup/<timestamp>/)
  --dry-run   Show what would happen without changing anything
  --no-exclude  Do not add the installed files to .git/info/exclude
              (use this when the workflow files should be committed)
  -h, --help  Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --no-exclude) EXCLUDE=0 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)
      if [ -n "$TARGET" ]; then echo "Only one target allowed" >&2; exit 1; fi
      TARGET="$1" ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then usage >&2; exit 1; fi
if [ ! -d "$TARGET" ]; then echo "Error: target '$TARGET' is not a directory" >&2; exit 1; fi
TARGET="$(cd "$TARGET" && pwd)"
if [ "$TARGET" = "$SRC" ]; then echo "Error: target is the starter repo itself" >&2; exit 1; fi

IS_GIT=0
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_GIT=1
else
  echo "Warning: $TARGET is not a git repository; changes cannot be reviewed with git diff."
fi

COPIED=0; SKIPPED=0; UNCHANGED=0
SKIPPED_LIST=""

# Run a command, unless in dry-run mode (the action is already reported).
run() {
  if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

# Backups go into one timestamped folder per run, mirroring the original
# paths, so nothing is left next to the real files (and no stale skill copies
# end up inside .claude/skills/). Created on first use only.
BACKUP_ROOT="$TARGET/.ai-workflow-backup"
BACKUP_DIR=""
BACKED_UP=0

# Move an existing path into this run's backup folder.
backup() {
  local path="$1" rel="${1#$TARGET/}"
  # A symlink holds no content of its own (and would dangle once moved),
  # so just remove it instead of backing it up.
  if [ -L "$path" ]; then
    echo "  remove   $rel (old symlink -> $(readlink "$path"); not backed up)"
    run rm "$path"
    return
  fi
  if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$BACKUP_ROOT/$(date +%Y-%m-%d_%H%M%S)"
    local base="$BACKUP_DIR" n=1
    # Two runs within the same second must not share a folder.
    while [ -e "$BACKUP_DIR" ]; do BACKUP_DIR="$base-$n"; n=$((n + 1)); done
  fi
  echo "  backup   $rel -> ${BACKUP_DIR#$TARGET/}/$rel"
  run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  run mv "$path" "$BACKUP_DIR/$rel"
  BACKED_UP=$((BACKED_UP + 1))
}

# Ask questions only when a terminal is available and no answer is implied
# by --force or --dry-run. Prompts read from /dev/tty, so piping the output
# (e.g. into tee) still works.
INTERACTIVE=0
if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && { : </dev/tty; } 2>/dev/null; then
  INTERACTIVE=1
fi
OVERWRITE_ALL="$FORCE"

# Show how an existing target differs from the template.
show_diff() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    echo "    existing is a symlink -> $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    diff -ru "$dst" "$src" || true
  else
    diff -u "$dst" "$src" || true
  fi
}

# Decide what to do with an existing target that differs from the template.
# Returns 0 to overwrite, 1 to skip; exits on "quit".
resolve_conflict() {
  local label="$1" src="$2" dst="$3" answer
  [ "$OVERWRITE_ALL" -eq 1 ] && return 0
  [ "$INTERACTIVE" -eq 1 ] || return 1
  while true; do
    {
      echo "  conflict $label already exists and differs from the template."
      printf '           Overwrite? [y]es / [n]o / [d]iff / [a]ll / [q]uit (default: n): '
    } >/dev/tty
    read -r answer </dev/tty || answer="n"
    case "$answer" in
      y|Y|yes) return 0 ;;
      ""|n|N|no) return 1 ;;
      d|D|diff) show_diff "$src" "$dst" >/dev/tty ;;
      a|A|all) OVERWRITE_ALL=1; return 0 ;;
      q|Q|quit)
        echo "  quit     installation stopped; files already installed are kept."
        update_exclude
        print_summary
        exit 1 ;;
      *) echo "           Please answer y, n, d, a or q." >/dev/tty ;;
    esac
  done
}

# Record a skipped target for the summary.
skip() {
  echo "  skip     $1 (exists and differs)"
  SKIPPED=$((SKIPPED + 1)); SKIPPED_LIST="$SKIPPED_LIST $1"
}

# Copy one file (path relative to the repo root) from SRC to TARGET.
copy_file() {
  local rel="$1" src="$SRC/$1" dst="$TARGET/$1"
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      UNCHANGED=$((UNCHANGED + 1)); return
    fi
    if ! resolve_conflict "$rel" "$src" "$dst"; then skip "$rel"; return; fi
    backup "$dst"
  fi
  echo "  copy     $rel"
  run mkdir -p "$(dirname "$dst")"
  run cp -p "$src" "$dst"
  COPIED=$((COPIED + 1))
}

# CLAUDE.md: copy if missing; otherwise make sure it imports AGENTS.md
# without discarding the target's existing Claude-specific content.
install_claude_md() {
  local dst="$TARGET/CLAUDE.md"
  if [ ! -e "$dst" ]; then copy_file "CLAUDE.md"; return; fi
  if grep -qxF '@AGENTS.md' "$dst"; then UNCHANGED=$((UNCHANGED + 1)); return; fi
  echo "  update   CLAUDE.md (prepend @AGENTS.md import; existing content kept)"
  echo "           Tip: move agent-agnostic rules from CLAUDE.md into AGENTS.md."
  if [ "$DRY_RUN" -eq 0 ]; then
    local tmp; tmp="$(mktemp)"
    { printf '@AGENTS.md\n\n'; cat "$dst"; } > "$tmp"
    cat "$tmp" > "$dst"   # keep original file permissions
    rm -f "$tmp"
  fi
  COPIED=$((COPIED + 1))
}

# Link .claude/skills/<name> -> ../../.agents/skills/<name> (relative, portable).
link_skill() {
  local name="$1" link="$TARGET/.claude/skills/$1" want="../../.agents/skills/$1"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$want" ]; then
    UNCHANGED=$((UNCHANGED + 1)); return
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    if ! resolve_conflict ".claude/skills/$name" "$SRC/.agents/skills/$name" "$link"; then
      skip ".claude/skills/$name"; return
    fi
    backup "$link"
  fi
  echo "  link     .claude/skills/$name -> $want"
  run mkdir -p "$TARGET/.claude/skills"
  run ln -s "$want" "$link"
  COPIED=$((COPIED + 1))
}

print_summary() {
  echo
  echo "Done: $COPIED installed/updated, $UNCHANGED already up to date, $SKIPPED skipped."
  if [ "$SKIPPED" -gt 0 ]; then
    echo "Skipped (review and merge manually, or rerun to overwrite):"
    for s in $SKIPPED_LIST; do echo "  - $s"; done
  fi
  if [ "$BACKED_UP" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Backed up $BACKED_UP original(s) to: ${BACKUP_DIR#$TARGET/}/"
    echo "  Delete that folder once you have reviewed the changes."
  fi
}

# Privately ignore the installed files in the target repository by adding
# root-anchored patterns to .git/info/exclude (never committed). Exact paths
# are used so the repo's own .claude/ files and features/<id>-*/ folders
# stay visible to git. Existing lines are left untouched; no duplicates.
update_exclude() {
  [ "$EXCLUDE" -eq 1 ] || return 0
  if [ "$IS_GIT" -eq 0 ]; then
    echo "  note     not a git repository; skipping .git/info/exclude"
    return 0
  fi

  local patterns="/AGENTS.md /CLAUDE.md" skill_dir name
  for skill_dir in "$SRC"/.agents/skills/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    patterns="$patterns /.agents/skills/$name/ /.claude/skills/$name"
  done
  patterns="$patterns /features/_templates/ /.ai-workflow-backup/"

  # --git-path also resolves correctly for worktrees and submodules.
  local file
  file="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
  case "$file" in /*) ;; *) file="$TARGET/$file" ;; esac

  local p missing="" path tracked
  for p in $patterns; do
    grep -qsxF -- "$p" "$file" || missing="$missing $p"
    # Ignore rules do not apply to files git already tracks.
    path="${p#/}"; path="${path%/}"
    tracked="$(git -C "$TARGET" ls-files -- "$path" | head -n 1)"
    if [ -n "$tracked" ]; then
      echo "  warning  $path is tracked by git; the exclude has no effect"
      echo "           (untrack it with: git rm -r --cached $path)"
    fi
  done

  if [ -z "$missing" ]; then
    echo "  exclude  .git/info/exclude already up to date"
    return 0
  fi
  for p in $missing; do echo "  exclude  $p"; done
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$file")"
    {
      # Make sure we start on a new line if the file lacks a trailing newline.
      if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then echo; fi
      grep -qsxF '# ai-workflow (added by install.sh)' "$file" \
        || echo '# ai-workflow (added by install.sh)'
      for p in $missing; do echo "$p"; done
    } >> "$file"
  fi
}

echo "Installing AI workflow starter"
echo "  from: $SRC"
echo "  into: $TARGET"
[ "$DRY_RUN" -eq 1 ] && echo "  mode: dry-run (no changes will be made)"
echo

# 1. Primary instruction file.
copy_file "AGENTS.md"

# 2. Canonical skills and feature templates (every regular file in these dirs).
for dir in .agents/skills features/_templates; do
  [ -d "$SRC/$dir" ] || continue
  while IFS= read -r f; do
    copy_file "${f#$SRC/}"
  done < <(find "$SRC/$dir" -type f ! -name '.DS_Store' | sort)
done

# 3. Claude Code adapter: CLAUDE.md import and skill symlinks.
install_claude_md
for skill_dir in "$SRC"/.agents/skills/*/; do
  [ -d "$skill_dir" ] || continue
  link_skill "$(basename "$skill_dir")"
done

# 4. Keep the installed files out of git, privately.
update_exclude

print_summary
if [ "$DRY_RUN" -eq 0 ]; then
  echo
  echo "Next steps:"
  echo "  1. Review the installed files (AGENTS.md, CLAUDE.md, .agents/skills/, features/_templates/)."
  echo "  2. Start a feature: mkdir features/001-short-name and copy the templates into it."
fi
