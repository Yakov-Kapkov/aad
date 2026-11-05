# Dev Report Schema

`dev-report.md` records **what was actually implemented** — the ground truth of
the implementation, including problems hit along the way. It sits at the
workflow container root, beside `design.md`. `design.md` is *intent*;
`dev-report.md` is *actual*. The two diverge when models make mistakes —
capturing that divergence is the report's main value.

---

## Template

```markdown
# Dev Report: {work-name}

## Summary
{1-2 sentences: what the work was and what was actually done.}

## Files Changed
- `{path}` — {what changed}

## Units Accomplished
- {Unit N — name} — {done | partial}

## Scenarios Implemented
- {scenario N — name} — {brief description, with steps where relevant}

## Issues Encountered
{Problems hit during RED/GREEN/REFACTOR/QUALITY: gate failures,
unresolved items, workarounds, deviations from the design, assumptions made under
uncertainty. Omit only if genuinely none.}
1. {Unit or PHASE if the issues happenned after all units}.
{issue}
{how it was resolved, or left open}
2. ...

## Follow-up Opportunities
{Pre-existing issues or intentionally deferred work left open — the natural
next piece of work. Distinct from Issues Encountered (implementation rough edges).
Omit only if genuinely none.}
1. {unit or file}. {issue}. {why deferred / what a follow-up would cover}
2. ...
```

---

## Schema Rules

### Summary
- 1-2 sentences. What the work was; what was actually done.

### Files Changed
- One bullet per file: path + what changed. The implementation surface area.

### Units Accomplished
- One bullet per implemented unit, marked `done` or `partial`.
- `partial` requires a matching entry in **Issues Encountered**.

### Scenarios Implemented
- One bullet per scenario, brief — with steps where they aid the reader.

### Issues Encountered
- **The most important section.** Capture every rough edge: gate failures,
  unresolved items, workarounds, deviations from the design, assumptions made
  under uncertainty.
- Each entry: the issue + how it was resolved or that it remains open.
- Omit the section only when there were genuinely no issues.

### Follow-up Opportunities
- Pre-existing issues or intentionally deferred work left open — the natural next piece of work.
- Each entry: the issue + why deferred / what a follow-up would cover.
- Omit the section only when there were genuinely none.
