# DEP Bounded Context

Specifies the **DEP (Deployment)** bounded context as a placeholder: it has **no
agents** this phase. Its only deliverable is the durable **deployment-context
ledger schema** — per-part deployment details that a future DEP agent (or a human)
records as the fifth durable SDLC ledger.

Companion to [architecture](01-architecture.md) (architecture;
DEP row + `paths.depContext`) and
[implementation plan](00-implementation-plan.md) (roadmap, phase **S5**). DEP is the
terminal BC: a User Story reaches `done` only after its deployment-context entry is
recorded alongside the other four durable ledgers.

---

## Deliverables

| # | Artifact | Target | Kind |
|---|---|---|---|
| S5-1 | Deployment-context ledger schema | `skills/sda-setup/assets/dep/deployment-context-schema.md` | new entity doc |

**No agents.** No `sda-dep` agent, no wiring, no workflow changes in this phase.

---

## S5-1 — Deployment-context ledger schema

### Purpose
Durable, per-part record of **how each deployable part of the system is deployed** —
the DEP bounded context's contribution to the SDLC. One entry per deployable part;
appended/updated as parts ship. Tool-agnostic and browsable, stored under
`paths.depContext`.

### Structure (schema only)

Ledger lives at `paths.depContext` as one document (or one file per part).
Each part entry:

```
## DP-{id} — {part name}

- **Part**: {deployable unit — service, package, job, site}
- **Target**: {environment / platform — cloud, cluster, registry, host}
- **Artifact**: {what is deployed — image, bundle, binary} + how it is produced
- **Procedure**: {how it is deployed — pipeline, command, manual steps}
- **Configuration**: {env vars, secrets ref, resource limits — values by reference,
  never inline secrets}
- **Dependencies**: {other parts / external services this deployment needs}
- **Rollback**: {how to revert this part}
- **Status**: recorded | verified
```

### Content rules
- Exactly one entry per deployable part; the part name is the entry key.
- **Never inline secrets** — reference the secrets location (`paths.secrets`), never
  literal values.
- Deployment *procedure* is described, not scripted here — this is a ledger, not a
  runbook executor.
- `Status: verified` means the deployment has been exercised at least once; default
  `recorded`.
- Pure entity doc: describes only the ledger's own structure and rules — names no
  producing/consuming agent, phase, or workflow.

---

## Open items for execution

Real-file wiring deferred to the S6 execution pass:

1. Create `skills/sda-setup/assets/dep/deployment-context-schema.md` with the structure
   and rules above.
2. Ensure `paths.depContext` is registered in the config paths (already listed
   in [architecture](01-architecture.md)); confirm the scaffolded
   `project-config.json` includes it.
3. No agent, handoff, or workflow-script changes — DEP stays agent-less until a future
   phase introduces a DEP agent.
