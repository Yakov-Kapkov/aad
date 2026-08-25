# CLI Schema

`cli.md` is **per-layer only** — `<layer>/docs/cli.md`. It lists every
command an agent needs to work on that layer. Global docs never hold CLI
commands; the readme's "run locally" section routes here.

---

## Template

```markdown
# CLI — {Layer}

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
```

---

## Schema Rules

- **Derive every command from the repo's actual files** (package manifest,
  lock files, task runner config) — never invent syntax.
- **Command-runner consistency:** if a wrapper is detected (`poetry run`,
  `pipenv run`, `npx`, `pnpm dlx`), wrap every invocation of a project binary
  or interpreter — including `uvicorn`, `pytest`, `node`, `python`.
  - ❌ `uvicorn api:app --reload` — bare, wrong when a wrapper exists
  - ✅ `poetry run uvicorn api:app --reload`
- Match the shell the layer is documented for; do not translate idioms across
  shells.
- Omit a row when that task does not apply to the layer.
- **Record both test passes.** `cli.md` lists the suite command (verdict) and
  the targeted one-file command (detail), plus the output filter that drops
  passing results.

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
