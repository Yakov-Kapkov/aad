# Escalation Brief Schema

An escalation brief is the evidence behind a workflow escalation: the assumption the
raising stage had been working from, what shows it does not hold, and the decision it
needs the upstream stage to make.

## Template

```markdown
# Escalation: {one-line ask}

## What we assumed
{The assumption the raising stage worked from, and why it does not hold.}

## Evidence
{The artifact and the section of it that shows the problem.}

## Decision requested
{The decision the upstream stage must make, as one question.}
```

## Rules

- **One heading and three sections, in that order** — nothing else.
- **`# Escalation:` states the ask in one line** — what must be re-decided, not what went
  wrong.
- **`## What we assumed` names the assumption, not the mistake.** The reader needs to know
  what the raising stage believed before it can see why that stage is blocked.
- **`## Evidence` is a pointer, never a copy.** Name the artifact and the section, and quote
  at most one short excerpt.
- **`## Decision requested` is exactly one question.** Two questions are two escalations.
- **One screen.** ASCII, no tables, no diagrams.
- **Never edited after it is written.** A claim that changes is a new escalation, not a
  revised brief.
- Entity doc — describes only the escalation brief; it names no agent, phase, or
  pipeline role.
