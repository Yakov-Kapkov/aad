# Design Record Schema

A **design record** is the design folder's entry point: the overall design, plus the index that
reaches every other file the design is recorded in. It carries what the design commits to, what
it deliberately leaves out, and where the durable decisions live. It is the implementation
stage's primary input — what behaviour to deliver, and, where the shape is load-bearing, the how
that behaviour must take.

Every other file of the design — the component model, the contracts, and one file per flow — is
reached through [Index](#index). The record names them; it never restates what they hold.

Where the design's folder lives is outside this schema. The record sits at its root and is
**renewed in place** — an existing record is read and updated, never duplicated into a new
location.

---

## Template

```markdown
# Design: {title}

## Context
- **Workflow:** {id}. {slug}
- **User Story:** [../user-story.md](../user-story.md)

## Index
| What | Where | Covers |
|---|---|---|
| components | [components.md](components.md) | {what the component model holds} |
| contracts | [contracts.md](contracts.md) | {what the seams hold} |
| {flow name} | [flows/{NN}-{slug}.md](flows/{NN}-{slug}.md) | {criterion id} · {test ids} |

## Scope
**In:** {what this design covers}
**Out:** {what it deliberately does not cover}
**Deferred:** {what waits} — {reason} — revisit when {trigger}

## Approach
- {component added, split, or merged — and what it owns}
- {named pattern, and the problem it solves here}

## Decisions
- {decision title} — {one line: why it matters here} — [{ADR doc}]({path})

## Conventions
- {convention title} — {one line: the rule it establishes} — [{convention doc}]({path})

## Docs
- [{document}]({path}) — {what it covers}

## Requirements
- {FR/NFR id} — {implemented | amended | retired} — {one line: how the design satisfies it}

## Acceptance criteria
- {id} — {one line: the outcome and the design condition the implementation must honour}

## Impacts & risks
- {cross-layer effect, migration needed}
- {risk} — {what it breaks, what must tolerate it}

## Rollout
- {what must land before what}
- {the condition that blocks release}
- {the way back, or `none`}

## Open questions
- {unsettled question} — {what it affects}

## Handoff
**Settled:** {the constraints implementation must honour}
**Contracts:** [contracts.md](contracts.md) — {n} seams touched
**Not to re-decide:** {what is closed, and the location that closes it}
```

---

## Schema Rules

### Context
- First section. The reference block: workflow id + slug, and a relative link to the user story.
- Links are **relative**, so they resolve from the record's own folder — the story beside the
  folder is `../user-story.md`.
- Requirement ids are not listed here — they belong to [Requirements](#requirements).

### Index
- Second section: the map a reader follows to everything else the design records.
- One row per file in the design folder other than this one: `components.md` and `contracts.md`
  when the folder holds them, and one row per flow file.
- `What` — the file's subject in a few words: `components`, `contracts`, or the flow's name.
- `Where` — a relative link. A flow file is exactly `flows/<NN>-<slug>.md`.
- `Covers` — for a flow row: its criterion id and the ids of its pseudo-tests. For a model
  row: one short phrase saying what the file holds, and no criterion.
- Rows run outside-in: the model files, then the flows in the order they are read.
- Every file in the folder except this one has a row, every row names a file that exists when
  the session ends, and every acceptance criterion appears in a flow row — unless the record
  states none. A file with no row, a row with no file, or a criterion in no row is a defect.
- No other section restates a flow, a component, or a contract — the row points at it instead.

### Scope
- Three lines: `In`, `Out`, `Deferred`.
- `Out` draws a boundary the design deliberately keeps; it is not "not yet".
- A `Deferred` item carries a reason **and** a revisit trigger. A deferral without a trigger
  is a dropped requirement.

### Approach
- Components touched or created, and the patterns in use — **stated as constraints**, not as a
  narrative of how to build it. A complex case states the how too: the owner, the seam, the
  pattern the behaviour must go through.
- Name a component by its role (`shared contract package`), never by symbol.
- Name a pattern only when it is load-bearing (`outbox`) — never as decoration.
- Call direction, sync vs async, and ordering are not stated here — those are seams, and the
  [contracts file](#index) owns them.

### Decisions
- **Pointers**, one line each: decision title — why it matters here — link to the durable
  ADR doc.
- The ADR doc is the authoritative home. The record may never be the **sole** home of a
  durable decision.

### Conventions
- **Pointers**, one line each: convention title — one line on the rule it establishes —
  link to the durable convention doc.
- The convention doc is the authoritative home. The record may never be the **sole** home
  of a durable convention.

### Docs
- One bullet per document this design produced or changed: relative link + what it covers.
- **State, not a log.** Renewal updates the list in place — it never accumulates per-session
  entries.
- Convention and ADR docs are listed under [Decisions](#decisions) and
  [Conventions](#conventions), not here.
- The design folder's other files are not listed here — [Index](#index) is their map.
- Relative `.md` links are expected here — [Altitude trigger](#4-altitude-trigger) exempts them.
- Omit only if the design changed no document.

### Requirements
- One line per requirement entry the design covers: id, its disposition — `implemented`,
  `amended`, or `retired` — and how the design satisfies it.
- A requirement the design narrows, replaces, or drops is named by id; never silently omitted.
- Cite the id; never restate the requirement text.

### Acceptance criteria
- The implementation stage's goal: what must be observably true when the change is done.
- Written from two sources: the requirement — a user-story scenario, or an `issue.md` item
  when no story exists — and the design this record settles.
- Each criterion cites the source line it comes from. The chain is criterion → flow →
  pseudo-test; cite, never restate, and let a flow file carry the next link.
- One line per criterion: id + the outcome, in design language. Add implementation detail
  only when the criterion cannot be stated without it.
- A design-shaped criterion states the condition the implementation must honour — the shape
  [Approach](#approach) settles. Never the symbol or source file.
- Ids are stable across renewals; a criterion the design drops moves to [Scope](#scope)
  as `Out` or `Deferred`.
- Never a Gherkin block. The pseudo-tests that develop each criterion live in the flow files,
  reached through [Index](#index).
- Omit only if the change delivers no user-observable behaviour.

### Impacts & risks
- Cross-layer effects and migration needed.
- Each risk names what breaks and what must tolerate the change. A risk attached to a contract
  names it as the [contracts file](#index) does — never restates the seam.

### Rollout
- Only when the change is disruptive: a migration, a stored-shape change, a coordinated
  multi-layer release, or a step that cannot be undone. Omit otherwise.
- `Way back` is stated even when it is `none` — an unanswered one is the gap, not the answer.
- A release-blocking condition is also an [acceptance criterion](#acceptance-criteria).

### Open questions
- One bullet per question the design has **not** settled, each naming what it affects.
- A deliberate scope cut belongs to [Scope](#scope) — not here.
- Omit only if none.

### Handoff
- **Settled** — the constraints implementation must honour.
- **Contracts** — a link to the [contracts file](#index) and how many seams it records. The
  next stage traces each seam, and its spec, from that file.
- **Not to re-decide** — what is already closed, plus the location that closes it.
- Omit the `Contracts` line if the design crosses no seam.

### Snippet-free
- Every line must pass the [Altitude trigger](#4-altitude-trigger).
- A durable convention doc keeps a small `application` allowance. The record does not.

---

## Decision taxonomy

Four guards, applied in order. A statement that survives all four is a design decision and
belongs in the record; everything else has a home elsewhere.

### 1. Generator — walk these kinds

| Kind | Answers | Example |
|---|---|---|
| Boundary / ownership | which layer owns this concern | — |
| Structure | what components are added, split, merged | extract a shared package |
| Interaction / flow | who calls whom, sync vs async, ordering | backend → outbox → worker |
| Pattern | which named pattern, for which problem | outbox, CQRS |
| Contract shape | *semantically* what crosses a boundary | event carries identity + version |
| Cross-cutting | retry / timeout / authz / logging policy | — |
| Scope | in / out / deferred + reason + revisit trigger | "broker deferred" |
| Impact / risk | what this breaks, migration needed | readers tolerate eventual consistency |

Walk the list — do not recall it.

### 2. Filter — two discriminators

| Discriminator | Test | Routes to |
|---|---|---|
| Home | "Would an unrelated future feature need to know this?" | yes → convention (how) or ADR (why) · no → the record |
| Altitude | "Can two *different* implementations both satisfy this?" | yes → design level · no → this is code |

### 3. Excluder — not design decisions

| Not a design decision | Home |
|---|---|
| pseudo-tests and their scenarios | the change's flow files |
| file layout, symbol and type names | implementation |
| schema field lists, exact payloads | spec files |
| CLI flags, config keys, env vars | readmes (mechanical) |
| logging message text | implementation |
| implementation order / unit sequencing | implementation |

### 4. Altitude trigger

The test is mechanical — a line is below altitude if it contains a **source** file path, a symbol
name, a code fence, a schema field name, a config key, or SQL.

Documentation references are the exception: a relative `.md` link to a readme, a docs topic
file, a requirement entry, a convention doc, or an ADR doc is **navigation**, and the record
requires it in [Context](#context) and [Docs](#docs).

---

## Form

- **Not BDD.** Acceptance detail has two homes off this record — the Gherkin scenarios in the
  user story, and the pseudo-tests in the change's flow files. The record carries only the
  one-line [acceptance criteria](#acceptance-criteria); it holds no scenarios, and
  [Index](#index) links each flow file.
- **Declarative.** decision → what it constrains → consequence.
- **Specific, not syntactic.** `outbox`, not `OutboxDispatcher.Dispatch()`.

---

## Completeness

> If implementation started from this record alone, what would it have to invent?

Everything they would invent is a missed design decision. The record is complete when nothing
is left that the design already settled.

The record is **not** a completeness gate. Questions stay allowed — the goal is fewer
re-derivations, not zero asks.
