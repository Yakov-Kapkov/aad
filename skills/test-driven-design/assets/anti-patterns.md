# Anti-patterns

Anti-patterns and their fixes, by stage of the record.

## Flows

| Anti-pattern | Fix |
|---|---|
| One flow per screen or page | name flows by trigger and outcome |
| One flow per CRUD verb | name what the actor or the system achieves |
| One god-flow | split at the chained boundaries |
| A flow naming no component | name the component each step requires |
| Flows recorded from the finished code | record them during design, before implementation |

## The list

| Anti-pattern | Problem | Fix |
|---|---|---|
| An item that already carries its design | the list stops being a reminder, and the design is done before its turn | keep it to one line; develop it in stage 3 |
| An item that asserts a component's internals | it drives implementation detail instead of the component's behaviour | put it to the user — it may belong in the unit's tests |
| The list treated as a checklist to finish | items get developed because they are listed, not because they matter | ask; an item that does not matter comes off the list |
| Developing every item before re-reading the list | the items the work itself reveals are missed | return to the list whenever an item changes shape |
| A level added for completeness | a level with no pseudo-test is shape without meaning | ask whether the level is part of this change |
| A participant no pseudo-test names | structure the implementation would still have to build | ask the user whether it stays |

## A pseudo-test

| Anti-pattern | Problem | Fix |
|---|---|---|
| Given/When/Then inside the pseudo-test | the user-facing acceptance form, not the design form — and the copy drifts | state the act and the assertion; user-facing acceptance is stated once, in the requirement |
| A language-tagged code fence | looks executable; someone runs it as a test | leave the fence untagged — the content is language-shaped, not runnable |
| A pseudo-test naming no component | the design is not being tested, only wished for | ask which participant must hold it |
| A pseudo-test naming the level below's internals | the steps' level placement collapses — the design is asserted through a structure it does not own | ask where the behaviour is decided |
| A pseudo-test that fits only after renaming or splitting a participant | the skill is designing, not recording | put the fit to the user; keep their vocabulary |
| A second implementation of an existing concern | duplication that outlives every refactor | raise the existing participant; the user chooses reuse, extend, or abandon |
| A pseudo-test restating a written requirement | a copy — and one of the two drifts | cite the requirement instead |
| A negation where an outcome is expected — `not.toBe("")`, `not.toBe("Cat")` | passes on any wrong value | assert the expected value |
| An assertion that bakes a choice the design never stated — absent vs null, a frozen clock, an ordering tie | the pseudo-test decides a contract | state the choice in the record, or assert what the caller observes |
| An expected value that is interface copy | a wording or translation change fails an unrelated test | assert the observable state or the key, not the sentence |

## Asserting internals

| ✅ Observable outcome | 🚫 Implementation detail |
|---|---|
| the charge is attempted once — asserted at the seam the component crosses | a call between the component's own internals |
| the response carries the new balance | the repository write ran before the audit hook |
