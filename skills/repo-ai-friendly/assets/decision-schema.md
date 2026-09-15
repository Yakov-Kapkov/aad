# Decision Schema

One decision per file, routed by an `index.md` in every folder. Decision
folders live at `docs/decisions/` (global) and `<layer>/docs/decisions/`
(layer), grouped by feature with descriptive kebab-case file names.

---

## Layout

```
{docs-root}/decisions/
├── index.md                     ← routes to each feature
└── <feature>/
    ├── index.md                 ← routes to each decision
    └── <decision>.md
```

## Decision index

`decisions/index.md` — routes to features:

```markdown
# Decisions

| Feature | When it applies | Document |
|---|---|---|
| Shared | auth, logging, retries — cross-layer rules | [shared/index.md](shared/index.md) |
| Users | user lifecycle and deletion | [users/index.md](users/index.md) |
```

`<feature>/index.md` — routes to decisions:

```markdown
# {Feature} decisions

| Decision | When it applies | Document |
|---|---|---|
| {Title} | {trigger phrase} | [delete-policy.md](delete-policy.md) |
| {Title} | {trigger phrase} | [soft-delete.md](soft-delete.md) |
```

The first column names the level the index routes to.

## Decision file

`docs/decisions/<feature>/<decision>.md`:

```markdown
# {Decision title}

**Decision:** {one sentence — the rule, not the rationale}

**Applies to:** {optional paths this governs}

**Why:** {optional one line — alternatives rejected}

**Application**
- ✅ DO: {concrete action}
- ❌ DON'T: {anti-pattern}
```

---

## Placement — global is global only

- Global `docs/decisions/` holds **only** cross-layer decisions.
- A decision touching one subsystem lives in that subsystem's
  `<layer>/docs/decisions/` — never global.
- ✅ auth spans frontend + backend → `docs/decisions/shared/auth.md`
- ❌ backend-only delete policy in `docs/decisions/` → belongs in
  `backend/docs/decisions/`

---

## Schema Rules

- Every folder has an `index.md`; every child is routed by its **parent's**
  index — exactly one router per decision (two = duplicate row, none = orphan).
- A feature folder exists only with its `index.md` — it is a routing level, not
  a bare grouping.
- One decision per file; the feature's index routes by file name.
- Feature folders use descriptive names; decision files use descriptive
  kebab-case names — no `d{N}` numbering.
- Lead with the decision; rationale is optional and capped at one line.
- **No stale wording.** Record only the current decision — never keep a
  "previous decision" block or past wording in the file. When a decision
  changes, amend only the part that changed (e.g. the `**Decision:**`
  sentence), not the whole file.
- **Exception:** a long-term refactoring or migration that spans multiple
  tasks may retain superseded wording where the history stays valuable.
- Place every decision per the Placement rule: global only for cross-layer.
