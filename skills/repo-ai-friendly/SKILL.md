---
name: repo-ai-friendly
description: "Authors and maintains AI-friendly documentation: thin routing readmes (AGENTS.md / CLAUDE.md / .cursorrules) plus a global and per-layer docs/ tree (architecture, vocabulary, requirements, decisions, coding standards, CLI). Use when: setting up docs for a new repo, onboarding or reorganizing an existing repo's docs, updating docs after code changes, or making a repo navigable for AI agents."
---

# Repo AI-Friendly

Make a repository navigable for AI agents. You produce two things:

1. **Thin routing readmes** — `AGENTS.md` (default), `CLAUDE.md`, or
   `.cursorrules` (whichever exist) at repo root and each layer root, plus
   the human `README.md`. Every link carries a one-line description.
2. **A docs tree** — global `docs/` + per-layer `<layer>/docs/`, with an
   `index.md` router per folder.

Read the asset schemas before writing any file (see
[Assets](#assets)). Never invent structure from memory.

---

## ⛔ ABSOLUTE RULE — YOU THINK *WITH* THE USER, NOT *FOR* THEM

The user owns every documentation decision. You sharpen their thinking —
never replace it.

- **Never author docs or structure the user did not approve.** When the
  user has not proposed an approach, ask: *"What's your approach? I'll
  pressure-test it."*
- **When you see a gap or a drawback** in the user's decision or repo docs or readmes, flag it and
  present **≥2 options with tradeoffs** — then hand the decision back.
  Never a single take-it-or-leave-it answer, never silently decide.
- **Never modify the repo without explicit approval.** Present the exact
  files to create, update, or remove; wait for "go".
- Freely provide decision *inputs*: repo facts, existing patterns, gaps,
  over/under-engineering risks, the pros and cons of the user's idea.

---

## What "AI-friendly" means

| Quality | Rule |
|---|---|
| Router, not to-read list | A readme routes to docs; it never inlines detail |
| One link, one description | Every reference carries "read when you need X" |
| AI ≡ human readme | Same sections, same links; tone differs only |
| Global ≠ layer | Global readme/docs hold repo-wide info only; layer info lives in the layer |
| No dead links | Every routed path exists; every doc is reachable from a readme |
| No orphan docs | Every doc is linked from an `index.md` or a readme |

---

## Canonical docs tree

Default layout — full tree in
[`assets/docs-tree.md`](assets/docs-tree.md). Highlights:

```
docs/                          ← global (repo-wide only)
  index.md · architecture.md · vocabulary.md
  requirements/<feature>/ · coding-standards/ · decisions/ · diagrams/   (as needed)
<layer>/docs/                  ← one per subsystem (backend, frontend, …)
  index.md · architecture.md · vocabulary.md · cli.md
  requirements/<feature>/ · coding-standards/ · decisions/               (as needed)
```

- `cli.md` is **per-layer only** — layers use different tools. Global docs
  never hold CLI commands; the readme's "run locally" section routes to
  each layer's `cli.md`.
- A repo with no subsystems gets only the global tree.
- Optional nodes are created only when needed — never pre-seed empty files.

---

## Modes

Detect the mode from the request. One question resolves ambiguity:
*"Is this a new repo, an existing repo to organize, or docs to update?"*

| Mode | Entry signal | Output |
|---|---|---|
| **Scaffold** | Empty/new repo, "set up docs", "make this repo AI-friendly" | Full tree + readmes |
| **Onboard** | Existing repo, "organize our docs", "onboard this repo" | Audit first → reorganized tree + readmes |
| **Reconcile** | "update docs", "docs are stale", code changed | Drift report → approved edits only |

**Every mode:** when a step runs a CLI command (tests, lint, build), never keep
the full output. Tests: run the suite for the verdict, then rerun failing
file(s) with a filter that drops passing results. See
[`assets/cli-schema.md`](assets/cli-schema.md).

### Mode 1 — Scaffold (new repo)

1. **Interview** — one question at a time: repo purpose, layers
   (frontend/backend/worker/…), language(s), primary tools per layer.
2. **Propose the tree** — show the exact files to create. Get approval.
3. **Write** — read the schemas, then create readmes + docs. Only files the
   repo needs.
4. **Verify** — re-read every link; confirm each resolves.

### Mode 2 — Onboard (existing repo)

1. **Audit (read-only)** — scan the repo: layers, existing readmes, existing
   docs. Report what exists, what's misplaced, what's missing.
2. **Propose reorganization** — global vs layer split, what moves where.
   Get approval before touching anything.
3. **Write** — apply the reorganization per the schemas. Preserve existing
   headings and wording where the content is still correct.
4. **Verify** — no dead links, no orphan docs, global holds only global info.

### Mode 3 — Reconcile (update)

1. **Audit (read-only)** — compare docs against the code. List drift:
   stale architecture, missing features in the readme, dead links, wrong
   commands in `cli.md`.
2. **Report + propose** — findings with the exact files to update. Get
   approval per file.
3. **Write** — apply approved edits only.
4. **Verify** — re-run the audit checks; report remaining drift.

---

## Global vs layer boundaries

| Content | Lives in |
|---|---|
| Repo purpose, layer list, cross-cutting concerns | Global `docs/architecture.md` |
| One subsystem's modules, storage, communication | `<layer>/docs/architecture.md` |
| Terms used across layers | Global `docs/vocabulary.md` |
| Terms special to one layer | `<layer>/docs/vocabulary.md` |
| Cross-layer rules only (never subsystem-specific) | Global `docs/decisions/` |
| Rules for one layer or feature | `<layer>/docs/decisions/` |
| Cross-layer requirements (FRs + shared NFRs) | Global `docs/requirements/` |
| Requirements for one layer's features | `<layer>/docs/requirements/` |
| Commands (test, lint, build, type-check, run) | `<layer>/docs/cli.md` |
| Cross-layer coding rules | Global `docs/coding-standards/` |
| Layer coding rules | `<layer>/docs/coding-standards/` |

**Rule of thumb:** "how to implement" detail belongs in a decision or
coding-standards doc — never in a router readme or global architecture doc.

---

## Interview & approval

- One question at a time; ask the single most consequential first.
- Present ≥2 options with tradeoffs when the path is unclear.
- **Exit condition for every mode:** the user approved the exact file list.
- **Failure path:** if the user rejects a proposal, revise and re-propose.
  If the repo cannot be scanned (unreadable files, no structure), stop and
  report what is blocking.

---

## Assets

Read the schema for each file type before writing it:

| File type | Schema (mandatory read) |
|---|---|
| Canonical folder layout | [`assets/docs-tree.md`](assets/docs-tree.md) |
| Readme outline (AI + human) | [`assets/readme-outline-schema.md`](assets/readme-outline-schema.md) |
| `docs/index.md` router | [`assets/docs-index-schema.md`](assets/docs-index-schema.md) |
| `architecture.md` | [`assets/architecture-schema.md`](assets/architecture-schema.md) |
| `vocabulary.md` | [`assets/vocabulary-schema.md`](assets/vocabulary-schema.md) |
| Decisions (per-level `index.md` + decision files) | [`assets/decision-schema.md`](assets/decision-schema.md) |
| Requirements (`index.md` + one file per feature + `nfr.md`) | [`assets/requirements-schema.md`](assets/requirements-schema.md) |
| Coding-standards routing | [`assets/coding-standards-schema.md`](assets/coding-standards-schema.md) |
| `cli.md` | [`assets/cli-schema.md`](assets/cli-schema.md) |

---

## Boundaries

- ✅ Always do: audit before reorganizing; approve before writing; link,
  never inline; verify every link after writing.
- ⚠️ Ask first: adding a top-level docs folder, removing or renaming
  existing docs, deleting files.
- 🚫 Never do: invent architecture or commands (derive from the code),
  pre-seed empty files, write docs for a subsystem you haven't scanned,
  modify the repo without approval, duplicate a layer's detail in global docs.
