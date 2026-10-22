# Operations Schema

`operations.md` lives at `docs/` (root); a subproject adds `<subproject>/docs/operations.md` only when it runs on its own. It answers two questions: is it up, and how is it undone?

---

## Template

```markdown
# Operations

## Health
{how to tell the system is up — endpoint, dashboard, command}

## Logs
{where they are, how to read them}

## Metrics & alerts
{what is watched, and what wakes someone up}

## Rollback
{how a bad release is undone}
```

A subproject's `operations.md` is the same file with only the sections that subproject
has.

---

## Schema Rules

- Name the dashboard, log sink, or endpoint — never restate a `cli.md` command.
- **`Rollback` states the mechanism** — the flag, the re-deploy, the migration —
  never an incident narrative.
- Environments are listed once, in `deployment.md` — link, never restate.
- Omit a section that would be empty; never write a placeholder line.
- Derive endpoints, dashboards, and log locations from the repo's actual config
  and infrastructure files — never invent.
