# Design Tests Schema

A **design tests** file records the behaviour one design change must exhibit. It names the
participants the behaviour is made of, lists the pseudo-tests, then develops each one as a
language-shaped assertion grouped under the level whose behaviour it states — the design is
revised until every pseudo-test reads cleanly. It is design evidence, not a runnable test: the
pseudo-tests are realised as real tests during implementation, and nothing here is executed.

Where the file lives is outside this schema. It is **renewed in place** — an existing file is
read and updated, never duplicated into a new location.

---

## Template

```markdown
# Design Tests: {title}

## Participants
- `{Name}` — {level} — {responsibility in one sentence}

## List
1. `{id}` — {one line: the behaviour asserted}
2. `{id}` — {one line: the behaviour asserted}

## {Level}

### `{id}` — {pseudo-test title}
{one line: what must be true}

{the act, then the assertion — in this language}

## Preserved

### `{id}` — {pseudo-test title}
{one line: the behaviour that must survive}
```

---

## Schema Rules

### Title
- `# Design Tests: {title}` — one line, mirroring the design record's title.

### Participants
- First section. One line per participant: its name, its level, and one sentence of
  responsibility.
- The vocabulary the pseudo-tests are written in: every participant a pseudo-test names is
  listed; a participant no pseudo-test names is not.

### List
- Second section, before any pseudo-test.
- One line per pseudo-test: its id, an em dash, one line stating the behaviour.
- Every acceptance criterion in the design record is developed by at least one pseudo-test;
  a criterion with none is a design gap. The record states the outcome; the pseudo-test
  states how it is proven.
- Ids are `T1`, `T2`, … and are stable — a renewed file keeps them.
- The list is the file's index: every pseudo-test has exactly one line, every line has exactly
  one pseudo-test. An id listed twice, or a pseudo-test with no line, is a defect.

### Level sections
- One `## {Level}` section per level the change touches, ordered outside-in — the system's own
  level names, not a fixed taxonomy.
- A level with no pseudo-test gets no section.
- A level written in more than one language splits into `## {Level} — {language}` sections.

### A pseudo-test
- `### \`{id}\` — {pseudo-test title}`, then one line stating what must be true.
- Then the pseudo-test body: the act, then the assertion.
- No source file path, no config key, no SQL, no production implementation.

### Fence and noise
- Untagged fence. Never executed, never treated as a source file.
- Omit imports, framework test structure, setup/teardown, fixtures, and mock construction.
  Keep the act, the assertion, and the component and seam.

### Preserved
- Present only when the change restructures existing behaviour; omit it otherwise.
- Same pseudo-test shape as any other section.

---

## Example

Example — a participant, a list line, and its pseudo-test, for a TypeScript subproject at
component level:

    ## Participants
    - `ChallengeService` — component — awards coins for a first-time submission

    ## List
    1. `T1` — a replayed challenge is rejected before scoring

    ## Component

    ### `T1` — replayed challenge
    a second submission of the same challenge awards no coins

      const result = await challengeService.submit(user, sameChallenge)

      expect(result.awardedCoins).toBe(0)
