# User Story Schema

A User Story has two layers: one **Actor statement** (Layer 1), then machine-readable
**Gherkin scenarios** (Layer 2), plus the NFR requirement entries the story is subject to.

## Template

````markdown
# User Story: {slug}

## Context
{Omit entirely for a standalone story.}
- **Workflow:** {id}. {slug}
- **Requirements:** [{FEATURE-SLUG}-{NNN}]({path})

## Actor statement
As a {role}, I want {action}, so that {benefit}.

## Scenarios

### FR-1 — {scenario name}  (happy)
```gherkin
Given {precondition}
When {action}
Then {observable outcome}
```

### FR-2 — {scenario name}  (negative)
```gherkin
Given {precondition}
When {invalid action}
Then {graceful rejection}
```

### FR-3 — {scenario name}  (edge)
```gherkin
Given {boundary precondition}
When {action}
Then {outcome}
```

## NFRs
{Cite the NFR requirement entries this story is subject to. A story constrains
behaviour, so it names the FRs each entry applies to — the entry itself carries
the metric, threshold, and method. Omit the section entirely if none.}
- [{FEATURE-SLUG}-NFR-{NNN}]({path}) — constrains FR-{n}
````

## Scenario Outline (edge families)

`{...}` = schema placeholder (fill it in). `<...>` = Gherkin parameter, filled per row from the `Examples` table.

Template:

```gherkin
Scenario Outline: {name} (edge)
  Given {boundary precondition} with <value>
  When {action}
  Then {outcome}

  Examples:
    | value |
    | {boundary value 1} |
    | {boundary value 2} |
```

Example:

```gherkin
Scenario Outline: Withdrawal rejected at balance limits (edge)
  Given my account has a balance of <balance>
  When I try to withdraw <amount>
  Then I see "<message>"

  Examples:
    | balance | amount | message            |
    | 0       | 1      | Insufficient funds |
    | 100     | 100    | Cannot leave zero  |
    | 100     | 101    | Insufficient funds |
```

## Rules

- **Exactly one** Actor statement (Layer 1). More than one actor → not a single story.
- **≥1 negative and ≥1 edge** scenario in addition to the happy path.
- Each scenario is a single Gherkin `Given/When/Then` block (machine-readable).
- **3–5 steps** per scenario; chain extra steps with `And`/`But`.
- **Declarative only.** Describe behaviour, not implementation — "When Bob logs in", never "When I click the login button". A step must survive an implementation change.
- **`Then` = observable outcome.** Assert what the user or external system sees — never internal state (database rows, records, field values).
- **`Given` = context only.** No user interaction in `Given` steps.
- **Edge-case families** (multiple boundary values) → one `Scenario Outline` with an `Examples` table, not near-duplicate scenarios.
- Each scenario is unambiguous and independently testable.
- **NFRs are cited, never authored here.** The requirement entry owns the metric,
  threshold, and measurement method; the story links the entry and names the FRs it
  constrains.
- **`## Context` is the first section** — workflow id + slug, and relative links to the
  requirement entries the story covers. Links are relative, so they resolve from the story's
  own folder. Omit the section entirely for a standalone story — never write an empty header.
- Entity doc — describes only the User Story document; it names no agent, phase, or
  pipeline role.
