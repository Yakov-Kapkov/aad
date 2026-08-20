# Readme Outline Schema

The readme outline is the thin routing index written at repo root and at each
layer root. It applies identically to every AI readme (`AGENTS.md`, `CLAUDE.md`,
`.cursorrules` — whichever exist) and the human `README.md`.

---

## Template

```markdown
# {App or Layer name}

## {Preamble}
{AI readme: "This file is the routing index to architecture, features, and decisions.
 Find the reference for what you're working on below; read what you need, or explore the code."
 Human README: one-line summary.}

## {Description}
{≤3 sentences. Layer readme: this layer's job.}

## {How to run locally}
{Plain step-by-step. Layer readme: this layer only.}

## {Architecture outline}
{3–5 sentences + a link to docs/index.md (global readme) or this layer's docs/index.md (layer readme).}

## {Implemented features}
- **{Feature}** — {≤3 sentences} → the owning layer's docs index (or docs folder) — read when changing {feature}

## {Design decisions}
{Global readme: routing line to every layer's docs index (or docs folder).
 Layer readme: routing line to this layer's decisions index.}

## {Coding standards}
{Global readme: link docs/coding-standards/. Layer readme: link <layer>/docs/coding-standards/.
 When present.}
```

---

## Schema Rules

- Outline only. ≤3 sentences per entry.
- Link, never inline detail.
- Every reference entry carries a trigger — "read when you need {X}",
  "mandatory for {scope}", or "covers {topic}" — no bare links.
- AI readme preamble must state the file is the routing index; agents find
  their task's references here or explore the code.
- **No implementation detail** — no endpoint-registration recipes, RBAC
  role-check lists, DB query rules, component prop tables, or code snippets.
- AI readme and human `README.md` carry the same sections; tone differs only.
- An AI readme routes to documentation, never to another AI readme. Each
  reference points to the docs that answer the reader's question — recorded
  architecture, vocabulary, design decisions: an index file when present,
  otherwise the docs files directly — each with a one-line description of
  what it covers. Concrete paths like `<layer>/docs/index.md` and
  `<layer>/docs/` are examples — follow the repo's actual structure.
- When updating an existing readme, preserve its existing section headings and
  wording; apply the content rules above.
