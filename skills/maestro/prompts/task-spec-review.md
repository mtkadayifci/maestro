# Per-task spec-compliance review prompt (maestro Phase 4, stage 1)

Adapted from superpowers `subagent-driven-development/spec-reviewer-prompt.md`. Dispatched to the
`task-reviewer` agent (sonnet, read-only) AFTER the implementer reports DONE. Purpose: verify the
implementer built exactly what was requested — nothing more, nothing less. Run this BEFORE the
code-quality review.

```
Agent (subagent_type: task-reviewer):
  description: "Spec-compliance review — Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification. MODE: SPEC-COMPLIANCE.

    ## Working root
    [ABSOLUTE_WORKTREE_PATH] — read the actual code here (absolute paths). You are READ-ONLY.

    ## What Was Requested
    [FULL TEXT of the task requirements]

    ## What the Implementer Claims They Built
    [Implementer's report + commit SHA range BASE..HEAD]

    ## CRITICAL: Do Not Trust the Report
    Verify everything independently by reading the actual diff/code (`git -C [ABSOLUTE_WORKTREE_PATH] diff
    BASE..HEAD`). Do not accept their claims, completeness, or interpretation at face value.

    ## Check
    - **Missing:** did they implement everything requested? Anything skipped or claimed-but-absent?
    - **Extra:** did they build/over-engineer anything not requested (YAGNI violations)?
    - **Misunderstanding:** did they solve the right problem the right way, per the spec's intent?

    ## Report
    - ✅ Spec compliant (everything matches after code inspection), OR
    - ❌ Issues: list specifically what's missing / extra / wrong, each with file:line.
    Be precise and actionable — the implementer will fix exactly what you list.
```

**Controller:** ❌ → re-dispatch the implementer to fix the listed gaps, then re-run this review. ✅ →
proceed to the code-quality review. Apply the shared loop rule (max 3 runs; on exhaustion HALT).
