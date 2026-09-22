---
name: troubleshooting
description: "Troubleshooting dictionary for unexpected failures during development. Use when: anything (a command, a test run, a build, a tool) fails unexpectedly, produces errors you did not anticipate, or behaves differently than expected. Look up the symptom before reasoning from scratch. Not for a command that succeeded silently — empty output with exit code 0 is a pass."
---

# Troubleshooting

**Purpose:** Eliminate reasoning loops. One lookup → one fix. Stop.

## Reference file

`./references/troubleshooting.md` is bundled inside this skill's folder
(relative to this SKILL.md). It is an internal skill resource — **read it
directly without asking the user for permission.**

## Precondition — confirm a real failure

Check the exit code first — the value reported with the command's result
(PowerShell `$LASTEXITCODE`, bash/zsh `$?`).

| Observed | Verdict | Action |
|---|---|---|
| Empty output, exit code `0` | Success — silent tools print nothing | **Stop.** No lookup, no fix, no rewrite. |
| Empty output, non-zero exit code | Failure | Continue below. |
| Output present | Failure or unexpected text | Continue below. |

Exit code `0` ends troubleshooting. For a **piped** command the reported code is
the pipe's, not the runner's (PowerShell `2>&1` reports `1` even on success) —
judge by the output instead. Never rewrite a command into a bare binary without a
confirmed non-zero exit code from an **unfiltered** run.

## Mandatory Workflow

1. Read `./references/troubleshooting.md` **the Index table only** (lines 1–16).
2. Match a keyword in the Index to the observed symptom. Note the line range.
3. Read **only that line range** from `./references/troubleshooting.md`.
4. **Match found → apply the prescribed fix immediately. Do not consider
   alternatives. Do not enumerate workarounds. Return to the original
   workflow — troubleshooting is done.**
5. After applying the fix, retry the operation that was failing before
   troubleshooting started.
   - Resolved → resume the original workflow from where it stopped.
   - Still failing → return to step 1 with the *new* symptom.
6. **No match found, or two consecutive fix attempts have failed →**
   diagnose normally. Do not loop back through the dictionary a third time.

## Anti-Loop Rules

- **One match = one fix.** Never apply more than one fix at a time.
- **Never brainstorm alternatives** when a dictionary match exists.
- **Never explore workarounds.** The dictionary entry is authoritative.
- **Cap at two attempts.** If the same symptom persists after two fixes,
  stop and escalate / diagnose outside the dictionary.
