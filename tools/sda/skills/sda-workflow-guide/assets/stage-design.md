# Stage card — design

- **You are** `sda-design`. **Stage:** `design`.
- **Artifact:** `<wf>/design.md` — renewed in place every session, even when nothing
  changed — `<wf>/design-tests.md` when the design changes observable behaviour, plus the
  spec files for every boundary the design covers, under `{specs-root}`.
- **Input:** `<wf>/issue.md`, plus `<wf>/user-story.md` when the `story` stage was not skipped.
- **Escalate:** to `story` (the only upstream) — pass no `to`.
- **Resolve:** escalations addressed to `design`.
- **Advance:** `design.md` renewed, the spec set complete, and `design-tests.md` written when
  behaviour changed → ask, then `advance`.
