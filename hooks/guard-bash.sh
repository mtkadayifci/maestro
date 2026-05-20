#!/usr/bin/env python3
# maestro PreToolUse Bash guard.
#
# Belt-and-suspenders backstop to the global permissions.deny rules. Active ONLY while a maestro run is in
# progress (the orchestrator creates ~/.claude/.maestro-active at the autonomy boundary and removes it at
# the Phase 6->7 boundary / completion). When no run is active this hook is a no-op, so it never interferes
# with normal Claude Code usage.
#
# It parses the command (per shell segment; the real git subcommand after skipping `-C <path>` etc.) so it
# catches forms the prefix-based permissions.deny misses, notably `git -C <worktree> push`. Exit 2 blocks
# the tool call; exit 0 allows it. Fail-open on parse errors (permissions.deny backstops the common forms).

import sys, os, json, re, shlex

MARKER = os.path.expanduser("~/.claude/.maestro-active")
if not os.path.exists(MARKER):
    sys.exit(0)  # no active maestro run -> allow everything

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "") or ""
except Exception:
    sys.exit(0)

GIT_GLOBAL_OPTS_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}

def reason(segment):
    try:
        toks = shlex.split(segment)
    except Exception:
        toks = segment.split()
    if not toks:
        return None

    if toks[0] == "rm":
        shortflags = "".join(t[1:] for t in toks[1:] if re.fullmatch(r"-[A-Za-z]+", t))
        longs = [t for t in toks[1:] if t.startswith("--")]
        if "r" in shortflags or "R" in shortflags or "--recursive" in longs:
            return "rm -r"

    if toks[0] == "git":
        i = 1
        while i < len(toks):
            t = toks[i]
            if t in GIT_GLOBAL_OPTS_WITH_ARG:
                i += 2
                continue
            if t.startswith("--") and "=" in t:
                i += 1
                continue
            if t.startswith("-"):
                i += 1
                continue
            sub, rest = t, toks[i + 1:]
            if sub == "push":
                return "git push"
            if sub == "reset" and "--hard" in rest:
                return "git reset --hard"
            if sub == "clean":
                return "git clean"
            if sub == "branch" and "-D" in rest:
                return "git branch -D"
            break
    return None

for seg in re.split(r"&&|\|\||[;|&\n]", cmd):
    why = reason(seg)
    if why:
        sys.stderr.write(
            "maestro: destructive command blocked during an active run (%s). Run it manually if intended.\n" % why
        )
        sys.exit(2)

sys.exit(0)
