# AGENTS.md — tools/sda/

Rules for AI agents working on the SDA (Software Development Assistant) tool suite.

---

## Overview

SDA is a coordinated suite of AI agents that implement a Specification-Driven Development workflow. Agents are **tightly coupled by design** — they share file formats, workflow contracts, and behavioral rules. Changes to one agent frequently require synchronized changes to connected agents and shared resources.

A **workflow** is a numbered container (`.sda/workflows/<NNN>. <slug>/`) holding one requirement's entry artifact (`issue.md`), optional `assets/` context files, its artifacts — `user-story.md`, `design.md`, `design-tests.md`, and `dev-report.md` — plus script-written state that tracks their stage. Progress runs `story → design → dev → ready`; `dev` is the single implementation stage and its artifact is the container's `dev-report.md`. Producers work workflow sessions by following the `sda-workflow-guide` skill, so their own files carry no workflow CLI or state logic. `sda-ba` and `sda-design` run in a workflow container only; `sda-dev` also works ad-hoc, without the skill.

## Folder Structure

```
tools/sda/
├── README.md                          ← user-facing docs, pipeline diagram, setup guide
├── AGENTS.md                          ← this file
├── agents/
│   ├── sda-workflow.agent.md           ← orchestrator surface: follows the workflow guide's orchestrator card — container position, next action + owner, `init` / user-requested `escalate` / `advance` / `commit`
│   ├── sda-ba.agent.md                ← Business Analyst: raw requirement → ready User Story (one Actor + Gherkin)
│   ├── sda-design.agent.md            ← system + feature design
│   ├── sda-qa-task.agent.md           ← qa-task.md authoring
│   ├── sda-scribe.agent.md             ← subagent: universal scribe (qa-task.md, dev-report.md, convention + ADR + design docs, design tests, specs, manifest.md)
│   ├── sda-code-explore.agent.md       ← subagent: fast read-only codebase exploration
│   ├── sda-web-explore.agent.md        ← subagent: web research for up-to-date API docs and library specs
│   ├── sda-dev.agent.md           ← TDD implementation orchestrator; owns the workflow's `dev` stage
│   ├── sda-test-writer.agent.md       ← subagent: writes tests (RED phase)
│   ├── sda-coder.agent.md             ← subagent: writes production code (GREEN phase)
│   ├── sda-refactor.agent.md          ← subagent: refactoring pass (REFACTOR phase)
│   ├── sda-dev-quality.agent.md       ← subagent: per-scope quality gates (Phase 5); check-and-report only
│   ├── sda-docs-check.agent.md       ← subagent: verifies docs tree + convention/ADR docs + AI-readme routing against reality (full scope, or targeted on a `docs` unit's files); check-and-report only
│   ├── sda-qa.agent.md                 ← runtime acceptance QA (read-only on source; writes qa-report.md)
│   └── sda-diagram-writer.agent.md   ← subagent: renders Mermaid diagrams from DIAGRAM blocks → `.md` files with ```mermaid fenced blocks
├── prompts/
│   ├── sda.qa.session-run.prompt.md       ← trigger sda-qa agent (QA verification)
│   ├── sda.qa.task-create.prompt.md       ← trigger sda-qa-task agent (create a QA task)
│   ├── sda.setup.prompt.md               ← setup SDA tool (scaffolds .sda/ + config)
│   ├── sda.docs.reconcile.prompt.md     ← run the make-repo-ai-friendly skill's Reconcile mode (repo, or a named scope)
│   ├── sda.workflow.init.prompt.md        ← create one workflow container + its issue.md
│   ├── sda.workflow.status.prompt.md      ← where the containers sit + the single next action
│   ├── sda.workflow.advance.prompt.md     ← move one stage forward
│   ├── sda.workflow.escalate.prompt.md    ← send a workflow back a stage
│   ├── sda.workflow.handle-escalation.prompt.md ← handle the open escalation in the current session
│   ├── sda.workflow.story.issue.prompt.md ← story stage, from the container's issue.md (sda-ba)
│   ├── sda.workflow.design.issue.prompt.md ← design stage, from the container's issue.md (sda-design)
│   └── sda.workflow.dev.issue.prompt.md    ← dev stage, from the container's issue.md (sda-dev)
└── skills/
    ├── sda-workflow-guide/            ← the workflow layer: fixed paths, CLI, role cards, state-script twins
    │   ├── SKILL.md
    │   ├── assets/
    │   │   ├── orchestrator.md         ← orchestrator card: advising, init, issue.md, assets, stage sessions, commit
    │   │   ├── stage-story.md
    │   │   ├── stage-design.md
    │   │   ├── stage-dev.md
    │   │   ├── workflow-schema.md     ← workflow.json structure + container template
    │   │   └── escalation-brief-schema.md ← escalation brief content
    │   └── scripts/
    │       ├── workflow.ps1           ← workflow state management (PowerShell twin)
    │       ├── workflow.sh            ← workflow state management (bash twin)
    │       └── _twins.Tests.ps1       ← differential harness for the twins (dev-only, not shipped)
    ├── sda-spec-guide/                 ← contract spec conventions for all planning agents
    │   └── SKILL.md
    └── sda-setup/                     ← project scaffolding skill
        ├── SKILL.md
        └── assets/
            ├── project-config.example.json
            ├── project-config.reference.yml   ← annotated config reference → .sda/
            ├── ba/                            ← user-story schema
            │   └── user-story-schema.md       ← user-story.md template + schema rules → .sda/resources/ba/
            ├── dev/                           ← dev workflow schema
            │   └── dev-report-schema.md       ← dev-report.md template + schema rules → .sda/resources/dev/
            ├── qa/                            ← QA schemas, credentials, and scripts
            │   ├── qa-task-schema.md          ← qa-task.md template + schema rules → .sda/resources/qa/
            │   ├── qa.example.secrets.env     ← placeholder QA credentials → .sda/secrets/
            │   ├── bash/
            │   │   ├── load-qa-secrets.sh     ← loads QA credentials into current shell session; outputs var_name | is_empty table → .sda/scripts/qa/
            │   │   ├── list-qa-secrets.sh     ← lists credential names + descriptions → .sda/scripts/qa/
            │   │   ├── qa-session-init.sh     ← dot-sourced by sda-qa; sets UTF-8 encoding + loads credentials → .sda/scripts/qa/
            │   │   └── invoke-http.sh         ← HTTP helper for sda-qa CLI/HTTP requests → .sda/scripts/qa/
            │   └── powershell/
            │       ├── load-qa-secrets.ps1    ← loads QA credentials into current session; outputs var_name | is_empty table → .sda/scripts/qa/
            │       ├── list-qa-secrets.ps1    ← lists credential names + descriptions → .sda/scripts/qa/
            │       ├── qa-session-init.ps1    ← dot-sourced by sda-qa; sets UTF-8 encoding + loads credentials → .sda/scripts/qa/
            │       └── invoke-http.ps1        ← HTTP helper for sda-qa CLI/HTTP requests → .sda/scripts/qa/

            ├── design/                       ← SDA-only design schemas
            │   ├── design-record-schema.md   ← design.md format + decision taxonomy → .sda/resources/design/
            │   └── design-tests-schema.md    ← design-tests.md document shape → .sda/resources/design/
        ├── scripts/
        │   ├── bash/
        │   │   ├── setup.sh               ← scaffold .sda/ folder
        │   │   ├── write-config.sh        ← write project-config.json
        │   │   └── read-config.sh             ← per-agent config hook script → .sda/scripts/
        │   └── powershell/
        │       ├── setup.ps1              ← scaffold .sda/ folder
        │       ├── write-config.ps1       ← write project-config.json
        │       └── read-config.ps1            ← per-agent config hook script → .sda/scripts/
```

## Agent Dependency Map

### Orchestrated implementation

The TDD implementation phase is **orchestrated**: `sda-dev` derives work units from the request and the design, then delegates RED to `sda-test-writer`, GREEN to `sda-coder`, and the REFACTOR pass to `sda-refactor` to keep each context small.

| Agent(s) | How it works |
|---|---|
| `sda-dev` → `sda-test-writer` + `sda-coder` + `sda-refactor` + `sda-dev-quality` | Orchestrator delegates RED to `sda-test-writer`, GREEN to `sda-coder`, REFACTOR to `sda-refactor`, and QUALITY to `sda-dev-quality`; it owns workflow decisions (slice processing, verification, state tracking) |

### Agent relationships

```
user ──▸ sda-ba                                          raw requirement → User Story (requirements front-end)
sda-ba ─delegates─▸ sda-code-explore / sda-web-explore  elicitation research only (never design)
sda-ba ─delegates─▸ sda-scribe                          requirements tree (Mode 6)
sda-ba ─produces──▸ user-story.md                       input for sda-design

sda-design ─delegates─▸ sda-diagram-writer            diagram generation
sda-design ─delegates─▸ sda-scribe                    specs, convention + ADR + design docs, design tests (Mode 9), design record (Mode 7)
sda-design ─delegates─▸ sda-code-explore              subproject discovery + structure
sda-design ─delegates─▸ sda-docs-check                docs structure + convention/ADR integrity + drift + readme routing
sda-design ────handoff──▸ sda-dev                     design pipeline (design.md → implementation)

user ──▸ sda-qa-task                                      qa-task.md authoring
sda-qa-task ─delegates─▸ sda-code-explore            entry-point discovery
sda-qa-task ─delegates─▸ sda-scribe                  qa-task.md write (Mode 4)
user ──▸ sda-qa                                          runtime acceptance QA

sda-dev ─delegates─▸ sda-test-writer             RED phase
sda-dev ─delegates─▸ sda-coder                   GREEN phase
sda-dev ─delegates─▸ sda-refactor                REFACTOR phase
sda-dev ─delegates─▸ sda-code-explore            ad-hoc mode: codebase exploration
sda-dev ─delegates─▸ sda-scribe                  dev-report.md (Mode 3) + `docs` unit files (Phase 3·D)
sda-dev ─delegates─▸ sda-docs-check             `docs` unit verification, targeted scope (Phase 3·D)
sda-dev ─delegates─▸ sda-dev-quality             per-scope quality gates (Phase 5)
```

### Detailed dependency matrix

| When you change… | Also update… | Why |
|---|---|---|
| `user-story-schema.md` | `sda-ba` (authors per it), **sda-setup skill** (copies asset to `.sda/resources/ba/`) | BA authors the story against the schema; setup scaffolds it into consumer projects |
| `design-record-schema.md` | `sda-design` (provides the content), `sda-scribe` (writes `design.md` per it), **sda-setup skill** (copies asset to `.sda/resources/design/`) | The design record's sections — including the acceptance criteria — decision taxonomy, and altitude rules; setup scaffolds it into consumer projects |
| `design-tests-schema.md` | `sda-design` (authors the pseudo-tests), `sda-scribe` (Mode 9 writes `design-tests.md` per it), `sda-workflow-guide` stage card (gates `advance` on it), **sda-setup skill** (copies asset to `.sda/resources/design/`) | The behaviour outline's document shape — participants, ids, level grouping, fence. The pseudo-test method lives in the `test-driven-design` skill |
| User Story output path (container root, `<wf>/user-story.md`) | `sda-ba` (writes it), `user-story-schema.md` (its `## Context` block), `workflow-schema.md` (container template) | The story is the `story` stage's artifact — one file at the container root, beside `design.md` and `dev-report.md` |
| Design tests output path (container root, `<wf>/design-tests.md`) | `sda-design` (owns the pseudo-tests), `sda-scribe` (Mode 9 target path), `sda-workflow-guide` (stage cards, container template, orchestrator card, path table), `README.md` | The design stage's second artifact — beside `design.md`, never in a subfolder; absent when the design changes no behaviour. Its pseudo-tests are the change's acceptance criteria |
| `sda-dev` RED/test-writing rules | `sda-test-writer` | `sda-test-writer` executes the RED phase the orchestrator delegates |
| `sda-dev` GREEN/implementation rules | `sda-coder` | `sda-coder` executes the GREEN phase the orchestrator delegates |
| `sda-dev` REFACTOR/refactoring rules | `sda-refactor` | `sda-refactor` executes both refactor scopes (per-unit 4·U, cross-unit 4·X) the orchestrator delegates; for `refactoring` units, also receives and applies Changes blocks as sweep 0. The `In-scope symbols` entries are produced by `sda-test-writer` (one locator per test), sourced and persisted by `sda-dev`, and parsed by `sda-refactor` — the entry syntax is one contract across all three |
| `sda-dev` delegation format | `sda-test-writer`, `sda-coder`, and `sda-refactor` input contracts | Subagents parse the exact format the orchestrator sends |
| Approval gate structure or output templates | All of: `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Gate outputs must be consistent across the orchestrated flow |
| `### Verification commands` block in every phase result | `sda-test-writer`, `sda-coder`, `sda-refactor`, `sda-dev-quality` (emit the exact commands they ran), `sda-dev` (relays them verbatim) | Each phase result names the commands that produced its verdict, so a reader can re-run them |
| `refactoring` unit type routing | `sda-dev` (routes to Phase 4·U directly, passes Changes blocks), `sda-refactor` (accepts Changes field, applies as sweep 0) | New unit type skips GREEN; sda-refactor handles both prescribed transformations and improvement sweeps |
| `standardsSkill` (`project-config.json`) | `sda-dev` (from session context, passes `Standards skill:` in every delegation), `sda-coder`, `sda-refactor`, `sda-test-writer` (load the named skill), **sda-setup skill** (scaffolds default) | Configurable coding-standards skill; default `standards-compliance` (the literal name lives only in `project-config.json` + docs, never in `.agent.md` files) |
| `qa-task.md` schema (`qa-task-schema.md`) | `sda-qa-task` (designs FRs), `sda-scribe` (writes — Mode 4), `sda-qa` (reads — sole input) | sda-qa-task designs the QA spec; scribe writes it; sda-qa verifies against it black-box |
| `dev-report.md` schema (`dev-report-schema.md`) | `sda-dev` (provides facts), `sda-scribe` (writes), `workflow.ps1` / `workflow.sh` (it is the `dev` stage's artifact) | Orchestrator reports what was built; scribe formats it. The workflow layer never reads its content — only whether it exists |
| `sda-scribe` Mode 4 content shape (`content` vs `changes`) | `sda-scribe`, its callers | Scribe applies the shape the caller passes; anchored deltas update an existing file, full content creates or rewrites one |
| File-write mechanism (built-in tools only — no CLI or script) | `sda-scribe` (states the rule), `sda-ba` (writes `user-story.md`), `sda-qa` (writes `qa-report.md` + `evidence/`), `sda-workflow` (writes `issue.md` + `assets/`), `sda-diagram-writer` (file writer — rule not stated) | Every agent that writes files edits through the host's built-in tools so changes stay reviewable; a CLI or script write bypasses change tracking |
| Required checks (tests, types, lint, format, build, pre-merge, data files) | `sda-dev` (lists them per phase), `sda-dev-quality` (runs them for a scope), `sda-test-writer`, `sda-coder`, `sda-refactor` (run the ones their unit needs) | Agents run the repo's own checks and report pass/fail; none receives a command string |
| `qa-report.md` format (in `sda-qa`) | `sda-qa` (writes and presents the report directly) | sda-qa posts the report link; no agent parses or acts on its findings |
| Application-run commands | `sda-qa-task` (authors `## Setup` from the repo's context), `sda-qa` (starts each layer from `qa-task.md ## Setup`) | sda-qa starts each layer from the commands the spec carries; the fallback is the repo's own context |
| `paths.issues` in `project-config.json` | `sda-qa-task` (designs standalone `qa-task.md`), `sda-scribe` (Mode 4 numbers + writes there), `sda-qa` (reads standalone specs, writes `qa-report.md` beside them) | Shared root for standalone QA work (no task); default `.sda/issues`. Spec + report co-locate in one `<NNN>-<slug>/` folder |
| `paths.secrets` in `project-config.json` | **sda-setup skill** (scaffolds git-ignored folder + writes `.gitignore`) | No agent resolves this field at runtime — credentials are loaded via `scripts.loadQaSecrets`; default `.sda/secrets` |
| `scripts.qaSessionInit` / `scripts.invokeHttp` in `project-config.json` | `sda-qa` (from session context), **sda-setup skill** (scaffolds scripts) | sda-qa uses session-init path (fallback: `scripts.loadQaSecrets`) and HTTP helper path; defaults `.sda/scripts/qa/qa-session-init.ps1` and `.sda/scripts/qa/invoke-http.ps1` |
| `sda-scribe` Mode 4 (QA spec) destination/numbering | `sda-qa-task` (delegates it), `sda-qa` (discovers specs in `paths.issues`) | Producer and consumer must agree on the `{issues-root}/<NNN>-<slug>/` layout |
| `sda-qa-task` FR / read-list rules | `qa-task-schema.md` (authoritative FR rules), `sda-qa` (verifies the resulting FRs) | Designer applies the schema's black-box FR rules; sda-qa executes them |
| `sda-qa-task` delegation format (Mode 4) | `sda-scribe` Mode 4 input contract | Scribe parses the exact QA Task fields sda-qa-task sends — precondition, reproduce, Settle, Expected data, expected outcome, compare, layers, Setup, Credentials |
| Contract spec conventions | `sda-spec-guide` skill (owns the model, storage, metadata, and content rules), `sda-design` / `sda-docs-check` / `sda-qa-task` (load it), `sda-scribe` (writes spec files + manifest rows), **install-dev-suite** (installs it), rule 6 below (the cross-agent ownership map) | Spec conventions have one home each — artifact facts in the skill, who may write what in rule 6 |
| `test-driven-design` skill | `sda-design` (loads it by name when the change alters observable behaviour; never restates it), **install-dev-suite** (installs it, both twins) | The method, the rules for what earns a pseudo-test, and the two-pseudo-tests-per-new-seam threshold live in the skill — the agent file carries only placement and the gate |
| App readme outline (`AGENTS.md`) | `sda-design` (owns content), `sda-scribe` (Mode 6 writes), `sda-dev` (routes `docs` units that touch it), `sda-docs-check` (verifies routing against reality) | Readmes are the routing map — the format comes from the `{docsSkill}` skill's readme outline; thin, no implementation detail; reference entries carry triggers; features listed in the features section |
| Doc tree & per-subproject readmes | `sda-design` (owns placement), `sda-scribe` (Mode 6 writes), `sda-dev` (routes `docs` units), `sda-docs-check` (verifies) | Layout comes from what the repo declares; the `{docsSkill}` skill's default profile is the fallback when it declares nothing — never an imposed standard |
| Design topic files (`architecture.md`, `vocabulary.md`) | `sda-design` (dictates content), `sda-scribe` (Mode 6 writes) | Formats come from the `{docsSkill}` skill's architecture + vocabulary file rules |
| `paths.specs` in `project-config.json` | `sda-design` (writes specs, reads manifest for affected specs), `sda-scribe` (writes spec files), `sda-docs-check` (resolves a spec path when verifying a spec) | All planning agents receive this from session context; default `.sda/specs` |
| `workflow-schema.md` (workflow container + `workflow.json` shape) | `{workflow}` script (implements it — and verifies every container against it before reading state), `sda-ba` / `sda-design` / `sda-dev` (read state via the `sda-workflow-guide` skill), `sda-scribe` (Mode 8 — records the brief in the workflow's `escalations/` folder), **sda-workflow-guide skill** (ships the asset beside the script) | Folder naming, stage order, the `start` stage (skipped prefix), `notes[]` entry types, and the escalation brief's folder + `brief` field are the contract — a shape change breaks every reader of `list` / `read`, the scribe's Step 9, and every brief already on disk |
| `escalation-brief-schema.md` (the escalation brief's content) | `sda-scribe` (Mode 8 writes it per the schema — **Step 9 owns its file name and numbering**), `sda-design` / `sda-dev` (draft that content before the raise), `sda-ba` (reads it when resolving), **sda-workflow-guide skill** (ships the asset) | A document schema, not state — the script never reads the brief. Its sections change what every future escalation must carry, so it moves independently of the container's rules |
| `workflow.ps1` + `workflow.sh` (the state-script twins) | `_twins.Tests.ps1` (test: differential harness — one scenario sequence against both, comparing output, exit codes, and the written `workflow.json`), `sda-workflow` (runs the twins; never writes state), `sda-workflow-guide` (ships them and documents the full CLI in its `SKILL.md`) | One contract, two implementations: every command, refusal, and exit code must exist in **both**, and the harness must stay green. It is a **test, not an asset** — `_<subject>.Tests.ps1`, pruned by `install-skill.*` and never copied into `.sda/` |
| Stage list + each stage's artifact (the machine itself) | Both twins (`workflow.ps1` / `workflow.sh`), `_twins.Tests.ps1` (a scenario per stage and gate), `workflow-schema.md` (documents it), `sda-workflow` (pipeline diagram, escalate reach, `gap=` reporting), the `sda-workflow-guide` skill (one card per role, encoding its gate) | One stage machine across the twins, the schema, the orchestrator, and the skill's cards. Each stage's artifact is one file at the container root — `dev`'s is `dev-report.md` |
| `manifest.md` format | `sda-design` (adds specs, reads for affected specs), `sda-scribe` (writes/updates rows), `sda-docs-check` (reads for verification) | Entry point for spec discovery; scribe maintains it |
| `sda-design` diagram delegation format (`DIAGRAM` block) | `sda-diagram-writer` input contract | Subagent parses the exact DIAGRAM block format the orchestrator sends |
| Shared constraint blocks (`File reading strategy`, `Decide once, act immediately` in `sda-dev` + the three subagents) | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Each block is duplicated verbatim in every file that carries it — editing one copy means editing every other copy |
| A new `execute`-carrying agent, or a change to an agent's script allowlist | that agent's own terminal-scope bound (rule 15) — a `Terminal command scope` section or a bullet inside an existing constraint block — and `README.md`'s agent table when the tool list itself changes | An undeclared or unbounded runnable set lets the agent run arbitrary build/test commands; a bound that also forbids reading, listing, or searching blocks the only route into hidden folders |
| `{workflow}` script boundary (read-only `list`/`current`/`read` + `escalate`/`resolve`/`advance`; `init` orchestrator-only) | `sda-workflow` (orchestrator — owns `init`, raises a user-requested escalation from any stage with an upstream, never `resolve`), `sda-workflow-guide` (the skill every role follows — ships the CLI table, the fixed paths, and the role cards), `sda-ba` / `sda-design` / `sda-dev` (raise, advance their own stage, or resolve per the skill), `sda-scribe` (Mode 8 writes the brief a raise requires), human (confirms every transition) | Producers never **structure** a workflow — `init` stays orchestrator-only and the script stays the sole writer of `workflow.json`. A producer advances its own stage, raises an escalation, or closes one only on the user's direct confirmation. In workflow mode a producer follows the skill, which first runs `current` and refuses to act when `stage=` is not its own. The orchestrator **names** producers and never invokes them. While an escalation is open, `advance` is refused; `escalate` is refused without an existing brief in the workflow's `escalations/` folder, so the evidence is written before the raise and the raise aborts if it is not. A standalone session never invokes the script |
| `sda-workflow-guide` skill (the workflow layer) | `sda-ba` / `sda-design` (always follow it), `sda-dev` (in a workflow session), `sda-workflow` (its orchestrator card), the stage-entry prompts (point at it), **install-dev-suite** (installs it, scripts and schemas included) | The workflow CLI table, the container layout and every artifact path inside it, the stage gate, the advance/escalate/resolve steps, the orchestrator's housekeeping steps, the state-script twins and both workflow schemas live here. Nothing about the workflow layer is a config key. A producer's file carries only its input contract — the workflow folder — the name of its own artifact, and escalation-evidence authoring |
| `sda-workflow` agent + the `/sda.workflow.{init,status,advance,escalate}` prompts (orchestrator surface) | `sda-scribe` (Mode 8 writes the brief a raise requires), `commit` (a user-requested commit — links to the workflow's artifacts, which it reads), the start stage's owner — `sda-ba` / `sda-design` / `sda-dev` — (started by the human on the new container from its `issue.md`), `sda-ba` / `sda-design` / `sda-dev` (name `sda-workflow` when offering to create a container) | The prompts carry intent only and set `agent: "sda-workflow"`, so the agent's role and the skill's orchestrator card do the work — a prompt must **omit `tools:`**, which would otherwise run it in the default agent. The agent declares no `tools:` of its own, so it inherits every tool the host offers. The orchestrator never invokes a producer and never runs `resolve`; it delegates a commit to `commit` with links to the workflow's artifacts as the recorded intention, which the commit agent reads to ground the message |
| `issue.md` (container entry artifact) | `sda-workflow` (writes it at `init`, plus `assets/`), `sda-ba` / `sda-design` / `sda-dev` (handed it by their stage-entry prompt), `workflow-schema.md` (container template lists it) | The stage owners' conversation starter: container name + the artifact paths + the issue in the user's words + links to any assets the user attached — an outline, not a requirements spec, and no design or implementation detail. **Not state** — the script never creates, reads, or checks it, so it is never a `gap=` and never blocks `advance`; absent on containers that predate it |
| Stage-entry prompts (`/sda.workflow.story.issue`, `/sda.workflow.design.issue`, `/sda.workflow.dev.issue`) | `sda-ba` / `sda-design` / `sda-dev` (the `agent:` each one sets), `sda-workflow-guide` (the skill each prompt points the owner to), `sda-workflow` (names the start stage's prompt at `init`), `issue.md` (the artifact they hand the owner) | Each carries intent only and sets `agent:` to the stage's owner — a prompt must **omit `tools:`**. Each also declares workflow mode and points the owner at the `sda-workflow-guide` skill. Unlike the orchestrator's prompts these target producers, not `sda-workflow` |
| `/sda.workflow.handle-escalation` prompt | `sda-ba` / `sda-design` / `sda-dev` (the escalated-to stage's session runs it), `sda-workflow-guide` (its Resolve steps carry the procedure) | A resolve trigger, not a stage entry: it sets no `agent:`, so it runs in whichever producer session is open, and the guide's Resolve steps — not the prompt — carry the procedure |
| Question mechanics (`[ASK]` = short gates; elicitation = chat text with context + pros/cons) | `sda-dev`, `sda-qa-task`, `sda-qa`, `sda-ba`, `sda-design` | Shared interaction convention — changing the split in one agent must not diverge from the others. Escalation handling is a shared case of it: both ends discuss it with the user and act only on direct approval, and an escalation never transfers a decision the target stage's ownership rules reserve |
| Standards compliance rules | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | All code-producing agents enforce standards |
| Unexpected-failure / troubleshooting handling | `sda-dev`, `sda-dev-quality` (never loads troubleshooting guidance) | Troubleshooting is a workflow decision — subagents stop and report; the orchestrator diagnoses and recovers |
| Coding standards skill references | `sda-dev` | References coding standards for output |
| Quality check gates (Phase 5) | `sda-dev-quality` | Phase 5 is a thin delegation in **global** mode; the quality agent owns gate execution, reporting, and flagging, and serves standalone **local** (target files) or **global** (whole areas) requests |
| `sda-dev-quality` report format | `sda-dev` (Phase 5 result relay) | Orchestrator relays the quality report verbatim as the Phase 5 result |
| `sda-dev` Flags processing (Phase 5) | `sda-coder`, `sda-test-writer` | Orchestrator routes quality flags to the correct subagent for fixes |
| `models` in `project-config.json` | `sda-setup` skill (asks user, normalizes, resolves, applies to agent frontmatter), `tools/sda/README.md` (the default map) | sda-setup resolves family names to versioned models and writes `model:` into every agent in `agents/` — the agent list is never enumerated here: it is whatever `agents/` holds |
| `docs` unit type (sda-dev's route table) | `sda-dev` (routes to Phase 3·D; skips refactor + quality for it), `sda-scribe` (Mode 4 writes the files), `sda-docs-check` (targeted verification) | The only sanctioned path for mechanical doc changes made during implementation — including an anchored delta to an existing spec and its `manifest.md` row. It never creates a spec (`sda-design`'s deliverable) |
| Convention + ADR docs (`<subproject>/docs/conventions/`, `<subproject>/docs/adrs/`) | No config field — derived per subproject from the repo layout. `sda-design` (records + structures via sda-scribe Mode 5), `sda-scribe` (Mode 5 writes), `sda-docs-check` (verifies) | Conventions (how) live per subproject under `<subproject>/docs/conventions/`; ADRs (why) under `<subproject>/docs/adrs/` — feature-grouped (`shared/`, `<feature>/`) with descriptively-named files; one rule or one decision per file, routed by the feature's `index.md` |
| Requirements tree (`requirements/<feature>/[<concern>/]<item>.md`) | No config field — resolved from the repo's AI readmes. `sda-ba` (owns content + FR/NFR ids), `sda-scribe` (Mode 6 writes), `sda-design` (reads for design scope), `sda-docs-check` (structure + NFR shape, via `check-tree`), `{docsSkill}` skill (schema) | Durable inventory of what is *specified* — no status field, no delivery link; an `index.md` at every level, max depth three, ids append-only |
| `is-repo-ai-friendly` skill (the AI-friendliness artifact list + the model-free `check-links`) | `sda-docs-check` (loads for the list + link checks), `{docsSkill}` (loads for the list), **install-dev-suite** (installs it) | The single home of what makes a repo AI-friendly — the artifact list, name-free. No other file restates it |
| `make-repo-ai-friendly` skill (docs-map schema, default tree profile, doc schemas, the model-bound `check-tree`) | `sda-design` (loads for the contract + schemas), `sda-scribe` (Mode 5/6 loads for formats), `sda-ba` (loads for the requirements structure + IDs), `sda-docs-check` (loads for verification), **install-dev-suite** (installs it), `read-config` (resolves `docsSkill`) | All consumers load it by name via `docsSkill`; the skill owns the schema formats and the **default profile** — a proposal, never an imposed tree |
| `sda-docs-check` input (scope + expected structure) | `sda-design` (passes `full` + the repo's declared structure, else the default profile), `sda-dev` (passes `targeted` + the written file list) | Caller decides what to verify against; otherwise the repo's declaration, else the `{docsSkill}` skill's default profile |
| `sda-docs-check` report findings | `sda-dev` (Phase 3·D: presents them and asks the user) | Findings are a report, not a failure — routing them to troubleshooting guidance misreads the verifier's output |
| Requirements tree (`requirements/<feature>/[<concern>/]<item>.md`) |
| `docsCheck.enabled` in `project-config.json` | `sda-docs-check` (reads it) | Turns docs verification off for a repo whose docs must not be maintained or verified. Default `true`; when false the agent reports `docs-check disabled` and runs nothing |
| `README.md` | Keep consistent with all agent descriptions and workflow phases | User-facing docs must match agent behavior |

## Rules

### 1. Orchestrator–Subagent Synchronization (highest priority)

`sda-dev` owns the TDD workflow; `sda-test-writer`, `sda-coder`, and `sda-refactor` execute the phases it delegates. When changing workflow logic:

- A RED-phase change in `sda-dev` must be reflected in `sda-test-writer`.
- A GREEN-phase change in `sda-dev` must be reflected in `sda-coder`.
- A REFACTOR-phase change in `sda-dev` must be reflected in `sda-refactor`.
- A change in a subagent's contract must be reflected in the orchestrator's delegation templates.

Before considering any workflow change complete, verify the orchestrator and subagents handle the same scenarios consistently.

### 2. Schema Changes Propagate Downstream

File schemas (`qa-task.md`, `dev-report.md`, `project-config.json`) are contracts between agents. When changing a schema:

1. Identify every agent that **reads** or **writes** that schema (use the dependency matrix above).
2. Update all affected agents to match the new schema.
3. Update `README.md` if the schema is documented there.

### 3. Subagent Contract Stability

`sda-test-writer`, `sda-coder`, and `sda-refactor` have explicit **input contracts** (the format `sda-dev` sends them). When changing delegation format:

1. Update the orchestrator's delegation templates.
2. Update the subagent's input contract section.
3. Verify the subagent's workflow still produces the expected output format.

**Subagents are mechanical workers.** They make domain decisions *within* their assigned unit (how to implement, how to structure tests, which algorithm to use). They do **not** make workflow decisions. When something outside their scope fails (environment error, unexpected tool failure, missing input), they stop immediately and report — they do not troubleshoot, retry with alternatives, or improvise. Recovery is the orchestrator's responsibility.

### 4. Shared Constraint Blocks Are Duplicated

`sda-dev`, `sda-dev-quality`, `sda-test-writer`, `sda-coder`, and `sda-refactor` repeat the same constraint blocks. When editing one copy, copy the change to every other copy.

| Block | Files that carry it |
|---|---|
| `File reading strategy`, `Decide once, act immediately` | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` |
| `CLI invocation form` (rule 17) | `sda-dev`, `sda-dev-quality`, `sda-docs-check`, `sda-qa`, `sda-qa-task`, `sda-workflow-guide` skill |

### 5. Keep README.md in Sync

The `README.md` in this folder documents the agent pipeline, setup steps, workflow phases, and configuration paths. When any of these change in the agent files, update `README.md` to match.

### 6. Contract Spec Ownership

One spec file, one creator — the design stage. `sda-design` ends every session
with a spec for every boundary the feature crosses: designed, or extracted
from code that already exists. Implementation amends an existing spec only
through a `docs` unit, and stops when a crossed boundary has none.

| Agent | May | Must not |
|---|---|---|
| `sda-design` | create any spec, via `sda-scribe` (Mode 6) | — |
| `sda-dev` | record an anchored delta into an existing spec via a `docs` unit; stop when a crossed boundary has none | create, delete, replace, or defer a spec |
| `sda-scribe` | write the spec file and its manifest row | decide content |
| `sda-docs-check` | verify a written spec | fix it |
| `sda-qa-task` | read specs and the manifest | edit a spec |

The spec model, storage layout, and metadata live in the `sda-spec-guide` skill.

### 7. Preserve Existing Patterns

- Follow the formatting conventions already in use (Markdown heading levels, table layout, section numbering, output template style).
- New sections should model their structure after existing peer sections in the same agent file.

### 8. Language-Agnostic Instructions

All SDA agent bodies, skills, and supporting assets must remain **language-agnostic**. Never hard-code language-specific commands, framework names, file extensions, or toolchain references into agent or skill instructions.

| Instead of… | Use… |
|---|---|
| `npm test`, `pytest`, `mvn verify` | "the repo's test command" |
| `*.ts`, `*.py`, `*.java` | "the files the change touches" |
| "Jest", "Vitest", "JUnit" | "the repo's test runner" |

Language-specific behavior is resolved at runtime from:
- the repo's own context — its AI readme and the docs it routes to;
- its own files, when nothing is documented.

Agent instructions describe **what** to do; the repo's context supplies the **how**. Never name the path where that context lives.

### 9. `.sda` Dependencies Section Required

Every agent or skill that reads or writes files in `.sda/` must include a `.sda dependencies` section with:

- **Heading level:** `###` when nested under a parent constraints section (e.g. `## HARD CONSTRAINTS`), `##` otherwise.
- **Standard preamble:** `".sda/ is a dot-prefixed folder that may be hidden from search tools. Access all files below by exact path from the repo root — never search for them."`
- **Dependency table:** `| File | Path |` listing every `.sda/` file the agent reads or writes, with the exact relative path from the repo root.

### 10. Delegation — Always Pass Full `.sda/` Paths

When delegating to a subagent, pass every `.sda/` file reference with its full path (e.g., `.sda/workflows/001. alpha/dev-report.md`, not `dev-report.md`). Subagents must never search for `.sda/` files — if a path is ambiguous, ask the caller.

### 11. Communication Style Placement

Every SDA agent that produces chat output must include a `## Communication style — mandatory` section (or `### Chat output style` when nested). This section is a **global governing rule** — it applies throughout the agent's entire session, not to a single phase or step.

**Placement:** After the constraint sections (HARD CONSTRAINTS, read-list, or equivalent) and **before** the first workflow or phase section. Never place it after workflow sections.

### 12. CLI Script String Encoding

All PowerShell (`.ps1`) and bash (`.sh`) scripts must use only ASCII characters inside string literals — including error messages, warnings, and output strings.

| Forbidden | Use instead |
|---|---|
| Em dash `—` (U+2014) inside `"..."` or `'...'` | Hyphen-minus `-` |
| Any non-ASCII character inside a string literal | Its ASCII equivalent |

Non-ASCII characters in `#` comments are safe. The restriction applies only to characters inside quoted strings. PowerShell 5.1 misparsed UTF-8 em dashes as `â€"`, producing `TerminatorExpectedAtEndOfString` parse errors.

### 13. Machine-Written State — Scripts Only

`workflow.json` is written by its script only. Never hand-edit it, and never let an agent write it directly. A rejected transition is an error to report and escalate — not a state file to patch.

### 14. Doc Locations Come From the AI Readmes

Doc trees (conventions, ADRs, requirements) and readmes are located from what the repo declares in its own readmes or docs declaration — never from a hardcoded layout and never from `project-config.json`. Repos differ: use the structure the repo has, create only the nodes it needs, and treat the `{docsSkill}` default profile as a proposal for repos that declare nothing.

### 15. Terminal Use — No File Changes Through the Shell

**Never create, edit, move, or delete a file with a terminal command** — no output redirection, no in-place edit, no rename, no delete, no VCS mutation. Every change goes through the host's built-in edit tools: a CLI-written file is invisible in the session until `git diff`. See the `File-write mechanism` matrix row.

**Never write a rule restricting terminal reading, listing, or searching** — it is the only route into hidden or git-ignored folders such as `.sda/`.

### 16. CLI Instructions Are Shell-Agnostic

Never name a shell-specific command, flag, or syntax in a rule. State the intent, or name the placeholder the session resolves (`{cli_separator}`, `{workflow}`, …).

| Never | Instead |
|---|---|
| `grep -r`, `Get-ChildItem`, `Select-String`, `rm -rf`, `Set-Content` | "search the tree", "delete the file", "write the file" |
| `&&` or `;` written into a rule | `{cli_separator}` |
| `npx prettier`, `tsc` | "the repo's format command" — see rule 8 |

Shell-specific syntax appears only in a **labelled pair** — one PowerShell form and one bash/zsh form, as the `.ps1` / `.sh` script pairs do — never as the unlabelled default.

### 17. SDA CLI Invocation Form — Raw Relative Path

Every resolved SDA script runs by its raw relative path (`.sda/scripts/qa/invoke-http.ps1`) — never with
an interpreter prefix (`bash`, `sh`, `zsh`), never `&`, never quotes or an absolute path.

`setup.sh` sets the executable bit and the shebang selects the interpreter, so the bare path is the
contract. The prefix is not a fallback — it works, but it hides a lost executable bit and makes approval
rules target the interpreter instead of the script.

**Exceptions — these keep the prefix:**

- frontmatter hooks, which run outside the agent terminal;
- installers, skill-folder scripts, and the `_twins.Tests.ps1` harness — they run from a location whose
  mode a separate installer or the harness sets (the sda-setup skill's invocation rules);
- third-party executables, whose file mode SDA does not control.

The **workflow state script** is the one skill-folder script an agent runs as ordinary work: it ships
in `sda-workflow-guide/scripts/`, so it is always invoked by its **absolute, quoted** path —
`& "<this-skill-folder>\scripts\workflow.ps1" current -slug <folder>` (PowerShell) or
`bash "<this-skill-folder>/scripts/workflow.sh" current --slug <folder>` (bash). The `&`/`bash` prefix
stays even when the path has no spaces, so the form never depends on the install location.

`Permission denied` (exit 126) → restore the bit (`chmod +x <path>`) — never adopt the prefix as the
standing form.

## Boundaries

- ✅ **Always do**: Propagate changes across connected agents, keep schemas consistent, update README.md.
- ⚠️ **Ask first**: Changing a file schema, adding/removing an agent, restructuring the delegation model, changing the approval gate sequence.
- 🚫 **Never do**: Change one branch without checking the other, modify subagent input contracts without updating the orchestrator, break the `dev-report.md` contract that the `dev` stage and its verification share, hard-code language-specific commands or framework names into agent or skill instructions.
