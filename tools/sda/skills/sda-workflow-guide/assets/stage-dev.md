# Stage card — dev

- **You are** `sda-dev` (default) or any implementation agent. **Stage:** `dev` — implementation.
- **Artifact:** `<wf>/dev-report.md` — one file at the container root, recording what was
  actually built.
- **Input:** `<wf>/issue.md`, plus `<wf>/design/` when the `design` stage was not skipped —
  the entry first, then the components, the contracts, and only the flows the work touches.
- **Escalate:** default one stage back (`design`) — a boundary the work crosses has no spec,
  or a spec is too coarse to conform to. Add `to story` when the story's FRs/NFRs are
  themselves insufficient.
- **Resolve:** escalations addressed to `dev`.
- **Advance:** `dev-report.md` written, with every criterion of the flows it touched marked
  passing or named as a deviation → ask, then `advance`.
