# Readme Outline Schema

The readme outline is the thin routing index written at the repo root, plus
each subproject root when the repo has subprojects. It applies identically to
every AI readme (`AGENTS.md`,
`CLAUDE.md`, `.cursorrules` — whichever exist) and the human `README.md`.

---

## Template

```markdown
# {Repo or subproject name}

## {Preamble}
{AI readme: "This file is the routing index to architecture, features,
requirements, conventions, and ADRs. The repo maintains three documentation
types — the design docs (architecture, vocabulary, conventions, ADRs), the
requirements docs, and the operational docs (testing, commands, deployment,
operations). Find the reference for what you're working on below; read what
you need, or explore the code."
Human README: one-line summary.}

## {Description}
{≤3 sentences. Subproject readme: this subproject's job.}

## {How to run locally}
{No inline commands. Root readme: one line per subproject → its docs/cli.md.
Subproject readme: one line → its own docs/cli.md.}

## {How to test}
{No inline commands. Root readme: one line → docs/testing.md. Subproject
readme: one line → its own docs/testing.md.}

## {Deployment & operations}
{Root readme: one line → docs/deployment.md, one line → docs/operations.md.
Subproject readme: only when this subproject ships, or runs, on its own.}

## {Architecture}
{3–5 sentences + a link to docs/index.md (root) or this subproject's
docs/index.md (subproject).}

## {Implemented features}
- **{Feature}** — {≤3 sentences} → **every** subproject it touches, listed as
  links to their docs indexes (or docs folders) — read when changing {feature}

## {Requirements}
{When a requirements tree exists. Root readme: routing line to
docs/requirements/ (cross-subproject) + one line per subproject → its
docs/requirements/ index. Subproject readme: routing line to this
subproject's docs/requirements/ index.}

## {Design conventions}
{Root readme: routing line to docs/conventions/ (cross-subproject) + one line
per subproject → its docs/conventions/ index.
Subproject readme: routing line to this subproject's docs/conventions/ index.}

## {ADRs}
{Root readme: routing line to docs/adrs/ (cross-subproject) + one line per
subproject → its docs/adrs/ index.
Subproject readme: routing line to this subproject's docs/adrs/ index.
Both: one line — "ADRs are immutable once accepted — the ADR folder readme
states the rules."}

## {Coding standards}
{Root readme: link docs/coding-standards/. Subproject readme: link
<subproject>/docs/coding-standards/. When present.}
```

---

## Schema Rules

- Outline only. ≤3 sentences per entry.
- Link, never inline detail.
- Every reference entry carries a trigger — "read when you need {X}",
  "mandatory for {scope}", or "covers {topic}" — no bare links.
- AI readme preamble must state the file is the routing index.
- The preamble also states the **maintenance rule**: the docs are updated in the
  same change as the code they describe. Mandatory at the root readme.
- **No implementation detail** — no endpoint recipes, RBAC lists, DB query
  rules, component prop tables, or code snippets.
- **AI readme and human `README.md` mirror each other:** identical sections,
  identical links and routing; tone differs only (routing preamble vs one-line
  summary).
- An AI readme routes to documentation, never to another AI readme.
- A feature touching several subprojects lists **all** of them — that fan-out is what
  makes a monorepo navigable.
- When updating an existing readme, preserve its existing section headings and
  wording; apply the content rules above.
