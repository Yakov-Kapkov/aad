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
| `docs/vocabulary.md` | Global term table — ubiquitous-language terms, each linking to the owning layer's `vocabulary.md` |
| `<layer>/docs/vocabulary.md` | That layer's terms only — one table, no cross-layer detail |

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

| Term | Definition | Layer |
|---|---|---|
| {Term} | {one-line definition} | [backend](backend/docs/vocabulary.md) |
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
  (`docs/coding/` and coding-standards), not here.
- Only create the files the design actually needs — never pre-seed empty files.
- Vocabulary: a term lives in exactly one layer's file (or the global file);
  the global table links to the owning layer instead of duplicating the term.
- `diagrams/*.md` are rendered separately; `docs/index.md` routes to them.
