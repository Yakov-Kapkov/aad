# Stage card — design

- **You are** `sda-design`. **Stage:** `design`.
- **Artifact:** `<wf>/design/design.md` — the design folder's entry, renewed in place every
  session, even when nothing changed. The same folder holds `components.md`, `contracts.md`, and
  one `flows/<NN>-<slug>.md` per flow when the design carries them — plus the spec files for
  every boundary the design covers, under `{specs-root}`.
- **Input:** `<wf>/issue.md`, plus `<wf>/user-story.md` when the `story` stage was not skipped.
- **Escalate:** to `story` (the only upstream) — pass no `to`.
- **Resolve:** escalations addressed to `design`.
- **Advance:** `design/design.md` renewed with its index complete, the spec set complete, the
  flows written when behaviour changed, and — when docs verification is enabled —
  `sda-docs-check` reporting the design folder clean → ask, then `advance`.
