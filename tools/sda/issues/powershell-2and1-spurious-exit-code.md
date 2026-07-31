# PowerShell `2>&1` Causes Spurious Exit Code 1 — Issue Report

Captured from dev workflow observation on 2026-07-31.

---

## Problem

When SDA constructs test commands with `2>&1` on PowerShell, libraries that log
stderr warnings (e.g. `@azure/functions`) cause the pipeline to report exit code 1,
even though the test runner itself exits 0.

| Scenario | Exit code |
|---|---|
| `vitest` (bare) | 0 ✅ |
| `vitest 2>&1 \| Select-String ...` | 1 ❌ |

**Root cause:** In PowerShell, `2>&1` merges the error stream into the success
stream, but error records still set `$?` to `$false`. The pipeline's reported
exit code becomes 1 regardless of the native command's actual exit code. In
bash/zsh, `2>&1` has no such side effect — exit codes are unaffected.

## Affected locations

| File | Line | Usage |
|---|---|---|
| `agents/sda-dev.agent.md` | ~190 | Test command construction: `{test-path} 2>&1 \| {composed-filter}` |
| `skills/sda-setup/assets/toolscan/project-tools-schema.md` | ~225 | `filter-last-n` template: `<command> 2>&1 \| {last-n-lines-tool} {N}` |

Both are used in the dev workflow — the first for all unit test runs (RED,
GREEN, quality), the second for baseline capture (`test-all` in Phase 1).

## Impact

- **sda-dev / sda-dev-quality** may interpret a passed test run as failed,
  triggering spurious retry loops or false regression flags.
- **Phase 1 baseline capture** may report pre-existing failures that don't
  exist, or fail to establish a clean baseline.

## Proposed fix

Make `2>&1` shell-conditional:

- **PowerShell:** pipe stdout only — `{test-path} | {filter}`. Stderr warnings
  are not test results; the filter regex targets stdout patterns.
- **bash/zsh:** keep `2>&1` — safe and standard.

The agent already knows `{shell}` from Phase 0 bootstrap, so the condition is
zero-cost at runtime.

## Decision

Pending.
