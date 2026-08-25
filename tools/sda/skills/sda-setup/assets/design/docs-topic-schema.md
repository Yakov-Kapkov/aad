# Design Topic Schema

Global design topic files live at the global docs root (`docs/`): one concern
per file, short and observable. The two global files are `architecture.md` and
`vocabulary.md`.

---

## File map

| File | Sections |
|---|---|
| `docs/architecture.md` | Repo structure + layer list · Services / modules · Communication · Storage · Integration points · Cross-cutting concerns · Feature boundaries |
| `<layer>/docs/architecture.md` | That layer's modules · Communication · Storage · Cross-cutting concerns |
| `docs/vocabulary.md` | Global term table — ubiquitous-language terms, each linking to every layer that specialises it |
| `<layer>/docs/vocabulary.md` | That layer's terms — specialisations of global terms + layer-only terms, one table |

---

## architecture.md

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

## vocabulary.md

Global `docs/vocabulary.md`:

```markdown
# Vocabulary

| Term | Definition | Layers |
|---|---|---|
| {Term} | {one-line global definition} | [frontend](frontend/docs/vocabulary.md), [backend](backend/docs/vocabulary.md) |
| {Term} | {one-line definition} | global |
```

Per-layer `<layer>/docs/vocabulary.md`:

```markdown
# Vocabulary — {Layer}

| Term | Definition |
|---|---|
| {Term} | {one-line definition} |
```

---

## Schema Rules

- One concern per file. Write as much as needed, no more.
- Short and observable — no implementation detail. That lives in Plane B
  (`docs/coding-standards/`), not here.
- Only create the files the design actually needs — never pre-seed empty files.
- Vocabulary: a global term links to every layer that specialises it; the
  per-layer entry clarifies that layer's meaning, never restates it. A term
  defined identically in all layers stays global-only — no layer entries.
- `diagrams/*.md` are rendered separately; `docs/index.md` routes to them.
