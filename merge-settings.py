#!/usr/bin/env python3
"""Idempotently add (or remove) maestro's settings into ~/.claude/settings.json.

Usage:
    merge-settings.py <settings.json path> <abs path to guard-bash.sh> [--uninstall]

Adds:
  - permissions.deny entries blocking destructive git/rm commands (globally; applies to subagents).
  - a hooks.PreToolUse Bash entry running the guard-bash.sh hook.

Safe to run repeatedly. Preserves all other settings.
"""
import json
import os
import sys

DENY_RULES = [
    "Bash(git push)",
    "Bash(git push:*)",
    "Bash(git reset --hard)",
    "Bash(git reset --hard:*)",
    "Bash(git clean:*)",
    "Bash(rm -rf:*)",
    "Bash(rm -fr:*)",
    "Bash(rm -r:*)",
    "Bash(rm -R:*)",
    "Bash(rm -Rf:*)",
]


def load(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def install(s, hook_path):
    perms = s.setdefault("permissions", {})
    deny = perms.setdefault("deny", [])
    for rule in DENY_RULES:
        if rule not in deny:
            deny.append(rule)

    hooks = s.setdefault("hooks", {})
    pre = hooks.setdefault("PreToolUse", [])
    already = any(
        h.get("command") == hook_path
        for entry in pre
        for h in entry.get("hooks", [])
    )
    if not already:
        pre.append({
            "matcher": "Bash",
            "hooks": [{"type": "command", "command": hook_path}],
        })
    return s


def uninstall(s, hook_path):
    deny = s.get("permissions", {}).get("deny", [])
    s.setdefault("permissions", {})["deny"] = [r for r in deny if r not in DENY_RULES]
    if not s["permissions"]["deny"]:
        s["permissions"].pop("deny", None)

    pre = s.get("hooks", {}).get("PreToolUse", [])
    new_pre = []
    for entry in pre:
        entry["hooks"] = [h for h in entry.get("hooks", []) if h.get("command") != hook_path]
        if entry["hooks"]:
            new_pre.append(entry)
    if "hooks" in s:
        if new_pre:
            s["hooks"]["PreToolUse"] = new_pre
        else:
            s["hooks"].pop("PreToolUse", None)
            if not s["hooks"]:
                s.pop("hooks", None)
    return s


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    path, hook_path = sys.argv[1], sys.argv[2]
    remove = "--uninstall" in sys.argv[3:]
    s = load(path)
    s = uninstall(s, hook_path) if remove else install(s, hook_path)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(("removed maestro settings from " if remove else "merged maestro settings into ") + path)


if __name__ == "__main__":
    main()
