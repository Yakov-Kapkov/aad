---
name: software-design-best-practices
description: "Software design best practices reference. MUST be loaded before creating development specifications or making structural decisions during implementation. Contains a route table mapping topic areas (web API, database, UI, layers) to language-agnostic best-practice files. Do NOT use for: trivial bug fixes with no design impact, pure refactoring without structural changes, or documentation-only tasks."
---

# Software Design Best Practices

**Read this file in full before taking any action.** Do not proceed until
every line of this SKILL.md has been read — rules in later sections govern
critical decisions.

Behavioral rules for applying established design best practices to
software architecture decisions. Language-agnostic — works with any
language or framework.

## When to Use

- Creating a development specification
- Making architectural decisions during implementation
- Reviewing code for design-level issues
- Any task involving: API design, data modeling, error handling
  strategy, UI structure, layer organization

---

## How It Works: Route Table

This skill bundles a knowledge base organized by topic area. A
two-level route table maps task domains to practice files.

### Master index

`./practices/index.md` maps topic areas to their sub-indexes with
keywords for matching.

### Area sub-indexes

Each area folder contains an `index.md` that maps concerns
(e.g., "error handling") to detailed practice files.

### Lookup workflow

1. Read `./practices/index.md` — match the task to one or more topic
   areas using the Keywords column.
2. For each matched area, read its `index.md` — identify which
   concerns apply to the task.
3. Read the relevant practice files **in full** — these are bundled
   skill resources, no user confirmation needed.
4. Apply the practices — translate language-agnostic rules to the
   project's language and framework idioms.

---

## Application Rules

### 1. Mandatory consultation

When creating a dev spec or making implementation decisions that
touch any topic in the route table, consult the relevant practice
files **before** finalizing the spec or writing code.

### 2. Suggest, don't prescribe

These are best practices, not inviolable rules. When the current
codebase violates a practice:

- Flag the violation with a concise rationale.
- Propose the recommended pattern.
- The user decides whether to adopt, defer, or decline.
- When flagging, always state: the rule, the observed deviation,
  and the recommended change.

### 3. Language-agnostic → language-specific

Practice files describe patterns without language or framework
specifics. The agent translates them to the project's idioms
(ASP.NET middleware, Express middleware, Flask decorators, etc.).

### 4. Local overrides

If the project has its own design standards (discovered via workspace
documentation, readme files, or agent configuration), those take
precedence over the global practices bundled here.

### 5. No topic match → no block

If no topic area in the route table matches the task, proceed without
this skill. Do not force a match.

---

## Practice File Format

Each practice file follows this structure:

```markdown
# Topic Name

## Rule

[The rule in one sentence.]

## Application

- ✅ DO: [concrete action]
- ❌ DON'T: [anti-pattern to avoid]
```

---
