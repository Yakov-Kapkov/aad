---
name: test-driven-design
description: "Test-driven design for software designers — building a short list of the tests a change needs, then developing each item into a pseudo-code case the design is shaped against. Use when: designing a change that alters behaviour, or pinning the behaviour of code you are about to restructure. Otherwise never load it."
---

# How to design software following Test Drive Design methodology

Design a change by writing its tests first: build a short list of the tests the change
needs, then develop each item into a pseudo-code case the design is revised against until
every one holds. The cases become the design's acceptance criteria — a design that
satisfies no stated behaviour is a guess nobody can check.

Cases are written in **pseudo-code**, not in a test framework — they describe the tests
the change needs, which in turn shape the behaviour. Two audiences read them: AI agents,
who turn each case into a real test in the project's language, and humans, who read a
short case instead of paragraphs of prose. Cases are never executed.

## Method

Work through three steps, returning to the list whenever it changes.

### Step 1 — Build the list of tests

Write one short line per test — enough to remember and to start from.

- Take items from: the requirement, the conversation, reading the code.
- Rephrase items for clarity and brevity — keep the proposed behaviour, not the wording.
- The list is a reminder, not a specification, and it is meant to change.

### Step 2 — Develop an item into a case

Take one line and shape it into a case. The case states three things, precisely enough
that the design has to answer them:

| The case states | Meaning |
|---|---|
| **behaviour** | what must be true |
| **seam** | the boundary it crosses |
| **component** | what must hold the behaviour |

This is where the design happens: the case is what the design is revised against.
A case nothing can satisfy is a design gap; a component no case requires is invented
structure.

### Step 3 — Return to the list

Developing an item often shows one is missing, one is really two, or two are one.
Go back to the list, amend it, and carry on — as often as it takes.

**Done when** developing its items stops changing the list.

**Deliverable:** the list, with every item developed — a set of tests, each stating a
required behaviour.

## What earns an item

Ask this while building the list — an item that fails all three is not worth one.

| Test | Question |
|---|---|
| Composition | Does the behaviour arise from ≥2 components interacting, or from crossing a boundary? |
| Design-constraining | Could two different implementations satisfy it differently? |
| Late-cost | Would discovering it late be expensive — ordering, retry, concurrency, consistency? |

Worth an item: flow and ordering · idempotency and duplication · failure semantics · consistency ·
concurrency · boundary behaviour.
**Not an item for this list:** unit-level behaviour — write it as a unit test during
implementation, not here · shape, fields and error codes (an interface contract) · acceptance
already stated in a requirement (cite it) · anything a type checker or linter catches.
**A handful per flow.** Past ~7 items, the flow is too big — or the design is unfinished.

## Existing code comes first

Find the home of a concern before designing a component for it. A second implementation of
something that already exists is paid for forever: two behaviours, drift, and a double migration.

Read bounded: this change's concerns and their current callers — never a behaviour inventory of
the codebase.

- **Reuse** — the existing component already does this.
- **Extend** — it gains the behaviour without changing what its current callers depend on.
- **Abandon** — it cannot, without breaking them. That is a migration, not a rename: it needs a decision and a list of the consumers it moves.

A new component is justified only when exploration found no home for the concern.

## Pinning behaviour you are about to restructure

Before restructuring code, pin the behaviour that must survive — read from the code as it is
today, not from what it ought to be. Those cases are the restructuring's guard.

**If what you pin is a defect, that is a decision, not a default.** Fix it or preserve it, say
which, and record the choice — a pinned defect nobody chose becomes permanent silence.

## Keeping cases simple

Pseudo-code format is the user's choice — this skill defines no syntax. One rule holds
in any format:

- **One outcome per case** — two outcomes are two cases.


## Assert the outcome, never the internals

A case states what is observable from **outside** the component that must hold it.

- **Gray box for mocking** — mock that component's collaborators at the seam it crosses; never reach inside the component.
- **Black box for asserting** — assert the outcome the caller sees. An internal call, field, or intermediate state is not an outcome.

| ✅ Observable outcome | 🚫 Implementation detail |
|---|---|
| the charge is attempted once | `chargeHandler` called `ledger.post` once |
| the response carries the new balance | the repository write ran before the audit hook |

## Examples

Format is the user's choice. One project's shape — each scenario is a developed list item
(shortened):

```
# Programming Challenge Instance test suite

## Frontend - APP layer

### Integration

SetUp
  program = createMockProgram()
  tasks = [{id: 1}, {id: 2}]
  api = { execute: mock().fn() }
  challengeInstance = new ChallengeInstance(executionDetails, challengeClass, tasks)

Scenario 1: the executor calls the backend execute method
  challengeExecutor = new ChallengeExecutor(conditionEvaluator, taskRunner, api)
  challengeExecutor.execute(program, challengeInstance)
  
  expect(api.execute).calledOnceWith(challengeInstance.id, program)

Scenario 2: the executor verifies preconditions for the program code
  challengeExecutor = new ChallengeExecutor(conditionEvaluator, taskRunner, api)
  challengeExecutor.execute(program, challengeInstance)
  
  expect(conditionEvaluator.evaluate).calledOnceWith(program)

Scenario 3: the executor returns the result of the program execution
  api = { execute: mock().fn().returns({ result: 'success' }) }
  
  challengeExecutor = new ChallengeExecutor(conditionEvaluator, taskRunner, api)
  executeResult = challengeExecutor.execute(program, challengeInstance)

  expect(executeResult.result).toBe('success')
```

## Anti-patterns

### The list

| Anti-pattern | Problem | Fix |
|---|---|---|
| An item that already carries its design | the list stops being a reminder, and the design is done before its turn | keep it to one line; develop it in stage 2 |
| An item that is a unit test | it drives implementation detail instead of design | move it to the unit's tests |
| The list treated as a checklist to finish | items get developed because they are listed, not because they matter | amend the list first — an item that does not matter comes off it |
| Developing every item before re-reading the list | the items the work itself reveals are missed | return to the list whenever an item changes shape |

### A case

| Anti-pattern | Problem | Fix |
|---|---|---|
| Given/When/Then inside the case | the acceptance form, not the design form — and the copy drifts | state the behaviour in pseudo-code; acceptance is stated once, elsewhere |
| A language-tagged code fence | looks executable; someone runs or copies it | untagged pseudo-code |
| A case naming no component | the design is not being tested, only wished for | name what must hold it |
| A second implementation of an existing concern | duplication that outlives every refactor | reuse or extend the existing component, or record the abandonment |
| A case restating a written requirement | a copy — and one of the two drifts | cite the requirement instead |
