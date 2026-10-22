---
name: make-repo-ai-friendly
description: "Authors and maintains AI-friendly documentation: thin routing readmes (AGENTS.md / CLAUDE.md / .cursorrules) plus a root and per-subproject docs/ tree (architecture, vocabulary, testing, deployment, operations, requirements, design conventions, ADRs, coding standards, commands, run instructions, the docs declaration). Use when: setting up docs for a new repo, onboarding or reorganizing an existing repo's docs, updating docs after code changes, or making a repo navigable for AI agents."
---

# Make Repo AI-Friendly

**Its question:** where does each artifact live, and who keeps it true?

Author and maintain AI-friendly documentation. You produce two things:

1. **Thin routing readmes** — `AGENTS.md` (default), `CLAUDE.md`, or
   `.cursorrules` (whichever exist) at the root and at each subproject root, plus
   the human `README.md`. Every link carries a one-line description.
2. **A docs tree** — the [default profile](assets/docs-tree.md), adapted to the
   repo's declared contract.

The criteria are not ours: load **`is-repo-ai-friendly`** and work from its
assessment. Read the asset schemas before writing any file (see
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
- **One question at a time** — ask the single most consequential first.
- Freely provide decision *inputs*: repo facts, existing patterns, gaps,
  over/under-engineering risks, the pros and cons of the user's idea.

---

## What the criteria require

The eleven artifacts and their entries are defined in `is-repo-ai-friendly`.
This skill never restates them, never waives them, never re-derives them — it
runs the assessment and works from the statuses it returns.

Three layers, in order of authority:

| Layer | Owns | Lives in |
|---|---|---|
| Criteria | what AI-friendliness requires — the artifacts and their entries | `is-repo-ai-friendly` skill |
| Declaration | what this repo does — layout, names, omissions, housekeeping | the repo's **Docs map** |
| Profile | one workable default when nothing is declared | [`assets/docs-tree.md`](assets/docs-tree.md) |

- Verify against the declaration, never against the profile.
- Offer the profile only when nothing is declared.
- Express every fix in the repo's own filenames.

## The implementation

One implementation of those criteria: the **default profile** — the folder
layout, the home of every artifact at the root and in a subproject, and the rules for
sharing between them: [`assets/docs-tree.md`](assets/docs-tree.md).

A repo that declares its own layout replaces the profile, never the target: all
eleven artifacts still need an answer at every level, or a declared omission.

## The Docs map

Every repo should declare its docs layout, names, omissions, and housekeeping.
The declaration is the contract. Schema:
[`assets/docs-map-schema.md`](assets/docs-map-schema.md). The readme
routes to it — an unrouted declaration is invisible.

Locate it in this order — stop at the first rung that answers:

1. a tracked declaration — a readme or a docs declaration
2. the AI readmes as found

| Situation | Action |
|---|---|
| Nothing declares it, repo may change | **Write** the declaration, route it from the readme |
| Nothing declares it, repo may not change | Say so; work from the readmes as found |

---

## Scope

Two questions, both asked before anything else: *how much of the repo*, and
*what kind of work*.

| Scope | Covers | Also touched |
|---|---|---|
| **Repo** | the root plus every subproject | — |
| **Subproject** | one subproject | the root's Structure: subproject map, feature → subprojects |
| **Artifact** | one of the eleven, at the levels in scope | the readme route to it |
| **Doc** | one file | its level's readme, when newly written |

A change never stops at its scope: whatever it drags in belongs in the
proposal.

## Modes

| Mode | Entry signal | Starts from |
|---|---|---|
| **Scaffold** | empty or new repo, "set up docs" | the profile |
| **Adapt** | existing repo, "organize our docs", "onboard this repo" | the assessment |
| **Reconcile** | "update docs", "docs are stale", code changed | the code diff |

Modes are scope-agnostic: any mode runs on the repo, one subproject, one artifact, or
one file. When the signal is ambiguous, ask one question: *"new repo, existing
repo to organize, or docs to update?"*

**Every mode:** when a step runs a CLI command (tests, lint, build), never keep
the full output. Tests: run the suite for the verdict, then rerun failing
file(s) with a filter that drops passing results. See
[`assets/cli-schema.md`](assets/cli-schema.md).

## Workflow

Inputs:

- **The repo** — read the files themselves, never a description of them.
- **The `is-repo-ai-friendly` report** — run its assessment; work from its
  statuses, never re-derive them.
- **The schemas** — [`assets/`](assets), read before writing.
- **The checkers** — `check-links` from `is-repo-ai-friendly`, and `check-tree`
  from [`assets/scripts/`](assets/scripts).

In order, every run.

1. **Locate the Docs map.** Apply the rung order and the situation table in
   The Docs map.
2. **Fix the scope and the levels.** Mode and scope from the request; the
   subprojects as the repo declares them, never by folder count.
3. **Assess.** Run `is-repo-ai-friendly` on the levels in scope. Its report is
   the finding list.
4. **Propose.** The exact file list — smallest change per finding, links first,
   then `absent`, then `partial`. Include what the change drags in beyond its
   scope. Wait for approval.
5. **Write.** Per the schemas. Preserve headings and wording that are still
   correct.
6. **Declare.** Write or update the Docs map: layout, names, omissions.
7. **Verify.** Re-run the assessment and `check-links`; report what remains.

**Stop and report** when the repo cannot be scanned, the user rejects the
proposal (revise once, then stop), or an artifact has no honest source in the
repo — never invent one.

## Report

Telegraph style. Two outputs.

Proposal, before any write:

| File | Action | Artifact | Why |
|---|---|---|---|
| `{path}` | create · update · remove | {artifact · level} | {finding or gap} |

After verify:

```
Assessment: {n} present of {n} applicable · {n} remaining
Links: {clean | output}
Written: {n} files — the approved list, no more
```

## Acceptance criteria

The work is complete when:

- **Coverage** — every artifact has a home or a declared omission at every
  level in scope.
- **Declaration** — the Docs map matches the repo, and a readme routes to it.
- **Links** — `check-links` exits 0 on the levels in scope.
- **Fidelity** — the docs describe the code; no invented command, structure, or
  feature.
- **Assessment** — the re-run shows the targeted findings resolved.
- **Approval** — every file written was on the approved list, and no other.
- **No waiver** — nothing in the declaration weakens a criterion.

---

## Assets

Read the schema for each file type before writing it:

| File type | Schema (mandatory read) |
|---|---|
| Default folder layout (a proposal) | [`assets/docs-tree.md`](assets/docs-tree.md) |
| Docs map — the declaration: layout, naming, omissions, housekeeping | [`assets/docs-map-schema.md`](assets/docs-map-schema.md) |
| Readme outline (AI + human) | [`assets/readme-outline-schema.md`](assets/readme-outline-schema.md) |
| `docs/index.md` router | [`assets/docs-index-schema.md`](assets/docs-index-schema.md) |
| `architecture.md` | [`assets/architecture-schema.md`](assets/architecture-schema.md) |
| `vocabulary.md` | [`assets/vocabulary-schema.md`](assets/vocabulary-schema.md) |
| Conventions (per-level `index.md` + convention files) | [`assets/convention-schema.md`](assets/convention-schema.md) |
| ADRs (per-level `index.md` + ADR files) | [`assets/adr-schema.md`](assets/adr-schema.md) |
| Requirements (`index.md` + one file per feature + `nfr.md`) | [`assets/requirements-schema.md`](assets/requirements-schema.md) |
| Coding-standards routing | [`assets/coding-standards-schema.md`](assets/coding-standards-schema.md) |
| Commands and run instructions (`cli.md`) | [`assets/cli-schema.md`](assets/cli-schema.md) |
| `testing.md` | [`assets/testing-schema.md`](assets/testing-schema.md) |
| `deployment.md` | [`assets/deployment-schema.md`](assets/deployment-schema.md) |
| `operations.md` | [`assets/operations-schema.md`](assets/operations-schema.md) |
| Tree conformance check | [`assets/scripts/check-tree.ps1`](assets/scripts/check-tree.ps1) (`.sh` on Bash) |

---

## Boundaries

- ⚠️ Ask first: adding a top-level docs folder, removing or renaming existing
  docs, deleting files.
- 🚫 Never do: impose the profile on a repo that declares its own layout; invent
  architecture, commands, or features (derive from the code and the diff);
  pre-seed empty files; leave an artifact without a home or a declared omission;
  write docs for a subproject you haven't scanned; duplicate a subproject's detail in
  the root docs.
- ✅ Always do: link, never inline; preserve headings and wording that are still
  correct.
