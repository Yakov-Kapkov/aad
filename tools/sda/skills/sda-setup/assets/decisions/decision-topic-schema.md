# Decision Topic Schema

A decision topic file records **one design decision** for one concern — the
chosen approach and why. It lives under `{paths.decisions}` (default
`docs/design/decisions/`), reachable through an `index.md` in the same folder.
Decision docs are written *after* a decision is made; the
`software-design-best-practices` skill is consulted *before*.

---

## Template

```markdown
# {Concern Name}

## Decision
{One sentence: the chosen approach.}

## Applies to
{Omit when the decision has no mechanically checkable governing location.}
- `{file-or-folder-path}` — {what it governs}

## Rationale
{One line: why this over the alternatives. Omit when obvious from the Decision.}

## Application
- ✅ DO: {concrete action}
- ❌ DON'T: {anti-pattern}
```

---

## Schema Rules

### One decision per file
- One file = one decision. Split the file when a second decision emerges.
- One ✅ DO and one ❌ DON'T minimum.

### Decision
- One imperative sentence — the rule to follow.

### Applies to
- Optional. Lists the files/folders the decision governs.
- Enables drift checking — `sda-docs-check` reads these paths as the "is".
- Omit only when the decision has no single governing location to verify.

### Rationale
- Optional. One line. Required when the choice is non-obvious — this is what
  stops implementers from "fixing" a deliberate decision.

### Application
- ✅ DO first, then ❌ DON'T.
- Language-agnostic — cite concepts, not framework-specific code.
