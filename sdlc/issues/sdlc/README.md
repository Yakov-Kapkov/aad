# SDLC Reshape — Design Specs

This folder holds the design specs for reshaping the SDA tool into a **five
bounded-context SDLC**: **BA → DESIGN → DEV + QA → DEP**. The files are numbered
in reading order. Nothing here mutates real tool files yet — the specs define the
work; [08-execution-checklist.md](08-execution-checklist.md) drives the real build.

## Reading order

| # | Doc | What it covers |
|---|---|---|
| 00 | [Implementation plan](00-implementation-plan.md) | Roadmap: goal, decisions (D1–D13), phases S0–S6. **Start here.** |
| 01 | [Architecture](01-architecture.md) | The 5-BC model, flow, two-tier storage, two nested state loops. The reference model. |
| 02 | [BA context](02-ba-context.md) | `sda-ba` agent, User Story schema, global gates (DoR/DoD/NFR), feature ledger. |
| 03 | [DESIGN context](03-design-context.md) | `sda-system` + `sda-feature` wiring; design-doc schema + pending lifecycle. |
| 04 | [DEV context](04-dev-context.md) | `sda-dev-task` consumes the User Story; system context = DEV durable ledger. |
| 05 | [QA context](05-qa-context.md) | `sda-qa-task` consumes Gherkin; known-test-case library + post-QA promotion. |
| 06 | [DEP context](06-dep-context.md) | Deployment-context ledger schema. Placeholder BC — no agents yet. |
| 07 | [DEV+QA internals](07-dev-qa-internals.md) | How the existing P1/P2/P3 changeset folds in; the base→delta layering rule. |
| 08 | [Execution checklist](08-execution-checklist.md) | Ordered real-file build plan (E0–E6), one verifiable phase per checkpoint. |

## How the docs relate

- **00** is the roadmap; every other doc realizes one of its phases (S0–S6).
- **01** is the architecture entity doc; **02–06** are the per-BC specs that cite it.
- **07** reconciles the pre-existing P1/P2/P3 changeset
  ([qa_plus_system_context.md](qa_plus_system_context.md)) with the reshape.
- **08** is the only doc that describes real-file mutation — it consolidates every
  spec's *Open items for execution* into one ordered pass.

## Conventions

- Config path keys are **camelCase** (`paths.design`, `paths.devSystemContext`, …).
- Setup assets are **BC-subfoldered** under `skills/sda-setup/assets/`
  (`ba/`, `design/`, `dev/`, `qa/`, `dep/`, `scripts/`).
- Each BC spec follows the same shape: intro + companion links → Deliverables table →
  per-item specs → *Open items for execution*.

## Status

Specs **S0–S6 complete**. Remaining work is the single real-file execution pass in
[08-execution-checklist.md](08-execution-checklist.md).
