# Component Schema

A **component model** records the components one design is made of — the vocabulary the flows
are written in. Each component is named once, with the level it sits at and the behaviour it
holds. Flows name these components and never re-describe them; pseudo-tests use these names
verbatim.

---

## Template

```markdown
# Components: {title}

| Component | Level | Status | Holds |
|---|---|---|---|
| `{Name}` | {level} | {new · existing (`{Symbol}`)} | {one sentence: the behaviour it holds} |
```

---

## Schema Rules

### Title
- `# Components: {title}` — one line, mirroring the design record's title.

### The model
- One row per component. The name is the one the user chose, in backticks.
- `Level` — the abstraction level the component sits at, in the user's own names
  (`application`, `domain`, `component`, `infrastructure`, and `test` for a fixture). One level
  per component, never a range and never a second row to say otherwise.
- `Status` — `existing` carries the symbol the code already uses for it, in backticks, so the
  claim is checkable; `new` states why no existing symbol holds the behaviour. An `existing`
  with no symbol is an assumption — raise it, never write it.
- `Holds` — one sentence: the behaviour this component is responsible for. Never a method
  list, a field list, a payload, or a file path.
- One component serves many flows — never a row per flow.
- Every component a flow's `Path` names is a row; every row is named by at least one flow.
  A component no flow names is structure nothing exercises — raise it, never list it.
- A component that replaces, splits, or merges another appears here once, under its own name,
  marked `new`; the change's shape belongs to the design record's `Approach`.
- The file is referenced from the record's `Index`; no other file restates a level or a
  responsibility.
- Omit the file when the design names no component — a docs-only change has neither flows nor a
  model.
