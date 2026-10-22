# Testing Schema

`testing.md` lives at `docs/` (root), plus `<subproject>/docs/` in each subproject. It says
*what* is tested and what the tests prove — never how to run them (`cli.md`).

---

## Template

Root `docs/testing.md`:

```markdown
# Testing

## Strategy
- {level: unit / integration / e2e} — {what it proves}

## Test cases
{where they live, how they are named}

## Smoke tests
{the shortest run that proves the system works}

## Not covered
{what is deliberately untested}
```

Subproject `<subproject>/docs/testing.md`:

```markdown
# Testing — {Subproject}

## Suites
| Suite | Covers | Lives in |
|---|---|---|
| {suite} | {what it proves} | {folder} |

## Smoke tests
{the shortest run for this subproject}

## Not covered
{what this subproject does not test}
```

---

## Schema Rules

- **Commands live in `cli.md`** — never restate a command here.
- Link a suite to the requirement id it proves — never restate the requirement.
- `Not covered` is the valuable section: name what is deliberately untested, so
  a reader stops looking for it.
- Omit a section that would be empty; never write a placeholder line.
- Derive suites, folders, and levels from the repo's actual test layout — never
  invent.
