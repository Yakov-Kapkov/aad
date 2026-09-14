# SDLC Bounded Contexts — Implementation Plan

Reshapes SDA from a QA+DEV pipeline into a **bounded-context (BC) SDLC**, started
from the correct end (BA). This plan is the master roadmap; read it before any code
is generated.

---

## Goal

Deliver an AI-driven SDLC composed of five bounded contexts — **BA → DESIGN →
DEV + QA → DEP** — glued by a CLI-driven workflow that **no BC knows about**. Each
BC is single-concern, scoped to its own agents/assets, and communicates only through
a shared workflow layer owned by an orchestrator (human today, engine later).

Each completed **User Story** must leave a durable contribution in every BC's
project-level ledger — that is the SDLC-level definition of done.

---

## Context

### Where we came from
- Prior design ([qa_plus_system_context.md](qa_plus_system_context.md)) built a
  QA+DEV-centric pipeline with system context, two-gate QA, multi-run task cycles,
  and engine-agnostic `cycle-state.yaml` + `next-step.ps1/sh`.
- [ai-sdlc.md](ai-sdlc.md) sketched a local CLI workflow runner and an explicit
  per-task state machine
  (`Backlog → Designed → Implemented → Verified → Context-Updated → Done`).

### What changed
- We now see the whole tool as **one system with bounded contexts**, and we start
  from **BA** (the requirement origin) rather than the middle.
- The existing P1/P2/P3 work is **not discarded** — it becomes the **DEV/QA/infra
  internals** layer beneath the BC model.

### The five bounded contexts

| # | BC | Owns (concern) | Agents | Durable contribution per story |
|---|---|---|---|---|
| 1 | **BA** | Requirement — the *what/why* | `sda-ba` *(new)* | Implemented-feature ledger (BA view of what exists) |
| 2 | **DESIGN** | Architecture/feature *how* + decisions | `sda-system`, `sda-feature` | System design docs (updated, change marked pending) |
| 3 | **DEV** | Code implementing the task | `sda-dev-task`, `sda-dev`, `sda-dev-context-writer` *(new)* (+ TDD leaves) | System context (behaviors, decisions, dependency map) |
| 4 | **QA** | Verify against US + global NFR | `sda-qa-task`, `sda-qa`, `sda-qa-context-writer` *(new)* | Known-test-case library |
| 5 | **DEP** | Deployment | *(none yet — out of scope)* | Deployment context (per-part deploy details) |

### Two nested state loops
- **SDLC workflow (outer):** a User Story moving through BA→DESIGN→DEV→QA→DEP.
  State: `workflow-state.yaml`. Scripts: `workflow-*.ps1/sh`.
- **DEV+QA verification cycle (inner):** one dev task's implement/QA/rework runs
  (spans DEV+QA). State: `dev-qa-cycle-state.yaml`. Scripts:
  `dev-qa-cycle-state.ps1/sh`, `dev-qa-next-step.ps1/sh`.

Same script *pattern* (init / read / advance), two scopes — both owned by the
workflow layer. The outer `workflow-*` scripts **delegate into** the inner cycle
when a story enters the DEV+QA span and read only its **terminal verdict** to
advance; they never manage individual runs. The inner cycle is driven by
`dev-qa-next-step.ps1/sh` + the human, which are the only callers of
`dev-qa-cycle-state.ps1/sh`. BCs never read either state file.

### Two-tier storage (durability, not BC)

| Tier | Contents | Location (configurable) | Audience |
|---|---|---|---|
| **Durable ledgers** | global-NFR/DoR/DoD, system design docs, known-test-case library, system context, implemented-feature docs, deployment context | project-level roots via `paths.*` (browsable, committed, tool-agnostic) | Everyone, incl. dev outside this tool |
| **Transient workspace** | `task.md`, `qa-task.md`, run folders, reports, `cycle-state`, agent state | tool-scoped root (e.g. `.sda/` or `Workflows/`) | The tool only |

Each completed User Story updates all five durable ledgers. A third area — the
**`Pending/` overlay** (`paths.pendingChanges`, D13) — mirrors the durable roots and holds
proposed-but-unapproved changes until the story completes, then merges in.

### Inter-BC interaction (BCs blind, orchestrator sees all)
- BCs receive only **a requirement + an output path**. They never read the workflow
  id or `workflow-state.yaml`.
- The orchestrator (human via `workflow-*.ps1/sh` now; an engine later) reads each
  BC's output and advances state.
- Per-workflow transient layout:

  ```
  {paths.workflows}/workflow-<id>/
    workflow-state.yaml        ← orchestrator-owned; BCs never touch it
    BA/    user-story.md (Actor + Gherkin), local NFRs
    DESIGN/ feature/design deltas
    DEV/   task.md, runs/, code SHAs (in dev-qa-cycle-state)
    QA/    qa-task.md, qa-report.md
    DEP/   (placeholder)
  ```

---

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **DESIGN is a standalone 5th BC** | Owns architecture *how* + decisions; distinct from BA (*what/why*) and DEV (code). Agents already exist. |
| D2 | Flow: **BA → DESIGN → DEV + QA → DEP** | DESIGN produces/updates design docs (change staged in the `Pending/` overlay — see D13) before DEV/QA. |
| D3 | All new + reworked topic files live in **`issues/sdlc/`** | Single home for the reshape. |
| D4 | Architecture doc: **`01-architecture.md`** (the BC model) | Per user preference; numbered for reading order. |
| D5 | **Code SHAs** stay, enriched | Immutable per-run anchor tying a verdict to exact code (repro, diff, bisect); avoids copying code into run folders. Recorded with short SHA + commit message + date for human readability. |
| D6 | BA **injects local NFRs**, **inherits global NFRs** | Local = feature-specific, authored per story on Gherkin scenarios. Global = system-wide guardrails, referenced not authored. |
| D7 | Workflow/cycle state stays **YAML** | Consistency with existing YAML state + system-context files; inline comments; no net gain from JSON given existing YAML commitment. |
| D8 | **Two-tier configurable storage** (durable ledgers vs transient workspace) | Durable global assets benefit development even outside this tool; internals stay tool-scoped. |
| D9 | **Two nested state loops** (`workflow-state` outer, `dev-qa-cycle-state` inner) | SDLC-level vs DEV+QA verification level; same pattern, different scope. |
| D10 | Each completed User Story **updates all five durable ledgers** | SDLC-level definition of done. |
| D11 | **Git branch-per-story; runs = commits; git ops owned by the workflow layer; approval = human merge** | Branch = human/PR navigation view; per-run SHA (D5) = immutable anchor. `sda-dev` stays pure (writes files only); a workflow commit-helper script creates the branch and commits each run. Both gates PASS → housekeeper advises merge; human approves. |
| D12 | **`cycle-state` reframed as workflow-owned DEV+QA sub-state; renamed `dev-qa-cycle-state`** | It spans DEV↔QA (inter-BC orchestration), so it is not DEV-internal (that is `task-dev-agent-state.json`). Scripts renamed `dev-qa-cycle-state.*` + inner housekeeper `dev-qa-next-step.*`, grouped under the workflow script family. Called only by `dev-qa-next-step` + the human; the outer `workflow-*` scripts only enter the span and read its terminal verdict. Supersedes the `cycle-state`/`next-step` naming in P2-8. |
| D13 | **`Pending/` overlay for durable docs** (DESIGN first) | Proposed-but-unapproved durable-doc changes are written to a `paths.pendingChanges` tree mirroring the durable roots' structure, then **merged** into the real durable docs on story completion. Keeps durable docs approved-only. Distinct from system context's inline `pending-reverification` status (structured YAML) — the overlay suits prose docs. Readers may opt into approved-only or approved+pending. |
| D14 | **`sda-workflow` — the human's orchestration advisor** (scope A) | The DoD needs an enforcer and the human-driven pipeline is bookkeeping-heavy. `sda-workflow` is the only agent that reads `workflow-state.yaml`; it verifies state against the gate docs (DoR/DoD + `ledgers:` block + QA verdict) and runs the `workflow-*` scripts on confirmation. It **advises** the next functional step (e.g. “run `sda-dev` with this task”) but does **not** invoke BC agents — deterministic invocation is deferred. Extends the housekeeper guardrail; human stays final supervisor. |

### Open questions (resolve during implementation)
- **OQ-A** ✅ RESOLVED (D13): unapproved design specs are staged in a `Pending/`
  overlay mirroring the durable docs structure, then merged into the durable docs on
  story completion.
- **OQ-B** ✅ RESOLVED (split): QA owns the *test-case definitions*; system context
  records *which behaviors are verified* and links to the case that verifies each.
  **Two post-QA writers, one per BC** — `sda-dev-context-writer` (DEV) writes the
  system-context verified-status; `sda-qa-context-writer` (QA) promotes passed qa-task
  FRs into the known-test-case library. Both read the same `qa-report.md` and run
  independently (the case id derives from the behavior key, so neither blocks the other).
- **OQ-C** ✅ RESOLVED (D9, D12): nested — `workflow-state` (outer) delegates into
  `dev-qa-cycle-state` (inner); it does not subsume it.
- **OQ-D** ✅ RESOLVED: move both into `issues/sdlc/`. `qa_plus_system_context.md` is
  relocated as-is; [ai-sdlc.md](ai-sdlc.md) is relocated **and reworked** to align
  with this BC design direction (see S6-1).

---

## Impl steps (short)

Phases are SDLC-level (**S0–S6**); they wrap the existing QA/DEV internals
(**P1/P2/P3** from [qa_plus_system_context.md](qa_plus_system_context.md)).

```
S0  Skeleton & conventions
    - 01-architecture.md (the 5-BC model, flows, storage, state loops)
    - storage model: paths.* config (durable roots + transient root)
    - workflow-state.yaml schema + workflow-*.ps1/sh skeleton (outer loop)

S1  BA BC
    - sda-ba.agent.md (new)
    - user-story-schema.md (Actor + Gherkin FR/NFR; one-actor slicing)
    - global assets: definition-of-ready.md, definition-of-done.md, global-nfr.md
    - implemented-feature ledger schema (BA durable contribution)

S2  DESIGN BC
    - wire sda-system + sda-feature to consume User Story
    - produce/update system design docs (durable); mark change pending (OQ-A)

S3  QA wiring to BA
    - sda-qa-task consumes User Story Gherkin as primary FR source
    - known-test-case library schema (QA durable contribution)

S4  DEV wiring to BA
    - sda-dev-task consumes User Story instead of raw requirement
    - system context = DEV durable contribution (mostly P2/P3 already)

S5  DEP BC (placeholder)
    - deployment-context ledger schema; no agents yet (out of scope)

S6  QA/DEV/infra internals
    - execute existing P1 → P2 → P3 (folded in unchanged in substance)
    - relocate qa_plus_system_context.md into issues/sdlc/ (OQ-D)
```

Dependency order: **S0 → S1 → {S2, S3, S4} → S5 → S6** (S2/S3/S4 parallel after S1;
S6 internals interleave with S3/S4).

---

## Impl steps (detailed)

### S0 — Skeleton & conventions

**S0-1 `01-architecture.md`** (new, `issues/sdlc/`)
- The 5-BC model table (concern, agents, durable contribution).
- Flow diagram: BA → DESIGN → DEV+QA → DEP, with loops/escalations.
- Two-tier storage model + two nested state loops.
- Inter-BC contract: BCs receive requirement + output path only; orchestrator owns
  `workflow-state.yaml`.
- Per-workflow folder layout.
- This is the entity doc for the BC architecture; the plan references it.

**S0-2 Storage config** — extend `project-config.json` `paths.*`:
- Durable roots: `paths.baStandards` (DoR/DoD/global-NFR), `paths.design`,
  `paths.qaTestCases` (QA known test cases), `paths.devSystemContext` (exists),
  `paths.baFeatures` (BA implemented-feature docs), `paths.depContext`.
- Pending overlay: `paths.pendingChanges` (D13) — mirrors the durable roots; merged on story
  completion.
- Transient root: `paths.workflows` (per-workflow workspace), `paths.specs` (exists).
- Defaults chosen to be browsable (e.g. `docs/…` for durable, `.sda/…` for transient).

**S0-3 `workflow-state.yaml` schema + `workflow-*.ps1/sh`** (outer loop)
- Schema fields: `workflow-id`, `user-story`, `current-bc`
  (`BA|DESIGN|DEV|QA|DEP|done`), per-BC status + output path, escalations.
- Scripts (mirror the `dev-qa-cycle-state`/`dev-qa-next-step` pattern — the state
    manager is named after the state file, so two scripts, not three):
  - `workflow-state.ps1/sh` — `init`/`read`/`update`/`escalate` `workflow-state.yaml`:
    create a new story's state + per-BC folders, record a BC's output/status/ledger,
    advance `current-bc`, append escalations.
  - `workflow-next-step.ps1/sh` — report the single next BC action (housekeeper;
    MUST NOT trigger a BC agent — same guardrail as `dev-qa-next-step`).
- Guardrail: identical to the Housekeeper guardrail — advises, never triggers agents.

### S1 — BA BC

**S1-1 `sda-ba.agent.md`** (new)
- Single responsibility: requirement → **User Story**. Does not design or implement.
- Tools: `read`, `edit`, `search` (+ delegate to explore if needed). No `execute`.
- Behavior:
  - Enforce **DoR** before hand-off; refuse to mark "ready" until met.
  - **One actor statement per story** — reject multi-actor requests; force a split.
  - Author **Gherkin** FR scenarios (Given/When/Then, happy + negative + edge).
  - **Inject local NFRs** (feature-specific) onto scenarios; **inherit/link global
    NFRs** from `global-nfr.md` (reference, not author).
  - Update the **implemented-feature ledger** on story completion (BA durable
    contribution).
- Boundaries (DO NOT): design architecture, write code, author QA specs, touch
  `workflow-state.yaml`.

**S1-2 `user-story-schema.md`** (new)
- Two-layer structure:
  - Layer 1 — one Actor statement: `As a [role], I want [action], so that [benefit]`.
  - Layer 2 — Mx Gherkin scenarios (FR + local NFR), machine-readable.
- Rules: exactly one Layer-1 statement; ≥1 negative + ≥1 edge scenario; local NFRs
  attached to scenarios; global NFRs referenced by id.
- Entity doc — describes only the User Story document (no agent/workflow mentions).

**S1-3 Global assets** (new, under `paths.baStandards`)
- `definition-of-ready.md` — BA-owned gate checklist (unambiguous, testable,
  unblocked, Gherkin present).
- `definition-of-done.md` — system-wide quality gate (coverage threshold, security
  scan, all five ledgers updated).
- `global-nfr.md` — system-wide NFR guardrails (auth, compliance, global perf
  limits), each with a stable id for referencing.

**S1-4 Implemented-feature ledger schema** (new)
- Structured, human- + AI-readable record of *what is implemented from the BA view*.
- Updated per completed story; the BA durable contribution.

### S2 — DESIGN BC

**S2-1 Wire `sda-system` + `sda-feature`** to the BC model
- Input: the User Story (from BA output path).
- Output: create supporting design docs or update existing **system design docs**
  (durable, under `paths.design`).
- Write the design delta to the `Pending/` overlay (D13); it merges into
  `paths.design` on story completion.
- Apply the existing conflict-detection gate (P3-5) against system context.
- Boundaries: DESIGN does not author `## System Context Impact` (DEV's `sda-dev-task`
  owns that) and does not write code.

**S2-2 System design doc schema** (new or formalized)
- Durable per-project design ledger. A story's delta is staged in the `Pending/`
  overlay (D13) and merged into `paths.design` when the story completes.

### S3 — QA wiring to BA

**S3-1 `sda-qa-task` consumes User Story Gherkin**
- Primary FR source becomes the User Story's Gherkin scenarios (today: `task.md`).
- Keep existing NFR + regression logic (P1-2, P3-2).

**S3-2 Known-test-case library schema** (new, under `paths.qaTestCases`)
- Reusable, durable executable test-case definitions (QA contribution).
- Written post-QA by `sda-qa-context-writer` (QA-owned, OQ-B split): passed qa-task FRs
  are promoted into durable reusable cases; system-context behaviors link to them and
  record verified status (written by `sda-dev-context-writer`).

### S4 — DEV wiring to BA

**S4-1 `sda-dev-task` consumes User Story**
- Input requirement becomes the User Story (Actor + Gherkin), not a raw prompt.
- Reads DESIGN docs (`paths.design`, plus this story's `Pending/` overlay) as
  design context.
- Keep P3-1 (bootstrap + conflict gate + `## System Context Impact`).

**S4-2 System context = DEV durable contribution**
- Already delivered by P2/P3 (behaviors, decisions, dependency map). No new work
  beyond confirming it is the DEV ledger updated per story.

### S5 — DEP BC (placeholder)

**S5-1 Deployment-context ledger schema** (new, under `paths.depContext`)
- Per-part deployment details (durable). Schema only; no agents this phase.

### S6 — QA/DEV/infra internals (existing P1/P2/P3)

Execute the existing changeset from
[qa_plus_system_context.md](qa_plus_system_context.md), unchanged in substance,
in its documented order:
- **P1** — expert's QA changeset (NFRs, implicit requirements, supplement
  regression).
- **P2** — system context infrastructure + workflow scripts (P2-8 `cycle-state`/
  `next-step` are created under the D12 names `dev-qa-cycle-state`/`dev-qa-next-step`).
- **P3** — wire system context into the QA pipeline + conflict gates.

**Layering rule** — "unchanged in substance" is not literal: S1–S5 rewire files that
P1/P2/P3 produce (e.g. `sda-qa-task`, `sda-dev-task`, `sda-dev-context-writer`,
`sda-feature`/`sda-system`, the `paths.*` keys). Apply each P-item as the base layer,
then apply the S1–S5 delta targeting the same file on top, in the same file — the
S-delta wins where they differ. All `paths.*` keys reconcile to camelCase. Full
mapping in [DEV+QA internals](07-dev-qa-internals.md).

**S6-1** Relocate [qa_plus_system_context.md](qa_plus_system_context.md) into
`issues/sdlc/` as-is. Relocate **and rework** [ai-sdlc.md](ai-sdlc.md) to align
with this BC design (the D-decisions above — engine, state loops, storage tiers);
update any references.

---

## Contribution model (SDLC definition of done)

A User Story is **done** only when it has updated every durable ledger:

| BC | Ledger | Root |
|---|---|---|
| BA | Implemented-feature doc | `paths.baFeatures` |
| DESIGN | System design docs | `paths.design` |
| DEV | System context | `paths.devSystemContext` |
| QA | Known-test-case library | `paths.qaTestCases` |
| DEP | Deployment context | `paths.depContext` |

`definition-of-done.md` enforces this checklist.

---

## What is NOT in scope
- DEP agents (deployment automation) — schema/placeholder only.
- **Automated** agent invocation — `sda-workflow` (D14) assists the human (verify state,
  advise the next step, run the `workflow-*` scripts) but does not auto-invoke BC
  agents; the human executes each functional step. A deterministic invocation engine is
  deferred.
- Any change to the substance of P1/P2/P3 — folded in as-is.
