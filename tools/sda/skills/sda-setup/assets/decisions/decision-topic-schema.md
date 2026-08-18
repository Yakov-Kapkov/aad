# Decision Topic Schema

A decision topic is a folder under `<layer>/docs/decisions/` holding one
decision per file, routed by an `index.md` in the same folder. Folders are
**feature-grouped**: `shared/` for cross-cutting concerns; one folder per
feature or bounded context (e.g., `Users/`, `Game/`, `Orders/`). Decision
docs are written *after* a decision is made; the `software-design-best-practices`
skill is consulted *before*.

## Folder layout

```
shared/                           ← cross-cutting decisions (auth, retries, logging, …)
  index.md
  <descriptive-name>.md            ← e.g. JWT token expiry.md, Retry with backoff.md
<feature>/                        ← one per feature / bounded context
  index.md
  <descriptive-name>.md            ← e.g. Challenge validation.md, Coin reward.md
  <descriptive-name>.md
```

File names are **descriptive kebab-case**: the decision title in 2–4 words,
no `d{N}` prefix. Example: `vertical-slice-structure-by-concern.md` not `d3.md`.

---

## Template

```markdown
# {Decision title}

**Decision:** {One sentence: the chosen approach.}

**Applies to:** {Omit when the decision has no mechanically checkable governing location.}
- `{file-or-folder-path}` — {what it governs}

**Why:** {One line: why this over the alternatives. Omit when obvious.}

**Application:**
- ✅ DO: {concrete action}
- ❌ DON'T: {anti-pattern}
```

---

## Schema Rules

### One decision per file
- Each file holds exactly one decision.
- New decision → new file. Never append a second decision to an existing file.
- Each decision: one ✅ DO and one ❌ DON'T minimum.

### Feature grouping
- **`shared/`** holds cross-cutting decisions that affect multiple features
  (auth, logging, retries, observability, naming conventions).
- **Feature folders** hold decisions specific to one bounded context or
  feature. One feature = one folder. Split into a new folder when a new
  bounded context emerges.
- Decision files live in the owning feature folder (or `shared/` for cross-
  cutting). The `index.md` at `docs/decisions/` routes to every feature folder.

### Naming — descriptive, never numeric
- Name files by their decision title in kebab-case, 2–4 words.
  Examples: `challenge-validation.md`, `coin-reward.md`, `eventual-consistency-with-outbox.md`.
- **Never** use `d{N}` prefixes.
- Cross-file references use the full file name (or the folder path for
  all decisions in one feature) — never a bare number.

### Decision
- One imperative sentence — the rule to follow.

### Applies to
- Optional. Lists the files/folders the decision governs.
- Enables drift checking — a verifier reads these paths as the "is".
- Omit only when the decision has no single governing location to verify.

### Why
- Optional. One line. Required when the choice is non-obvious — this is what
  stops implementers from "fixing" a deliberate decision.

### Application
- ✅ DO first, then ❌ DON'T.
- Language-agnostic — cite concepts, not framework-specific code.
