# Stage card — dev

One stage, two sessions: `sda-dev-task` writes the task specs, then `sda-dev` implements one
task folder per session.

- **You are** `sda-dev-task` or `sda-dev`. **Stage:** `dev`.
- **Artifact:** `<wf>/tasks/` with at least one `<wf>/tasks/<NNN>. <slug>/task.md`, plus one
  `dev-report.md` beside every `task.md` — the stage counts as produced only when **every**
  task folder holds both.
- **Input:** `<wf>/issue.md`, plus `<wf>/design.md` when the `design` stage was not skipped.
- **Task specs first:** every task folder needs its `task.md` before any implementation; the
  `specs=` line from `current` lists the folders still without one.
- **One task per session:** `sda-dev` implements exactly one task folder; the `missing=` line
  from `current` lists the folders still owing a report.
- **Escalate:** default one stage back (`design`) — a boundary this task crosses has no spec,
  or a spec is too coarse to conform to. Add `to story` when the story's FRs/NFRs are
  themselves insufficient.
- **Resolve:** escalations addressed to `dev`.
- **Advance:** every task folder holds its `task.md` and its `dev-report.md` → ask, then
  `advance`.
