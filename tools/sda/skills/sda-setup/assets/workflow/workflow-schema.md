# Workflow Schema

A **workflow** is a numbered container holding one requirement's planning
artifacts together with the state that records how far those artifacts have
progressed.

It lives at `{workflows-root}/<NNN>. <slug>/`. `{workflows-root}` defaults to
`.sda/workflows`.

`workflow.json` is written only by the workflow script; every field below is
script-owned. Progress runs `story → design → tasks → ready`; an escalation
moves the pointer back, is recorded in `notes`, and keeps its evidence in
`escalations/`.

---

## Template

```
{workflows-root}/
  001. const-refactoring/
    workflow.json
    user-story.md
    design.md
    tasks/
      001. ui-refactoring/
    escalations/
      001. 2026-09-15_14-20-tasks-to-design.md
```

```json
{
  "id": "001",
  "slug": "const-refactoring",
  "created": "2026-09-14",
  "stage": "story",
  "notes": []
}
```

---

## Schema Rules

### Folder name
- `<NNN>. <slug>` — a zero-padded 3-digit prefix, a period, one space, then
  the slug in kebab-case.
- The prefix is the highest existing prefix plus one. Never renumbered.

### `id`
- The folder's numeric prefix, as a string — keeps leading zeros.

### `slug`
- Kebab-case, identical to the slug part of the folder name. Unique across
  workflows.

### `created`
- `yyyy-MM-dd`.

### `stage`
- One of `story`, `design`, `tasks`, `ready` — in that order.
- `advance` moves exactly one stage forward, and only after the current stage's
  artifact exists.
- `escalate` moves back one or more stages; `resolve` moves forward exactly one.
- While any escalation is open, `advance` is refused.
- `story` is the first stage; `ready` is terminal.

### `notes`
- Append-only. Entries are never edited, reordered, or removed.
- Each entry carries a `type` discriminator.

| `type` | Fields | Meaning |
|---|---|---|
| `escalation` | `id`, `from`, `to`, `reason`, `brief`, `date` | a stage asked an upstream stage to reconsider |
| `resolution` | `id`, `report`, `date` | the upstream stage answered, and the pointer moved forward one |

- `id` is `E1`, `E2`, … assigned in order and never reused.
- `reason` and `report` are free text and required. They are written by different
  stages: the escalation by the blocked one, the resolution by the target.
- `brief` is the path of the evidence file under `escalations/`, and is required:
  a raise without evidence is refused.
- Open-ness is **derived**: an escalation is open while no `resolution` carrying
  the same `id` follows it. The open escalations form a LIFO stack, and the
  deepest one is the only one `resolve` may close.

### Artifacts
- `user-story.md` (story), `design.md` (design), and `tasks/` (tasks). `ready`
  has no artifact of its own.
- Every stage produces its artifact; no stage can be passed over. A design pass
  with nothing to decide renews `design.md` with what was considered and why it
  stands.
- An absent artifact for the current stage blocks `advance`, and `current`
  reports it as a `gap=` line.
- `tasks/` is created with the container and may stay empty; `tasks` counts as
  produced only when it holds at least one entry.

### Escalation briefs
- `escalations/` holds one brief per escalation, created with the container. The
  recorded `notes[].brief` path is the only link between the two.
- Evidence, not state: the script checks that the file exists and never reads it. A
  brief whose raise was abandoned stays on disk — `notes` remains the only truth about
  what was raised.

### Consistency
- A container is consistent only when `workflow.json` exists, parses, carries
  `id`, `slug`, `created`, and `stage`, and holds a known `stage`.
- The script verifies this before it reads state and stops on the first
  inconsistent container with an `error=` line — never a partial answer.
- `list` verifies every container before printing anything, so a corrupted one
  never leaves a half-list behind.

### Editing
- `workflow.json` is machine-written state. It is never hand-edited.
- `notes` is the only append point; every append is a deliberate,
  user-confirmed transition.
