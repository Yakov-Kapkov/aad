# Stage card — dev

- **Stage:** `dev` — implementation.
- **Artifact:** `<wf>/dev-report.md` — one file at the container root, recording what was
  actually built.
- **Input:** `<wf>/issue.md`, plus `<wf>/design.md` when the `design` stage was not skipped.
- **Escalate:** default one stage back (`design`) — a boundary the work crosses has no spec,
  or a spec is too coarse to conform to. Add `to story` when the story's FRs/NFRs are
  themselves insufficient.
- **Resolve:** escalations addressed to `dev`.
- **Advance:** `dev-report.md` written → ask, then `advance`.
