# ADR Schema

An ADR records one architecture decision and why it was made — the direction,
the alternatives rejected, and the consequences accepted. ADR folders live at
`docs/adrs/` (root), plus `<subproject>/docs/adrs/` in each subproject — grouped
by feature with descriptive kebab-case file names. Read an ADR when a decision is questioned
or a redesign looms — never during routine feature work.

---

## Layout

```
{docs-root}/adrs/
├── index.md                     ← routes to each feature
└── <feature>/
    ├── index.md                 ← routes to each ADR
    └── <adr>.md
```

## ADR index

`adrs/index.md` — routes to features:

```markdown
# ADRs

| Feature | When to read | Document |
|---|---|---|
| Shared | before changing auth, logging, retries — cross-subproject directions | [shared/index.md](shared/index.md) |
| Users | before changing user lifecycle or deletion | [users/index.md](users/index.md) |
```

`<feature>/index.md` — routes to ADRs:

```markdown
# {Feature} ADRs

| ADR | When to read | Document |
|---|---|---|
| {Title} | {trigger phrase} | [postgres-not-mongo.md](postgres-not-mongo.md) |
| {Title} | {trigger phrase} | [eventual-consistency.md](eventual-consistency.md) |
```

## ADR file

`docs/adrs/<feature>/<adr>.md`:

```markdown
# ADR: {title}

**Status:** {accepted · superseded by [successor](successor.md) · proposed}

**Context:** {2–3 sentences — the forces that forced a decision}

**Decision:** {one sentence — what we chose}

**Alternatives:** {one line per rejected option, and why}

**Consequences:** {one line per accepted trade-off}
```

---

## Placement — the root is root only

- Root `docs/adrs/` holds **only** cross-subproject directions.
- A direction touching one subproject lives in that subproject's
  `<subproject>/docs/adrs/` — never at the root.
- ✅ auth spans frontend + backend → `docs/adrs/shared/auth.md`
- ❌ backend-only storage swap in `docs/adrs/` → belongs in
  `backend/docs/adrs/`

---

## Schema Rules

- **Warrant.** An ADR exists only for a decision weighed against ≥2 live
  alternatives and load-bearing (reversing it is costly). A decision with one
  sensible option has a self-evident "why" — record the convention only, no ADR.
- One decision per ADR; the feature's index routes by file name.
- Every folder has an `index.md`; every child is routed by its **parent's**
  index — exactly one router per ADR (two = duplicate row, none = orphan).
- A feature folder exists only with its `index.md` — a routing level, not
  a bare grouping.
- Descriptive kebab-case names — no `ADR-{N}` numbering. Reference another
  ADR by folder + title, never by number.
- **Two pages max, ~300 words.** Diagrams allowed; code snippets are not.
- **History stays.** A superseded ADR keeps its `**Status:** superseded by`
  link to the successor — it answers "why did we move away". This is the one
  doc kind where past wording survives.
- Amend an ADR only when the direction changes: set `**Status:**` to
  superseded and link the successor — never edit the past wording silently.
- Write the ADR when the direction is chosen: no `proposed` ADR left open at
  session end.
- A convention may reference the ADR that chose its direction — see
  `convention-schema.md`.
