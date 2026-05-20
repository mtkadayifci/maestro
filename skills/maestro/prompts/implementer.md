# Implementer dispatch prompt (maestro Phase 4)

Adapted from superpowers `subagent-driven-development/implementer-prompt.md`. The orchestrator fills the
`[...]` placeholders and dispatches this to the domain implementer agent (`dev-general` / `dev-frontend` /
`dev-unity` / `dev-devops`) via the Agent tool. Paste full task text — never tell the subagent to read the
plan file.

```
Agent (subagent_type: dev-<domain>):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name] for feature "[slug]".

    ## Working root (READ CAREFULLY)
    All work happens in this git worktree ONLY:
        [ABSOLUTE_WORKTREE_PATH]
    - Read/edit files only under that path. Use ABSOLUTE paths for every file op.
    - For git, use `git -C [ABSOLUTE_WORKTREE_PATH] ...` (your `cd` does not persist between bash calls).
    - You must NOT edit anything outside this worktree (e.g. sibling repos). If the task seems to require
      that, STOP and report BLOCKED — do not proceed.
    - Do NOT push, merge, force, reset --hard, clean, or rm -rf. (These are blocked anyway.)

    ## Task Description
    [FULL TEXT of the task from the plan — pasted, not referenced]

    ## Context
    [Scene-setting: where this fits, dependencies, files involved, architectural context, relevant
     CLAUDE.md rules for this repo]

    ## Before You Begin
    If anything about requirements, approach, dependencies, or acceptance criteria is unclear, ASK NOW
    (report NEEDS_CONTEXT). Do not guess.

    ## Your Job
    1. Implement exactly what the task specifies — nothing more (YAGNI).
    2. Follow TDD: write a failing test first, watch it fail, minimal code to pass, refactor.
    3. Verify it works (run the tests/build).
    4. Commit your work: `git -C [ABSOLUTE_WORKTREE_PATH] add -A && git -C [ABSOLUTE_WORKTREE_PATH] commit -m "..."`.
    5. Self-review with fresh eyes (completeness, quality, discipline, real tests).
    6. Report back.

    ## Code Organization
    - Follow the file structure in the plan; one clear responsibility per file.
    - If a file grows beyond the plan's intent, stop and report DONE_WITH_CONCERNS — don't split on your own.
    - In existing code, follow established patterns; don't restructure outside your task.

    ## When You're in Over Your Head
    It is always OK to stop. Bad work is worse than no work. STOP and report BLOCKED / NEEDS_CONTEXT when
    the task needs architectural decisions, code understanding you can't reach, or restructuring the plan
    didn't anticipate. Say specifically what you're stuck on and what help you need.

    ## Report Format
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or attempted)
    - What you tested + results
    - Files changed (absolute paths) + commit SHA
    - Self-review findings
    - Concerns / blockers
    Never silently produce work you're unsure about.
```

**Controller handling of status:** DONE → spec-compliance review. DONE_WITH_CONCERNS → read concerns,
address correctness/scope ones first. NEEDS_CONTEXT → provide context, re-dispatch. BLOCKED → escalate this
task once to an opus implementer; still blocked → HALT (write `phase4-UNRESOLVED.md`, surface to human).
