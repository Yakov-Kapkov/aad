# Design Convention Schema

One convention per file, routed by an `index.md` in every folder. Convention
folders live at `docs/conventions/` (root), plus `<subproject>/docs/conventions/`
in each subproject — grouped by feature with descriptive kebab-case file names.

---

## Layout

```
{docs-root}/conventions/
├── index.md                     ← routes to each feature
└── <feature>/
    ├── index.md                 ← routes to each convention
    └── <convention>.md
```

## Convention index

`conventions/index.md` — routes to features:

```markdown
# Conventions

| Feature | When it applies | Document |
|---|---|---|
| Shared | auth, logging, retries — cross-subproject rules | [shared/index.md](shared/index.md) |
| Users | user lifecycle and deletion | [users/index.md](users/index.md) |
```

`<feature>/index.md` — routes to conventions:

```markdown
# {Feature} conventions

| Convention | When it applies | Document |
|---|---|---|
| {Title} | {trigger phrase} | [delete-policy.md](delete-policy.md) |
| {Title} | {trigger phrase} | [soft-delete.md](soft-delete.md) |
```

The first column names the level the index routes to.

## Convention file

`docs/conventions/<feature>/<convention>.md`:

```markdown
# {Convention title}

**Convention:** {one sentence — the rule to follow}

**Applies to:** {optional paths this governs}

**ADR:** {optional link — the ADR that chose this direction}

**Application**
- ✅ DO: {concrete action}
- ❌ DON'T: {anti-pattern}
```

---

## Placement — the root is root only

- Root `docs/conventions/` holds **only** cross-subproject conventions.
- A convention touching one subproject lives in that subproject's
  `<subproject>/docs/conventions/` — never at the root.
- ✅ auth spans frontend + backend → `docs/conventions/shared/auth.md`
- ❌ backend-only delete policy in `docs/conventions/` → belongs in
  `backend/docs/conventions/`

---

## Schema Rules

- Every folder has an `index.md`; every child is routed by its **parent's**
  index — exactly one router per convention (two = duplicate row, none = orphan).
- A feature folder exists only with its `index.md` — it is a routing level, not
  a bare grouping.
- One convention per file; the feature's index routes by file name.
- Feature folders use descriptive names; convention files use descriptive
  kebab-case names — no `d{N}` numbering.
- Lead with the convention; link its ADR when one exists — never restate the
  rationale here.
- **No stale wording.** Record only the current convention — never keep a
  "previous convention" block or past wording in the file. When a convention
  changes, amend only the part that changed (e.g. the `**Convention:**`
  sentence), not the whole file.
- **Exception:** a long-term refactoring or migration that spans multiple
  tasks may retain superseded wording where the history stays valuable.
- Place every convention per the Placement rule: the root only for cross-subproject.
- Cross-references are folder + title, never numeric: a convention links its
  ADR, and a subproject convention links the root convention it refines.
