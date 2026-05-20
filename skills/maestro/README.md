# maestro

A multi-agent dev orchestration workflow for Claude Code. Installed as **user-level** files (works in every
repo), invoked with a bare **`/maestro <slug>`**. Ported from a hand-built opencode workflow.

## Files (all under `~/.claude/`)
- `skills/maestro/SKILL.md` — the orchestrator (thin dispatcher); `prompts/*.md` — Phase-4 dispatch templates.
- `agents/{spec-critic,plan-critic,planner,dev-general,dev-frontend,dev-unity,dev-devops,task-reviewer,qa-verifier,review-tl,security-reviewer,docs-reviewer,final-reviewer}.md` — the 13 agents.
- `hooks/guard-bash.sh` + a `hooks.PreToolUse` entry in `settings.json` — marker-gated destructive-command guard.
- `settings.json` `permissions.deny` — global block on `git push` / `reset --hard` / `clean` / `rm -rf`.

## Flow
```
/maestro <slug>
  0 Spec design     INTERACTIVE (brainstorming) — only mid-run human gate
  ── create one worktree; arm ~/.claude/.maestro-active; copy spec in ──
  1 Spec review     spec-critic        (opus)
  2 Plan            planner            (opus, runs writing-plans)
  3 Plan review     plan-critic        (opus)
  4 Implement       dev-* + task-reviewer  (sonnet; per-task TDD + spec→quality review)
  5 Test & review   qa-verifier, review-tl, [security], [docs]  (sonnet / opus security)
  6 Final gate      final-reviewer     (opus, CTO + repo CLAUDE.md rules)
  7 Completion      finishing-a-development-branch  (human merge/PR decision)
```
Autonomous after spec approval; **never auto-pushes/merges**. On an unresolved BLOCKER it HALTs and writes
`<phase>-UNRESOLVED.md`.

## Model tiering
- **opus** — spec-critic, plan-critic, planner, security-reviewer, final-reviewer, orchestrator session.
- **sonnet** — dev-*, review-tl, task-reviewer, qa-verifier, docs-reviewer.
- **haiku** — built-in Explore (scouting).

## Notes
- `git push` is blocked globally (by design) — push manually in a terminal. Revert by removing the deny
  lines + the `hooks` block from `~/.claude/settings.json`.
- Depends on the `superpowers` plugin (brainstorming / writing-plans / using-git-worktrees /
  systematic-debugging / finishing-a-development-branch).
