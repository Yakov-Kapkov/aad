# Workflow Schema

A **workflow** is a numbered container holding one requirement's planning
artifacts together with the state that records how far those artifacts have
progressed.

It lives at `{workflows-root}/<NNN>. <slug>/`. `{workflows-root}` defaults to
`.sda/workflows`.

`workflow.json` is written only by the workflow script; every field below is
script-owned. Progress runs `story → design → tasks → dev → ready`; an escalation
moves the pointer back, is recorded in `notes`, and keeps its evidence in
`escalations/`.

---

## Template

```
{workflows-root}/
  001. const-refactoring/
    workflow.json
    issue.md
    user-story.md
    design.md
    tasks/
      001. ui-refactoring/
        task.md
        dev-report.md
    escalations/
      001. 2026-09-15_14-20-tasks-to-design.md
```

```json
{
  "id": "001",
  "slug": "const-refactoring",
  "created": "2026-09-14",
  "stage": "story",
  "start": "story",
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
- One of `story`, `design`, `tasks`, `dev`, `ready` — in that order.
- `advance` moves exactly one stage forward, and only after the current stage's
  artifact exists.
- `escalate` moves back one or more stages; `resolve` moves forward exactly one.
- While any escalation is open, `advance` is refused.
- `story` is the first stage by default — a container may start later (see
  `start`). `dev` is the implementation stage: every task folder must hold its
  `dev-report.md` before the pointer can leave it. `ready` is terminal.

### `start`
- The stage the container was created at: `story` (default), `design`, or
  `tasks`. `dev` and `ready` are never a valid start.
- Stages before `start` are **skipped** — they produce no artifact, and
  `current` reports no `gap=` for them. If an escalation later moves the
  pointer back into a skipped stage, that stage becomes real and requires its
  artifact before `advance` can leave it.
- Absent on containers written before it existed; treated as `story`.

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
  has no artifact of its own — it is terminal.
- `dev`'s artifact is one `dev-report.md` per task folder under `tasks/`, written
  beside that task's `task.md`. The stage counts as produced only when **every**
  task folder holds one, so a container with an unimplemented task cannot leave
  `dev`.
- `issue.md` is the container's **entry artifact**, not a stage artifact: no stage owns it,
  it produces no `gap=` line, and it never blocks `advance`. It is created with the
  container.
- Every stage from `start` onward produces its artifact; a stage can be passed
  over only by starting the container after it. A design pass with nothing to
  decide renews `design.md` with what was considered and why it stands.
- An absent artifact for the current stage blocks `advance`, and `current`
  reports it as a `gap=` line. A partial `dev` gap is followed by a
  `missing=<folder>, <folder>` line naming the task folders still without a
  report, so the implementation stage can act without searching `.sda/`.
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
- A present `start` must be a known start stage (`story`, `design`, or
  `tasks`); when absent it is treated as `story`.
- The script verifies this before it reads state and stops on the first
  inconsistent container with an `error=` line — never a partial answer.
- `list` verifies every container before printing anything, so a corrupted one
  never leaves a half-list behind.

### Editing
- `workflow.json` is machine-written state. It is never hand-edited.
- `notes` is the only append point; every append is a deliberate,
  user-confirmed transition.
