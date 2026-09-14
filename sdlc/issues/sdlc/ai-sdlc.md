# AI-Driven SDLC — SDA Architecture Overview

The SDA SDLC is a **five bounded-context model** driven by two nested state loops
with two-tier storage. This doc is the high-level reference; the canonical
architecture lives in [01-architecture.md](01-architecture.md).

---

## Five Bounded Contexts

A User Story moves left to right through five BCs. DEV + QA form a loop, not a
single pass.

| # | BC | Concern | Agents | Durable contribution |
|---|---|---|---|---|
| 1 | **BA** | Requirement — the *what/why* | `sda-ba` | Implemented-feature ledger |
| 2 | **DESIGN** | Architecture/feature *how* + decisions | `sda-system`, `sda-feature` | System design docs |
| 3 | **DEV** | Code implementing the task | `sda-dev-task`, `sda-dev`, `sda-dev-context-writer` (+ TDD leaves) | System context |
| 4 | **QA** | Verify against User Story + global NFR | `sda-qa-task`, `sda-qa`, `sda-qa-context-writer` | Known-test-case library |
| 5 | **DEP** | Deployment | *(none yet)* | Deployment context |

```
requirement
   │
   ▼
 ┌────┐    ┌────────┐    ┌───────────── DEV + QA ─────────────┐    ┌─────┐
 │ BA │──▶ │ DESIGN │──▶ │  implement ⇄ verify ⇄ rework (loop) │──▶ │ DEP │──▶ done
 └────┘    └────────┘    └────────────────────────────────────┘    └─────┘
   │           │                        │                             │
 story      design                  both gates                    deploy
 ready      staged                    PASS                         context
```

### Escalations

A BC may reject its input and send the story back one BC (e.g., QA finds the User
Story untestable → back to BA; DEV finds the design infeasible → back to DESIGN).
The orchestrator records the escalation in `workflow-state.yaml` and re-enters the
earlier BC.

---

## Two Nested State Loops

The workflow is **data + transition scripts**, never hard-coded into an
orchestrator. Two scopes, same pattern.

| Loop | Scope | State file | Scripts |
|---|---|---|---|
| **Outer — SDLC workflow** | a User Story across BA→DESIGN→DEV→QA→DEP | `workflow-state.yaml` | `workflow-state`, `workflow-next-step` |
| **Inner — DEV + QA cycle** | one dev task's implement/QA/rework runs | `dev-qa-cycle-state.yaml` | `dev-qa-cycle-state`, `dev-qa-next-step` |

### Outer loop (`workflow-state.yaml`)

Tracks the story's progress across all five BCs. Owned by the workflow layer;
written only via `workflow-state` (`init`/`read`/`update`/`escalate`).
`workflow-next-step` reads it and reports the single next BC action — never
triggers an agent.

BC agents never read `workflow-state.yaml`. They receive a caller-provided output
path and treat it as opaque. The `workflow-state read` action is the only
interface BC agents use to discover their working folder.

### Inner loop (`dev-qa-cycle-state.yaml`)

Drives the DEV + QA span: `implementing` → `qa-primary` → `qa-regression` →
`passed` (or `rework`). A rework creates a new run folder; each run is a normal
`task.md` → implement → QA cycle. The inner loop is driven by `dev-qa-next-step`
+ the human.

The outer scripts read only the inner loop's **terminal verdict** to advance —
they never manage individual runs.

### Housekeeper guardrail

`workflow-next-step` / `dev-qa-next-step` **MAY**: update their state file,
record verdicts/ledger status, run helper scripts, compute + report the single
next step.

They **MUST NOT** trigger the next functional agent. Bookkeeping and "here is
what is next" only — the human executes the next step. This keeps humans in
control, prevents runaway agent chains, and keeps every agent
single-responsibility.

---

## Two-Tier Storage

Storage is split by **durability**, not by BC. All roots are configurable via
`project-config.json` `paths.*`.

| Tier | Contents | Default location | Audience |
|---|---|---|---|
| **Durable ledgers** | global NFR/DoR/DoD, design docs, test-case library, system context, implemented-feature docs, deployment context | `docs/…` (committed, tool-agnostic) | Everyone |
| **Transient workspace** | `task.md`, `qa-task.md`, run folders, reports, cycle state, agent state | `.sda/workflows/` (tool-scoped) | The tool only |
| **Pending overlay** | proposed-but-unapproved durable-doc changes | `.sda/pending/` | Reviewers, until story completes |

### Durable ledger per BC

| BC | Ledger | `paths.*` key | Default |
|---|---|---|---|
| BA | Implemented-feature docs | `baFeatures` | `docs/features` |
| DESIGN | System design docs | `design` | `docs/design` |
| DEV | System context (behaviors, decisions, dependency map) | `devSystemContext` | `docs/system-context` |
| QA | Known-test-case library | `qaTestCases` | `docs/test-cases` |
| DEP | Deployment context | `depContext` | `docs/deployment` |

Plus gate templates: `baStandards` → `docs/standards` (DoR, DoD, global NFR).

### Definition of Done

A story is `done` when all five durable ledgers are updated **and** both QA
gates (primary + regression) PASS **and** the human approves the merge. The
`ledgers:` block in `workflow-state.yaml` tracks each BC's ledger status
(`pending` → `done`).

---

## BC-Blindness Invariant

BC agents never read workflow state. They receive a requirement + an output
path and treat the path as opaque. State is read only via each script's `read`
action — never by opening `workflow-state.yaml` or `dev-qa-cycle-state.yaml`.

Path creation is workflow-only: `sda-workflow` runs `workflow-state init` to
create the per-BC subfolders. A task-folder agent invoked without a
caller-provided output path fails a blocking gate — no standalone fallback.

---

## Git Model

- **Branch per story** — human/PR navigation view.
- **Runs = commits** — each run's SHA is recorded in `dev-qa-cycle-state.yaml`.
- **Git ops owned by the workflow layer** — a commit-helper script creates the
  branch and commits each run. `sda-dev` writes files only.
