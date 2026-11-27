# Flow Schema

A **flow file** records one path the design must support: its trigger, the components it crosses
in order, the outcome an outside observer checks when it finishes, and the outcome that same
observer sees when a step fails — with the pseudo-tests that pin each outcome.

One file per flow. It is design evidence, not a runnable test: the pseudo-tests are realised as
real tests during implementation, and nothing here is executed.

---

## Template

```markdown
# Flow: {trigger} → {outcome}

- Trigger: {what starts it}
- Covers: {criterion id}
- Path: {Component} → {Component}
- Terminal outcome: {what an outside observer checks when it finishes}
- Failure outcome: {what that observer sees when a step fails — one entry per distinct mode}
- Harness: {the fixtures and fakes the pseudo-tests assume}

## Tests

### `{T1}` — {what the test verifies}
{one line: the subject, the condition it holds under, and the result}

{the act, then the assertion}
```

---

## Schema Rules

### File and title
- `flows/<NN>-<slug>.md` — `<NN>` is two digits, the flow's position in the design's outside-in
  order, never renumbered; `<slug>` is the flow's kebab-case name.
- `# Flow: {trigger} → {outcome}` — one line. The name states the trigger and the outcome, never
  a screen, a CRUD verb, or the system.
- A flow that pins behaviour a restructure must keep carries `- Preserved: yes` alongside the
  same fields. It describes behaviour this change leaves alone, never one it adds.

### The fields
- `Trigger` — a user action, an inbound request, a domain event, or a scheduled tick.
- `Covers` — exactly one criterion id from the design record's `## Acceptance criteria`. A flow
  covers one criterion; a criterion may take several flows.
- `Path` — the components in order, exactly as the [component schema](component-schema.md)
  names them. A component crossed twice is listed twice. Never a level, a method, a signature,
  or a file — levels live with their components.
- `Terminal outcome` — what an outside observer checks when the flow finishes.
- `Failure outcome` — what that observer sees when a step fails. Mandatory: a flow without one
  is unfinished. One entry per **distinct observable mode**, not one per flow; past three, the
  flow is probably two — raise it.
- `Harness` — the fixtures and fakes the pseudo-tests assume (a stored-state reader, a delivery
  trigger, a failing fake), each named as the [component schema](component-schema.md) names it.
  A harness entry with no component row is a gap.
- `Preserved` — written only when `yes`; omit it otherwise.

### Tests
- Shape: `### \`{id}\` — {title}`, the expectation line, the body — the act, then the assertion.
- Title: subject and outcome. Never a topic, never a subject alone.
- Expectation line: subject, condition, result. A missing part is a gap — ask, never supply it.
- Example: ❌ `T1` — a product row in the selected language · ✅ `T1` — a product row shows its
  name in the selected language
- Ids are `T1`, `T2`, … and are stable — a renewed file keeps them.
- At least one pseudo-test per outcome: the terminal outcome and **each** failure mode are
  asserted.
- One outcome per pseudo-test — two outcomes are two pseudo-tests.
- A handful per flow — past about seven, the flow is probably two flows. Raise it; never drop a
  pseudo-test to meet the count.
- No source file path, no config key, no SQL, no production implementation.
- Untagged fence. Never executed, never treated as a source file.
- Omit imports, framework test structure, setup/teardown, fixtures, and mock construction. Keep
  the act, the assertion, and the component and seam.

### Standing
- The flow is the design's unit: the record's `Index` links this file against the criterion it
  covers, and that criterion's pseudo-tests are here.
- A `Path` naming a component the [component schema](component-schema.md) lacks is a gap —
  raise it, never add the row.
- A pseudo-test body is the caller's, copied verbatim — never rewritten, softened, or completed.

---

## Example

Example — one flow at component level, with its pseudo-test:

    # Flow: a player replays a challenge → zero coins awarded

    - Trigger: the player submits a challenge already played
    - Covers: AC2
    - Path: ChallengeService → CoinLedger
    - Terminal outcome: the submission is accepted and zero coins are awarded
    - Failure outcome: a typed rejection, and no coins awarded twice
    - Harness: challengeService's store, and a submission already recorded

    ## Tests

    ### `T1` — a replayed challenge awards no coins
    for a challenge already recorded, a second submission awards no coins

      const result = await challengeService.submit(user, sameChallenge)

      expect(result.awardedCoins).toBe(0)
