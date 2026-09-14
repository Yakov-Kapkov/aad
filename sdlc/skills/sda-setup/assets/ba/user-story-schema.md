# User Story Schema

A User Story has two layers: one **Actor statement** (Layer 1), then machine-readable
**Gherkin scenarios** (Layer 2), plus attached local NFRs and referenced global NFRs.

## Template

````markdown
# User Story: {slug}

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

## Local NFRs
- **LNFR-1** — {feature-specific quality constraint} → applies to FR-{n}

## Global NFRs (referenced)
- {GNFR-id} — {one-line name}  (see global-nfr.md)
````

## Rules

- **Exactly one** Actor statement (Layer 1). More than one actor → not a single story.
- **≥1 negative and ≥1 edge** scenario in addition to the happy path.
- Each scenario is a single Gherkin `Given/When/Then` block (machine-readable).
- Each scenario is unambiguous and independently testable.
- Local NFRs are authored here and attached to specific FRs.
- Global NFRs are **referenced by id** only — never restated.
- Entity doc — describes only the User Story document; it names no agent, phase, or
  workflow.
