# Design Doc Schema

The **durable design ledger** — the DESIGN bounded context's contribution. Two document
types under `paths.design`, governed by a pending → merge lifecycle. The detailed
content structure of each document is defined by the design agents (`sda-system` /
`sda-feature`); this schema formalizes the ledger layout, the overlay lifecycle, and
the rules.

## Ledger layout

```
{paths.design}/
  design.md              — system-level architecture, standards, domain model
  {feature}/feature.md   — per-feature design + decisions
```

- Both are **approved-only**: browsable, committed, tool-agnostic.
- `design.md` is system-wide; `feature.md` is one per feature area.

## Pending → merge lifecycle

1. A story's proposed change is written to `paths.pendingChanges`, mirroring the
   `paths.design` tree (e.g. `paths.pendingChanges/design.md`,
   `paths.pendingChanges/{feature}/feature.md`).
2. It stays there through DEV + QA, available to downstream contexts as *pending*
   design context.
3. On **story completion**, the pending delta merges into `paths.design`; the pending
   entry is cleared.

This overlay suits prose design docs. It is distinct from the system context's inline
`pending-reverification` status (structured YAML).

## Rules

- Entity doc — describes only the design documents + overlay lifecycle; names no agent
  or workflow phase.
- A design delta references the source `user-story.md`; it does not copy scenarios.
- Superseding a prior design decision is explicit (marked, dated) — never silent.
- Durable docs stay approved-only; unapproved changes live only in `paths.pendingChanges`
  until merged.
