---
name: is-repo-ai-friendly
description: "Defines what makes a repository AI-friendly and assesses a repo against those criteria. Use when: asked whether a repo is AI-friendly, auditing how readable, maintainable, or navigable a repo is for AI agents, or when a docs authoring or verification session needs the AI-friendliness criteria. Read-only — it never writes."
---

# Is Repo AI-Friendly

To answer the question "Is this repo AI-friendly?" first learn what that means, then run the assessment.

**Its question:** could a capable engineer with no memory of this repo start
working in it today? AI-friendly means readable, maintainable, onboardable, and
changeable — not merely navigable.

## What an AI-friendly repo is

A repo is AI-friendly if it is easy for AI agents to work with. How to achieve this? By providing context they need. If the required context is easy, fast and cheap to get, the repo is AI-friendly. If the context is hard to get, or requires a lot of work to get, the repo is not AI-friendly.

The entry points for agents are AI readmes: AGENTS.md, CLAUDE.md, etc. They sit at
the root and in any folder — a folder readme explains what goes on in that folder,
and there can be many of them at any depth. Entering the repo through AI readmes,
the agent should get the context it needs without an extensive repo scan.

What the readmes themselves must be: short, and a table of contents — each entry
names what an artifact is for and links it. Every link resolves, every doc is
reachable from a readme, and a fact repeated at another level adds clarification
or detail — a bare copy is a defect, and two copies that disagree are worse than
either. Routing is the mechanism, so it is not one of the artifacts below.

The readmes also carry the maintenance rule — **docs are updated in the same
change as the code they describe**: a new feature, a new deployment approach, a
changed standard, a new requirement, etc. Without it, docs that are right today are wrong tomorrow.

What the readmes must route to — the context an agent needs, one artifact at a
time. The third column is the artifact's **entry**: an artifact **answers its
entry** when every item in that entry has an answer, and no answer is contradicted
by the code. Judge by the entry — never by volume, polish, or how much prose a doc
carries.

| # | Artifact | Its entry |
|---|---|---|
| 1 | Vocabulary | the terms a newcomer would guess wrong, defined once |
| 2 | Structure | the subprojects — how many, which, what each owns |
| 3 | BA context | requirements and user stories — what is implemented, what is not |
| 4 | Designer context | design conventions, ADRs, diagrams, schemas, specs, cross-boundary contracts |
| 5 | Developer context | coding standards, implementation conventions |
| 6 | Dev commands | every command an agent needs while coding: build, test (suite, and one file), lint, format, type-check, the pre-merge gate — plus the toolchain's versions and bootstrap |
| 7 | QA context | test cases, automated and manual tests, smoke and regression testing, FRs, NFRs — how the product is verified |
| 8 | Deployment | how the system ships — pipeline, environments, triggers |
| 9 | Run locally | how to run the whole system, or any part of it |
| 10 | Operations | logs, metrics, health, how to roll back |
| 11 | Docs map | where the docs live, how they are named and kept current, and what the repo deliberately leaves undocumented |

Any layout qualifies — never require a folder, a filename, or a tool of the repo.

## Levels: root and subprojects

All eleven artifacts from the list are judged at every level. The root is always
judged; a monorepo adds one verdict per subproject.

A **subproject** is a separate part of the system: a package, service, app, or
library — never merely a folder that carries a readme. Enumerate subprojects from
the repo — its workspaces, build files, deploy targets — never from readme
presence. A repo that declares none has no subprojects: it is judged at the root
alone.

The two levels split the work: the root carries what is broader than any one
subproject, a subproject carries what is local to itself. Each level's readme
answers all eleven
artifacts — with local docs, or by routing up. **Inherit, don't duplicate**: an
artifact satisfied by routing to the root is complete, not a gap; restating it at
both levels is a defect.

**The root** carries what no subproject can:

| The root carries | Artifact |
|---|---|
| Subproject map — every subproject: folder, what it owns, link to its readme | Structure |
| Feature → subprojects — one row per feature, **every** subproject it touches | Structure |
| Vocabulary met at repo level | Vocabulary |
| Overall architecture, and the contracts between subprojects | Designer context |
| Cross-subproject conventions and ADRs | Designer context |
| Cross-subproject requirements — FRs, shared NFRs | BA context |
| Repo-wide standards | Developer context |
| Repo-wide commands — the pre-merge gate, cross-subproject orchestration, toolchain versions | Dev commands |
| Composing the whole stack | Run locally |
| The pipeline and environments | Deployment |
| Logs, metrics, health, rollback for the composition | Operations |
| The docs declaration — layout, naming, omissions, how a subproject is added or retired | Docs map |

**Reachable, or it is a finding.** Every subproject must be reachable from the
root — its own readme, or a route from its parent. A subproject nobody routes is
a finding against the parent's Structure.

## Statuses

Content and route are judged separately, and both are required: a route never
substitutes for the content, and content nothing links to never reaches an agent.

Every status is one of these seven — each a different repair:

- `present` — one or more documents answer its entry, and a route reaches them: a
  readme link, or a location outside the repo the agent can open unaided. Nothing
  to do.
- `partial` — the routed documents answer part of its entry. Finish the missing
  items.
- `orphaned` — a document exists, but no readme links to it. Add one link; whether
  it is complete is settled after that.
- `broken` — a readme link is broken or points to a document that doesn't exist.
  Repair or remove the link. A dead link that routes no artifact is reported in
  the level's `check-links` line, never as an artifact row.
- `absent` — nothing is written, and no readme links to it. Someone has to write it.
- `unverified` — a readme links to where the answer lives outside the repo, and the
  agent cannot fetch it. Confirm access, or copy it in.
- `n/a` — the artifact does not apply at this level: the repo declares it out of
  scope, or the level has none (a library has no deployment). Not a gap.

A route may leave the repo — a wiki, a dashboard, Confluence, a design tool — but
it must name the system *and* the location: "BA context lives in Confluence" is not
a route; a space, a page tree, or a URL is. `check-links` resolves relative links
only, so unaided access is the agent's call: needing a human or an access grant —
log in, ask the BA team, open the deck — makes the route `unverified`.

## Workflow

Inputs:

- **The repo** — read the files themselves, never a description of them.
- **`check-links`** — files or folders; folders are walked for `.md`. Exit 0 is a
  pass; exit 1 prints findings as `<path> | <check> | <status>`.

Run it from the assessed repo, `<skill>` standing for this skill's folder.

Windows:

```powershell
<skill>\assets\scripts\check-links.ps1 docs AGENTS.md
```

macOS / Linux:

```bash
<skill>/assets/scripts/check-links.sh --path docs --path AGENTS.md
```

In order, every run.

1. **Locate the routing.** Stop at the first rung that answers and record which:
   a tracked declaration (a readme or a docs declaration stating the docs
   layout) → the AI readmes as found → a `.sda/` local override. Nothing answers
   → the repo is undeclared; say so and continue.
2. **Enumerate the subprojects.** The root, plus every subproject the repo
   declares — by the definition and rule in Levels, never by counting folder
   readmes.
3. **Resolve every link.** Run `check-links` on the paths step 1 recorded; when
   nothing is declared, on every markdown file the repo tracks, and say so.
4. **Judge the readmes**, once per level. Are they short routers? Is any doc
   unrouted? Is any restatement a bare copy? Does each state the up-to-date
   rule? The link check ran in step 3.
5. **Judge the artifacts**, one level at a time — root first, then each subproject —
   one artifact at a time, in list order: which of the seven statuses does each
   earn? A doc that contradicts the code it describes is not `present` — mark it
   `partial`, report the contradiction, never hunt for drift.
6. **Search for what the walk missed.** An artifact no readme reaches does not
   reach the agent; search only to tell `orphaned` from `absent` — a document
   found makes it `orphaned`, nothing found makes it `absent`. A search result
   never becomes `present`.
7. **Report** — the section below fixes the form.

## Report

Telegraph style. No preamble, no praise, no restatement of the list — prose only where a
table or a bullet cannot carry it, and a finding reported once per session.

Print only non-`present` rows — repairs and scope claims. `present` is counted,
never listed. A readme is `short` when it routes and carries no artifact content,
`bloated` when it restates some; `Fix first` names the repair that unblocks the
most artifacts.

```
Score: {n}% — {n} present of {n} applicable · {n} n/a
Missing: {n} broken · {n} absent · {n} orphaned
Incomplete: {n} partial · {n} unverified
Fix first: {one sentence}

## Root
Routing: {rung} → {path}
Readmes: {short | bloated} · up-to-date rule: {stated | missing} · check-links: {clean | output} · unrouted docs: {none | list} · duplicate facts: {none | list}
| Artifact | Status | Evidence |
|---|---|---|
| {name} | {partial · orphaned · broken · absent · unverified · n/a} | {path}, the route, or what is missing |
{n} present · {n} partial · {n} orphaned · {n} broken · {n} absent · {n} unverified · {n} n/a

## {subproject}
{same block, in list order; no table when it has no non-`present` row}
```

## Acceptance criteria

The assessment is complete when:

- **Coverage** — every artifact has exactly one status at every level; none
  skipped, merged, or invented.
- **Statuses** — one of the seven, never blank; `present` needs both the route and
  the content, never a route alone or a search hit.
- **Evidence** — every printed row names the file, the route, or the missing
  piece; an `n/a` row names its scope.
- **Report** — the root first, then one section per subproject; each opens with its
  rung, readme verdict, and `check-links` result, and lists only non-`present`
  rows.
- **Score** — `present` over applicable, rounded to a whole number; repairs
  grouped by kind, never a yes/no.
- **Fidelity** — contradictions hit on the walk are reported; drift is never
  hunted.
- **Read-only** — nothing is written.
