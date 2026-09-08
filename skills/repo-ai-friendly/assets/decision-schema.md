# Decision Schema

One decision per file, routed by an `index.md`. Decision folders live at
`docs/decisions/` (global) and `<layer>/docs/decisions/` (layer), grouped by
feature with descriptive kebab-case file names.

---

## Decision index

`docs/decisions/index.md` (same shape for a layer):

```markdown
# Decisions

| Decision | When it applies | Document |
|---|---|---|
| {Title} | {trigger phrase} | [shared/auth.md](shared/auth.md) |
| {Title} | {trigger phrase} | [users/delete-policy.md](users/delete-policy.md) |
```

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

- One decision per file; the index routes by file name.
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
