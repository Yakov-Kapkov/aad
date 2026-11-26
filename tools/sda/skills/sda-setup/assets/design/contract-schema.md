# Contract Schema

A **contracts file** records the seams one design crosses: for each, the two components it joins,
the information that crosses, the guarantees the crossing carries, the failure the caller
observes, its owner, and the spec file that fixes its concrete shape.

It states semantics only. Field names, types, optionality, error codes, and payloads belong to
the spec file — this file never restates them.

---

## Template

```markdown
# Contracts: {title}

## {What crosses}
- Seam: {Component A} → {Component B} — {sync | async | stream}
- Crosses: {what information, semantically}
- Guarantees: {the guarantees the design commits to}
- On failure: {what the caller observes}
- Owner: {the one component that may change the shape}
- Spec: [{path}]({path}) — {use-as-is | extend | create}
```

A seam nothing outside its deployable depends on carries `- Spec: none — in-process seam`.

---

## Schema Rules

### Title
- `# Contracts: {title}` — one line, mirroring the design record's title.

### Sections
- One `## {What crosses}` section per seam, named by the thing that crosses — `OrderPlaced`,
  `StockLookup` — never after the components, never `XToYService`.
- Ordered outside-in, matching the order the flows are read.
- Every seam in any flow's `Path` that changes owning component is a section; a seam with no
  section is a design gap.
- A contract no flow crosses is structure nothing exercises — raise it, never write it.

### The six fields
- `Seam` — the two components as the [component schema](component-schema.md) names them, one
  arrow, then the direction in words.
- `Crosses` — the information that crosses, semantically: the identities, versions, and
  orderings the other side depends on. Never a field list, a type, or a payload.
- `Guarantees` — only what the design commits to: delivery, ordering, idempotency, timeout,
  retry. A guarantee nobody decided is a gap, not a default. A stored state the flows assert on —
  absent vs empty, missing vs null — is stated here, once, so every flow means the same thing.
- `On failure` — what the caller observes when the crossing fails. A seam without one is
  unfinished.
- `Owner` — exactly one component. Two owners is a design gap.
- `Spec` — a relative link to the spec file plus `use-as-is`, `extend`, or `create`; or
  `none — in-process seam` when nothing outside the deployable depends on it **and** its
  guarantee leaves no field, error code, or stored state for the implementation to invent. A
  load-bearing in-process seam is `extend` or `create` regardless of deployable. Every spec file
  named exists when the design stage ends.

### Boundaries
- No field names, types, error codes, SQL, or code — the spec file carries the shape.
- No call sequence — that is a flow's `Path`.
- Omit the file when the design crosses no seam; the record's `Index` and `Handoff` then omit
  it too.
