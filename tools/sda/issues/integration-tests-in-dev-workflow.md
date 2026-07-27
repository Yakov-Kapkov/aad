# Integration Tests in the Dev Workflow — Decision Record

Captured from design discussion on 2026-07-03. Depends on the `integration only` → `code only` rename landing first.

---

## Problem

`sda-dev` and its subagents write and run **unit tests** well, but the workflow has no facility for the **integration** layer of the testing pyramid (unit → integration → e2e).

The existing `integration only` unit type is a naming trap: it means *wiring/config/re-export code with no new tests* — not an integration-test layer. That term is being renamed to **`code only`**, which frees the word "integration" for the actual test layer.

---

## Decision

Add `integration tests` as a **new first-class unit type** alongside `tests required`, `tests only`, and `code only`. Do **not** overload `code only`.

Gate the change on two prerequisites:

1. **Extend the test-writer input contract** — replace the mock-centric `Test Context` with a fixture/environment contract for integration units: setup, teardown, required services, seed data.
2. **Model integration commands in `project-tools.md`** — a distinct `test-integration-path` command, longer timeout, and any "services running" precondition, so the orchestrator invokes documented commands only.

---

## Resulting route table

| Unit type | Route |
|---|---|
| `tests required` | RED → GREEN (unit) |
| `tests only` | RED (expected GREEN) |
| `integration tests` | RED → GREEN (integration) |
| `code only` | GREEN (wiring, no new tests) |

---

## Rationale — Pros

| Pro | Detail |
|---|---|
| Clean three-tier vocabulary | unit / integration / e2e as layers; `code only` is the orthogonal no-test wiring type. No overloaded terms. |
| Reuse of existing machinery | RED/GREEN gates, approval gates, state tracking, standards propagation, Phase 5 quality gates apply unchanged. |
| Pyramid enforceable per unit | Orchestrator can require unit units before integration units — pyramid becomes structural, not conventional. |
| Single source of truth | All layers in one `task.md`, one route table, one state machine. No parallel workflow to sync. |
| Consistent reporting & escalation | One Result format, one failure-handling path surfaced to the user. |

---

## Rationale — Cons / Costs

| Con | Detail |
|---|---|
| Test-writer contract mismatch | Current `Test Context` is mock-boundary-centric with zero-exploration/no-real-IO leanings. Integration tests need fixtures, real setup/teardown, seeded data, services. |
| Tooling gaps | `project-tools.md` has no `test-integration-path` command, timeout, or "services up" precondition. Must be modelled first. |
| RED-phase semantics blur | A failing integration test may fail from missing infra, not missing code — weakening the "fails for the right reason" gate. |
| Flakiness vs determinism | "Write, run, observe / no execution-path tracing" assumes deterministic outcomes. Integration tests flake (ordering, shared state, external services), stressing single-retry escalation. |
| Slower, costlier cycles | Running integration suites in every GREEN/Phase-5 gate lengthens units and raises runtime + token cost, especially under `approvalGates: false`. |
| Scope creep toward e2e | Without a firm boundary, the middle layer drifts into slow full-stack tests. |

---

## Impacted artifacts (when scheduled)

- `tools/sda/skills/sda-setup/assets/task-schema.md` — new unit type, route rules, section applicability.
- `tools/sda/agents/sda-dev.agent.md` — route table, delegation contract, test command construction.
- `tools/sda/agents/sda-test-writer.agent.md` — fixture/environment input contract for integration units.
- `tools/sda/skills/sda-setup/assets/project-tools-schema.md` — `test-integration-path` command + preconditions.

---

## Status

Not scheduled. Blocked on: `integration only` → `code only` rename.
