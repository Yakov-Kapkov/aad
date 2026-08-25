# Coding Standards Schema

The coding-standards folder routes readers to rules. It **routes** — it does
not duplicate rule content that lives elsewhere.

Two locations: global `docs/coding-standards/` (cross-layer rules) and
`<layer>/docs/coding-standards/` (layer rules).

---

## index.md

```markdown
# Coding standards

| Concern | Source | When to read |
|---|---|---|
| {Language} rules | [{language}]({language}.md) | writing {Language} |
| All languages | standards-compliance skill | global defaults |
```

One row per language in the repo — e.g. `Python rules | [python](python.md) |
writing Python`, `Java rules | [java](java.md) | writing Java`.

## Language file (when rules live in the repo)

`docs/coding-standards/<language>.md`:

```markdown
# {Language} coding standards

## {Section}
- ✅ DO: {concrete rule}
- ❌ DON'T: {anti-pattern}
```

---

## Schema Rules

- **Prefer an existing source over duplicating rules.** If the repo uses a
  standards skill (e.g. `standards-compliance`), route to it; author local
  language files only for repo-specific rules the skill does not cover.
- Global `docs/coding-standards/` holds cross-layer rules only; layer rules
  live in `<layer>/docs/coding-standards/`.
- One language per file; file names match the language (`python.md`,
  `typescript.md`).
- Only create the files the repo actually needs — never pre-seed empty files.
