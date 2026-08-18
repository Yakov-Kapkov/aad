# Decision Index Schema

An `index.md` routes readers to decision folders or decision files. It is the
navigation layer of the decision tree — references only, no decision content.
Two levels use it: `<layer>/docs/decisions/index.md` (routes to feature folders)
and `<layer>/docs/decisions/<feature>/index.md` (routes to decision files).

---

## Template

```markdown
# {Area Name}

| Concern | When to read | Document |
|---|---|---|
| {concern} | {trigger phrases} | [{file}]({path}) |
```

- Decisions root: one row per feature folder → `Document` = `<feature>/index.md`.
- Feature folder: one row per decision file → `Document` = `<filename>.md` (e.g. `challenge-validation.md`).

---

## Schema Rules

### Routing table
- One row per feature folder (decisions root) or per decision file (feature folder).
- `When to read` = trigger phrases — "adding a DB repository", "new API
  endpoint", "inter-BC communication". This is the matching surface agents
  self-route on before making a design choice.
- `Document` targets a child `index.md` (decisions root) or a decision
  file (feature folder) — recursion by target, not by a second schema.

### References only
- No decision content in an index. Each row routes; the target holds the
  content.
- No duplicates — the same concern/target appears in one row only.

### No global numbering
- The index routes; it never numbers decisions. Decision files use descriptive
  kebab-case names, never `d{N}` prefixes.
