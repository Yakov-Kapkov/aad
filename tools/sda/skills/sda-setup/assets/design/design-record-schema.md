# Design Record Schema

A **design record** carries the design-level context for one workflow's requirement: what the
design commits to, what it deliberately leaves out, and where the durable decisions live. It
exists so the task breakdown can be designed without re-deriving the architecture.

The file lives at `{workflow}/design.md`. It is **renewed in place** — an existing record is
read and updated, never duplicated into a new location.

---

## Template

```markdown
# Design: {title}

## Context
- **Workflow:** {id}. {slug}
- **User Story:** [user-story.md](user-story.md)

## Scope
**In:** {what this design covers}
**Out:** {what it deliberately does not cover}
**Deferred:** {what waits} — {reason} — revisit when {trigger}

## Approach
- {component added, split, or merged — and what it owns}
- {who calls whom — sync or async — ordering}
- {named pattern, and the problem it solves here}

## Decisions
- {decision title} — {one line: why it matters here} — [{decision doc}]({path})

## Docs
- [{document}]({path}) — {what it covers}

## Requirements
- {FR/NFR id} — {one line: how the design satisfies it}

## Impacts & risks
- {cross-layer effect, contract touched, migration needed}
- {risk} — {what it breaks, what must tolerate it}

## Open questions
- {unsettled question} — {what it affects}

## Handoff
**Settled:** {the constraints a task must honour}
**Specs:** use-as-is — {spec} · extend — {spec} · create — {spec}
**Not to re-decide:** {what is closed, and the location that closes it}
```

---

## Schema Rules

### Context
- First section. The reference block: workflow id + slug, and a relative link to the user story.
- Links are **relative**, so they resolve from the record's own folder.
- Requirement ids are not listed here — they belong to [Requirements](#requirements).

### Scope
- Three lines: `In`, `Out`, `Deferred`.
- `Out` draws a boundary the design deliberately keeps; it is not "not yet".
- A `Deferred` item carries a reason **and** a revisit trigger. A deferral without a trigger
  is a dropped requirement.

### Approach
- Components touched or created, the interactions between them, and the patterns in use —
  **stated as constraints**, not as a narrative of how to build it.
- Name a component by its role (`shared contract package`), never by symbol.
- Name a pattern only when it is load-bearing (`outbox`) — never as decoration.

### Decisions
- **Pointers**, one line each: decision title — why it matters here — link to the durable
  decision doc.
- The decision doc is the authoritative home. The record may never be the **sole** home of a
  durable decision.

### Docs
- One bullet per document this design produced or changed: relative link + what it covers.
- **State, not a log.** Renewal updates the list in place — it never accumulates per-session
  entries.
- Decision docs are listed under [Decisions](#decisions), not here.
- Relative `.md` links are expected here — [Altitude trigger](#4-altitude-trigger) exempts them.
- Omit only if the design changed no document.

### Requirements
- One line per requirement entry the design covers: id + how the design satisfies it.
- Cite the id; never restate the requirement text.

### Impacts & risks
- Cross-layer effects, contracts touched, migration needed.
- Each risk names what breaks and what must tolerate the change.

### Open questions
- One bullet per question the design has **not** settled, each naming what it affects.
- A deliberate scope cut belongs to [Scope](#scope) — not here.
- Omit only if none.

### Handoff
- **Settled** — the constraints the task breakdown must honour.
- **Specs** — the contracts the tasks read, extend, or create, split `use-as-is` / `extend` /
  `create`. The next stage traces contracts from this line.
- **Not to re-decide** — what is already closed, plus the location that closes it.
- Omit the `Specs` line if the design touches no contract.

### Snippet-free
- Every line must pass the [Altitude trigger](#4-altitude-trigger).
- A durable decision doc keeps a small `application` allowance. The record does not.

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
| Home | "Would an unrelated future feature need to know this?" | yes → durable decision doc · no → the record |
| Altitude | "Can two *different* implementations both satisfy this?" | yes → design level · no → this is code |

### 3. Excluder — not design decisions

| Not a design decision | Home |
|---|---|
| test scenarios and cases | the task document |
| file layout, symbol and type names | the task document |
| schema field lists, exact payloads | spec files, inlined into the task document |
| CLI flags, config keys, env vars | readmes (mechanical) |
| logging message text | the task document |
| implementation order / unit sequencing | the task document's implementation plan |

### 4. Altitude trigger

The test is mechanical — a line is below altitude if it contains a **source** file path, a symbol
name, a code fence, a schema field name, a config key, or SQL.

Documentation references are the exception: a relative `.md` link to a readme, a docs topic
file, a requirement entry, or a decision doc is **navigation**, and the record requires it in
[Context](#context) and [Docs](#docs).

---

## Form

- **Not BDD.** Behaviour already has two homes — acceptance in the user story, executable
  scenarios in the task document. A third home means two copies, and the non-executable one
  drifts. The record holds no scenarios.
- **Declarative.** decision → what it constrains → consequence.
- **Specific, not syntactic.** `outbox`, not `OutboxDispatcher.Dispatch()`.

---

## Completeness

> If the tasks were designed from this record alone, what would they have to invent?

Everything they would invent is a missed design decision. The record is complete when nothing
is left that the design already settled.

The record is **not** a completeness gate. Questions stay allowed — the goal is fewer
re-derivations, not zero asks.
