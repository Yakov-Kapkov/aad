# System Context — Design Findings

Design decisions captured from discussion on 2026-06-29. Ready for implementation.

---

## What System Context Is

SDA already has two context layers:
- **Design-time**: `design.md`, `feature.md` — architecture decisions, static
- **Task-time**: `task.md`, `dev-report.md` — per-task specs and implementation records

The missing layer:
- **Verified-behaviour context** — accumulating record of what the system is confirmed to do, post-verification, across all tasks

Without this layer every QA run is stateless: it can only verify the current task's FRs. It has no ground truth for regression.

---

## Core Design Principle

> System context captures **WHY** and **WHAT IS VERIFIED** — never **WHAT EXISTS**.

Forbidden in system context:
- File listings, class/method inventories
- Database schema dumps
- Any structural information already derivable from reading the code

Allowed:
- Verified behavioural claims ("POST /auth/login returns 200 + token on valid credentials — confirmed")
- Architectural decisions + rationale ("Optimistic locking chosen — read-heavy, low contention")
- Coarse-grained component dependency graph (for regression blast-radius analysis)

---

## Location

Visible in the repo — NOT hidden in `.sda/`. Configurable via `paths.system-context` in `project-config.json`. Default: `system-context/` at repo root (or a project-chosen location). Committed and version-controlled alongside code.

---

## File Structure

```
system-context/
  index.yaml              — domain registry
  dependency-map.yaml     — coarse-grained component dependency graph (intra + cross-domain)
  {domain}.yaml           — per-domain: verified behaviors + architectural decisions
  cross-domain.yaml       — behaviors that span ≥ 2 domains
```

---

## index.yaml

Domain registry only. No behaviors, no decisions.

```yaml
project: my-app
last_updated: 2026-06-29
domains:
  - name: auth
    file: system-context/auth.yaml
  - name: payment
    file: system-context/payment.yaml
```

---

## dependency-map.yaml

Coarse-grained component graph. Contains only components that are **behaviourally significant** — entry points and components whose change can alter observable behaviour. Not exhaustive. Curated.

`path` is a **locator** (where to find the component in the codebase), NOT a matching key. Never used for mechanical file-path matching.

```yaml
components:
  - id: auth-api
    type: api
    path: src/api/auth/
    domain: auth
  - id: payment-api
    type: api
    path: src/api/payment/
    domain: payment
  - id: token-service
    type: service
    path: src/services/TokenService.ts
    domain: auth
  - id: user-repo
    type: repository
    path: src/repositories/UserRepository.ts
    domain: auth

dependencies:
  - from: auth-api
    to: [token-service, user-repo]
  - from: payment-api
    to: [auth-api]                    # cross-domain dependency
  - from: token-service
    to: [user-repo]
```

Regression walk: "token-service changed" → reverse-traverse edges → `auth-api` → `payment-api`. Both domains at risk.

Node types: `api`, `service`, `repository`, `external`, `ui`.

---

## {domain}.yaml

Per-domain file. Two sections: `decisions` and `behaviors`.

### decisions
Architectural choices with rationale. No task references required.

```yaml
decisions:
  - id: D001
    summary: "Optimistic locking over Redis-based locking"
    rationale: "Read-heavy workload, low contention — DB-level versioning is sufficient"
    status: active          # active | superseded
    superseded_by: null
```

Status field: `active` or `superseded`. When superseded, `superseded_by` names the decision that replaced it.

### behaviors
Verified observable behaviours. Linked to dependency-map component IDs. No task references required.

```yaml
behaviors:
  - id: B001
    claim: "POST /auth/login returns 200 + token on valid credentials"
    via: auth-api
    status: verified        # verified | pending-reverification
    note: null
  - id: B002
    claim: "POST /auth/login rate-limits to 5 attempts per IP per minute"
    via: auth-api
    status: pending-reverification
    note: "auth-api modified in task 012 — not covered by that QA run"
```

Status field:
- `verified` — confirmed by a QA run
- `pending-reverification` — in blast radius of a recent change, not yet re-verified

---

## cross-domain.yaml

Behaviours whose entry point spans ≥ 2 domains. Same structure as domain `behaviors` section, but `via` is an array.

```yaml
behaviors:
  - id: XB001
    claim: "Payment is rejected if auth token is expired"
    via: [auth-api, payment-api]
    domains: [auth, payment]
    status: verified
```

---

## Component Impact Declaration in task.md

**Key decision**: `sda-context-writer` does NOT infer affected components from git diff file paths (file paths are not firm evidence of semantic impact). Instead, `sda-dev-task` declares affected components explicitly in the task spec at design time.

A new optional section in `task-schema.md`:

```markdown
## System Context Impact
affected_components: [token-service, auth-api]
decisions_affected: []        # IDs of decisions being superseded or amended
```

- Authored by `sda-dev-task` at design time
- Reviewed and confirmed by user as part of task approval
- Read by `sda-context-writer` post-QA to determine which behaviors to update
- Mandatory when the task's blast radius overlaps the dependency map; omitted for tasks that introduce only new components

For **manual changes** (no task.md): user tells `sda-context-writer` which component IDs were affected when invoking it. The agent may inspect git diff as a prompt to suggest candidates, but the user confirms.

---

## pending-reverification Lifecycle

```
sda-dev-task authors task.md
  → includes ## System Context Impact with affected_components

sda-dev implements → sda-qa verifies → sda-qa writes qa-report.md

sda-context-writer runs (invoked after QA):
  1. Read task.md ## System Context Impact → get affected_components list
  2. Walk dependency-map.yaml reverse-edges → expand blast radius
  3. Read qa-report.md → find which behaviors were explicitly covered
  4. For behaviors linked to affected/blast-radius components:
       - Covered in qa-report, PASS → status: verified
       - Covered in qa-report, FAIL → status: pending-reverification + note
       - NOT covered in qa-report  → status: pending-reverification + note

sda-qa-task (next task or standalone):
  → reads system context for affected domains
  → finds all status: pending-reverification behaviors
  → generates mandatory regression FRs for each one

sda-qa runs regression FRs alongside new task FRs

sda-context-writer runs again (post that QA):
  → resolves pending behaviors → verified (if passed) or keeps pending (if failed)
```

`pending-reverification` is never silently cleared. Accumulating pending behaviors are a visible signal of regression debt.

---

## Regression Testing — FRs vs pending-reverification

`pending-reverification` statuses are the **source**; FRs are the **carrier**.

`sda-qa` only executes FRs. `sda-qa-task` translates `pending-reverification` behaviors into FRs when building qa-task.md. The qa-task.md ends up with two FR categories:

| FR source | Purpose |
|---|---|
| Task acceptance criteria | Verify new behaviour works |
| `pending-reverification` behaviors | Verify existing behaviour wasn't broken |
| Secondary: blast-radius neighbors | Precautionary regression coverage |

As the system grows, regression FRs become a larger share of each qa-task.md automatically.

---

## Conflict Detection Gate

When an agent is about to propose or implement something that contradicts an architectural decision or would invalidate a verified behavior → **hard stop + confirmation**. Not a warning.

Gate format:
```
⚠️ System Context Conflict

This request contradicts:
  Decision D001: "Optimistic locking over Redis-based locking" [auth.yaml]
  Verified behaviors at risk: B001, B002 [auth.yaml]
  Downstream impact: payment-api depends on auth-api (dependency-map)

Proceeding will require:
  — D001 marked superseded
  — B001, B002 marked pending-reverification
  — Regression check on payment domain

Confirm to proceed, or revise the request.
```

Gate applies to:

| Agent | When | Mode |
|---|---|---|
| `sda-dev-task` | Proposed design contradicts a decision or alters a verified behavior's entry point | Always |
| `sda-feature` | Feature scope overlaps a decision constraint | Always |
| `sda-system` | System-level change contradicts active decisions | Always |
| `sda-dev` | Ad-hoc mode only — no prior task spec vetting | Ad-hoc only |
| `sda-dev` | Task mode — task was already vetted by sda-dev-task | No gate |

`sda-qa` does not gate — it verifies and reports, never blocks design.

---

## sda-dev-task Bootstrap Instructions (summary)

On every invocation:
1. Read `index.yaml` + domain files for task's affected domains
2. Read `dependency-map.yaml`
3. Apply conflict detection gate before writing any spec section
4. Include blast-radius domains in task's `## Regression Risks` section
5. Author `## System Context Impact` section with affected component IDs

---

## sda-qa-task Bootstrap Instructions (summary)

On every invocation:
1. Read system context for all domains touched by the task (and blast-radius neighbors)
2. Find all `status: pending-reverification` behaviors in those domains
3. Generate a mandatory regression FR for each pending behavior — not optional
4. Include alongside task-derived FRs in qa-task.md

---

## sda-context-writer Agent (summary)

New agent. Tools: `read`, `edit`, `execute` (for git diff as secondary signal).

Two invocation modes:
- **Post-task**: invoked after QA passes. Reads task.md + qa-report.md. Updates domain files and dependency map.
- **Manual**: invoked by developer after a manual code change. User provides affected component IDs. Agent may suggest candidates from git diff; user confirms.

**Setup mode**: on fresh SDA install, reads `design.md` if it exists, bootstraps skeleton domain files with architectural decisions. Empty `behaviors` tables.

---

## project-config.json Addition

```json
"paths": {
  "system-context": "system-context"
}
```

Default: `system-context/` at repo root. Overridable per project.

---

## task-schema.md Addition

New optional section:

```markdown
## System Context Impact
affected_components: []          # existing component IDs whose behaviour may change
new_components: []               # new component IDs to register in dependency-map.yaml
new_domain:                      # name of new domain file to create (omit if none)
decisions_affected: []           # decision IDs being superseded or amended
```

Rules:
- `affected_components`: list existing dependency-map IDs touched by this task. Triggers `pending-reverification` for linked behaviors + blast-radius walk.
- `new_components`: list IDs for brand-new components. `sda-context-writer` resolves their definition (type, path, depends_on) from the task's `## Design Approach`.
- `new_domain`: present only when a new domain file must be created and registered in `index.yaml`.
- Section is omitted entirely for tasks that touch no existing components and add no new ones.

### New component update flow

**Pure addition** (new component, no wiring into existing flows):
- No existing behaviors disrupted → nothing goes `pending-reverification`
- `sda-context-writer`: adds node + edges to `dependency-map.yaml`, creates domain file if new domain, adds `status: verified` behaviors from `qa-report.md`

**Addition with wiring** (new component inserted into an existing flow):
- Existing components whose flow changed are listed in `affected_components`
- Their linked behaviors go `pending-reverification` (the new component is now in their path)
- `new_components` and `affected_components` are both populated

Example — new caching layer inserted between `auth-api` and `token-service`:
```markdown
## System Context Impact
affected_components: [auth-api]       # existing flow changed
new_components: [token-cache]         # new component added
new_domain:
decisions_affected: []
```

---

## Open Questions

### OQ-1 — Does `pending-reverification` enforce anything? (SDLC workflow)

As designed, `pending-reverification` is a **passive flag**. Its only active effect is that `sda-qa-task` must generate mandatory regression FRs for pending behaviors. If `sda-qa-task` is not invoked, or the user skips QA entirely, the flag sits unresolved.

The actual gate downstream is a **FAIL result** from `sda-qa` on a regression FR — that signals known-bad state. `pending-reverification` alone signals unknown state (not tested, not failed).

Open question: should the SDLC pipeline enforce that pending behaviors are resolved before a task cycle is considered complete? This is a workflow-level decision — it implies a project-level state machine where a task cannot transition to `done` while related behaviors remain pending. See `sdlc/ai-sdlc.md` for the state machine idea.

---

## What Is NOT Designed Yet (implementation plan in `sdlc/qa_plus_system_context.md`)

The items below are specified in `sdlc/qa_plus_system_context.md` but not yet implemented:

- `sda-context-writer.agent.md` — new agent (P2-4)
- `system-context-schema.md` — schema file for sda-setup to scaffold (P2-1)
- CLI scripts in `.sda/scripts/system-context/` — `components.ps1`, `edges.ps1`, `behaviors.ps1`, `decisions.ps1`, `domains.ps1`, `blast-radius.ps1` (P2-7)
- Updates to `sda-dev-task.agent.md` — bootstrap + conflict gate + System Context Impact section (P3-1)
- Updates to `sda-qa-task.agent.md` — primary regression from pending-reverification + regression-only mode (P3-2)
- Updates to `sda-dev.agent.md` — ad-hoc mode gate (P3-3)
- Updates to `sda-feature.agent.md` + `sda-system.agent.md` — conflict detection gate (P3-6)
- `sda-qa-orc.agent.md` — new user-triggered QA orchestrator (P3-5)
- `paths.system-context` in project-config.json schema (P2-3)
- Updates to `task-schema.md` — System Context Impact section (P2-2)
- Updates to `AGENTS.md` dependency matrix — all new agents, schemas, paths (P2-6, P3-4)
- Updates to `sda-setup` skill — scaffold `system-context/` + install scripts (P2-5)
