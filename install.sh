#!/usr/bin/env bash
# Install maestro into this machine's ~/.claude (user-level, bare /maestro command).
# Idempotent — safe to re-run (e.g. to update). Override target with CLAUDE_DIR=/path ./install.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_DIR:-$HOME/.claude}"

echo "Installing maestro into $DEST ..."
mkdir -p "$DEST/skills/maestro/prompts" "$DEST/agents" "$DEST/hooks"

# Skill (+ prompts), agents, hook
cp -R "$SRC/skills/maestro/." "$DEST/skills/maestro/"
cp "$SRC/agents/"*.md "$DEST/agents/"
cp "$SRC/hooks/guard-bash.sh" "$DEST/hooks/guard-bash.sh"
chmod +x "$DEST/hooks/guard-bash.sh"

# Merge settings (permissions.deny + the PreToolUse hook, with this machine's absolute hook path)
python3 "$SRC/merge-settings.py" "$DEST/settings.json" "$DEST/hooks/guard-bash.sh"

echo
# Dependency checks
if ! command -v python3 >/dev/null 2>&1; then
  echo "WARNING: python3 not found — the guard-bash.sh hook needs it. Install python3."
fi
if grep -q '"superpowers' "$DEST/settings.json" 2>/dev/null; then
  echo "superpowers: referenced in settings (good)."
else
  echo "NOTE: maestro depends on the 'superpowers' plugin. Install it with:"
  echo "      /plugin marketplace add obra/superpowers   (then)   /plugin install superpowers"
fi

echo
echo "Installed:"
echo "  $DEST/skills/maestro/SKILL.md (+ prompts/)"
echo "  $DEST/agents/{spec-critic,plan-critic,planner,dev-general,dev-frontend,dev-unity,dev-devops,task-reviewer,qa-verifier,review-tl,security-reviewer,docs-reviewer,final-reviewer}.md"
echo "  $DEST/hooks/guard-bash.sh  +  settings.json (permissions.deny + PreToolUse hook)"
echo
echo ">>> RESTART Claude Code so the 13 agents register, then run:  /maestro <slug>"
echo "    (git push is now globally blocked in Claude Code on this machine — push from a terminal.)"
