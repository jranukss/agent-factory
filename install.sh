#!/usr/bin/env bash
# Installs the agent factory into a target project's .claude/ directory.
# Usage:  ./install.sh /path/to/your/project
# Safe to re-run for updates: never overwrites an existing config.md.
set -euo pipefail

TARGET="${1:?usage: ./install.sh /path/to/target/project}"
SRC="$(cd "$(dirname "$0")" && pwd)"

[ -d "$TARGET/.git" ] || echo "warning: $TARGET does not look like a git repo (.git not found); continuing."

for pair in "agents:.claude/agents" "commands:.claude/commands" "factory:.claude/factory" "factory/scripts:.claude/factory/scripts"; do
  from="${pair%%:*}"; to="${pair##*:}"
  mkdir -p "$TARGET/$to"
  for f in "$SRC/$from"/*; do
    [ -f "$f" ] || continue   # subdirectories are handled by their own pair
    cp -f "$f" "$TARGET/$to/$(basename "$f")"
    echo "  installed $to/$(basename "$f")"
  done
done

# Version marker — read by /factory-init sync mode ("installed vs synced").
cp -f "$SRC/VERSION" "$TARGET/.claude/factory/VERSION"
echo "  installed .claude/factory/VERSION"

# Skills are directories (skills/<name>/SKILL.md + any references)
for d in "$SRC/skills"/*/; do
  name="$(basename "$d")"
  mkdir -p "$TARGET/.claude/skills/$name"
  cp -rf "$d"* "$TARGET/.claude/skills/$name/"
  echo "  installed .claude/skills/$name/"
done

if [ -f "$TARGET/.claude/factory/config.md" ]; then
  echo "  kept existing config.md (template updated alongside it)"
fi

cat <<'EOF'

Done. Next steps in the target project:
  1. RELOAD the Claude Code session (agents register at session start).
  2. Run /factory-init to generate/validate .claude/factory/config.md.
  3. Run /feature <your first request>.
EOF
