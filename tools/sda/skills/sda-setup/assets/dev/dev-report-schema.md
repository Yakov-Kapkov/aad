# Dev Report Schema

`dev-report.md` records **what was actually implemented** — the ground truth of
a task's implementation, including problems hit during implementation. It lives
beside `task.md` in the task folder. `task.md` is *intent*; `dev-report.md` is
*actual*. The two diverge when models make mistakes — capturing that divergence
is the report's main value.

---

## Template

```markdown
# Dev Report: {task-name}

## Summary
{1-2 sentences: what the task was and what was actually done.}

## Files Changed
- `{path}` — {what changed}

## Units Accomplished
- {Unit N — name} — {done | partial} _(maps to task.md units)_

## Scenarios Implemented
- {scenario N — name} — {brief description, with steps where relevant}

## Issues Encountered
{Problems hit during RED/GREEN: gate failures,
unresolved items, workarounds, deviations from task.md, assumptions made under
uncertainty. Omit only if genuinely none.}
- {issue} — {how it was resolved, or left open}
```

---

## Schema Rules

### Summary
- 1-2 sentences. What the task was; what was actually done.

### Files Changed
- One bullet per file: path + what changed. The implementation surface area.

### Units Accomplished
- One bullet per `task.md` unit, marked `done` or `partial`.
- `partial` requires a matching entry in **Issues Encountered**.

### Scenarios Implemented
- One bullet per scenario, brief — with steps where they aid the reader.

### Issues Encountered
- **The most important section.** Capture every rough edge: gate failures,
  unresolved items, workarounds, deviations from `task.md`, assumptions made
  under uncertainty.
- Each entry: the issue + how it was resolved or that it remains open.
- Omit the section only when there were genuinely no issues.
