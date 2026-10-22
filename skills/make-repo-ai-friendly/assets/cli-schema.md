# CLI Schema

`cli.md` holds the commands an agent runs while working: the root
`docs/cli.md`, plus `<subproject>/docs/cli.md` for each subproject. The readme's "run
locally" section routes here.

---

## Template

```markdown
# Commands — {Subproject}

## Bootstrap
| Step | Command |
|---|---|
| Toolchain {x.y}, install, codegen | `{exact command}` |

## Commands

| Task | Command |
|---|---|
| Run all tests | `{exact command}` |
| Run one test file | `{exact command}` |
| Lint | `{exact command}` |
| Format | `{exact command}` |
| Build | `{exact command}` |
| Type check | `{exact command}` |
| Start locally | `{exact command}` |

## Before merge
{the ordered gate — what must pass, in what order}
```

Root `docs/cli.md` is the same file with `Run {subproject}'s tests` in place of `Run
one test file`, plus whatever composes the whole stack.

---

## Schema Rules

- **Derive every command from the repo's actual files** (package manifest,
  lock files, task runner config) — never invent syntax.
- **Command-runner consistency:** if a wrapper is detected (`poetry run`,
  `pipenv run`, `npx`, `pnpm dlx`), wrap every invocation of a project binary
  or interpreter — including `uvicorn`, `pytest`, `node`, `python`.
  - ❌ `uvicorn api:app --reload` — bare, wrong when a wrapper exists
  - ✅ `poetry run uvicorn api:app --reload`
- Match the shell the subproject is documented for; do not translate idioms across
  shells.
- Omit a row when that task does not apply to the subproject.
- **Record both test passes.** `cli.md` lists the suite command (verdict) and
  the targeted one-file command (detail), plus the output filter that drops
  passing results.
- **`Before merge` is a gate, not a command** — the ordered list an agent runs
  to know a change is done. It points at the subproject's commands rather than
  restating them.
- **Root `cli.md` states how to run one subproject's command from the root** — never
  make an agent run the whole monorepo to check one package.
- A command that must follow a change (codegen, migrations) is stated as a
  sequence: what to change, then what to run.

---

## Reading results — trim verbose output

Long output costs tokens. Read tests in two passes; never keep the full run.

1. **Verdict pass** — run the suite; keep the summary + the failed test names.
2. **Detail pass** — if anything failed, rerun the failing file(s) with the
   targeted command, filtering out passing results so only failures remain.

- ✅ vitest — pass 1: keep `Test Files  2 failed (2)` + the two failing names;
  pass 2: `vitest run path/to/failing.test.ts` filtered to failure output.
- ❌ vitest — paste the full run, or stop at "2 failed" without rerunning the
  failing files.
