# Isolate Refactor Mode Out of sda-coder

Captured from design discussion on 2026-07-03. Independent of the integration-tests work — can proceed on its own.

---

## Problem

`sda-coder` supports three modes on one plane: **GREEN**, **integration**, **refactor**. GREEN and integration are close cousins (integration is roughly GREEN minus the mandatory test run). **Refactor is the outlier** — it does not merely add rules, it **inverts** several shared constraints. Because refactor lives beside GREEN/integration in one prompt, those inversions are expressed as "Exception —" clauses layered over opposite defaults, and the model must bind each exception to the current mode. Mis-binding causes silent, high-cost failures.

---

## How refactor inverts the shared constraints

| Dimension | GREEN / integration | Refactor | Nature |
|---|---|---|---|
| Read scope | Zero exploration — read only Source (+Test) | Read *all* files in the request | Inverted |
| Test failure response | Fix implementation, max 3 attempts | Revert the last change | Inverted |
| Behaviour | Add behaviour to pass tests | Do NOT introduce new behaviour | Inverted |
| Out-of-scope edits | N/A | Revert unconditionally, regardless of test results | Unique |
| Surrounding non-compliant code | Write compliant, fix in place | Report as observation, do NOT fix | Inverted |
| Change cadence | Implement, then run once | Incremental — run tests after each change | Unique |
| Input contract | Changes / Design Approach / Test | File list + refactoring rules (no Changes, no scenarios) | Different |
| Invocation cadence | Per unit, narrow file set | Once per task (Phase 4), all modified files | Different |

Every "Inverted" row reads the opposite way depending on mode.

---

## Concrete bleed failures (why co-location is risky)

- **"Revert instead of fix" leaks into GREEN** → coder abandons a failing test instead of implementing it. GREEN's core job silently fails.
- **"Fix the failure" leaks into refactor** → coder mutates code to force a green bar, masking a regression it just introduced. Defeats refactor's safety purpose — a broken test must mean "undo," never "patch."
- **Zero-exploration applied during refactor** → coder under-reads the modified-file set, misses cross-file duplication.
- **Read-all leaks into GREEN** → violates zero-exploration, bloats context, invites pattern-matching from surrounding code that GREEN forbids.
- **Standards "fix in place" leaks into refactor** → coder edits unchanged surrounding code (out of scope) instead of report-only.

---

## Decision

Split `sda-coder` on the **mode plane**, extracting **refactor only** in the first pass into a new **`sda-refactor` sub-agent**. Keep GREEN and integration together in `sda-coder` (they align).

**Carrier: sub-agent, not skill.** Refactor's most divergent rules — revert-on-failure, no-new-behaviour, unconditional out-of-scope revert — are safety-critical. A sub-agent keeps them at **system-level authority**; a skill would demote exactly those rules to user-level. That trade decides it.

Rationale for the split: refactor is the one mode whose rules read against the grain of `sda-coder`'s shared defaults. Isolating it into its own agent lets its rules be stated **positively** (read all listed files; revert on failure; report don't fix) instead of as exceptions over opposite defaults. Fewer conditional bindings → fewer misfires.

---

## Target shape

**`sda-coder` keeps:**
- Frontmatter + input contract (GREEN + integration only).
- Hard-stop-on-execution-failure, commands-immutable, working-directory.
- Shared positive-default sub-steps: `Run tests` (= fix), `Type check`, `Validate data`, `Format code`.
- GREEN and integration workflow bodies + their result templates.

**New `sda-refactor` sub-agent holds (system-level):**
- Its own copy of the shared constraints it needs (hard-stop, commands-immutable, working-directory, the shared sub-steps).
- Refactor-specific rules, stated positively: read-all scope; revert-on-failure; no-new-behaviour; unconditional out-of-scope revert; report-don't-fix standards; incremental-with-test-after-each.
- Refactor input contract (file list + refactoring rules) and result template.

**Selection:** `sda-dev` Phase 4 delegates directly to `sda-refactor` — deterministic, no new routing logic inside `sda-coder`.

---

## Plan of action

1. **Create `sda-refactor`.**
   Add `tools/sda/agents/sda-refactor.agent.md`. Frontmatter modelled on `sda-coder` (tools: `read`, `edit`, `search`, `execute`; `user-invocable: false`; same model). Description: "Subagent of sda-dev. Runs the refactoring pass over task-modified files. Use when: sda-dev delegates a refactoring pass."

2. **Move the refactor body.**
   Cut the `## Workflow — Refactoring` section and its result template from `tools/sda/agents/sda-coder.agent.md` into `sda-refactor`.

3. **Give `sda-refactor` its own shared constraints.**
   Copy the constraints it needs from `sda-coder` (hard-stop-on-execution-failure, commands-immutable, working-directory, and the `Run tests` / `Type check` / `Validate data` / `Format code` sub-steps) so its in-file anchors resolve. It is a standalone agent — no cross-file references back into `sda-coder`.

4. **State refactor rules positively in `sda-refactor`.**
   Rewrite the moved rules as plain defaults (not exceptions): read all listed files; revert on any test failure; introduce no new behaviour; revert out-of-scope touches unconditionally; report (never fix) surrounding non-compliant code; run tests after each incremental change.

5. **De-exception `sda-coder`.**
   Delete the now-orphaned refactor exception clauses:
   - `### Zero exploration` — remove the "Exception — refactoring pass" paragraph.
   - `### Run tests` — remove the "Refactoring exception: revert instead of fix" clause.
   - `### Coding standards` — remove the "During a refactoring pass, report..." clause.
   - `## Input contract` — remove the "Refactoring pass" input block.
   - Description — drop "and refactoring passes".
   Result: GREEN/integration constraints become clean positive defaults with nothing to override.

6. **Rewire the orchestrator.**
   In `tools/sda/agents/sda-dev.agent.md`, Phase 4 (REFACTOR): change the delegation target from `sda-coder` to `sda-refactor`. Verify the Phase 4 result template still matches `sda-refactor`'s result block.

7. **Update dependency docs.**
   - `tools/sda/AGENTS.md` — agent inventory + any dependency-map rows referencing sda-coder's refactor mode; add `sda-refactor`.
   - `tools/sda/README.md` — component list: add `sda-refactor`, amend `sda-coder`.
   - `sda-dev` frontmatter `agents:` list (currently `["*"]` — verify no narrowing needed).
   - `_installation/` manifests that enumerate agents.

8. **Consistency pass.**
   Re-read `sda-coder` and `sda-refactor` end-to-end: confirm no orphaned refactor references in `sda-coder`, no dangling anchors in either, no duplicate rows, and that GREEN/integration read cleanly without the removed exceptions.

---

## Scope guard

First pass extracts **refactor only**. Do NOT split GREEN from integration in the same change — they align and splitting them is low ROI. Revisit a GREEN/integration split only if the `integration tests` unit type lands and materially diverges.

---

## Status

**Implemented (2026-07-03).** Carrier: `sda-refactor` sub-agent. `tools/sda/agents/sda-refactor.agent.md` created; refactor mode removed from `sda-coder`; `sda-dev` Phase 4 delegates to `sda-refactor`; `AGENTS.md`, `README.md`, and `project-config.reference.yml` updated. Installer needs no change — `short` mode only excludes `sda-system` and `sda-feature`, so `sda-refactor` installs automatically.
