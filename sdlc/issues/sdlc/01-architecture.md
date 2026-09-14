# SDLC Bounded Contexts

The canonical architecture doc for SDA-as-an-SDLC. It defines the five bounded
contexts (BCs), the flow that connects them, the two-tier storage model, and the
two nested state loops that drive a User Story from requirement to deployment.

This is the **entity doc** for the BC architecture; the
[implementation plan](00-implementation-plan.md) references it. It is descriptive
(the *what* and *how* of the architecture), not a task list.

---

## Scope

- **In:** the BC model, inter-BC contract, storage tiers, state loops, folder layout,
  the SDLC definition of done.
- **Out:** per-BC internals (agent behaviour, schemas) — those live in each BC's own
  assets. Execution order — that lives in the implementation plan.

---

## The five bounded contexts

SDA is **one system with five bounded contexts**. Each is single-concern, owns its
own agents/assets, and communicates only through the shared workflow layer.

| # | BC | Concern (what it owns) | Agents | Durable contribution per story |
|---|---|---|---|---|
| 1 | **BA** | Requirement — the *what/why* | `sda-ba` *(new)* | Implemented-feature ledger |
| 2 | **DESIGN** | Architecture/feature *how* + decisions | `sda-system`, `sda-feature` | System design docs |
| 3 | **DEV** | Code implementing the task | `sda-dev-task`, `sda-dev`, `sda-dev-context-writer` (+ TDD leaves) | System context |
| 4 | **QA** | Verify against User Story + global NFR | `sda-qa-task`, `sda-qa`, `sda-qa-context-writer` | Known-test-case library |
| 5 | **DEP** | Deployment | *(none yet — out of scope)* | Deployment context |

---

## Flow

A User Story moves left to right; the **DEV + QA** span is a loop, not a single pass.

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

### Loops and escalations
- **DEV + QA loop:** implement → QA-primary → QA-regression → rework, repeating until
  both gates PASS. Governed by the inner state loop (below).
- **Escalation backward:** a BC may reject its input and send the story back one BC
  (e.g. QA finds the User Story untestable → back to BA; DEV finds the design
  infeasible → back to DESIGN). The orchestrator records the escalation and re-enters
  the earlier BC.
- **Terminal:** when DEV + QA both PASS and the human approves the merge, the story
  advances to DEP, then `done` once all five durable ledgers are updated.

---

## Two-tier storage model

Storage is split by **durability**, not by BC. All roots are configurable via
`project-config.json` `paths.*`.

| Tier | Contents | Location (default) | Audience |
|---|---|---|---|
| **Durable ledgers** | global NFR/DoR/DoD, system design docs, known-test-case library, system context, implemented-feature docs, deployment context | project-level roots (browsable, committed, tool-agnostic) | Everyone, incl. devs outside this tool |
| **Transient workspace** | `task.md`, `qa-task.md`, run folders, reports, cycle state, agent state | tool-scoped root | The tool only |
| **Pending overlay** | proposed-but-unapproved durable-doc changes | mirrors the durable roots | Reviewers, until story completes |

### `paths.*` keys

Config keys follow the existing camelCase convention (`standardsSkill`,
`designOwnership`). New durable + transient roots:

| Key | Tier | Holds | Default |
|---|---|---|---|
| `baStandards` | durable | `definition-of-ready.md`, `definition-of-done.md`, `global-nfr.md` | `docs/standards` |
| `design` | durable | system design docs (DESIGN contribution) | `docs/design` |
| `qaTestCases` | durable | known-test-case library (QA contribution) | `docs/test-cases` |
| `devSystemContext` | durable | behaviors, decisions, dependency map (DEV contribution) | `docs/system-context` |
| `baFeatures` | durable | implemented-feature docs (BA contribution) | `docs/features` |
| `depContext` | durable | per-part deployment details (DEP contribution) | `docs/deployment` |
| `pendingChanges` | overlay | staged durable-doc changes, mirrors the roots above | `.sda/pending` |
| `workflows` | transient | per-workflow workspace (`workflow-<id>/`) | `.sda/workflows` |
| `specs` *(exists)* | transient | contract specs | `.sda/specs` |

**Reconciliation with existing config.** The existing `paths.design` key is
repurposed as the durable design ledger — its default moves `.sda/design` →
`docs/design`, and its transient scratch role folds into `workflows`. No separate
`designDocs` key is introduced. Existing
`paths.specs`, `paths.secrets` are unchanged; `paths.tasks` / `paths.features` /
`paths.issues` are **dropped in E4b** (task/feature/QA creation is workflow-only —
output folders come from the workflow, not config). Defaults above are
browsable (`docs/…` durable, `.sda/…` transient) but every key is overridable.

### Pending overlay

Durable docs stay **approved-only**. A story's proposed change is written to a
`paths.pendingChanges` tree that mirrors the durable roots' structure, then **merged** into
the real durable docs when the story completes. Readers may opt into *approved-only*
or *approved + pending*. This suits prose docs (system design docs first); it is
distinct from system context's inline `pending-reverification` status, which suits
structured YAML.

---

## State: two nested loops

The workflow is **data + a transition script**, never hard-coded into an
orchestrator. Same script *pattern* (init / read / advance) at two scopes, both owned
by the **workflow layer**.

| Loop | Scope | State file | Scripts |
|---|---|---|---|
| **Outer — SDLC workflow** | a User Story across BA→DESIGN→DEV→QA→DEP | `workflow-state.yaml` | `workflow-state`, `workflow-next-step` (`.ps1/.sh`) |
| **Inner — DEV + QA cycle** | one dev task's implement/QA/rework runs | `dev-qa-cycle-state.yaml` | `dev-qa-cycle-state`, `dev-qa-next-step` (`.ps1/.sh`) |

The outer scripts **delegate into** the inner cycle when a story enters the DEV + QA
span and read only its **terminal verdict** to advance — they never manage individual
runs. The inner cycle is driven by `dev-qa-next-step` + the human, the only callers of
`dev-qa-cycle-state`. BCs never read either state file. (The inner cycle and its
scripts are created in the P2 changeset under these names — see
[qa_plus_system_context.md](qa_plus_system_context.md) and D12 in the plan.)

### `workflow-state.yaml` (outer) schema

```yaml
workflow-id: 0007-user-login
user-story: BA/user-story.md          # path to the Actor + Gherkin story
current-bc: DEV                       # BA | DESIGN | DEV | QA | DEP | done
branch: story/0007-user-login         # git branch-per-story (D11)
bcs:
  - bc: BA
    status: done                      # pending | active | done | escalated
    output: BA/user-story.md
  - bc: DESIGN
    status: done
    output: DESIGN/design-delta.md    # staged in the pending overlay until done
  - bc: DEV
    status: active
    output: DEV/task.md
    cycle: DEV/dev-qa-cycle-state.yaml # inner loop handle; read verdict only
  - bc: QA
    status: pending
    output: QA/qa-task.md
  - bc: DEP
    status: pending
    output: DEP/
escalations:                          # backward sends, append-only
  - from: QA
    to: BA
    reason: US-3 not testable as written
ledgers:                              # SDLC definition of done (D10)
  ba: pending                         # implemented-feature doc updated?
  design: pending
  dev: pending
  qa: pending
  dep: pending
```

Written only via `workflow-*.ps1/sh`, by the human (or a future engine). No BC agent
writes it. A BC may read its own resolved output path — never the workflow id or
sibling state.

### `workflow-*` script contract

The state manager is named after the state file (mirroring the inner
`dev-qa-cycle-state`), so the outer loop is two scripts, not three.

| Script | Reads | Does | Never |
|---|---|---|---|
| `workflow-state` | `workflow-state.yaml` | `init`/`read`/`update`/`escalate`: create a story's state + per-BC folders, record a BC's output + status + ledger, advance `current-bc`, append escalations | run git; trigger a BC agent |
| `workflow-next-step` | `workflow-state.yaml` (+ inner verdict) | reports the single next BC action (housekeeper) | trigger a BC agent |

### Housekeeper guardrail

`workflow-next-step` / `dev-qa-next-step` (and any future housekeeper) **MAY**: update
their state file, record verdicts/ledger status, run helper scripts, compute + report
the single next step.

They **MUST NOT** trigger the next functional agent (`sda-ba`, `sda-system`,
`sda-feature`, `sda-dev-task`, `sda-dev`, `sda-qa-task`, `sda-qa`). Bookkeeping and
"here is what is next" only — the human (or a future engine) executes the next step.
This keeps humans in control, prevents runaway agent chains, and keeps every agent
single-responsibility and non-chaining.

### Git model (D11)

- **Branch per story** — human/PR navigation view; the branch pointer advances with
  every run.
- **Runs = commits; per-run SHA** — the immutable anchor tying a QA verdict to exact
  code (recorded in `dev-qa-cycle-state.yaml` with short SHA + message + date).
- **Git ops owned by the workflow layer** — a commit-helper script creates the branch
  and commits each run. `sda-dev` stays pure (writes files only).
- **Approval = human merge** — both gates PASS → housekeeper advises merge; the human
  approves.

---

## Inter-BC contract (BCs blind, orchestrator sees all)

- A BC receives only **a requirement + an output path**. It never reads the workflow
  id, `workflow-state.yaml`, or `dev-qa-cycle-state.yaml`.
- The **orchestrator** (human via `workflow-*.ps1/sh` today; an engine later) reads
  each BC's output and advances state.
- The BC writes its result to the given output path and returns. Any escalation is a
  return signal the orchestrator records — the BC does not route the story itself.

This is what makes the workflow engine-swappable with zero BC rework: the transition
logic lives entirely in the state file + scripts, never inside a BC.

---

## Orchestration assistant (`sda-workflow`)

The workflow layer is human-driven; `sda-workflow` is the human's **advisor** over it —
not an automated engine. It is the only agent that consumes the workflow state — read
through the `workflow-state` script (never the raw `workflow-state.yaml`; the YAML format
is owned by that script) — and it verifies the current state against the governing
documents before advising the next step.

- **Reads:** the **workflow state** via `workflow-state read` and the inner cycle's
  terminal verdict via `dev-qa-next-step` (never the raw state YAML), plus the gate docs
  for the current transition — `definition-of-ready.md` (entering DEV),
  `definition-of-done.md` + the `ledgers:` block + QA verdict (entering `done`).
- **Verifies:** maps each gate line to a real signal and reports pass/fail per line.
  DoD becomes its machine-checked completion gate — it refuses to advance to `done`
  until all five ledgers are `done`, both QA gates PASS, and the human has approved the
  merge.
- **Runs:** the workflow CLI scripts (`workflow-state`, `workflow-next-step`; inner
  `dev-qa-next-step`) on human confirmation. It never writes state directly — the
  scripts do (state stays *written only via the workflow scripts*).
- **Advises, never triggers (scope A):** it names the next action for the human — e.g.
  *“DEV task ready → run `sda-dev` and pass it `DEV/task.md`”* — but does **not**
  invoke BC agents. Deterministic agent invocation is a separate, later concern; the
  human is the final supervisor and executes each functional step.

**Tools:** `read`, `execute` (CLI scripts), `agent` (research only) — no `edit`.

**Output presentation.** Every document `sda-workflow` names to the human is a
**clickable link** for navigation. Preferred form: the human-readable label as plain
text, with the link in parentheses — e.g. *“`User Story 123` ([user-story.md](…)) is
ready and complies with the DoR ([definition-of-ready.md](…))”*. Applies to every file
it references — the user story, gate docs (DoR/DoD), design docs, `qa-report.md`, the
task, the ledgers — so the human can jump straight to the evidence behind each verdict.

**Boundaries:** never edits durable docs, code, or state files; never authors a BC's
output; every state transition is human-approved. BCs stay blind; `sda-workflow` is the
sole workflow-state reader. It **extends, not replaces** the housekeeper guardrail:
`workflow-next-step` still computes “what is next”; `sda-workflow` adds document-aware
gate verification and human-facing guidance on top, and still never triggers a BC agent.

---

## Per-workflow folder layout

```
{paths.workflows}/workflow-<id>/
  workflow-state.yaml        ← orchestrator-owned; BCs never touch it
  BA/     user-story.md (Actor + Gherkin), local NFRs
  DESIGN/ feature/design deltas (also staged in {paths.pendingChanges})
  DEV/    task.md, runs/, dev-qa-cycle-state.yaml (per-run SHAs)
  QA/     qa-task.md, qa-report.md
  DEP/    (placeholder)
```

Durable contributions do **not** live here — they are written (or staged via the
pending overlay) to the durable roots under `paths.*`.

---

## SDLC definition of done

A User Story is **done** only when it has updated **every** durable ledger. The
`ledgers` block in `workflow-state.yaml` tracks it; `definition-of-done.md` enforces
it.

| BC | Ledger | Root |
|---|---|---|
| BA | Implemented-feature doc | `paths.baFeatures` |
| DESIGN | System design docs | `paths.design` |
| DEV | System context | `paths.devSystemContext` |
| QA | Known-test-case library | `paths.qaTestCases` |
| DEP | Deployment context | `paths.depContext` |
