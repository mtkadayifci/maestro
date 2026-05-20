#!/usr/bin/env bash
# Remove maestro from this machine's ~/.claude. Override target with CLAUDE_DIR=/path ./uninstall.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_DIR:-$HOME/.claude}"

echo "Removing maestro from $DEST ..."

# Settings first (remove deny rules + the hook entry)
[ -f "$DEST/settings.json" ] && python3 "$SRC/merge-settings.py" "$DEST/settings.json" "$DEST/hooks/guard-bash.sh" --uninstall || true

# Files (rm -rf is intentionally NOT used — it may be blocked by the deny rules just removed; use find -delete)
for a in spec-critic plan-critic planner dev-general dev-frontend dev-unity dev-devops task-reviewer qa-verifier review-tl security-reviewer docs-reviewer final-reviewer; do
  rm -f "$DEST/agents/$a.md"
done
rm -f "$DEST/hooks/guard-bash.sh"
find "$DEST/skills/maestro" -delete 2>/dev/null || true

echo "Done. Restart Claude Code. (The 'superpowers' plugin and local-coder agent are left untouched.)"
