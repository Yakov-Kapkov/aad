# Coding Standards Schema

The coding-standards folder routes readers to rules. It **routes** — it does
not duplicate rule content that lives elsewhere.

Root `docs/coding-standards/` holds cross-subproject rules; each subproject adds
`<subproject>/docs/coding-standards/` for its own rules.

---

## index.md

```markdown
# Coding standards

| Concern | Source | When to read |
|---|---|---|
| {Language} rules | [{language}]({language}.md) | writing {Language} |
| All languages | standards-compliance skill | global defaults |
```

One row per language in the repo:

```markdown
| Python rules | [python](python.md) | writing Python |
| Java rules | [java](java.md) | writing Java |
```

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
- Root `docs/coding-standards/` holds cross-subproject rules only; one subproject's rules
  live in `<subproject>/docs/coding-standards/`.
- One language per file; file names match the language (`python.md`,
  `typescript.md`).
- Only create the files the repo actually needs — never pre-seed empty files.
