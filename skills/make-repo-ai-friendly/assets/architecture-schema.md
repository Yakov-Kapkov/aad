# Architecture Schema

`architecture.md` lives at `docs/` (root), plus `<subproject>/docs/` in each subproject.
One concern per file, short and observable.

---

## Template

Global `docs/architecture.md`:

```markdown
# Architecture

## Repo structure
| Subproject | Folder | Owns |
|---|---|---|
| {Subproject} | {folder} | {one-line ownership} |

## Services / modules
- {Service} — {one-line ownership}

## Communication
{sync vs async, protocols}

## Storage
{which store for which concern}

## Integration points
{external systems}

## Cross-cutting concerns
- {Auth / observability / retries} — {one line; omit the rest}

## Feature boundaries & dependencies
{features + sequencing}
```

Subproject `<subproject>/docs/architecture.md`:

```markdown
# Architecture — {Subproject}

## Modules
- {Module} — {one-line ownership}

## Communication
{how it talks to the other subprojects / services}

## Storage
{which store for which concern}

## Cross-cutting concerns
- {concern} — {one line; omit the rest}
```

---

## Schema Rules

- Root `architecture.md` holds repo-wide structure and the subproject map only — no
  single subproject's detail.
- A subproject's `architecture.md` holds only that subproject's modules, communication,
  storage, and cross-cutting concerns.
- Short and observable — no implementation detail (that lives in
  `coding-standards/`, convention, or ADR files).
- Only create the files the design actually needs — never pre-seed empty files.
- Derive every subproject name, folder, and storage claim from the actual code —
  never invent.
