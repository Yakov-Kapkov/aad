---
name: test-driven-design
description: "Test-driven design for software designers — use when you are about to record a feature's design as tests with TDD methodology, or when you want to pin the current behaviour before refactoring. Triggers include: asking to record a design with tests, pin the current behaviour, or similar."
---

# Test-Driven Design — recording a design as tests

The user designs the change. This skill records that design as tests and pressure-tests it:
the vocabulary the user names becomes the vocabulary the pseudo-tests are written in, each
behaviour the user states becomes a pseudo-test, and the record is refined until it holds
together. The pseudo-tests are the design's acceptance criteria — a design that satisfies no
stated behaviour is a guess nobody can check.

A pseudo-test glues the agreed participants together and states the behaviour that must emerge
from them. It is written in the language the project already uses, with the noise of a real test
stripped out — no imports, no mock construction, no fixtures, no setup — so what remains is the
act and the assertion. Each one speaks in its level's abstractions, so the record is checkable
and the implementation is written against the same names the user chose. Two audiences read
them: AI agents, who complete each pseudo-test into a runnable test, and humans, who read a
short test instead of paragraphs of prose. Pseudo-tests are never executed.

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

### Step 2 — Build the list of tests, grouped by level

Propose one short line per test — enough to remember and to start from; the user confirms the
list.

- Take items from: the requirement, the conversation, reading the code.
- Rephrase items for clarity and brevity — keep the proposed behaviour, not the wording.
- Record each item under the level the user assigns it to; unclear → ask — see [Levels](#levels).
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
developed — pseudo-tests grouped by level, each stating a required behaviour in its level's
vocabulary.

## The vocabulary

The vocabulary is the set of participants the design is made of: abstract classes, interfaces,
types, and other named symbols. The user names them; the pseudo-tests are written in them.

These are questions to put to the user — not rules this skill applies:

| Question | When the answer is no |
|---|---|
| Does a pseudo-test need this participant? | it may not be needed yet — propose leaving it out |
| Is it one responsibility, at one level? | ask whether two participants are hiding in it |
| Does an existing participant already hold this concern? | see [Existing code comes first](#existing-code-comes-first) |
| Does the name say the role, in the domain's language? | propose a name; the user keeps or changes it |
| Is every symbol a pseudo-test names listed here? | ask which participant holds it — never add one yourself |

## Levels

Pseudo-tests are grouped by **level** — the layer of abstraction whose behaviour they state. The
user names the levels the system has, outside-in: an app level above, middleware beneath it, the
components beneath that. The names are the user's, not a fixed taxonomy.

These are the questions to put when a pseudo-test is hard to place:

| Question | What to raise |
|---|---|
| Can this pseudo-test only be written a level above where the behaviour lives? | the rule is hidden behind that level's wiring — say so |
| Does it reach into the level below? | ask which participant at that level owns the behaviour, or whether it belongs lower |
| Does this level have no pseudo-test? | ask whether the level is part of this change; an empty level may be shape without meaning |
| Is a participant used by two levels? | ask which level owns it — shared vocabulary is a design decision |
| Does the same behaviour appear at two levels? | ask what each level proves that the other cannot, or it is one pseudo-test written twice |

Record the groups outside-in, so a reader meets the coarse behaviour first. Each group reads in
its level's abstraction: an app-level pseudo-test speaks in requests, screens, or commands; a
component-level pseudo-test speaks in the component's interface and the collaborators it crosses.

## What earns an item

Ask this while building the list — an item that fails all three is a question for the user, not
a quiet omission.

| Test | Question |
|---|---|
| Composition | Does the behaviour arise from ≥2 components interacting, or from crossing a boundary? |
| Design-constraining | Could two different implementations satisfy it differently? |
| Late-cost | Would discovering it late be expensive — ordering, retry, concurrency, consistency? |

Worth an item: flow and ordering · idempotency and duplication · failure semantics · consistency ·
concurrency · boundary behaviour.
**Not an item for this list:** behaviour behind a component's interface — private helpers,
internal state — write it as a unit test during implementation, not here · shape, fields and
error codes (an interface contract) · acceptance already stated in a requirement (cite it) ·
anything a type checker or linter catches.
**A handful per flow.** Past ~7 items, raise it — the flow may be too big, or the design
unfinished.
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

The project's language is the form — this skill adds no syntax of its own. One rule holds in
any format:

- **One outcome per pseudo-test** — two outcomes are two pseudo-tests.


## Assert the outcome, never the internals

A pseudo-test states what is observable from **outside** the component that must hold it.

- **Gray box at the seam** — name the collaborator the component crosses; the mock itself is noise and is left out.
- **Black box for asserting** — assert the outcome the caller sees, or a call the component makes across its outward seam. A call between the component's own internals is not an outcome.

| ✅ Observable outcome | 🚫 Implementation detail |
|---|---|
| the charge is attempted once — asserted at the seam the component crosses | a call between the component's own internals |
| the response carries the new balance | the repository write ran before the audit hook |

## Examples

The project's language, with the noise removed. One project's shape — one level shown here; a
change touching several gets one such group per level. Each scenario is a developed list item
(shortened):

```
# Programming Challenge Instance test suite

## Frontend — component level

Scenario 1: the executor calls the backend execute method
  challengeExecutor.execute(program, challengeInstance)

  expect(api.execute).calledOnceWith(challengeInstance.id, program)

Scenario 2: the executor verifies preconditions for the program code
  challengeExecutor.execute(program, challengeInstance)

  expect(conditionEvaluator.evaluate).calledOnceWith(program)

Scenario 3: the executor returns the result of the program execution
  result = challengeExecutor.execute(program, challengeInstance)

  expect(result.result).toBe('success')
```

## Anti-patterns

### The list

| Anti-pattern | Problem | Fix |
|---|---|---|
| An item that already carries its design | the list stops being a reminder, and the design is done before its turn | keep it to one line; develop it in stage 3 |
| An item that asserts a component's internals | it drives implementation detail instead of the component's behaviour | put it to the user — it may belong in the unit's tests |
| The list treated as a checklist to finish | items get developed because they are listed, not because they matter | ask; an item that does not matter comes off the list |
| Developing every item before re-reading the list | the items the work itself reveals are missed | return to the list whenever an item changes shape |
| A level added for completeness | a level with no pseudo-test is shape without meaning | ask whether the level is part of this change |
| A participant no pseudo-test names | structure the implementation would still have to build | ask the user whether it stays |

### A pseudo-test

| Anti-pattern | Problem | Fix |
|---|---|---|
| Given/When/Then inside the pseudo-test | the user-facing acceptance form, not the design form — and the copy drifts | state the act and the assertion; user-facing acceptance is stated once, in the requirement |
| A language-tagged code fence | looks executable; someone runs it as a test | leave the fence untagged — the content is language-shaped, not runnable |
| A pseudo-test naming no component | the design is not being tested, only wished for | ask which participant must hold it |
| A pseudo-test naming the level below's internals | the level grouping collapses — the design is asserted through a structure it does not own | ask where the behaviour is decided |
| A pseudo-test that fits only after renaming or splitting a participant | the skill is designing, not recording | put the fit to the user; keep their vocabulary |
| A second implementation of an existing concern | duplication that outlives every refactor | raise the existing participant; the user chooses reuse, extend, or abandon |
| A pseudo-test restating a written requirement | a copy — and one of the two drifts | cite the requirement instead |
