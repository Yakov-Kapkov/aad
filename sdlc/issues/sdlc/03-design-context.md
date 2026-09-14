# DESIGN Bounded Context

Specifies the **second** bounded context: DESIGN consumes the BA **User Story** and
produces or updates the durable **system design docs** (the *how* + decisions). It
reuses the existing `sda-system` → `sda-feature` pipeline unchanged in behaviour —
only the **input** (now a User Story) and the **output destination** (durable design
ledger, staged via the pending overlay) change.

Companion to [architecture](01-architecture.md),
[BA context](02-ba-context.md) (upstream BC), and
[implementation plan](00-implementation-plan.md) (roadmap, phase **S2**). This is the
DESIGN-BC design spec; the execution pass applies each block to the real tool files.

---

## Deliverables

| # | Artifact | Target | Kind |
|---|---|---|---|
| S2-1 | Wire `sda-system` + `sda-feature` to the BC model | `agents/sda-system.agent.md`, `agents/sda-feature.agent.md` | agent edits |
| S2-2 | System design doc schema (durable ledger + pending lifecycle) | `skills/sda-setup/assets/design/design-doc-schema.md` | new/formalized entity doc |

---

## S2-1 — Wire `sda-system` + `sda-feature`

The two agents keep their personas, `designOwnership` sparring behaviour, and the
`sda-system → sda-feature` handoff. Three changes fold them into the BC model.

### Input contract (BC-blind)
- The requirement input becomes the BA **User Story** (Actor + Gherkin), resolved from
  the output path the orchestrator provides — not raw user prose.
- DESIGN agents pressure-test the design **against the User Story's scenarios and its
  referenced global NFRs**. Dialogue with the human is unchanged; only the anchored
  requirement is now the story.
- **Blind to the workflow:** they never read the workflow id, `workflow-state.yaml`,
  or `dev-qa-cycle-state.yaml`. They receive a requirement + an output path only.

### Output → durable design ledger via the pending overlay
- `design.md` (system) and `feature.md` (feature) become the **durable design docs**
  under `paths.design` (the DESIGN durable contribution).
- A story's design change is written as a **delta to the pending overlay**
  (`paths.pendingChanges`, mirroring `paths.design`), **not** directly into the approved
  ledger. It **merges** into `paths.design` on story completion (D13).
- Readers may consume *approved-only* or *approved + pending*.

### Conflict-detection gate
- Before writing, run the existing **conflict-detection gate (P3-5)** against the
  current **system context** (`paths.devSystemContext`): a proposed design change that
  contradicts a recorded behaviour/decision must be surfaced and resolved, not
  silently applied. (See P3-5 in
  [qa_plus_system_context.md](qa_plus_system_context.md).)

### Read-list additions (both agents)

| File | Path |
|---|---|
| user-story.md (input) | provided output path from BA |
| design-doc-schema.md | `.sda/resources/design-doc-schema.md` |
| system context | `{paths.devSystemContext}/…` (read-only, for the conflict gate) |

The existing `paths.design` key is repurposed as the durable design ledger (see the
reconciliation note in [architecture](01-architecture.md)); its default moves
`.sda/design` → `docs/design` and the transient scratch role folds into `paths.workflows`.

### Boundaries (DO NOT)
- Author `## System Context Impact` — that section is owned by DEV's `sda-dev-task`.
- Write code, tests, or QA specs.
- Write directly into the approved `paths.design` — always stage in the pending
  overlay first.
- Touch `workflow-state.yaml` or any state file.

---

## S2-2 — System design doc schema

Formalizes the **durable design ledger** and its pending lifecycle. The ledger is the
existing `design.md` + `feature.md` documents (schemas already defined inside
`sda-system` / `sda-feature`), relocated to `paths.design` and governed by the
overlay lifecycle below.

### Durable design ledger
- `paths.design/design.md` — system-level architecture, standards, domain model.
- `paths.design/{feature}/feature.md` — per-feature design + decisions.
- Both are **approved-only**; browsable and tool-agnostic.

### Pending → merge lifecycle
1. A story's change is written to `paths.pendingChanges`, mirroring the `paths.design`
   tree (e.g. `paths.pendingChanges/design.md`, `paths.pendingChanges/{feature}/feature.md`).
2. It stays there through DEV + QA, available to downstream BCs as *pending* context.
3. On **story completion**, the pending delta merges into `paths.design`; the
   pending entry is cleared.
4. Distinct from system context's inline `pending-reverification` status — the overlay
   suits prose design docs; the inline status suits structured YAML.

### Rules
- Entity doc — describes only the design documents + overlay lifecycle; names no agent
  or workflow phase.
- A design delta references the source `user-story.md`; it does not copy scenarios.
- Superseding a prior design decision is explicit (marked, dated), never silent.

---

## Open items for execution (S2)
- Edit `sda-system` + `sda-feature`: input = User Story; output staged to pending
  overlay; add the read-list rows; add the conflict-gate + boundary rules.
- Update [AGENTS.md](../../AGENTS.md): dependency-matrix rows for `design-doc-schema.md`,
  `paths.design`, `paths.pendingChanges`; note `paths.design` is repurposed as the
  durable design ledger; reflect the User-Story input in the design-pipeline description.
- Update tool [README.md](../../README.md): pipeline now BA → DESIGN, design docs
  durable.
- Add `paths.design` (+ pending merge) to `project-config.example.json` /
  `.reference.yml`; formalize `design-doc-schema.md` in sda-setup assets.
