# Readme Outline Schema

The readme outline is the thin routing index written at repo root and each
layer root. It applies identically to every AI readme (`AGENTS.md`,
`CLAUDE.md`, `.cursorrules` — whichever exist) and the human `README.md`.

---

## Template

```markdown
# {Repo or layer name}

## {Preamble}
{AI readme: "This file is the routing index to architecture, features,
requirements, and decisions. The repo maintains two documentation types — the
design docs (architecture, vocabulary, decisions) and the requirements docs.
Find the reference for what you're working on below; read what you need, or
explore the code."
Human README: one-line summary.}

## {Description}
{≤3 sentences. Layer readme: this layer's job.}

## {How to run locally}
{No inline commands. Global readme: one line per layer → its docs/cli.md.
Layer readme: one line → its own docs/cli.md.}

## {Architecture}
{3–5 sentences + a link to docs/index.md (global) or this layer's
docs/index.md (layer).}

## {Implemented features}
- **{Feature}** — {≤3 sentences} → the owning layer's docs index (or docs
  folder) — read when changing {feature}

## {Requirements}
{When a requirements tree exists. Global readme: routing line to
docs/requirements/ (cross-layer) + one line per layer → its
docs/requirements/ index. Layer readme: routing line to this layer's
docs/requirements/ index.}

## {Design decisions}
{Global readme: routing line to docs/decisions/ (cross-layer) + one line per
layer → its docs/decisions/ index.
Layer readme: routing line to this layer's docs/decisions/ index.}

## {Coding standards}
{Global readme: link docs/coding-standards/. Layer readme: link
<layer>/docs/coding-standards/. When present.}
```

---

## Schema Rules

- Outline only. ≤3 sentences per entry.
- Link, never inline detail.
- Every reference entry carries a trigger — "read when you need {X}",
  "mandatory for {scope}", or "covers {topic}" — no bare links.
- AI readme preamble must state the file is the routing index.
- **No implementation detail** — no endpoint recipes, RBAC lists, DB query
  rules, component prop tables, or code snippets.
- **AI readme and human `README.md` mirror each other:** identical sections,
  identical links and routing; tone differs only (routing preamble vs one-line
  summary).
- An AI readme routes to documentation, never to another AI readme.
- When updating an existing readme, preserve its existing section headings and
  wording; apply the content rules above.
