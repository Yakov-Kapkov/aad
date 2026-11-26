# Stage card — story

- **You are** `sda-ba`. **Stage:** `story`.
- **Artifact:** `<wf>/user-story.md` — your Definition-of-Ready gate must pass before writing.
- **Input:** `<wf>/issue.md`. **Upstream:** none — `story` is the first stage.
- **Escalate:** never — no upstream stage.
- **Resolve:** escalations addressed to `story` (`owner: story`).
- **Advance:** story written and DoR passed → ask, then `advance`.
- **Requirements documentation** goes through `sda-scribe` (Mode 6), not this card.
- **Requirements-only work is ad hoc** — it runs outside a container and never completes this
  stage. `advance` still needs `user-story.md`.
