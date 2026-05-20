# maestro

A multi-agent dev orchestration workflow for Claude Code. One command — **`/maestro <slug>`** — runs a
feature from interactive spec design through autonomous spec-review → plan → plan-review → per-task
implementation (TDD + 2-stage review) → whole-change review (qa, architecture, conditional security/docs) →
final CTO gate, stopping at a human merge decision. Best-model-per-job (opus on gates, sonnet on impl,
haiku on scouting). Ported from a hand-built opencode workflow.

Installed as **user-level** Claude Code files, so the command is a clean bare `/maestro` and works in every
repo on the machine.

## Use it on a new machine

```bash
git clone <your-fork-url> ~/maestro      # or anywhere
cd ~/maestro
./install.sh                              # copies files into ~/.claude, merges settings (idempotent)
# RESTART Claude Code (agents register at session start)
```
Then in any repo: `/maestro <feature-slug>`.

To update later: `git pull && ./install.sh`. To remove: `./uninstall.sh`.

`install.sh` writes this machine's absolute hook path into `settings.json`, so it's portable across
machines/usernames. Override the target dir with `CLAUDE_DIR=/path ./install.sh`.

## Dependencies

- **`superpowers` plugin** (required) — maestro reuses its skills (brainstorming, writing-plans,
  using-git-worktrees, systematic-debugging, finishing-a-development-branch).
  Install: `/plugin marketplace add obra/superpowers` then `/plugin install superpowers`.
- **python3** (required) — the `guard-bash.sh` safety hook is a python3 script.
- Claude Code with access to opus / sonnet / haiku.

## What gets installed (into `~/.claude/`)

- `skills/maestro/SKILL.md` (+ `prompts/`) — the orchestrator (thin dispatcher).
- `agents/*.md` — the 13 agents (bare names: spec-critic, plan-critic, planner, dev-general, dev-frontend,
  dev-unity, dev-devops, task-reviewer, qa-verifier, review-tl, security-reviewer, docs-reviewer,
  final-reviewer).
- `hooks/guard-bash.sh` + a `hooks.PreToolUse` entry in `settings.json`.
- `permissions.deny` in `settings.json` — global block on `git push` / `reset --hard` / `clean` / `rm -rf`.

## Safety model

- **`permissions.deny`** is the primary block; it applies to subagents (verified). The **marker-gated hook**
  (`~/.claude/.maestro-active`, set only during a run) backstops it and catches forms the deny misses
  (e.g. `git -C <worktree> push`). Verified: both fire on subagent tool calls.
- Reviewer/critic agents are read-only (`tools: Read, Grep, Glob`).
- **maestro never auto-pushes or merges** — it stops at a human merge decision. On any unresolved BLOCKER it
  HALTs and writes `<phase>-UNRESOLVED.md`.
- Trade-off: `git push` is blocked in *all* Claude Code sessions on the machine — push from a terminal.
  Revert by running `./uninstall.sh` (or remove the `deny` lines + `hooks` block from `settings.json`).

## Model tiering

- **opus** — spec-critic, plan-critic, planner, security-reviewer, final-reviewer, and the orchestrator
  session (run `/maestro` from an Opus session for best coordination).
- **sonnet** — dev-*, review-tl, task-reviewer, qa-verifier, docs-reviewer.
- **haiku** — built-in Explore (scouting).
