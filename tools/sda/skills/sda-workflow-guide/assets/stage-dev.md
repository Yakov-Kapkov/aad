# Stage card — dev

- **You are** `sda-dev`. **Stage:** `dev`.
- **Artifact:** one `dev-report.md` per task folder under `<wf>/tasks/` — the stage counts as
  produced only when **every** folder holds one.
- **Input:** `<wf>/issue.md` + one task folder. **One task per session** — implement exactly
  one; the `missing=` line from `current` lists the folders still owing a report.
- **Finish:** this task's `dev-report.md` written → the stage's gate is **every** folder
  holding one; still owing (`missing=`) → report them and stop, each in its own session.
- **Escalate:** default one stage back (`tasks`); add `to design` when `design.md` itself
  must change.
- **Resolve:** escalations addressed to `dev`.
- **Advance:** every task folder holds its `dev-report.md` → ask, then `advance`.
