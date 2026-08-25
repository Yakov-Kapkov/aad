# Vocabulary Schema

`vocabulary.md` lives at `docs/` (global) and `<layer>/docs/` (layer).
Global terms are shared; layer terms are specialisations or layer-only terms.

---

## Template

Global `docs/vocabulary.md`:

```markdown
# Vocabulary

| Term | Definition | Layers |
|---|---|---|
| {Term} | {one-line global definition} | [frontend](frontend/docs/vocabulary.md), [backend](backend/docs/vocabulary.md) |
| {Term} | {one-line definition} | global |
```

Layer `<layer>/docs/vocabulary.md`:

```markdown
# Vocabulary — {Layer}

| Term | Definition |
|---|---|
| {Term} | {one-line definition} |
```

---

## Schema Rules

- A global term links to every layer that specialises it; a layer-only term
  is defined in the layer, not the global table.
- A layer never restates a global term with identical meaning (duplicate).
- One-line definitions. No implementation-level jargon.
- Only create the files the design actually needs — never pre-seed empty files.
