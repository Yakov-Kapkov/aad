---
name: troubleshooting
description: "Troubleshooting dictionary for unexpected failures during development. Use when: anything (a command, a test run, a build, a tool) fails unexpectedly, produces errors you did not anticipate, or behaves differently than expected. Look up the symptom before reasoning from scratch. Not for a command that succeeded silently — empty output with exit code 0 is a pass."
---

# Troubleshooting

**Purpose:** Eliminate reasoning loops. Symptom → cause → fix. One lookup → one fix. Stop.

## Precondition — confirm a real failure

Check the exit code first — the value reported with the command's result
(PowerShell `$LASTEXITCODE`, bash/zsh `$?`).

| Observed | Verdict | Action |
|---|---|---|
| Empty output, exit code `0` | Success — silent tools print nothing | **Stop.** No lookup, no fix, no rewrite. |
| Empty output, non-zero exit code | Failure | Continue below. |
| Output present | Failure or unexpected text | Continue below. |

Elimination of the symptom ends troubleshooting of the current issue. For a **piped** command the reported code is
the pipe's, not the runner's (PowerShell `2>&1` reports `1` even on success) —
judge by the output instead. Never rewrite a command into a bare binary without a
confirmed non-zero exit code from an **unfiltered** run.

## Mandatory Workflow

1. Scan the Symptom Index below and match a keyword to the observed symptom.
2. Read **only the matching section**.
3. **Verify every condition in that row's Symptom cell.** A partial match is not
   a match.
4. **All conditions confirmed →** apply the prescribed fix immediately. This is
   the only thing that justifies a fix. Do not consider alternatives. Do not
   enumerate workarounds. Return to the original workflow — troubleshooting is done.
5. After applying the fix, retry the operation that was failing before
   troubleshooting started.
   - Resolved → resume the original workflow from where it stopped.
   - Still failing → return to step 1 with the *new* symptom.
6. **No confirmed match, or two consecutive fix attempts have failed →**
   diagnose normally. Do not loop back through the dictionary a third time.

## Anti-Loop Rules

- **One confirmed match = one fix.** Never apply more than one fix at a time.
- **Never brainstorm alternatives** once a full symptom match is confirmed.
- **Never explore workarounds.** The dictionary entry is authoritative.
- **Cap at two attempts.** If the same symptom persists after two fixes,
  stop and escalate / diagnose outside the dictionary.

## Symptom Index

Keywords are lookup hints, not evidence — matching one only tells you which section to read.

| Section | Keywords |
|---|---|
| Test Failures | env var, test hangs |
| Command Execution | env var not set, KeyError, empty config, dotenv |
| CLI Execution Errors | -1073740791, 0xC0000409, npx/npm, EDR block, Windows, exit 126, permission denied |

## Test Failures

| Symptom | Cause | Fix |
|---|---|---|
| `KeyError` / `ValidationError` / crash on missing env var during test collection or run | Code reads environment variables but no test fixture provides them | Add a test fixture that sets required env vars before the test runs — never set env vars in the shell command |
| Test hangs indefinitely (no output, no failure) | Real network call — no mock on HTTP/DB/socket dependency | Mock every external endpoint; unit tests must never make real I/O |

## Command Execution

| Symptom | Cause | Fix |
|---|---|---|
| Command fails with "env var not set" / `KeyError` / empty-string config error | Required environment variable not configured in the shell session | **During tests:** add a test fixture that sets the var (see Test Failures above). **Outside tests:** check project setup docs for required env vars; verify `.env` / shell profile; if the project uses a dotenv loader, ensure it runs before the failing command. Never prepend `VAR=value` to the command. |

## CLI Execution Errors

| Symptom | Cause | Fix |
|---|---|---|
| **All must hold:** on Windows, a command run via `npx`/`npm run` exits with code `-1073740791` (`0xC0000409`) and prints **no test results and no error message**. Exit code `0` with empty output is a pass — not this entry. | Corporate EDR blocked the multi-hop process tree spawned by `npx` or `npm run` (`npx → cmd.exe → tool.cmd → node → spawn → node`). Intermittent — self-resolves in ~1–2 hours or on reboot. | Replace `npx {tool}` with `node node_modules/{tool}/bin/{entry}.js`. Find the entry point in `node_modules/{tool}/package.json → bin`. Common substitutions: `npx mocha … → node node_modules/mocha/bin/mocha.js …`; `npx jest … → node node_modules/jest/bin/jest.js …`; `npx tsc … → node node_modules/typescript/bin/tsc …`; `npx eslint … → node node_modules/eslint/bin/eslint.js …`; `npx prettier … → node node_modules/prettier/bin/prettier.cjs …`. `npm test` / `npm run` "run-all" scripts can stay as-is. Re-run once with the direct form. |
| `.sh` script invoked by its path fails with `Permission denied` (exit 126) | Executable bit not set — the mode was lost in an archive or ZIP download, a copy through Windows, or a checkout with `core.fileMode=false` | Restore the bit once (`chmod +x <path>`), then re-run the bare path. A shell-interpreter prefix also runs it, but it masks the broken mode — never the standing invocation form |
