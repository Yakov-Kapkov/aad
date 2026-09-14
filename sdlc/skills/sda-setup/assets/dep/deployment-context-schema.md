# Deployment Context Schema

The **deployment-context ledger** — the DEP bounded context's durable contribution: a
per-part record of *how each deployable part of the system is deployed*, under
`paths.depContext`. One entry per deployable part, appended/updated as parts ship.
Tool-agnostic and browsable.

## Structure

The ledger lives at `paths.depContext` as one document (or one file per part). Each
part entry:

```markdown
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

## Rules

- Exactly one entry per deployable part; the part name is the entry key.
- **Never inline secrets** — reference the secrets location (`paths.secrets`), never
  literal values.
- Deployment *procedure* is described, not scripted here — this is a ledger, not a
  runbook executor.
- `Status: verified` means the deployment has been exercised at least once; default
  `recorded`.
- Pure entity doc: describes only the ledger's own structure and rules — names no
  producing/consuming agent, phase, or workflow.
