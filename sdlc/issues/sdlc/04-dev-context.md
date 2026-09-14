# DEV Bounded Context

Specifies how DEV wires to BA: `sda-dev-task` takes the BA **User Story** (Actor +
Gherkin) as its requirement input instead of a raw prompt, reads DESIGN docs as
context, and DEV's durable contribution — the **system context** (behaviors,
decisions, dependency map) — is confirmed as the per-story DEV ledger.

Companion to [architecture](01-architecture.md),
[BA context](02-ba-context.md) (upstream requirement source),
[DESIGN context](03-design-context.md) (design context DEV reads),
and [implementation plan](00-implementation-plan.md) (roadmap, phase **S4**). DEV's
internal machinery (TDD loop, `sda-dev`, system-context bootstrap + conflict
gate) is defined in the P1/P2/P3 changeset of
[qa_plus_system_context.md](qa_plus_system_context.md) and executed in **S6**;
this doc only adds the BA linkage and confirms the durable ledger.

---

## Deliverables

| # | Artifact | Target | Kind |
|---|---|---|---|
| S4-1 | `sda-dev-task` consumes the User Story + reads DESIGN docs | `agents/sda-dev-task.agent.md` | agent edit |
| S4-2 | Confirm system context = DEV durable ledger (no new work) | — (P2/P3 delivers it) | confirmation |

---

## S4-1 — `sda-dev-task` consumes the User Story

### Input change
- **Requirement input** becomes the BA **User Story** (Actor statement + Gherkin
  scenarios), not a raw user prompt. The story is the intent `sda-dev-task` translates
  into an implementation-ready `task.md`.
- `sda-dev-task` treats each Gherkin scenario as an acceptance target the task's design
  must satisfy; the Actor + local/referenced NFRs bound scope. It does **not**
  re-elicit requirements — that is BA's job (escalate up if the story is unclear).

### Design context read
- Reads DESIGN docs from `paths.design` (`design.md` + `feature.md`) as the
  architecture/feature context for the task.
- Also reads this story's **`paths.pendingChanges` overlay** — DESIGN deltas not yet merged
  — so the task is designed against the in-flight design, not a stale durable copy.
- Reads `paths.devSystemContext` (behaviors, decisions, dependency map) to align the
  task with existing system reality.

### Preserved behaviour (P3-1, unchanged)
- **Bootstrap** the system-context ledger on first run if absent.
- **Conflict gate**: detect where the requested change conflicts with recorded
  system context; surface the conflict before designing.
- Authors the **`## System Context Impact`** section in `task.md` — DEV's declared
  delta to the durable system context. **DEV owns this section; DESIGN must not
  author it.**

### Read-list additions (`.sda dependencies`)
| File | Path |
|---|---|
| User Story | `paths.baFeatures` story entry (Actor + Gherkin) |
| design.md | `paths.design/design.md` |
| feature.md | `paths.design/feature.md` |
| pending overlay | `paths.pendingChanges/<story>/` |
| system context | `paths.devSystemContext` |

### Boundaries
- **BC-blind**: receives the User Story + output path; never reads
  `workflow-state.yaml` or `dev-qa-cycle-state.yaml`.
- Does **not** re-open requirements (BA), redesign architecture (DESIGN), or author
  qa-task FRs (delegates to `sda-qa-task`).
- Keeps both absolute rules: never writes files/code directly (delegates to
  `sda-scribe`), never designs *for* the user under `designOwnership: user`.

---

## S4-2 — System context is the DEV durable ledger

- The **system context** (behaviors, decisions, dependency map) is DEV's durable
  contribution to the SDLC. It is already fully specified and built by the **P2/P3**
  changeset in [qa_plus_system_context.md](qa_plus_system_context.md).
- **No new work** in this phase beyond confirming the wiring:
  - `sda-dev-task` declares the per-story delta via `## System Context Impact`.
  - The delta is merged into `paths.devSystemContext` as the story completes (verified
    status set post-QA by `sda-dev-context-writer` — see
    [QA context](05-qa-context.md) S3-2).
  - This ledger is one of the five durable ledgers the SDLC definition of done
    enforces per completed User Story.

---

## Open items for execution

Real-file wiring deferred to the S6 execution pass:

1. Edit `agents/sda-dev-task.agent.md`: change requirement input to the User Story;
   add `paths.design`, `paths.pendingChanges`, `paths.devSystemContext`, and the feature
   ledger to the `.sda dependencies` read-list; keep P3-1 bootstrap + conflict gate
   + `## System Context Impact`; add BC-blind boundary.
2. Confirm (no edit) that P2/P3's system-context infrastructure is the DEV durable
   ledger updated per story; cross-link `sda-dev-context-writer`'s post-QA verified-status
   write.
3. Confirm DEV reads design context from `paths.design` (durable ledger) plus this
   story's `paths.pendingChanges` overlay.
