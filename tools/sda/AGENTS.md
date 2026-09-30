# AGENTS.md — tools/sda/

Rules for AI agents working on the SDA (Software Development Assistant) tool suite.

---

## Overview

SDA is a coordinated suite of AI agents that implement a Specification-Driven Development workflow. Agents are **tightly coupled by design** — they share file formats, workflow contracts, and behavioral rules. Changes to one agent frequently require synchronized changes to connected agents and shared resources.

A **workflow** is a numbered container (`.sda/workflows/<NNN>. <slug>/`) holding one requirement's entry artifact (`issue.md`), its artifacts — `user-story.md`, `design.md`, `tasks/`, one `dev-report.md` per task folder — plus script-written state that tracks their stage. Producers work workflow sessions by following the `sda-workflow-guide` skill, so their own files carry no workflow CLI or state logic. It is opt-in: standalone single-agent use is unchanged.

## Folder Structure

```
tools/sda/
├── README.md                          ← user-facing docs, pipeline diagram, setup guide
├── AGENTS.md                          ← this file
├── agents/
│   ├── sda-workflow.agent.md           ← advisor: container position, next action + owner, `init` / user-requested `escalate` (`advance` on request)
│   ├── sda-toolscan.agent.md           ← toolchain scanning and project-tools generation
│   └── sda-tool-installer.agent.md    ← subagent: installs required dev tools (delegated by sda-setup skill)
│   ├── sda-ba.agent.md                ← Business Analyst: raw requirement → ready User Story (one Actor + Gherkin)
│   ├── sda-design.agent.md            ← system + feature design
│   ├── sda-dev-task.agent.md              ← task specification design
│   ├── sda-qa-task.agent.md           ← qa-task.md authoring (coupled + standalone)
│   ├── sda-scribe.agent.md             ← subagent: universal scribe (task.md, qa-task.md, dev-report.md, decision + design docs, specs, manifest.md)
│   ├── sda-dev-task-verifier.agent.md      ← subagent: consistency + regression + contract compliance checks
│   ├── sda-code-explore.agent.md       ← subagent: fast read-only codebase exploration
│   ├── sda-web-explore.agent.md        ← subagent: web research for up-to-date API docs and library specs
│   ├── sda-dev.agent.md           ← TDD implementation orchestrator; owns the workflow's `dev` stage
│   ├── sda-test-writer.agent.md       ← subagent: writes tests (RED phase)
│   ├── sda-coder.agent.md             ← subagent: writes production code (GREEN phase)
│   ├── sda-refactor.agent.md          ← subagent: refactoring pass (REFACTOR phase)
│   ├── sda-dev-quality.agent.md       ← subagent: per-area quality gates (Phase 5); check-and-report only
│   ├── sda-docs-check.agent.md       ← subagent: verifies docs tree + decision docs + AI-readme routing against reality (full scope, or targeted on a `docs` unit's files); check-and-report only
│   ├── sda-qa.agent.md                 ← runtime acceptance QA (read-only on source; writes qa-report.md)
│   └── sda-diagram-writer.agent.md   ← subagent: renders Mermaid diagrams from DIAGRAM blocks → `.md` files with ```mermaid fenced blocks
├── prompts/
│   ├── sda.dev.task-verify.prompt.md       ← verify task spec consistency + regression analysis
│   ├── sda.qa.session-run.prompt.md       ← trigger sda-qa agent (QA verification for a task)
│   ├── sda.dev.task-implement.prompt.md   ← trigger sda-dev agent (implement a task via TDD)
│   ├── sda.qa.task-create.prompt.md       ← trigger sda-qa-task agent (create a QA task)
│   ├── sda.setup.prompt.md               ← setup SDA tool (with toolchain scan)
│   ├── sda.setup.no-scan.prompt.md       ← setup SDA tool (skip toolchain scan)
│   ├── sda.design.reconcile.prompt.md    ← trigger sda-design agent (reconcile design docs with code)
│   ├── sda.workflow.init.prompt.md        ← create one workflow container + its issue.md
│   ├── sda.workflow.status.prompt.md      ← where the containers sit + the single next action
│   ├── sda.workflow.advance.prompt.md     ← move one stage forward
│   ├── sda.workflow.escalate.prompt.md    ← send a workflow back a stage
│   ├── sda.workflow.story.issue.prompt.md ← story stage, from the container's issue.md (sda-ba)
│   ├── sda.workflow.design.issue.prompt.md ← design stage, from the container's issue.md (sda-design)
│   ├── sda.workflow.task.issue.prompt.md   ← tasks stage, from the container's issue.md (sda-dev-task)
│   └── sda.workflow.dev.issue.prompt.md    ← dev stage, from the container's issue.md (sda-dev)
└── skills/
    ├── sda-workflow-guide/            ← workflow-mode operating instructions for producers
    │   ├── SKILL.md
    │   └── assets/
    │       ├── stage-story.md
    │       ├── stage-design.md
    │       ├── stage-tasks.md
    │       └── stage-dev.md
    ├── sda-spec-guide/                 ← contract spec conventions for all planning agents
    │   └── SKILL.md
    └── sda-setup/                     ← project scaffolding skill
        ├── SKILL.md
        └── assets/
            ├── project-config.example.json
            ├── project-config.reference.yml   ← annotated config reference → .sda/
            ├── ba/                            ← user-story schema
            │   └── user-story-schema.md       ← user-story.md template + schema rules → .sda/resources/ba/
            ├── dev/                           ← dev workflow schemas + task-state scripts
            │   ├── task-schema.md             ← task.md template + schema rules → .sda/resources/dev/
            │   ├── dev-report-schema.md       ← dev-report.md template + schema rules → .sda/resources/dev/
            │   ├── bash/
            │   │   ├── task-state.sh          ← state.json management → .sda/scripts/dev/
            │   │   └── unit-file-size.sh      ← file line-count check (task + verify modes) → .sda/scripts/dev/
            │   └── powershell/
            │       ├── task-state.ps1         ← state.json management → .sda/scripts/dev/
            │       └── unit-file-size.ps1     ← file line-count check (task + verify modes) → .sda/scripts/dev/
            ├── qa/                            ← QA schemas, credentials, and scripts
            │   ├── qa-task-schema.md          ← qa-task.md template + schema rules → .sda/resources/qa/
            │   ├── qa.example.secrets.env     ← placeholder QA credentials → .sda/secrets/
            │   ├── bash/
            │   │   ├── load-qa-secrets.sh     ← loads QA credentials into current shell session; outputs var_name | is_empty table → .sda/scripts/qa/
            │   │   └── list-qa-secrets.sh     ← lists credential names + descriptions → .sda/scripts/qa/
            │   └── powershell/
            │       ├── load-qa-secrets.ps1    ← loads QA credentials into current session; outputs var_name | is_empty table → .sda/scripts/qa/
            │       └── list-qa-secrets.ps1    ← lists credential names + descriptions → .sda/scripts/qa/
            ├── toolscan/                      ← toolscan schema + scripts
            │   ├── project-tools-schema.md    ← project-tools.md template + content rules → .sda/resources/toolscan/
            │   ├── bash/
            │   │   ├── cleanup-project-tools.sh   ← rename project-tools.md to project-tools_backup.md before scan
            │   │   ├── get-timestamp.sh           ← output scan timestamp string
            │   │   └── probe-validators.sh        ← probe all format validators; output pipe-delimited table
            │   └── powershell/
            │       ├── cleanup-project-tools.ps1  ← rename project-tools.md to project-tools_backup.md before scan
            │       ├── get-timestamp.ps1          ← output scan timestamp string
            │       └── probe-validators.ps1       ← probe all format validators; output pipe-delimited table
            ├── docs/                           ← docs integrity script
            │   ├── bash/
            │   │   └── docs-integrity.sh       ← root + single-file check → .sda/scripts/docs/
            │   └── powershell/
            │       └── docs-integrity.ps1      ← root + single-file check → .sda/scripts/docs/
            ├── design/                       ← SDA-only design schema
            │   └── design-record-schema.md   ← design.md format + decision taxonomy → .sda/resources/design/
            ├── workflow/                     ← workflow schemas, state scripts + twin test
            │   ├── workflow-schema.md        ← workflow.json structure, brief folder → .sda/resources/workflow/
            │   ├── escalation-brief-schema.md ← escalation brief content → .sda/resources/workflow/
            │   ├── _twins.Tests.ps1          ← test: differential harness for the two state scripts (dev-only, not shipped)
            │   ├── bash/
            │   │   └── workflow.sh           ← workflow state management → .sda/scripts/workflow/
            │   └── powershell/
            │       └── workflow.ps1          ← workflow state management → .sda/scripts/workflow/
        ├── scripts/
        │   ├── bash/
        │   │   ├── setup.sh               ← scaffold .sda/ folder
        │   │   ├── write-config.sh        ← write project-config.json
        │   │   ├── read-config.sh             ← per-agent config hook script → .sda/scripts/
        │   │   └── read-project-tools.sh      ← area-aware command lookup by folder → .sda/scripts/
        │   └── powershell/
        │       ├── setup.ps1              ← scaffold .sda/ folder
        │       ├── write-config.ps1       ← write project-config.json
        │       ├── read-config.ps1            ← per-agent config hook script → .sda/scripts/
        │       └── read-project-tools.ps1     ← area-aware command lookup by folder → .sda/scripts/
        ├── tool-discovery/                ← language toolchain specs (shipped with the skill)
        └── tool-catalog/                  ← language tool install catalogs (shipped with the skill)
```

## Agent Dependency Map

### Orchestrated implementation

The TDD implementation phase is **orchestrated**: `sda-dev` reads `task.md`, then delegates RED to `sda-test-writer`, GREEN to `sda-coder`, and the REFACTOR pass to `sda-refactor` to keep each context small.

| Agent(s) | How it works |
|---|---|
| `sda-dev` → `sda-test-writer` + `sda-coder` + `sda-refactor` + `sda-dev-quality` | Orchestrator delegates RED to `sda-test-writer`, GREEN to `sda-coder`, REFACTOR to `sda-refactor`, and QUALITY to `sda-dev-quality`; it owns workflow decisions (slice processing, verification, state tracking) |

### Agent relationships

```
sda-setup skill ──▸ sda-toolscan                          project scaffolding + scanning
sda-setup skill ──▸ sda-tool-installer                    required tool installation (Step 7)

user ──▸ sda-ba                                          raw requirement → User Story (requirements front-end)
sda-ba ─delegates─▸ sda-code-explore / sda-web-explore  elicitation research only (never design)
sda-ba ─delegates─▸ sda-scribe                          requirements tree (Mode 6)
sda-ba ─produces──▸ user-story.md                       input for sda-design / sda-dev-task

sda-design ─delegates─▸ sda-diagram-writer            diagram generation (system mode)
sda-design ─delegates─▸ sda-scribe                    specs, decision + design docs, design record (Mode 7)
sda-design ─delegates─▸ sda-code-explore              layer discovery + structure
sda-design ─delegates─▸ sda-docs-check                docs structure + decision integrity + drift + readme routing
sda-design ────handoff──▸ sda-dev-task               design pipeline (feature → tasks); passes design.md path
sda-dev-task ─delegates─▸ sda-code-explore              task design pipeline (research)
sda-dev-task ─delegates─▸ sda-web-explore               task design pipeline (web/API research)
sda-dev-task ─delegates─▸ sda-scribe                     task design pipeline (Phase 6: task.md)
sda-dev-task ─delegates─▸ sda-dev-task-verifier              task design pipeline (Phase 7 + contract compliance)
sda-dev-task-verifier ─delegates─▸ sda-code-explore     file-gathering for structural + regression checks
sda-dev-task ────handoff──▸ sda-dev                  tasks → dev (the workflow's dev stage)

user ──▸ sda-qa-task                                      qa-task.md authoring (standalone / coupled)
sda-qa-task ─delegates─▸ sda-code-explore            standalone entry-point discovery
sda-qa-task ─delegates─▸ sda-scribe                  qa-task.md write (Mode 4: coupled or standalone)
user ──▸ sda-qa                                          runtime acceptance QA (task-coupled or standalone)

sda-dev ─delegates─▸ sda-test-writer             RED phase
sda-dev ─delegates─▸ sda-coder                   GREEN phase
sda-dev ─delegates─▸ sda-refactor                REFACTOR phase
sda-dev ─delegates─▸ sda-code-explore            ad-hoc mode: codebase exploration
sda-dev ─delegates─▸ sda-scribe                  dev-report.md (Mode 3) + `docs` unit files (Phase 3·D)
sda-dev ─delegates─▸ sda-docs-check             `docs` unit verification, targeted scope (Phase 3·D)
sda-dev ─delegates─▸ sda-dev-quality             per-area quality gates (Phase 5)
```

### Detailed dependency matrix

| When you change… | Also update… | Why |
|---|---|---|
| `user-story-schema.md` | `sda-ba` (authors per it), **sda-setup skill** (copies asset to `.sda/resources/ba/`) | BA authors the story against the schema; setup scaffolds it into consumer projects |
| `design-record-schema.md` | `sda-design` (provides the content), `sda-scribe` (writes `design.md` per it), **sda-setup skill** (copies asset to `.sda/resources/design/`) | The design record's sections, decision taxonomy, and altitude rules; setup scaffolds it into consumer projects |
| `paths.userStories` in `project-config.json` | `sda-ba` (default story output root), **sda-setup skill** (config example + read-config defaults) | Injected via session context; default `.sda/stories` |
| `sda-dev` RED/test-writing rules | `sda-test-writer` | `sda-test-writer` executes the RED phase the orchestrator delegates |
| `sda-dev` GREEN/implementation rules | `sda-coder` | `sda-coder` executes the GREEN phase the orchestrator delegates |
| `sda-dev` REFACTOR/refactoring rules | `sda-refactor` | `sda-refactor` executes both refactor scopes (per-unit 4·U, cross-unit 4·X) the orchestrator delegates; for `refactoring` units, also receives and applies Changes blocks as sweep 0 |
| `sda-dev` delegation format | `sda-test-writer`, `sda-coder`, and `sda-refactor` input contracts | Subagents parse the exact format the orchestrator sends |
| Approval gate structure or output templates | All of: `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Gate outputs must be consistent across the orchestrated flow |
| `read-project-tools.ps1` / `read-project-tools.sh` (area-matching logic) | `sda-dev`, `sda-dev-quality`, `sda-dev-task`, `sda-qa-task`, `sda-qa` (call it per area with command labels) | Changing area-matching logic, command labels, or output format → update both scripts and agent call sites |
| `task.md` schema (`task-schema.md`) | `sda-scribe`, `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Scribe produces the schema; implementation agents consume it |
| Integration-unit `Related tests` field (`task-schema.md`) | `sda-dev-task` (identifies runnable tests), `sda-scribe` (writes), `sda-dev` (passes as the test target or omits), `sda-coder` (runs them or skips) | Regression check for integration-only units; when absent, no tests run |
| `refactoring` unit type routing | `sda-dev` (routes to Phase 4·U directly, passes Changes blocks), `sda-refactor` (accepts Changes field, applies as sweep 0) | New unit type skips GREEN; sda-refactor handles both prescribed transformations and improvement sweeps |
| `Detected shell` (`project-tools.md`, Output Filter Command) | `sda-dev` (passes `Shell:` in every delegation), `sda-coder`, `sda-refactor`, `sda-test-writer` (run commands in that shell; never translate idioms) | Prevents shell-mismatch errors (e.g. `tail` vs `Select-Object`) |
| Command-invocation form (runner/script vs bare binary) | `sda-dev`, `sda-dev-quality` (run `{read-project-tools}` output as-is — never a troubleshooting entry), `sda-test-writer`, `sda-coder`, `sda-refactor` (run the passed command as-is) | A returned or passed invocation is never rewritten into a direct binary or entry-point call; a bare binary is valid only when it is the returned command, or when a troubleshooting entry prescribes it for an unfiltered command with a confirmed non-zero exit code |
| Empty-output verdict (silent success) | `sda-dev`, `sda-dev-quality`, `sda-coder`, `sda-test-writer`, `sda-refactor` (every agent that runs or judges a command), `skills/troubleshooting` (precondition gate) | Exit code `0` with no output is a pass. A filtered **findings** gate (lint, coverage, pre-merge, build) with empty output is also a pass — a clean run has nothing to report; a filtered **test** gate with empty output is ❌ unable to verify, reported without a re-run (the subagents report the same case as their hard-stop `⚠️ UNRESOLVED`, also without a re-run) |
| `standardsSkill` (`project-config.json`) | `sda-dev` (from session context, passes `Standards skill:` in every delegation), `sda-coder`, `sda-refactor`, `sda-test-writer` (load the named skill), `sda-dev-task` (loads it for task.md code examples), **sda-setup skill** (scaffolds default) | Configurable coding-standards skill; default `standards-compliance` (the literal name lives only in `project-config.json` + docs, never in `.agent.md` files) |
| `qa-task.md` schema (`qa-task-schema.md`) | `sda-qa-task` (designs FRs — coupled or standalone), `sda-scribe` (writes — Mode 4), `sda-qa` (reads — sole input) | sda-qa-task designs the QA spec; scribe writes it; sda-qa verifies against it black-box. Standalone specs live under `paths.issues` |
| `dev-report.md` schema (`dev-report-schema.md`) | `sda-dev` (provides facts), `sda-scribe` (writes), `workflow.ps1` / `workflow.sh` (the file's presence in **every** task folder is the `dev` stage's artifact) | Orchestrator reports what was built; scribe formats it. The workflow layer never reads its content — only whether each task folder has one |
| `sda-scribe` update-mode input (anchored deltas) | `sda-dev-task` (Mode 2 delegation for task.md add/change/remove) | Scribe matches caller-supplied anchors with the host's built-in file tools and refuses a change described without one — `sda-dev-task` must pass `anchor` + `content` |
| File-write mechanism (built-in tools only — no CLI or script) | `sda-scribe` (states the rule), `sda-toolscan` (states a host-specific `create_file`), `sda-ba` (writes `user-story.md`), `sda-qa` (writes `qa-report.md` + `evidence/`), `sda-workflow` (writes `issue.md`), `sda-diagram-writer` (file writer — rule not stated) | Every agent that writes files edits through the host's built-in tools so changes stay reviewable; a CLI or script write bypasses change tracking |
| `project-tools.md` schema (`project-tools-schema.md`) | `sda-toolscan` (writes output), `sda-dev` (fetches command labels via read-project-tools script) | Labels are machine-readable keys — renaming breaks script lookups |
| Filtered commands (`filter-test-output`, `filter-last-n`, `filter-tool`) | `sda-dev`, `sda-dev-quality`, `sda-coder`, `sda-test-writer`, `sda-refactor` (pass/fail from the returned output — never an empty or unclassifiable result) | A filter pipe replaces the runner's exit status on every shell — `{stderr-redirect}` is emitted for both, so runner stderr reaches the filter; the shell's rendering of that merged stderr is never a failure marker |
| Two-pass test runs (`filter-last-n` first pass → `filter-test-output` failure detail) | `sda-dev` (baseline + every delegation), `sda-test-writer` (RED starts at the failure-detail command), `sda-coder`, `sda-refactor`, `sda-dev-quality` (its own two-pass gate wording), and the delegated `Test command` / `Test command (failure detail)` field pair | Subagents run complete commands and never compose filters — the verdict pass and the diagnostic pass both arrive in the delegation |
| Format commands (`format-code-all`, `format-code-path`) | the tool-catalog `Hook command` (supplies the in-place form and its silence flag), `sda-toolscan` (emits both), `sda-dev` (delegates), `sda-coder`, `sda-refactor`, `sda-test-writer` (run them as passed) | A Format command is the formatter's in-place invocation — never a read-only check variant — and emits no verdict line: its exit status is the verdict, so it never carries a filter tail. `sda-dev-quality` runs none — it is check-and-report only |
| `test-all-coverage` label (in `project-tools.md`) | `project-tools-schema.md` (template + content rule), `sda-toolscan` (generation rules), the four language discovery specs (invocation), `read-project-tools.ps1` / `.sh` (area command list), `sda-dev-quality` (G6) | The whole-area coverage gate — no path argument and inherits project config unchanged, so the scoped override flags never apply to it |
| Language-specific command knowledge (runner prefix, file-targeting flags, application-run entry points, watch/emit flags) | `tool-discovery/{language}/tool-discovery.md` (owns it), `tool-catalog/{language}/tool-catalog.md` (per-tool `Hook command` / `Check command` / `Category` rows), `sda-toolscan` (reads both; states no language facts of its own), **sda-setup skill** (copies both assets) | Rules 8 and 16: the agent carries procedure only. Adding a language is a new asset pair — never an edit to the agent's rules |
| `qa-report.md` format (in `sda-qa`) | `sda-qa` (writes and presents the report directly) | sda-qa posts the report link; no agent parses or acts on its findings |
| Application-run commands (in `project-tools.md`) | `sda-toolscan` (discovers + writes `### Application Run` inside each area block), `sda-qa` (reads to start the app) | sda-qa starts each layer from these long-running commands |
| `paths.issues` in `project-config.json` | `sda-qa-task` (designs standalone `qa-task.md`), `sda-scribe` (Mode 4 numbers + writes there), `sda-qa` (reads standalone specs, writes `qa-report.md` beside them) | Shared root for standalone QA work (no task); default `.sda/issues`. Spec + report co-locate in one `<NNN>-<slug>/` folder |
| `paths.secrets` in `project-config.json` | **sda-setup skill** (scaffolds git-ignored folder + writes `.gitignore`) | No agent resolves this field at runtime — credentials are loaded via `scripts.loadQaSecrets`; default `.sda/secrets` |
| `scripts.qaSessionInit` / `scripts.invokeHttp` in `project-config.json` | `sda-qa` (from session context), **sda-setup skill** (scaffolds scripts) | sda-qa uses session-init path (fallback: `scripts.loadQaSecrets`) and HTTP helper path; defaults `.sda/scripts/qa/qa-session-init.ps1` and `.sda/scripts/qa/invoke-http.ps1` |
| Step 7 required-tools table (in **sda-setup skill**) | `sda-tool-installer` | Installer receives the missing-category list and runs the install commands |
| `sda-scribe` Mode 4 (QA spec) destination/numbering | `sda-qa-task` (delegates it — coupled or standalone), `sda-qa` (discovers standalone specs in `paths.issues`) | Producer and consumer must agree on the coupled (beside `task.md`) and standalone (`{issues-root}/<NNN>-<slug>/`) layouts |
| `state.json` schema (in `task-schema.md`) | `sda-dev-task` (creates via script), `sda-dev` | Task agent initializes it; the orchestrator updates via `task-state` script |
| `sda-dev-task` Phase 6 delegation format | `sda-scribe` input contract | Scribe parses the exact context sda-dev-task sends |
| `sda-qa-task` FR / read-list rules | `qa-task-schema.md` (authoritative FR rules), `sda-qa` (verifies the resulting FRs) | Designer applies the schema's black-box FR rules; sda-qa executes them |
| `sda-qa-task` delegation format (Mode 4) | `sda-scribe` Mode 4 input contract | Scribe parses the exact QA Task fields sda-qa-task sends — precondition, reproduce, Settle, Expected data, expected outcome, compare, layers, Setup, Credentials |
| `sda-dev-task-verifier` output format | `sda-dev-task` (processes results), `sda.dev.task-verify` prompt | Both depend on the report structure |
| `sda-dev-task-verifier` delegation to `sda-code-explore` | `sda-code-explore` input contract | Verifier sends file lists for structural + regression fact-gathering; explorer returns raw findings |
| Consistency/regression check rules | `sda-dev-task-verifier` | All verification logic lives in the verifier |
| Contract spec conventions | `sda-spec-guide` skill (owns the model, storage, metadata, and content rules), `sda-design` / `sda-dev-task` / `sda-dev-task-verifier` / `sda-docs-check` / `sda-qa-task` (load it), `sda-scribe` (writes spec files + manifest rows), **install-dev-suite** (installs it), rule 6 below (the cross-agent ownership map) | Spec conventions have one home each — artifact facts in the skill, who may write what in rule 6 |
| App readme outline (`AGENTS.md`) | `sda-design` (owns content), `sda-scribe` (Mode 6 writes), `sda-dev-task` (reads the AI readme for task scope), `sda-dev` (routes `docs` units that touch it), `sda-docs-check` (verifies routing against reality) | Readmes are the routing map — the format comes from the `{docsSkill}` skill's readme outline; thin, no implementation detail; reference entries carry triggers; features listed in the features section |
| Doc tree & per-layer readmes | `sda-design` (owns placement), `sda-scribe` (Mode 6 writes), `sda-dev` (routes `docs` units), `sda-docs-check` (verifies) | The tree layout comes from the `{docsSkill}` skill's doc tree — every layer gets AI readme + human README + a docs set; every docs folder gets an `index.md` |
| Design topic files (`architecture.md`, `vocabulary.md`) | `sda-design` (dictates content), `sda-scribe` (Mode 6 writes) | Formats come from the `{docsSkill}` skill's architecture + vocabulary file rules |
| `paths.specs` in `project-config.json` | `sda-design` (writes specs, reads manifest for affected specs), `sda-dev-task` (reads specs during contract trace), `sda-scribe` (writes spec files), `sda-dev-task-verifier` (reads specs for verification), `sda-docs-check` (resolves a spec path when verifying a spec) | All planning agents receive this from session context; default `.sda/specs` |
| `workflow-schema.md` (workflow container + `workflow.json` shape) | `{workflow}` script (implements it — and verifies every container against it before reading state), `sda-ba` / `sda-design` / `sda-dev-task` / `sda-dev` (read state via the `sda-workflow-guide` skill), `sda-scribe` (Mode 8 — records the brief in the workflow's `escalations/` folder), **sda-setup skill** (copies the asset to `.sda/resources/workflow/`) | Folder naming, stage order, the `start` stage (skipped prefix), `notes[]` entry types, and the escalation brief's folder + `brief` field are the contract — a shape change breaks every reader of `list` / `read`, the scribe's Step 10, and every brief already on disk |
| `escalation-brief-schema.md` (the escalation brief's content) | `sda-scribe` (Mode 8 writes it per the schema — **Step 10 owns its file name and numbering**), `sda-design` / `sda-dev-task` / `sda-dev` (draft that content before the raise), `sda-ba` (reads it when resolving), **sda-setup skill** (copies the asset) | A document schema, not state — the script never reads the brief. Its sections change what every future escalation must carry, so it moves independently of the container's rules |
| `workflow.ps1` + `workflow.sh` (the state-script twins) | `_twins.Tests.ps1` (test: differential harness — one scenario sequence against both, comparing output, exit codes, and the written `workflow.json`), `sda-workflow` (runs the twins; never writes state), `sda-workflow-guide` (documents the producer-facing subset: `current`/`read`/`advance`/`escalate`/`resolve`) | One contract, two implementations: every command, refusal, and exit code must exist in **both**, and the harness must stay green. It is a **test, not an asset** — `_<subject>.Tests.ps1`, pruned by `install-skill.*` and never copied into `.sda/` |
| Stage list + each stage's artifact (the machine itself) | Both twins (`workflow.ps1` / `workflow.sh`), `_twins.Tests.ps1` (a scenario per stage and gate), `workflow-schema.md` (documents it), `sda-workflow` (pipeline diagram, escalate reach, `gap=` / `missing=` reporting), the `sda-workflow-guide` skill (one stage card per producer, encoding its gate) | One stage machine across the twins, the schema, the advisor, and the skill's stage cards. `dev`'s artifact is per task folder, so its gate covers the whole `tasks/` tree rather than one file |
| `paths.workflows` + `scripts.workflow` in `project-config.json` | `sda-ba`, `sda-design`, `sda-dev-task`, `sda-dev` (receive the keys; the `sda-workflow-guide` skill consumes them in workflow sessions), **sda-setup skill** (config example + read-config defaults) | Injected via session context; `paths.workflows` defaults to `.sda/workflows`. Presence does **not** imply a workflow exists — see the `{workflow}` script boundary row for who may run what |
| `manifest.md` format | `sda-design` (adds specs, reads for affected specs), `sda-dev-task` (reads for spec discovery), `sda-scribe` (writes/updates rows), `sda-dev-task-verifier` (reads for verification) | Entry point for spec discovery; scribe maintains it |
| `sda-design` diagram delegation format (`DIAGRAM` block) | `sda-diagram-writer` input contract | Subagent parses the exact DIAGRAM block format the orchestrator sends |
| Shared constraint blocks (`Two-pass test runs`, `Filtered command verdict`, `File reading strategy`, `Terminal working directory`; plus `Commands are immutable`, `Type check`, `Validate data`, `Format code` in the coder + refactor pair) | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Each block is duplicated verbatim in every file that carries it — editing one copy means editing every other copy |
| A new `execute`-carrying agent, or a change to an agent's script allowlist | that agent's own terminal-scope bound (rule 15) — a `Terminal command scope` section or a bullet inside an existing constraint block — and `README.md`'s agent table when the tool list itself changes | An undeclared or unbounded runnable set lets the agent run arbitrary build/test commands; a bound that also forbids reading, listing, or searching blocks the only route into hidden folders |
| `{workflow}` script boundary (read-only `list`/`current`/`read` + `escalate`/`resolve`/`advance`; `init` orchestrator-only) | `sda-workflow` (advisor — owns `init`, raises a user-requested escalation from any stage with an upstream, never `resolve`), `sda-workflow-guide` (the skill producers follow — encodes the producer-facing subset and stage cards), `sda-ba` / `sda-design` / `sda-dev-task` / `sda-dev` (raise, advance their own stage, or resolve per the skill), `sda-scribe` (Mode 8 writes the brief a raise requires), human (confirms every transition) | Producers never **structure** a workflow — `init` stays orchestrator-only and the script stays the sole writer of `workflow.json`. A producer advances its own stage, raises an escalation, or closes one only on the user's direct confirmation. In workflow mode a producer follows the skill, which first runs `current` and refuses to act when `stage=` is not its own. The advisor **names** producers and never invokes them. While an escalation is open, `advance` is refused; `escalate` is refused without an existing brief in the workflow's `escalations/` folder, so the evidence is written before the raise and the raise aborts if it is not. A standalone session never invokes the script |
| `sda-workflow-guide` skill (workflow-mode operating instructions for producers) | `sda-ba` / `sda-design` / `sda-dev-task` / `sda-dev` (follow it in workflow sessions), `sda-workflow` (names it when handing to a producer), the stage-entry prompts (point at it), **install-dev-suite** (installs it) | The workflow CLI table, the stage gate, and the advance/escalate/resolve steps live here — not in the producer files. A producer's own file keeps only the one dispatch line plus escalation-evidence authoring |
| `sda-workflow` agent + the `/sda.workflow.{init,status,advance,escalate}` prompts (orchestrator surface) | `sda-scribe` (Mode 8 writes the brief a raise requires), `{workflow}` script, the start stage's owner — `sda-ba` / `sda-design` / `sda-dev-task` — (started by the human on the new container from its `issue.md`), `sda-ba` / `sda-design` / `sda-dev-task` (name `sda-workflow` when offering to create a container) | The prompts carry intent only and set `agent: "sda-workflow"`, so the agent's own instructions plus its hook-injected `{workflow}` do the work — a prompt must **omit `tools:`**, which would otherwise run it in the default agent. The advisor never invokes a producer and never runs `resolve` |
| `issue.md` (container entry artifact) | `sda-workflow` (writes it at `init` — the only file it writes), `sda-ba` / `sda-design` / `sda-dev-task` / `sda-dev` (handed it by their stage-entry prompt), `workflow-schema.md` (container template lists it) | The stage owners' conversation starter: container name + the three artifact paths + the issue in the user's words — an outline, not a requirements spec, and no design or implementation detail. **Not state** — the script never creates, reads, or checks it, so it is never a `gap=` and never blocks `advance`; absent on containers that predate it |
| Stage-entry prompts (`/sda.workflow.story.issue`, `/sda.workflow.design.issue`, `/sda.workflow.task.issue`, `/sda.workflow.dev.issue`) | `sda-ba` / `sda-design` / `sda-dev-task` / `sda-dev` (the `agent:` each one sets), `sda-workflow-guide` (the skill each prompt points the owner to), `sda-workflow` (names the start stage's prompt at `init`), `issue.md` (the artifact they hand the owner) | Each carries intent only and sets `agent:` to the stage's owner — a prompt must **omit `tools:`**. Each also declares workflow mode and points the owner at the `sda-workflow-guide` skill. Unlike the advisor prompts these target producers, not `sda-workflow` |
| Question mechanics (`[ASK]` = short gates; elicitation = chat text with context + pros/cons) | `sda-dev-task`, `sda-dev`, `sda-qa-task`, `sda-toolscan`, `sda-ba`, `sda-design` | Shared interaction convention — changing the split in one agent must not diverge from the others. Escalation handling is a shared case of it: both ends discuss it with the user and act only on direct approval, and an escalation never transfers a decision the target stage's ownership rules reserve |
| Standards compliance rules | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | All code-producing agents enforce standards |
| Unexpected-failure / troubleshooting handling | `sda-dev`, `sda-dev-quality` (never loads troubleshooting guidance) | Troubleshooting is a workflow decision — subagents stop and report; the orchestrator diagnoses and recovers |
| Coding standards skill references | `sda-dev` | References coding standards for output |
| Quality check gates (Phase 5) | `sda-dev-quality` | Phase 5 is a thin delegation in **global** mode; the quality agent owns gate execution, reporting, and flagging, and serves standalone **local** (target files) or **global** (whole areas) requests |
| `sda-dev-quality` report format | `sda-dev` (Phase 5 result relay) | Orchestrator relays the quality report verbatim as the Phase 5 result |
| `sda-dev` Flags processing (Phase 5) | `sda-coder`, `sda-test-writer` | Orchestrator routes quality flags to the correct subagent for fixes |
| `task.md` Area field + Area Index in `project-tools.md` | `sda-dev-task` (derives area per unit), `sda-scribe` (writes), `sda-dev` (reads per-unit areas), `sda-dev-quality` (discovers areas) | Area connects task design → implementation → quality gates |
| Init output format (`project-tools.md`) | `sda-toolscan`, `sda-dev`, **sda-setup skill** | The orchestrator, the toolscan agent, and the setup skill depend on project-tools output |
| `models` in `project-config.json` | `sda-setup` skill (asks user, normalizes, resolves, applies to agent frontmatter), `tools/sda/README.md` (the default map) | sda-setup resolves family names to versioned models and writes `model:` into every agent in `agents/` — all 19 carry the line, `sda-workflow` included. The agent list is never enumerated here: it is whatever `agents/` holds |
| `unit-file-size` script (parameters or output format) | `sda-dev-task` (Phase 6 Step 1), `sda-dev-task-verifier` (Check 1) | Both agents invoke the script; interface changes break invocations |
| Decision docs (`<layer>/docs/decisions/`) | No config field — derived per layer from the repo layout. `sda-design` (records + structures via sda-scribe Mode 5), `sda-scribe` (Mode 5 writes), `sda-docs-check` (verifies) | Decision docs live per layer under `<layer>/docs/decisions/` — feature-grouped (`shared/`, `<feature>/`) with descriptively-named files; one decision per file, routed by the feature's `index.md` |
| Requirements tree (`requirements/<feature>/[<concern>/]<item>.md`) | No config field — resolved from the repo's AI readmes. `sda-ba` (owns content + FR/NFR ids), `sda-scribe` (Mode 6 writes), `sda-design` (reads for design scope), `sda-docs-check` (structure + NFR shape, via `docs-integrity -Root`), `{docsSkill}` skill (schema) | Durable inventory of what is *specified* — no status field, no delivery link; an `index.md` at every level, max depth three, ids append-only |
| `repo-ai-friendly` skill (design + decision + requirements schemas) | `sda-design` (loads for structure), `sda-scribe` (Mode 5/6 loads for formats), `sda-ba` (loads for the requirements structure + IDs), `sda-docs-check` (loads for verification), **install-dev-suite** (installs it), `read-config` (resolves `docsSkill`) | All consumers load it by name via `docsSkill`; the skill owns the doc tree + schema formats; sda-setup no longer copies them |
| `sda-docs-check` input (scope + expected structure) | `sda-design` (passes `full` + the repo's structure when its AI readme declares one, else default), `sda-dev` (passes `targeted` + the written file list) | Caller decides what to verify against; otherwise the repo's AI readme if it declares one, else the `{docsSkill}` skill's canonical tree |
| `sda-docs-check` report findings | `sda-dev` (Phase 3·D: presents them and asks the user) | Findings are a report, not a failure — routing them to troubleshooting guidance misreads the verifier's output |
| `docs` unit type (`task-schema.md`) | `sda-dev-task` (designs it — one per task, last), `sda-dev-task-verifier` (validates it), `sda-dev` (routes to Phase 3·D; skips refactor + quality for it), `sda-scribe` (Mode 6 writes the files), `sda-docs-check` (targeted verification) | The only sanctioned path for mechanical doc changes made during implementation — including an anchored delta to an existing spec and its `manifest.md` row. It never creates a spec (`sda-design`'s deliverable); semantic doc changes escalate to `sda-design`, semantic requirements changes to `sda-ba` |
| `sda-scribe` Mode 6 content shape (`content` vs `changes`) | `sda-design`, `sda-dev`, `sda-ba` (all callers) | Callers must pass the shape the scribe parses; anchored deltas update an existing file, full content creates or rewrites one |
| `design.md` renewal (Mode 7) | `sda-design` (reads it at session start), `sda-scribe` (writes it), `sda-dev-task` (reads it as handoff context) | The record is renewed in place — a second file or an appended session log breaks the two-placement model |
| `scripts.docsIntegrity` in `project-config.json` | `sda-docs-check` (runs it) | Docs-integrity script. `-Root` takes a decisions/requirements tree (links, orphans, duplicates, one-way `.sda/` rule); `-File` takes one document (links, code fence, non-`.md` path) |
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

File schemas (`task.md`, `qa-task.md`, `dev-report.md`, `state.json`, `project-tools.md`, `project-config.json`) are contracts between agents. When changing a schema:

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

`sda-dev`, `sda-test-writer`, `sda-coder`, and `sda-refactor` repeat the same constraint blocks. When editing one copy, copy the change to every other copy.

| Block | Files that carry it |
|---|---|
| `Two-pass test runs`, `Filtered command verdict`, `File reading strategy`, `Terminal working directory` | `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` |
| `Commands are immutable`, `Type check`, `Validate data`, `Format code` | `sda-coder`, `sda-refactor` |
| `CLI invocation form` (rule 17) | `sda-dev`, `sda-dev-quality`, `sda-dev-task`, `sda-dev-task-verifier`, `sda-docs-check`, `sda-qa`, `sda-qa-task`, `sda-toolscan`, `sda-workflow`, `sda-workflow-guide` skill |

### 5. Keep README.md in Sync

The `README.md` in this folder documents the agent pipeline, setup steps, workflow phases, and configuration paths. When any of these change in the agent files, update `README.md` to match.

### 6. Contract Spec Ownership

One spec file, one creator — the design stage. `sda-design` ends every session
with a spec for every boundary the feature crosses: designed, or extracted
from code that already exists. `sda-dev-task` requires them to exist already,
stops when one is missing, and may record its own delta into one that exists.

| Agent | May | Must not |
|---|---|---|
| `sda-design` | create any spec, via `sda-scribe` (Mode 6) | — |
| `sda-dev-task` | read specs; record an anchored delta into an existing spec via a `docs` unit; stop when a crossed boundary has none | create, delete, replace, or defer a spec |
| `sda-dev` | — | author spec content |
| `sda-scribe` | write the spec file and its manifest row | decide content |
| `sda-dev-task-verifier` | read specs; report mismatches | edit a spec |
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
| `npm test`, `pytest`, `mvn verify` | The command from `project-tools.md` |
| `*.ts`, `*.py`, `*.java` | File patterns resolved from project config |
| "Jest", "Vitest", "JUnit" | "the project's test runner" |

Language-specific behavior is resolved at runtime through:
- `project-tools.md` — executable commands discovered by `sda-toolscan`.
- `project-config.json` — project metadata and paths.
- Tool-discovery specs (`.sda/resources/{language}/tool-discovery.md`) — copied at setup time, read by `sda-toolscan`.

Agent instructions describe **what** to do; runtime artifacts supply the **how**.

### 9. `.sda` Dependencies Section Required

Every agent or skill that reads or writes files in `.sda/` must include a `.sda dependencies` section with:

- **Heading level:** `###` when nested under a parent constraints section (e.g. `## HARD CONSTRAINTS`), `##` otherwise.
- **Standard preamble:** `".sda/ is a dot-prefixed folder that may be hidden from search tools. Access all files below by exact path from the repo root — never search for them."`
- **Dependency table:** `| File | Path |` listing every `.sda/` file the agent reads or writes, with the exact relative path from the repo root.

### 10. Delegation — Always Pass Full `.sda/` Paths

When delegating to a subagent, pass every `.sda/` file reference with its full path (e.g., `.sda/project-tools.md`, not `project-tools.md`). Subagents must never search for `.sda/` files — if a path is ambiguous, ask the caller.

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

`workflow.json` and `state.json` are written by their scripts only. Never hand-edit them, and never let an agent write them directly. A rejected transition is an error to report and escalate — not a state file to patch.

### 14. Doc Locations Come From the AI Readmes

Doc trees (decisions, requirements) and readmes are located by reading the repo's own AI readmes — never from a hardcoded canonical layout and never from `project-config.json`. Repos differ: use the structure the repo has, create only the nodes it needs, and do not assume the `{docsSkill}` default tree is fully present.

### 15. Terminal Use — No File Changes Through the Shell

**Never create, edit, move, or delete a file with a terminal command** — no output redirection, no in-place edit, no rename, no delete, no VCS mutation. Every change goes through the host's built-in edit tools: a CLI-written file is invisible in the session until `git diff`. See the `File-write mechanism` matrix row.

**Never run a build, test, or project command that the agent's own file does not name.** Name them in a terminal-scope bound — a `Terminal command scope` section (placed with the constraint sections, before the first workflow or phase section) or a bullet inside an existing constraint block.

**Never write a rule restricting terminal reading, listing, or searching** — it is the only route into hidden or git-ignored folders such as `.sda/`.

### 16. CLI Instructions Are Shell-Agnostic

Never name a shell-specific command, flag, or syntax in a rule. State the intent, or name the placeholder the session resolves (`{shell}`, `{cli_separator}`, `{task-state}`, …).

| Never | Instead |
|---|---|
| `grep -r`, `Get-ChildItem`, `Select-String`, `rm -rf`, `Set-Content` | "search the tree", "delete the file", "write the file" |
| `&&` or `;` written into a rule | `{cli_separator}` |
| `npx prettier`, `tsc` | the resolved command from `{read-project-tools}` — see rule 8 |

Shell-specific syntax appears only in a **labelled pair** — one PowerShell form and one bash/zsh form, as the `.ps1` / `.sh` script pairs do — never as the unlabelled default.

### 17. SDA CLI Invocation Form — Raw Relative Path

Every resolved SDA script runs by its raw relative path (`{unit-file-size} -Mode verify …`) — never with
an interpreter prefix (`bash`, `sh`, `zsh`), never `&`, never quotes or an absolute path.

`setup.sh` sets the executable bit and the shebang selects the interpreter, so the bare path is the
contract. The prefix is not a fallback — it works, but it hides a lost executable bit and makes approval
rules target the interpreter instead of the script.

**Exceptions — these keep the `bash` prefix:**

- frontmatter hooks, which run outside the agent terminal;
- installers, skill-folder scripts, and the `_twins.Tests.ps1` harness — they run from a location whose
  mode a separate installer or the harness sets (the sda-setup skill's invocation rules);
- third-party commands recorded in `project-tools.md`, whose file mode SDA does not control.

`Permission denied` (exit 126) → restore the bit (`chmod +x <path>`) — never adopt the prefix as the
standing form.

## Boundaries

- ✅ **Always do**: Propagate changes across connected agents, keep schemas consistent, update README.md.
- ⚠️ **Ask first**: Changing a file schema, adding/removing an agent, restructuring the delegation model, changing the approval gate sequence.
- 🚫 **Never do**: Change one branch without checking the other, modify subagent input contracts without updating the orchestrator, break the `task.md`/`state.json` contract that `sda-dev-task` and implementation agents share, hard-code language-specific commands or framework names into agent or skill instructions.
