---
name: test-driven-design
description: "Test-driven design for software designers — use when you are about to record a feature's design as tests with TDD methodology, or when you want to pin the current behaviour before refactoring. Triggers include: asking to record a design with tests, pin the current behaviour, or similar."
---

# Test-Driven Design — recording a design as tests

The user designs the change. This skill records that design as tests and pressure-tests it:
the vocabulary the user names becomes the vocabulary the pseudo-tests are written in, the
behaviours the user states are cut into flows, and each flow is proven by its pseudo-tests.
The record is refined until it holds together. The pseudo-tests are the design's acceptance
criteria — a design that satisfies no stated behaviour is a guess nobody can check.

A pseudo-test glues the agreed participants together and states the behaviour that must emerge
from them: the project's own language, with the noise of a real test stripped out — no imports,
no mock construction, no fixtures, no setup. Each speaks in its level's abstractions, so the
record is checkable and the implementation uses the names the user chose. Two audiences read
them: AI agents, who complete each into a runnable test, and humans, who read a short test
instead of paragraphs of prose. Pseudo-tests are never executed.

## Ownership

**The user owns the design.** Every participant, level, name, and behaviour in the record is
the user's decision. This skill neither makes them nor replaces them.

- **Record, don't choose.** Transcribe what the user decided; nothing enters the record on
  this skill's authority.
- **Write the pseudo-test to test the idea.** The pseudo-test is the pressure: if the user's
  naming, seam, or level does not hold, the pseudo-test is where it shows.
- **Question, don't rename.** A pseudo-test that needs a participant the user has not named, or
  that fits only after splitting or renaming one, is a question back to the user — never an
  edit.
- **Hand the decision back.** Present the options and what each costs; the user picks. Never a
  single take-it-or-leave-it answer, and never a change already applied.

## Method

Work through four steps, returning to the vocabulary and the list whenever either changes.

### Step 1 — Record the vocabulary

Take the participants the user names — the abstract classes, interfaces, types, and other
symbols a pseudo-test will name and the implementation will build.

- One line each: the name as the user said it, its level, and its responsibility in one
  sentence.
- Nothing is added, split, or renamed here. Put the gap to the user and record their answer —
  see [The vocabulary](#the-vocabulary).

### Step 2 — Build the list of tests, grouped by flow

Propose one short line per test — enough to remember and to start from; the user confirms the
list.

- Take items from: the requirement, the conversation, reading the code.
- Rephrase items for clarity and brevity — keep the proposed behaviour, not the wording.
- Record each item under the flow it proves; unclear → ask — see [Flows](#flows).
- The list is a reminder, not a specification, and it is meant to change.

### Step 3 — Develop an item into a pseudo-test

Take one line and shape it into a pseudo-test. It has to answer three things, precisely enough
that the user's design has to as well:

| It answers | Meaning |
|---|---|
| **behaviour** | what must be true |
| **seam** | the boundary it crosses |
| **component** | what must hold the behaviour — a participant from the vocabulary |

This is where the design meets its test: the pseudo-test has to hold against the user's
vocabulary and levels. One nothing can satisfy is a gap in the recorded design — put it to the
user; a participant no pseudo-test names is structure nobody asked for.

### Step 4 — Return to the vocabulary and the list

Developing an item often shows the recorded design has a gap: an item missing, one that is
really two, a participant absent or carrying two responsibilities. Put the gap to the user,
record what they decide, and carry on — as often as it takes.

**Done when** developing its items stops changing the list and the vocabulary.

**Deliverable:** the vocabulary as the user agreed it, and the confirmed list with every item
developed — pseudo-tests grouped by flow, each stating a required behaviour in its level's
vocabulary.

## Flows

A **flow** is a trigger-to-outcome path with one entry point and one observable terminal state.
It is the record's unit: every pseudo-test belongs to the flow it proves.

| Part | What it is |
|---|---|
| Trigger | what starts it: a user action, an inbound request, a domain event, a scheduled tick |
| Path | the steps it crosses, in order, each naming its component |
| Terminal outcome | what an outside observer checks when it finishes |
| Failure outcome | what that same observer sees when a step fails |

A flow without a failure outcome is unfinished — a happy-path-only flow hides the part of the
design most likely to be wrong.

**Two behaviours share a flow when they share both the trigger and the terminal outcome.**
Different trigger → different flow. Different outcome → different flow. Same both, crossing
different seams → one flow with two pseudo-tests.

**One rule, one pseudo-test.** The same behaviour proven in several flows is a single shared
pseudo-test, or the flows do not share their trigger and outcome — ask which holds.

**A handful per flow** — up to about seven. More usually means the flow is really two flows, or
the design is unfinished. Grow a flow only by finding a new trigger or a new terminal outcome,
never by re-labelling the same path.

**A flow may end in an artifact that triggers another** — an emitted event, a queued job, a
status transition. Keep them separate and joined by that artifact: the first must succeed when
the second never runs.

Example: flow anti-patterns and their fixes — [assets/anti-patterns.md](assets/anti-patterns.md#flows).

## The vocabulary

The vocabulary is the set of participants the design is made of: abstract classes, interfaces,
types, and other named symbols. The user names them; the pseudo-tests are written in them.

**Fixtures are participants too.** A helper a pseudo-test names — a stored-state reader, a
delivery trigger, a fake that fails — is something the implementation must build, so it is
recorded with the rest, at its own level.

Questions to put to the user: [assets/design-questions.md](assets/design-questions.md#the-vocabulary).

## Steps and levels

A **level** is the layer of abstraction a step happens at — an app level above, middleware
beneath it, the components beneath that. A component sits at one level, and the steps that cross
it inherit that level, so a level is recorded once — with its component — never per step. It
places a step inside a flow; it does not group the record. The user names the levels,
outside-in, and the names are the user's, not a fixed taxonomy.

Questions to put when a step is hard to place: [assets/design-questions.md](assets/design-questions.md#steps-and-levels).

Record the flows outside-in, so a reader meets the coarse behaviour first. Inside a flow, order
the steps from the outermost level down.

## What earns an item

Ask this while building the list — an item that fails all three is a question for the user, not
a quiet omission. The three tests: [assets/design-questions.md](assets/design-questions.md#what-earns-an-item).

Worth an item: flow and ordering · idempotency and duplication · failure semantics · consistency ·
concurrency · boundary behaviour.
**Not an item for this list:** behaviour behind a component's interface — private helpers,
internal state — write it as a unit test during implementation, not here · shape, fields and
error codes (an interface contract) · acceptance already stated in a requirement (cite it) ·
anything a type checker or linter catches.
**A new seam carries ≥2 pseudo-tests.** Each crosses it differently; with one, say so — the seam
may not be justified yet, and that is the user's call. Neither this nor the handful is a cap: a
flow that exceeds the handful because it adds several seams is a question for the user, not a
reason to drop one.

## Existing code comes first

Before a participant is added for a concern, find whether one already holds it. A second
implementation of something that already exists is paid for forever: two behaviours, drift,
and a double migration.

Read bounded: this change's concerns and their current callers — never a behaviour inventory of
the codebase.

- **Reuse** — the existing component already does this.
- **Extend** — it gains the behaviour without changing what its current callers depend on.
- **Abandon** — it cannot, without breaking them. That is a migration, not a rename: it needs a decision and a list of the consumers it moves.

A new participant is justified only when exploration found no home — the user decides on what
you found.

## Pinning behaviour you are about to restructure

Before restructuring code, pin the behaviour that must survive — read from the code as it is
today, not from what it ought to be. Those pseudo-tests are the restructuring's guard.

**If what you pin is a defect, that is a decision, not a default.** Fix it or preserve it — the
user says which — and record the choice. A pinned defect nobody chose becomes permanent
silence.

## Keeping pseudo-tests simple

The project's language is the form — this skill adds no syntax. **One outcome per
pseudo-test** — two outcomes are two pseudo-tests.

## Assert the outcome, never the internals

A pseudo-test states what is observable from **outside** the component that must hold it.

- **Gray box at the seam** — name the collaborator the component crosses; the mock itself is noise and is left out.
- **Black box for asserting** — assert the outcome the caller sees, or a call the component makes across its outward seam. A call between the component's own internals is not an outcome.

## Examples and anti-patterns

- Example: one flow's developed items in a project's own language, with the noise removed — [assets/example-pseudo-tests.md](assets/example-pseudo-tests.md). A change touching several flows gets one such group per flow.
- Anti-patterns and fixes for the list, a pseudo-test, its flows, and asserting internals — [assets/anti-patterns.md](assets/anti-patterns.md).
