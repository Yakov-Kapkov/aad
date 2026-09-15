# Workflows — Design Note

**Status:** design locked 2026-09-15 (rev 5 — the `sda-workflow` advisor) · tranches 1–10 implemented · **script twins verified 2026-09-15** (60-case differential harness: identical output and exit codes) 
**Scope:** `tools/sda` (+ `skills/repo-ai-friendly` as a dependency; `skills/sda-setup` assets)
**Origin:** the `sdlc/` folder is a parallel evolution branch kept for reference. Its
**state discipline** (state = data + transition script; one writer; housekeeper vs advisor)
is borrowed. Its 5-BC pipeline, per-BC folders, ledgers, DoD, pending overlay, and inner
DEV+QA cycle are **not** adopted.

---

## 1. Concept

A **workflow** is a numbered container for one requirement's planning artifacts, shared by
`sda-ba` → `sda-design` → `sda-dev-task`, and consumed by `sda-dev` / `sda-qa`.

```
.sda/workflows/
  001. const-refactoring/
    workflow.json          orchestrator-owned state (script-written only)
    user-story.md          owner: sda-ba       (renewable)
    design.md              owner: sda-design   (renewable)
    tasks/
      001. ui-refactoring/
        task.md            owner: sda-dev-task
        state.json
        qa-task.md · dev-report.md · qa-report.md
```

| Rule | Detail |
|---|---|
| One owner per artifact | story → `sda-ba`, design → `sda-design`, tasks → `sda-dev-task`. Others read-only. |
| Renewable = idempotent overwrite | Workflow mode reads the existing artifact at session start and updates it in place. **No timestamped folders** in workflow mode. |
| `design.md` is handoff context | Purpose: let `sda-dev-task` design tasks without re-deriving architecture. Approach + scope + pointers — never a restatement. Content rules in §6. |
| Every stage produces its artifact | No stage is skipped. A design pass with nothing to decide renews `design.md` with what was considered and why it stands. |
| Link direction is one-way | Durable docs never link into `.sda`; transient artifacts link to durable docs. |
| Workflows are opt-in containers | Standalone single-agent use is fully supported and unchanged. |
| Numbering | `<NNN>. <slug>`, zero-padded, matches the existing task-folder convention. Highest existing prefix + 1. |

## 2. Modes

| Agent | Default | Workflow mode | Standalone mode |
|---|---|---|---|
| `sda-ba` | workflow | `<wf>/user-story.md` + requirements docs | `.sda/stories/<slug>/` (or chat-only) |
| `sda-design` | workflow | read + renew `<wf>/design.md` | **`[ASK]`**: save (where?) or skip saving |
| `sda-dev-task` | workflow | `<wf>/tasks/<NNN>. <slug>/` | `.sda/tasks/<NNN>. <slug>/` |

**Resolution order (all three):**
1. Workflow named in the request → use it.
2. Request says standalone / gives an explicit output path → standalone.
3. Exactly one workflow exists and the request is a continuation → propose it.
4. Otherwise → list workflows, then offer both, workflow first (the default):
   create a new workflow, or work standalone.

Never silently fall back to standalone, and never silently enter a workflow. A producer that
is told a workflow path that does not exist **stops and asks** — it never creates the workflow.

`sda-design` needs two tool additions: `vscode/askQuestions` (the standalone save/skip gate) and
`execute` (to record an escalation, or resolve one — §3).

## 3. Orchestration

| Layer | Component | Responsibility |
|---|---|---|
| Scaffold + state | `{workflow}` script | `init · list · current · read · advance · escalate · resolve` (§4). Only writer of `workflow.json`. Creates folders. Enforces direction, blocking, and artifact presence. Never triggers an agent. |
| Invocation | `sda-workflow` agent + the `/sda.workflow.*` prompts | Reports position and the single next action, owns `init`/`advance`, and raises a user-requested escalation. Advises: never invokes a producer, never `resolve`s. |

**Stage machine:** `story → design → tasks → ready`. Every stage produces one artifact
(`user-story.md`, `design.md`, `tasks/`); `ready` is terminal and has none. `advance` moves
exactly one stage forward and refuses to leave a stage whose artifact is absent.

- **The orchestrator advances.** `advance` is the only forward motion and is orchestrator-only —
  a producer never moves its own stage forward. So is `init`.
- **A producer may raise and close escalations** as the orchestrator's proxy; the script stays
  the sole writer of `workflow.json` either way. All three producers hold `execute`:
  `sda-dev-task` and `sda-design` raise and close, `sda-ba` closes only (it has no upstream
  stage).
- **`sda-workflow` is the orchestrator surface.** It holds `execute` too and is the only holder
  of `init` and `advance`; it may raise a user-requested escalation from any stage with an
  upstream, and never `resolve`s. Its prompts carry intent only and set
  `agent: "sda-workflow"`, so the agent's hook injects `{workflow}` — no prompt reads
  `project-config.json` itself.
- Implementation and QA progress stay per-task (`task.md` + `state.json`) — the workflow
  layer does not track runs.
- Human-confirmed transitions: state changes are recorded by the script, never hand-edited.

### Escalations

An escalation is a **request to an upstream stage**, raised when the current stage cannot finish
on the artifacts it was given. It has a lifecycle, and it is the only way a workflow moves
backwards.

| Step | Command | Who |
|---|---|---|
| raise | `escalate --reason "…" --brief "<path>"` — add `--to <stage>` to reach further back | the blocked producer |
| read | `current` → `escalation=E<n>` with `owner`, `reason`, and `brief` | the target producer |
| close | `resolve --id <E<n>> --report "…"` | the target producer |

- **One escalation per raise.** A jump back over several stages is still one escalation, owned by
  the stage it lands on.
- **The brief carries the evidence.** It is written **before** the raise, by the blocked producer
  via `sda-scribe` (Mode 8), which numbers and names the file; `notes[].brief` records the
  path. It is the artifact for a transition that otherwise produces none.
- **The guarantee is one-directional.** `escalate` refuses without a brief, so an escalation never
  lacks evidence. A brief whose raise was abandoned is a harmless stray file — `notes` stays the
  only truth, and the script checks that the brief exists without ever reading it.
- **`NNN` counts briefs; `E<n>` counts escalations.** The two are independent and linked only by
  the recorded path — nothing infers one from the other.
- **Retry, then stop.** A failed `sda-scribe` call is retried; after 3 failures the producer stops
  and reports to the user. Escalating without a brief is never an option.
- **Discuss, then act on approval — at both ends.** The raiser says what the stage is missing and
  asks whether the user wants to escalate; the resolver walks the user through what the brief
  claims, what it found, and what it proposes. Neither acts before the user's explicit go-ahead,
  and a declined escalation is a valid outcome — say what stays unresolved, then stop for
  direction. A brief that does not say what must be re-decided is a question to ask, never a gap
  to fill by guessing.
- **`sda-workflow` raises on request.** The human asks to escalate; the advisor elicits the
  three brief items from them and raises from any stage with an upstream (`design`, `tasks`,
  `ready` — never `story`). Its evidence comes from the user rather than from a blocked stage,
  which is why it must also ask which stage to return to. It never `resolve`s: closing renews an
  upstream artifact, which is that stage's act.
- **An escalation transfers no decision.** The target stage's own ownership rules still apply:
  `designOwnership` still governs a `design.md` renewal, and a requirement is still the user's
  to state.
- **Open-ness is derived.** `notes` is append-only and never edited, so an escalation is open iff
  an `escalation` entry exists after the last `resolution` entry.
- **Blocking.** While any escalation is open, `advance` is refused; `resolve` is the only command
  that clears it.
- **LIFO unwind.** Open escalations stack, and `resolve` always closes the **deepest** one and
  advances exactly one stage — never back to the escalation's `from`. The stage therefore parks
  at each intermediate stage, and the orchestrator runs that stage's agent on the way down. At all
  times `stage` equals `to` of the deepest open escalation.
- **At `ready`** no producer is active, so the backwards move belongs to `sda-workflow`: it
  elicits the brief's three items from the user, delegates them to `sda-scribe`, and runs
  `escalate --to <stage> --reason "…" --brief "…"`.

**Recipient protocol** — the target agent, when told to address the escalation:

1. Run `current`; if `owner` is not this agent's stage, say so and stop.
2. Read the **brief** at the path `current` prints — `<wf>/escalations/<NNN>. …md` — then the
   artifact it cites, and only the parts it cites. `.sda` is unsearchable, so the brief is what
   bounds a read that would otherwise open a whole `task.md`.
3. Discuss it with the user — what the brief claims, what this stage found, and what it proposes
   (a change, or that nothing changes and why) — and address it only after the user approves.
4. Renew this agent's own artifact.
5. `resolve --id <E<n>> --report "<what changed · where · what the downstream must redo>"`.
6. Report; the orchestrator then `advance`s, and the next stage reads the report plus the renewed
   artifact.

A resolution need not change anything — *"design unaffected by the FR reword"* is a valid report.
The point is that the intermediate stage is visited and says so.

Accepted cost: the retry rule is stated identically in the two raisers — the SDA install surface
has no shared instructions file to hold it once.

### Out of workflow

Escalation is a **workflow-mode operation** — with no state to move, there is nothing to
record. The standalone route:

| Situation | Action |
|---|---|
| the story / design / decision proved insufficient | state the problem, name the upstream agent, **stop** — the user re-runs it |
| a workflow exists for this feature | **offer** it; escalate only a workflow the user names explicitly |
| the user wants a container retroactively | offer `{workflow} init`; never create it |

**Never silently switch containers** — not into a workflow, not out of one. §2 governs entry;
this governs mid-session discovery. A standalone session does not run `{workflow} list` to go
looking.

`scripts.workflow` is injected **per-agent, not per-workflow** — its presence in session context
does not imply a workflow exists, and a standalone session never invokes it.

Accepted cost: a standalone escalation leaves no trace, so it can be rediscovered. Standalone
is stateless by design.

## 4. `{workflow}` script contract

Installed to `.sda/scripts/workflow/workflow.ps1` / `.sh` (registered as `scripts.workflow`).
Flags are `--flag` in bash, `-Flag` in PowerShell.

```
{workflow} init     --slug <slug>
{workflow} list
{workflow} current  --slug <folder>
{workflow} read     --slug <folder> [--field <id|slug|created|stage|notes>]
{workflow} advance  --slug <folder>
{workflow} escalate --slug <folder> [--to <stage>] --reason <text> --brief <path>
{workflow} resolve  --slug <folder> --id <E#> --report <text>
```

### Output grammar

| Kind | Shape |
|---|---|
| mutation — `init`, `advance`, `escalate`, `resolve` | `ok: workflow '<slug>' <verb> <subject> -> '<stage>'` |
| status — `current` | `key=value` lines |
| raw — `read` | pretty-printed JSON, or the bare field value |
| failure | `error=<X cannot do Y because Z>` and exit 1 |

```
ok: workflow '001. const-refactoring' created -> 'story'
ok: workflow '001. const-refactoring' advanced 'story' -> 'design'
ok: workflow '001. const-refactoring' escalated 'tasks' -> 'story'
ok: workflow '001. const-refactoring' resolved 'E1' -> 'design'
error=advance cannot move from 'design' because escalation E1 is open; run 'current', then 'resolve' E1
```

The resulting stage is always the last token, so a caller never needs a second call to learn
where the workflow now is.

### Container consistency

Every command that reads state verifies the container first: `workflow.json`
exists, parses, carries `id`, `slug`, `created`, and `stage`, and holds a known
`stage`. An inconsistent container stops the command with an `error=` line
rather than yielding an empty field or a partial answer. `list` verifies **every**
container before printing anything, so one corrupted folder cannot leave a
half-list behind.

### Commands

| Command | Effect | Refused when |
|---|---|---|
| `init --slug` | creates `<root>/<NNN>. <slug>/`, its `tasks/` and `escalations/` folders, and `workflow.json` at stage `story` | slug is not kebab-case; the slug is taken; numbering is exhausted |
| `list` | verifies every container, then prints one line per workflow and marks the deepest open escalation | any container is inconsistent — no `workflow.json`, invalid JSON, a missing field, or an unknown stage |
| `current --slug` | prints `stage=`, the open escalation block, and any artifact gap | — |
| `read --slug [--field]` | the whole state, or one field; `--field notes` gives full history | the field is unknown |
| `advance --slug` | stage + 1 | an escalation is open; already at `ready`; the current stage's artifact is absent |
| `escalate --slug [--to] --reason --brief` | stage − N (default 1); records one escalation with a new id and the brief's path | `--to` is not earlier than the current stage; the current stage is `story`; `--reason` is missing; `--brief` is missing, does not exist, or does not sit in `<wf>/escalations/` |
| `resolve --slug --id --report` | closes the deepest open escalation; stage + 1 | no such id; the id is not the deepest open one; `--report` is missing |

### `current`

```
ok: workflow '001. const-refactoring'
stage=design
escalation=E1
owner=design
raisedBy=tasks
since=2026-09-15
reason=FR-ORD-014 under-specified; no ordering NFR
brief=.sda/workflows/001. const-refactoring/escalations/001. 2026-09-15_14-20-tasks-to-design.md
```

`escalation=none` when nothing is open — the key is always present, so a missing key is never
ambiguous. `owner` is the stage whose agent must resolve it; `raisedBy` is the stage that raised it.
`brief=-` when the escalation was recorded before briefs existed — a container written by an
earlier build; the resolver then works from `reason` alone.

### `list`

```
001. const-refactoring | design | escalation E1 open | 2026-09-14
002. auth-refactor | tasks | - | 2026-09-14
```

One line per workflow. The escalation field shows the **deepest open** escalation, or `-`; full
history is `read --field notes`.

### Reasons and reports

All three are **pointer-quality**: one line, ASCII, no newlines. They exist because a session
does not survive to the next stage.

| Argument | Carries | Points at |
|---|---|---|
| `--reason` | **the ask** — what broke, what must be re-decided | the brief, by name — never a reproduction of it |
| `--brief` | **the evidence** — the brief file at the path the note records | the level the target stage must re-decide |
| `--report` | **the answer** — what changed, where, what the downstream must redo | the renewed upstream artifact |

`reason` wins on *what is being asked*; the brief supplies the evidence. Both are frozen once
written, so they can only diverge if the raiser let them — and the recorded path, never the file
name, is what links them.

### `workflow.json`

```json
{
  "id": "001",
  "slug": "const-refactoring",
  "created": "2026-09-14",
  "stage": "design",
  "notes": [
    { "type": "escalation", "id": "E1", "from": "tasks", "to": "design", "reason": "…", "brief": "…", "date": "2026-09-15" },
    { "type": "resolution", "id": "E1", "report": "…", "date": "2026-09-15" }
  ]
}
```

| `type` | Shape | Written by |
|---|---|---|
| `escalation` | `{ type, id, from, to, reason, brief, date }` | `escalate` |
| `resolution` | `{ type, id, report, date }` | `resolve` |

- Ids are `E1`, `E2`, … assigned in order, never reused — one per `escalate`.
- `brief` is a path, and the only link to the evidence file. The script refuses the raise when
  that file is absent and never reads its contents — the brief is evidence, not state.
- `notes` is append-only and **never edited**, which is why closure is a new entry and open-ness
  is derived (§3).
- `notes` doubles as the **inter-session channel** — the only thing that survives a session
  boundary.
- Known limitation: the log is per-workflow — no cross-workflow history (§11).

**Removed in rev 3:** `next` (folded into `current`), `update` (renamed `advance`), the skip
concept, and the `--title`, `--from`, `--stage`, and `--note` flags.

## 5. Artifact cross-references

First section of every workflow artifact — relative links so they are clickable:

```markdown
## Context
- **Workflow:** 001. const-refactoring
- **User Story:** [user-story.md](user-story.md)
- **Design:** [design.md](design.md)
- **Requirements:** [FR-ORD-014](…)   ← path resolved from the repo's AI readmes
```

- `user-story.md`: workflow id + title. `design.md`: + user story. `task.md`: + design (above `## Scope`).
- **Omitted entirely** for standalone artifacts — no empty headers.

## 6. `design.md` content rules

`design.md` is **context for `sda-dev-task`**, not a completeness gate. Questions stay allowed;
the goal is fewer *re-derivations*, not zero asks.

### What counts as a design decision

Four guards, applied in order.

**1. Generator — walk these kinds; do not recall them.**

| Kind | Answers | Example |
|---|---|---|
| Boundary / ownership | which layer owns this concern | — |
| Structure | what components are added, split, merged | extract a shared package |
| Interaction / flow | who calls whom, sync vs async, ordering | backend → outbox → worker |
| Pattern | which named pattern, for which problem | outbox, CQRS |
| Contract shape | *semantically* what crosses a boundary | event carries identity + version |
| Cross-cutting | retry / timeout / authz / logging policy | — |
| Scope | in / out / deferred + reason + revisit trigger | "broker deferred" |
| Impact / risk | what this breaks, migration needed | readers tolerate eventual consistency |

**2. Filter — two discriminators.**

| Discriminator | Test | Routes to |
|---|---|---|
| Home | "Would an unrelated future feature need to know this?" | yes → decision doc · no → `design.md` |
| Altitude | "Can two *different* implementations both satisfy this?" | yes → design-level · no → you are writing code |

**3. Excluder — not design decisions, and their real home.**

| Not a design decision | Home |
|---|---|
| test scenarios and cases | `task.md` |
| file layout, symbol and type names | `task.md` |
| schema field lists, exact payloads | spec files → inlined into `task.md` |
| CLI flags, config keys, env vars | readmes (mechanical) |
| logging message text | `task.md` |
| implementation order / unit sequencing | `task.md` Implementation Plan |

**4. Altitude trigger — mechanical.** A line is below altitude if it contains a **source** file
path, a symbol name, a code fence, a schema field name, a config key, or SQL. **`design.md` is
snippet-free.** Decision docs keep their small `application` allowance; `design.md` does not.
Documentation references are the exception — relative `.md` links to the docs, readmes,
requirements, and decision docs are navigation, and `design.md` requires them in `## Docs` and
`## Context`.

### Form

- Not BDD — behaviour already has two homes (acceptance in `user-story.md`, executable
  scenarios in `task.md`). A third home means two copies, and the non-executable one drifts.
  `design.md` holds no scenarios.
- Declarative: decision → what it constrains → consequence.
- Specificity as in the examples: `outbox`, not `OutboxDispatcher.Dispatch()`.

### Content

| Section | Contains |
|---|---|
| `## Context` | the reference block (§5) |
| `## Scope` | in / out / deferred + reason + revisit trigger |
| `## Approach` | components touched or created, interactions, patterns — stated as constraints |
| `## Decisions` | **pointers** to the durable decision docs, one line each on why it matters here |
| `## Docs` | the documents this design produced or changed, as relative links |
| `## Requirements` | FR/NFR ids covered + how the design satisfies each (one line) |
| `## Impacts & risks` | cross-layer effects, contracts, migration |
| `## Open questions` | questions the design has not settled, each with what it affects |
| `## Handoff` | what is settled; the affected-spec list (`use-as-is` / `extend` / `create`); what `sda-dev-task` must not re-decide |

`design.md` may not be the **sole** home of any durable decision — decisions are recorded in
decision docs first.

### Coverage test — closing step, both surfaces

> If `sda-dev-task` had to design this task alone, what would it have to invent?

Everything it would invent is a missed design decision. The agent runs this itself **and**
surfaces it to the user as a closing question.

## 7. Requirements docs (durable)

`sda-ba` becomes the requirements owner, mirroring `sda-design` for tech docs.

| Tier | Artifact | Location | Owner |
|---|---|---|---|
| Durable | requirements tree — FR/NFR entries | **outside `.sda`**, wherever the repo's docs live (global + per subsystem) | `sda-ba` (content) → `sda-scribe` (writes) |
| Transient | `user-story.md` — one increment, linking the IDs it covers | `<wf>/user-story.md` | `sda-ba` |

**Repo-structure principle (applies to all agents).** Doc locations are resolved from the
repo's **AI readmes**, never from a hardcoded canonical layout. Repos differ: use the
structure the repo actually has, create only the nodes it needs, and never assume the
`repo-ai-friendly` default tree is fully present.

| Aspect | Rule |
|---|---|
| Layout | `requirements/<feature>/[<concern>/]<item>.md` with an `index.md` at every level. The concern level is **optional** — a single-slice feature keeps items at `<feature>/`. Max depth three. |
| Grouping | Feature = one bounded context, matching `task.md`'s `Feature:` and the readme's feature list. Concern = one slice (audience `admin/`, capability `scheduling/`). Item = one capability. Split a file at ~15 entries; add a concern at the second slice. |
| Naming | Items by capability or outcome — never by UI surface. Concerns are never `misc/`, `other/`, or a single-slice `default/`. |
| IDs | FRs: `<FEATURE-SLUG>-<NNN>` uppercased (`AUTH-003`) — the slug is the **feature**, so regrouping never renumbers. NFRs: `<FEATURE-SLUG>-NFR-<NNN>` scoped, `<SCOPE>-NFR-<NNN>` in a tree-level `nfr.md` (`GLOBAL-NFR-001`) so ids stay unique across the global and layer trees. Append-only. |
| Status | **None.** The tree is an inventory of what is *specified*. "What is implemented" is read coarsely from the readmes' implemented-features section. |
| Delivery link | **None** (`Delivered by` rejected — a durable → transient pointer would dangle). |
| Write split | `sda-ba` writes `user-story.md` directly; the requirements tree goes to `sda-scribe`. |

**NFR rule (replaces the current "local NFRs only / no global-NFR catalog" constraint):**

> **NFRs are measurable and live with the requirements docs.** An NFR sits at the level it
> constrains: the item's `## NFRs` section, `<concern>/nfr.md`, `<feature>/nfr.md`, or the
> tree's root `nfr.md`. Resolve the location from the repo's AI readmes. A story or scenario
> cites the requirements entry rather than restating it.

**Measurability** = metric + threshold (operator, value, unit) + measurement method +
condition (load/dataset/environment) + applies-to. Two failure modes: *unmeasurable*
(no metric/threshold) and *unfalsifiable* (threshold without method/condition).

Escalation symmetry:

| Change | Route |
|---|---|
| mechanical doc change | `docs` unit (`sda-dev` → `sda-scribe`) |
| semantic doc change | `sda-design` |
| **semantic requirements change** | **`sda-ba`** |
| decision content already agreed in a non-design session | `docs` unit — writes the **decision doc** only; `design.md` renewal stays with `sda-design` (R1) |
| the current stage's output proved insufficient | `{workflow} escalate` — moves the stage back, records why, and requires the evidence brief |

## 8. Verification — `sda-docs-check`

Read-only, structure/shape only. It never judges whether an NFR threshold is *met* (that is
`sda-qa`).

| Stage | Requirements addition |
|---|---|
| 1 Structure | every requirements folder exists, has an `index.md`, and routes every child — recursively, global + per layer |
| 2 Integrity (script) | run `docs-integrity` on each requirements root — broken link / orphan / duplicate row |
| 3 Drift / shape | entries declare no code files → `not checkable` for drift; instead lint **NFR shape**: missing threshold or missing measurement method → flag |
| 4 Readmes | the requirements section exists and its links resolve per layer |

**`design.md` checks** — the caller passes the exact path (`.sda` is unsearchable):

| Check | Mechanism |
|---|---|
| `## Context` / `## Docs` links resolve | script — `docs-integrity -File` |
| code fence present | script — `docs-integrity -File` |
| path token present that is not a `.md` link (§6 guard 4) | script — `docs-integrity -File` |
| symbol or type names present (altitude) | agent judgement |
| schema field name, config key, or SQL present | agent judgement |
| durable docs contain **no** `.sda/` reference (one-way link rule) | script — `docs-integrity -Root` |
| *restates a decision doc* | **not checkable** |

Only the mechanical half of guard 4 is checkable by script: a fence, a non-`.md` path, and a
`.md` link are all decidable from text alone. Symbols, schema fields, config keys, and SQL
need the repo's own tables — they stay with the agent. `.md` links are navigation, so
`## Context` and `## Docs` pass the check rather than tripping it.

**Not checkable by design:** references from tasks/stories → requirements. `Covers:` lives in
`.sda` (transient, unsearchable), so the reference is one-way.

**Script change:** `docs-integrity.ps1|.sh` gains one new mode and keeps its tree contract.

1. **`-Root <dir>`** — rename the param from `-DecisionsRoot` (keep it as an alias) and make
   the `MISSING` message generic, so one script serves decisions and requirements roots. While
   walking, it also fails a durable doc that contains the literal `.sda/`.
2. **`-File <path>`** — new mode for a single file: resolve every relative markdown link, flag
   a code fence, and flag a path-shaped token that is not a `.md` link. This is the only way to
   check `design.md`, which lives under `.sda/` and therefore inside no docs root — the tree
   walk cannot reach it, and pointing `-Root` at `.sda` would flag every `task.md` and
   `state.json` as an orphan.
3. **Install folder** — `assets/decisions/` → `assets/docs/`, installing to
   `.sda/scripts/docs/`. One script now serves two roots, and the old folder named only one of
   them; the new name also restores the source-folder→install-folder pairing every other asset
   folder has. `write-config.*` carries the pre-rename path in its shipped list, and `setup.*`
   deletes the retired folder, so re-running setup completes the move.

## 9. `repo-ai-friendly` changes

| File | Change |
|---|---|
| `assets/docs-tree.md` | add `requirements/` (global + per-layer) |
| `assets/decision-schema.md` | `<feature>/index.md` added to the decision tree — the uniform per-level index rule (decision 24) |
| `assets/requirements-schema.md` | **new** — requirements tree: per-level index, item file, and `nfr.md` schemas |
| `assets/readme-outline-schema.md` | add a requirements section; preamble states both docs types are maintained |
| `assets/docs-index-schema.md` | requirements rows |
| `SKILL.md` · `README.md` · `AGENTS.md` | description + tree + table sync |

## 10. Locked decisions

| # | Decision |
|---|---|
| 1 | No `workflows.md` index — enumeration via `{workflow} list` |
| 2 | No `sda-workflow` agent; the script + one prompt are the orchestrator surface — **superseded by 40** |
| 3 | Orchestrator (human) owns workflow creation; producers never scaffold |
| 4 | `## Context` reference block in workflow artifacts; omitted standalone |
| 5 | Requirements tree is durable, outside `.sda`, split by subsystem like tech docs |
| 6 | One requirements file per feature (FRs + local NFRs); `nfr.md` for wider NFRs |
| 7 | No requirement status field; no delivery link |
| 8 | NFR rule replaced with the generic measurable-NFR wording (§7) |
| 9 | `sda-ba` writes the story; `sda-scribe` writes the requirements tree |
| 10 | Doc paths come from AI readmes, not `project-config.json` |
| 11 | `sda-docs-check` verifies requirements structure + NFR shape |
| 12 | `sda-scribe` Create mode: task parent is caller-provided (no hardcoded `.sda/tasks/`) |
| 13 | Numbering `<NNN>. <slug>` everywhere; `workflow.json`; `.sda/scripts/workflow/` |
| 14 | Standalone fallbacks stay: `.sda/stories`, `.sda/tasks`, `.sda/design/reports/` |
| 15 | Producers may invoke `escalate` only, as the orchestrator's proxy (E2b); `init`/`update` stay orchestrator-only — extended by 31, renamed by 26 |
| 16 | `update` forward-only; `escalate` backward exactly one stage — both enforced by the script — **superseded by 26, 30** |
| 17 | Skips and escalations land in `workflow.json.notes[]` with a `type`; `list` marks them — **superseded by 27, 32** |
| 18 | Design is skippable; the orchestrator decides and the skip is recorded — **removed by 27** |
| 19 | `design.md` = handoff context; design decisions are structural constraints, snippet-free (§6) |
| 20 | A decision agreed outside a design session → `docs` unit writes the decision doc; `design.md` renewal stays with `sda-design` (R1) |
| 21 | `sda-design` gains `vscode/askQuestions` + `execute`; its terminal ban narrows to the `{workflow}` script |
| 22 | Standalone is offered at entry, never assumed; a standalone session never invokes the workflow script |
| 23 | A design session has **one** deliverable — `design.md`, one schema, two placements (`<wf>/design.md`, `.sda/design/reports/<yyyy-MM-dd_HH-mm_<short-name>>/design.md`). `design_report.md` is retired, and so is `design-report-schema.md` |
| 24 | Every folder under `decisions/` and `requirements/` carries an `index.md` — a feature folder is a routing level, not a bare grouping. Routes run index → feature index → document. Existing decision trees conform on their next touch |
| 25 | `task.md` carries no `## QA` section — QA scope is not recorded in the task document |
| 26 | `update` → `advance`: one stage forward, no target argument, refused when the current stage's artifact is absent (16) |
| 27 | No skips: every stage produces its artifact; a design pass with nothing to decide renews `design.md` with what was considered and why it stands (18, 17) |
| 28 | `next` is deleted; its artifact-gap check folds into `current` |
| 29 | `init` takes no `--title`; the `title` field leaves `workflow.json` |
| 30 | `escalate` drops `--from` and may jump several stages with `--to`; each raise records exactly one escalation note, owned by the stage it lands on (16) |
| 31 | `resolve` closes the deepest open escalation and advances one stage — the producer-side mirror of `escalate`; `--id` and `--report` are required (15) |
| 32 | Escalations carry ids (`E1`, `E2`, …); open-ness is derived from the append-only log; `advance` is refused while any escalation is open (17) |
| 33 | `notes` is the inter-session channel, not only a deviation log; entries are never edited, so closure is a new `resolution` entry |
| 34 | Output grammar: mutations print `ok: workflow '<slug>' <verb> <subject> -> '<stage>'`; `current` and `read` print `key=value` / JSON; failures print `error=<X cannot do Y because Z>` |
| 35 | An escalation writes a **brief** — the evidence — before the raise; `escalate` refuses without one, and `notes[].brief` records its path. A brief is evidence, not state: the script checks that it exists and never reads it |
| 36 | The brief is numbered and named `<NNN>. <yyyy-MM-dd_HH-mm>-<from>-to-<to>.md` by `sda-scribe`, which already numbers inside `.sda`. `NNN` counts briefs, `E<n>` counts escalations, and the recorded path is the only link between them |
| 37 | `reason` is the one-line ask and `brief` is the evidence: the reason may name the brief but never reproduces it, and it wins on what is being asked |
| 38 | Escalation is blocking — a failed brief write is retried, then hard-stops the producer after 3 attempts. The rule is duplicated in the two raisers because the install surface has no shared instructions file |
| 39 | Escalation handling is discussed with the user at **both** ends and acted on only after direct approval — the raiser asks whether to escalate, the resolver discusses the brief before addressing it — and an escalation never transfers a decision the target stage's ownership rules reserve (`designOwnership`, the user's requirement) |
| 40 | `sda-workflow` is the orchestrator surface (2): it reports position and the single next action, owns `init`/`advance`, and raises a user-requested escalation from any stage with an upstream. It never invokes a producer and never runs `resolve` — closing renews an upstream artifact. Four prompts (`init`, `status`, `advance`, `escalate`) replace `/sda.workflow.new` and set `agent: "sda-workflow"` (41) |
| 41 | A prompt that targets a custom agent carries **intent only** and omits `tools:` — specifying tools would run it in the default agent instead. The procedure lives in the agent, so the hook-injected `{workflow}` is always available |
| 42 | Slug validation (`init`) and slug resolution (`--slug <slug>`) are **case-sensitive** in both twins — only `[a-z0-9]` and single hyphens. PowerShell's `-match`/`-eq` are case-insensitive by default, so the twin needs `-cnotmatch`/`-ceq`; Windows' case-insensitive filesystem must not leak into the contract |
| 43 | Every failure, including CLI misuse, prints `error=<X cannot do Y because Z>` and exits 1 (34) — no `usage` block, no raw parameter-binding error. A PowerShell `ValidateSet` or a mandatory parameter pre-empts the script's own check, so validation happens in the body, never in the param block |
| 44 | A container is read only after it is verified **consistent**: `workflow.json` present, parseable, carrying `id`, `slug`, `created`, `stage`, and a known stage. `list` verifies every container **before printing**, so a corrupted folder stops the command instead of leaving a partial answer — a half-list would read as a complete one |

## 11. Deferred

| Item | Revisit when |
|---|---|
| Semantic gate checks (DoR/DoD-style criteria the advisor would verify artifacts against) | the user authors the criteria; the mechanical artifact gate proves insufficient |
| Requirement status / delivery tracking | a durable, machine-checked "delivered" signal is actually needed |
| Inner DEV+QA cycle state | task `state.json` proves insufficient |
| Engine that triggers producers | workflow state is script-owned, so the swap stays cheap |
| Cross-workflow escalation history | a durable, queryable record of escalations across workflows is wanted |

## 12. Implementation order

1. Skill assets + scripts: `assets/workflow/workflow-schema.md`, `assets/workflow/{powershell,bash}/workflow.ps1|sh` (§4 — directions enforced, `--note`, `notes[].type`, `list` markers, `next` skip-tolerant); `setup.*` copies them; `read-config.*` gains `paths.workflows` + `scripts.workflow` and per-agent manifests.
2. Schemas: `## Context` block in `user-story-schema.md` and `task-schema.md`; **new** `design-record-schema.md` carrying the §6 content rules; **delete** `design-report-schema.md` and repoint its consumers (decision 23).
3. `repo-ai-friendly` requirements work (§9).
4. `sda-docs-check` + `docs-integrity` param generalization (§8), including the `design.md` checks.
5. Agents: `sda-ba`, `sda-design` (+ `vscode/askQuestions`, + `execute`, narrowed terminal ban), `sda-dev-task`, `sda-scribe`.
6. Prompt: `sda.workflow.new.prompt.md`.
7. Docs sync: `tools/sda/AGENTS.md` (concept, folder diagram, dependency-matrix rows, tool scoping, CLI-script rule, repo-structure rule, escalation proxy), `tools/sda/README.md`, root `README.md`, `skills/repo-ai-friendly/README.md` + `AGENTS.md`.
8. **Rev 3** (§3–§4): script twins — the seven-command surface, escalation ids, derived open-ness, the blocking rule, the artifact gate, the output grammar; `workflow-schema.md` (`title` out, `escalation` + `resolution` in, ids); the recipient protocol plus `current`/`escalate`/`resolve` in `sda-ba`, `sda-design`, `sda-dev-task`; the `/sda.workflow.new` prompt; then the docs sync (`tools/sda/AGENTS.md` matrix rows, `tools/sda/README.md`).
9. **Rev 4** (§3–§4): the escalation brief — `--brief` with its two refusals, `init`'s `escalations/`, `notes[].brief`, and `current`'s `brief=` line; `workflow-schema.md` (folder + field), **new** `escalation-brief-schema.md` (content), and the scribe's Step 10 (name); the raise protocol in `sda-design` + `sda-dev-task` and the brief-first read in all three resolvers; then the docs sync — plus the discuss-and-approve and stage-ownership rules (39).
10. **Rev 5** (§3): the `sda-workflow` advisor agent + its four prompts (`/sda.workflow.new` removed); `paths.workflows` + `scripts.workflow` in both `read-config` manifests; the three producers' offer naming `sda-workflow`; then the docs sync (`tools/sda/AGENTS.md` diagram + matrix rows, `tools/sda/README.md`, root `README.md`).
11. **Verification pass** (§13): a differential harness runs the same scenario against both twins and compares output, exit codes, and the resulting `workflow.json` — the stage machine, the artifact gate, the brief gate, `--to` jumps, LIFO unwind, derived open-ness, `brief=-` on a rev-3 state, and CLI misuse. Five defects fixed in the twins (42, 43), plus the missing unknown-stage check in the PowerShell twin and the `sda-workflow` escalation invocation (decision 40's step 5 dropped `--to`).

## 13. Open items

**Found while implementing tranche 7:** one §7 escalation route stays unimplemented. A decision
agreed outside a design session (decision 20) still routes to `sda-design` in `sda-dev-task`'s
docs table rather than to the `docs` unit. The blocker is an integration gap, not wording: the
`docs` unit's `kind` space maps to a single scribe mode, while a decision file needs
`sda-scribe` Mode 5 (decisions root + feature indexes) instead of Mode 6 — inputs the `docs`
unit contract does not carry. Decision 20's `(R1)` reference has no definition. The semantic
**requirements** route to `sda-ba` is now implemented, in `sda-dev-task`'s docs-routing table.

**The script twins are verified.** A differential harness
(`assets/workflow/_twins.Tests.ps1`, run with `powershell -NoProfile -File`) runs one scenario
sequence against both twins in separate roots and compares stdout, exit codes, and the resulting
`workflow.json`. The twins now agree on every step; the only residual difference is path syntax
(`\` vs `/`) and line endings, which are the platform's, not the script's — `brief` is recorded
as given.

Five defects were found by running it and fixed: PowerShell accepted mixed-case slugs; the
parameter block's `ValidateSet`/mandatory attributes pre-empted the contract's own error
messages; the unknown-stage check was missing; the bash twin had five failure messages that did
not follow the grammar; PowerShell's folder resolution was case-insensitive; and the PowerShell
twin wrote a UTF-8 BOM into `workflow.json` where jq writes none.

`workflow.sh` was verified 2026-09-14 by the same 23 cases the PowerShell twin
passes, run through Git Bash against `jq` 1.8.2 — one bug found and fixed (a subshell leak in
`resolve_folder`; see the comment on that function).

**Found while implementing tranche 5:** `task-schema.md` declared a required `## QA` section
(`State:` `required` | `declined`) that no agent produced or checked. Removed — see decision 25.

**Migration:** the `.sda/scripts/decisions/` → `.sda/scripts/docs/` rename (§8) changes a shipped
config default. `write-config.*` rewrites a path only when it is absent or still matches a
shipped value, so both the old and new `docsIntegrity` paths are listed as shipped. `setup.*`
ends with a cleanup step that deletes every retired shipped path, so re-running it completes the
migration on both the config and the filesystem — currently the legacy `scripts/decisions/`
folder and the retired `design-report-schema.md` (§12 item 2).
