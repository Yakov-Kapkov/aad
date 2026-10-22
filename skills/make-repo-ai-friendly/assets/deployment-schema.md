# Deployment Schema

`deployment.md` lives at `docs/` (root); a subproject adds `<subproject>/docs/deployment.md` only when it ships on its own. It answers one question: how does a change reach users?

---

## Template

Global `docs/deployment.md`:

```markdown
# Deployment

## Pipeline
{workflow file(s)} — {what triggers each}

| Stage | Runs | Gate |
|---|---|---|
| {stage} | {what it does} | {what must pass} |

## Environments
| Environment | Purpose | Deployed by |
|---|---|---|

## Triggers
{what ships when — merge to the default branch, a tag, a manual dispatch}

## Manual steps
{what a human must do}
```

Subproject `<subproject>/docs/deployment.md` — the same file, with only the sections that
subproject has: `Pipeline`, `Environments`, `Manual steps`.

---

## Schema Rules

- **The deploy path is often a CI/CD workflow, not a command** — name the
  workflow file; never invent a command line for it.
- Commands that do exist belong to `cli.md` — link, never restate.
- `Manual steps: none` is a finding, not an omission — write it when the
  pipeline is fully automated. Every other empty section is omitted.
- `Rollback` belongs to `operations.md` — never restate it here.
- Derive workflow names, environments, and gates from the repo's actual CI/CD
  files — never invent.
