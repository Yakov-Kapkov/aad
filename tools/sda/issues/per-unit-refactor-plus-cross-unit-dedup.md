# Per-Unit Refactor + Thin Cross-Unit Dedup

Captured from design discussion on 2026-07-03. Builds on the `sda-refactor`
sub-agent (see [isolate-refactor-mode.md](isolate-refactor-mode.md)).

---

## Problem

The workflow is advertised as TDD (**RED → GREEN → REFACTOR**) but actually
runs **RED → GREEN, RED → GREEN, …, REFACTOR** — one global refactoring pass
(Phase 4) over *all* task-modified files after every unit is done.

Two costs:

- **Stale-context refactoring.** A unit's code is refactored long after it was
  written, in a large batch far from the moment of authoring.
- **Large single pass.** One `sda-refactor` invocation over the whole task
  surface is heavy and throttle-prone on big tasks.

But the global pass has one property worth keeping: it is the **only** stage
where all task files are in scope together, so it is the only place
duplication *across* units can be seen. `sda-refactor` has a hard read-scope
lock (read only listed files, never search), so a purely per-unit refactor is
structurally blind to inter-unit duplication.

---

## Decision

Split refactoring into two scopes:

1. **Per-unit refactor (full).** Add a refactor step to every unit cycle:
   **RED → GREEN → REFACTOR**, scoped to that unit's files only. Full 5-pass
   refactor.
2. **Cross-unit dedup (thin).** Replace the global Phase 4 with a single
   post-loop pass whose **only** job is removing duplication that spans
   *different* units. Runs the duplication pass only — not a full re-refactor.

Per-unit keeps context fresh and batches small; the thin cross-unit pass
recovers the one thing per-unit alone loses (inter-unit duplication).

**This obsoletes the parallel-fan-out idea** — per-unit refactor keeps every
batch small, so throttling is addressed without parallel `sda-refactor`
agents. The cross-unit pass is duplication-only over a read-mostly surface,
also light.

---

## Phase map (numbering preserved, 0–6)

Phase 4 splits into two modes under one banner; QUALITY stays Phase 5,
COMPLETE stays Phase 6 (no renumbering ripple).

| Mode | When | Scope | Passes |
|---|---|---|---|
| **4·U — per-unit refactor** | End of every unit cycle, inside the loop | That unit's modified files only | Full (all 5 passes) |
| **4·X — cross-unit dedup** | Once, after all units DONE | All task files, grouped by unit | Duplication pass only, inter-unit matches only |

New per-unit cycle:

```
Phase 1 (Plan) → Phase 2 (RED) → Phase 3 (GREEN) → Phase 4·U (per-unit refactor)
   → [gate or loop back to Phase 1]
```

- `approvalGates: false` → run 4·U immediately after GREEN, then loop to the
  next unit in the same response.
- After the **last** unit's 4·U → run **Phase 4·X** once → Phase 5.
- 4·U runs for **every** unit type (tests-required, tests-only, code-only),
  scoped to that unit's Source + Test files.
- Ad-hoc mode: single derived unit → run **4·U only**, skip 4·X.

---

## Phase 4·U — Per-unit refactor

- Delegation identical to today's Phase 4, but file lists are **only the
  current unit's** Source/Test files.
- Pass `Scope: per-unit`.
- Result rendered per unit; title includes the unit number.
- No `sda-refactor` behaviour change — its current input contract fits.

## Phase 4·X — Cross-unit dedup (thin global)

- Runs once, only when the task had **≥ 2 units** (single-unit tasks and
  ad-hoc mode skip it — no inter-unit duplication possible).
- Delegation passes **all task files grouped by unit** so the agent knows unit
  boundaries.
- Pass `Scope: cross-unit`.
- Charter: detect and remove logic duplicated across files belonging to
  **different** units. Do **not** re-run standards/naming/structure/
  simplification — those were done per-unit.
- Reverts anything that breaks a test, same as today.

---

## `sda-refactor` change

Add a first-class **`Scope`** field to the input contract:

| `Scope` | Passes executed | Extra rule |
|---|---|---|
| `per-unit` | All 5 passes (current behaviour) | none |
| `cross-unit` | **Duplication pass only** | Act only on duplication whose instances span two or more files belonging to **different** units; skip intra-unit duplication (handled per-unit) |

Read-scope lock unchanged: in `cross-unit` mode all task files are listed, so
the agent may legitimately see them all. Everything else (hard-stop on
execution failure, revert-on-test-break, commands-immutable, result block) is
unchanged.

---

## Approval gates

Refactor is now the last step of each unit, so the per-unit gate moves from
"after GREEN" to "after REFACTOR":

| Unit type | Gates (`approvalGates: true`) |
|---|---|
| TDD (tests required) | 🛑 after RED, 🛑 after **4·U REFACTOR** |
| Tests only | 🛑 after **4·U REFACTOR** |
| Code only | 🛑 after **4·U REFACTOR** |

- Phase 4·X has **no gate** — runs then proceeds to Phase 5 (matches today's
  global-refactor behaviour).
- RED-phase approval-decision cross-refs: "Phase 4 (no units left)" →
  "Phase 4·X (no units left)".

---

## Failure handling

Unchanged — the existing per-delegation protocol applies to **each** 4·U and
the 4·X invocation independently (retry-once on `⚠️ UNRESOLVED` / `❌ Type
gate`; surface logic-gate failures verbatim).

---

## Output templates

- **4·U Result** — reuse the current Phase 4 Result block, titled per unit:
  `🔵 **REFACTOR** — _Refactoring unit {N}..._`.
- **4·X Result** — new thin block:
  ```
  ### Cross-unit duplication
  - {files} → {shared logic extracted to <target>}

  or:
  ### Cross-unit duplication
  None found.
  ```
- Pre-existing issues from either mode still flow into Phase 6 Follow-up
  Opportunities.

---

## Plan of action

1. **`sda-dev.agent.md`**
   - Subagent bullet: note per-unit + cross-unit modes.
   - Phase-label table: keep `4 | REFACTOR`.
   - Unit loop (Phase 1 task mode + ad-hoc): insert 4·U after GREEN; route to
     4·X after the last unit.
   - Phase 4 section: split into 4·U (in loop) and 4·X (once), each with its
     own delegation, `Scope`, title, and Result block.
   - Gate table: move per-unit gate to "after REFACTOR".
   - Fix RED-phase gate cross-refs ("Phase 4" → "Phase 4·X").

2. **`sda-refactor.agent.md`**
   - Add `Scope` field to the input contract + pass-set table.
   - Add the cross-unit duplication rule (inter-unit matches only).

3. **`tools/sda/AGENTS.md`**
   - REFACTOR-phase descriptions and delegation-format dependency rows: note
     the two scopes.

4. **`tools/sda/README.md`**
   - Pipeline description, `sda-refactor` capability row, ASCII phase diagram:
     reflect per-unit REFACTOR in the loop + cross-unit dedup pass.

5. **Consistency pass** — re-read `sda-dev` and `sda-refactor` end to end;
   confirm no dangling "Phase 4 (global)" references, no duplicate rows.

---

## Open decisions

- **4·X trigger:** run whenever `units ≥ 2` (even if units share no files),
  or only when unit file sets overlap? **Resolved: always when ≥ 2** — cheap;
  agent reports "None found."
- **Tests-only units:** run 4·U (refactors test files for duplication/naming)
  or skip? **Resolved: keep** for uniformity.

---

## Status

**Implemented (2026-07-03).** Both open decisions resolved as above.
`sda-dev` Phase 4 split into 4·U (per-unit, in the loop) and 4·X
(cross-unit, once, ≥ 2 units); per-unit gate moved to "after REFACTOR (4·U)";
route table, gate table, GREEN/RED approval decisions, resume handling, and
Phase 6 references updated. `sda-refactor` gained a `Scope` field
(`per-unit` | `cross-unit`) with a scope-modes pass table and cross-unit
result variant. `AGENTS.md` dependency matrix and `README.md`
capability + phase overview synced.

**Follow-up dedup (2026-07-03).** Removed the behavioral `Rules:` blocks
from both the 4·U and 4·X delegations and dropped the obsolete `Rules`
input field from `sda-refactor` — the `Scope` field + Scope-modes table
are now the single source of truth for each scope's behaviour
(orchestrator passes only `Scope:` + files). Reworded the stale
"delete files … the rules" DO NOT bullet accordingly.
