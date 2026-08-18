# Design Report Schema

`design_report.md` records **what changed in the repo's design/docs** during
a `sda-design` session. It is the handoff artifact for the next agent
(`sda-dev-task`) — that agent reads this file instead of the whole
conversation, because a fresh agent does not share the first agent's token
cache and replaying the full conversation is expensive.

The file lives at `.sda/design/reports/yyyy-MM-dd_HH-mm_<short-name>/design_report.md`.

---

## Template

```markdown
# Design Report: {short-name}

## Summary
{1-2 sentences: mode (system | feature) + what was designed or changed.}

## Docs Changed
- `{path}` — {created | updated | removed} — {what changed}

## Decisions Recorded
- {decision title} — {one-line decision} — {location}

## Handoff Context
{The minimum the next agent needs to design tasks without the conversation:
feature name, scope, layer, affected specs.}

## Unresolved
{Open questions or intentionally deferred work. Omit only if none.}
```

---

## Schema Rules

### Summary
- 1-2 sentences. Mode (system | feature) and what was designed or changed.

### Docs Changed
- One bullet per file: path + `created` / `updated` / `removed` + what changed.
- Covers readmes, `docs/` topic files, decision docs, diagrams, spec files,
  and `manifest.md`.

### Decisions Recorded
- One bullet per decision: title + one-line decision + the folder it lives in.
- Omit only if no decisions were recorded.

### Handoff Context
- The minimum the next agent needs to start: feature name, scope
  (`Feature: <name>` or `Global`), layer, and the affected-spec list
  (use-as-is / extend / create).
- Concise — the point is token economy.

### Unresolved
- Open questions or deferred work the next agent should know about.
- Omit only if none.
