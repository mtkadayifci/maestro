# Per-task code-quality review prompt (maestro Phase 4, stage 2)

Adapted from superpowers `subagent-driven-development/code-quality-reviewer-prompt.md` (which delegates to
`requesting-code-review/code-reviewer.md` — its essence is inlined below so this is version-stable).
Dispatched to the `task-reviewer` agent (sonnet, read-only) ONLY AFTER spec-compliance passes ✅. Purpose:
verify the implementation is well-built (clean, tested, maintainable).

```
Agent (subagent_type: task-reviewer):
  description: "Code-quality review — Task N"
  prompt: |
    You are doing a code-quality review of a single task's diff. MODE: CODE-QUALITY.

    ## Working root
    [ABSOLUTE_WORKTREE_PATH] — READ-ONLY. Inspect the diff:
        git -C [ABSOLUTE_WORKTREE_PATH] diff [BASE_SHA]..[HEAD_SHA]

    ## What this task was
    [task summary] — Task N from [plan-file path]. Requirements: [brief].

    ## Review for
    - **Correctness & robustness:** logic errors, unhandled edge cases, error handling, resource/lifecycle
      cleanup, concurrency.
    - **Tests:** do tests verify real behavior (not just mocks)? Was TDD followed? Coverage of the change?
    - **Clarity & maintainability:** clear names (what things do, not how), readable control flow, no dead
      code, no needless abstraction.
    - **Decomposition:** does each file/unit have one clear responsibility and a well-defined interface?
      Can units be understood and tested independently? Does it follow the plan's file structure?
    - **Footprint:** did THIS change create already-large files or significantly grow existing ones? (Don't
      flag pre-existing sizes — only what this change contributed.)
    - **Conventions:** follows existing codebase patterns + this repo's CLAUDE.md rules.

    ## Report
    - **Strengths:** brief.
    - **Issues:** grouped Critical / Important / Minor, each with file:line and a concrete fix.
    - **Assessment:** APPROVED, or CHANGES REQUESTED (list the must-fix items).
```

**Controller:** CHANGES REQUESTED → re-dispatch the implementer to fix, then re-run this review. APPROVED →
mark the task done in TodoWrite, move to the next task. Apply the shared loop rule (max 3 runs; on
exhaustion HALT).
