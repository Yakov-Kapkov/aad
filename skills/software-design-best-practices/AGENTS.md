# AGENTS.md — software-design-best-practices

Instructions for AI agents maintaining this skill.

---

## Structure

```
SKILL.md                       — lookup workflow, application rules, practice file format
README.md                      — human-facing overview, setup, usage
practices/
  index.md                     — master route table: topic area → area index + keywords
  {area}/
    index.md                   — concern → practice file + "When to Apply"
    {concern}.md               — one Rule + one Application (DO/DON'T)
```

## Practice file format

Every practice file has exactly **one** concern:

```markdown
# Concern Name

## Rule
[One sentence.]

## Application
- ✅ DO: [concrete action]
- ❌ DON'T: [anti-pattern]
```

Rules:
- One file = one rule. Split a file when a second rule emerges.
- Rules are language-agnostic. Examples cite multiple technologies (SQL, ORM, NoSQL) but no single language.
- `## Application` lists ✅ DO first, then ❌ DON'T.

## Adding a new practice rule

1. Create `practices/{area}/{concern}.md` following the format above.
2. Add a row to `practices/{area}/index.md` — describe the scope where this practice applies (the "When to Apply" column is a scope, not a narrow change trigger).
3. If the concern introduces new keywords, update the Keywords column in `practices/index.md`.
4. If this adds a new concern category, update the Topic Areas table in `README.md`.

## Adding a new topic area

1. Create `practices/{area}/` with `index.md` and at least one practice file.
2. Add a row to `practices/index.md` with keywords.
3. Add a row to `README.md` Topic Areas table.

## Modifying an existing practice

1. Edit the practice file directly.
2. If the scope changes, update its "When to Apply" in the area `index.md`.
3. If the change affects keyword matching, update `practices/index.md`.

## Removing a practice

1. Delete the practice file.
2. Remove its row from the area `index.md`.
3. If it was the last row in a topic area, remove the area entirely from `practices/index.md` and `README.md`.
4. Run `grep` for the filename — remove any stale references.

## Boundaries

- ✅ **Always do**: Update the area `index.md` when adding/removing practice files. Keep "When to Apply" triggers narrow and concrete.
- ✅ **Always do**: Follow one-rule-per-file. Never add a second `## Rule` section to an existing file.
- ⚠️ **Ask first**: Adding a new topic area, removing an entire area, changing the practice file format.
- 🚫 **Never do**: Add language-specific code examples that only work in one framework. Keep rules language-agnostic.
- 🚫 **Never do**: Add runtime dependencies, package managers, or build scripts to this skill.
