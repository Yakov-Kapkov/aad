# Architecture Schema

`architecture.md` lives at `docs/` (global) and `<layer>/docs/` (layer).
One concern per file, short and observable.

---

## Template

Global `docs/architecture.md`:

```markdown
# Architecture

## Repo structure
| Layer | Folder | Owns |
|---|---|---|
| {Layer} | {folder} | {one-line ownership} |

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

Layer `<layer>/docs/architecture.md`:

```markdown
# Architecture — {Layer}

## Modules
- {Module} — {one-line ownership}

## Communication
{how it talks to other layers / services}

## Storage
{which store for which concern}

## Cross-cutting concerns
- {concern} — {one line; omit the rest}
```

---

## Schema Rules

- Global `architecture.md` holds repo-wide structure only — no subsystem detail.
- Layer `architecture.md` holds only that layer's modules, communication,
  storage, and cross-cutting concerns.
- Short and observable — no implementation detail (that lives in
  `coding-standards/` or decision files).
- Only create the files the design actually needs — never pre-seed empty files.
- Derive every layer name, folder, and storage claim from the actual code —
  never invent.
