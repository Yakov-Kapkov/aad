# AGENTS.md — tools/sda/

Rules for AI agents working on the SDA (Software Development Assistant) tool suite.

---

## Overview

SDA is a coordinated suite of AI agents that implement a Specification-Driven Development workflow. Agents are **tightly coupled by design** — they share file formats, workflow contracts, and behavioral rules. Changes to one agent frequently require synchronized changes to connected agents and shared resources.

## Folder Structure

```
tools/sda/
├── README.md                          ← user-facing docs, pipeline diagram, setup guide
├── AGENTS.md                          ← this file
├── agents/
│   ├── sda-toolscan.agent.md           ← toolchain scanning and project-tools generation
│   └── sda-tool-installer.agent.md    ← subagent: installs required dev tools (delegated by sda-setup skill)
│   ├── sda-system.agent.md            ← system architecture design
│   ├── sda-feature.agent.md           ← feature-level design
│   ├── sda-dev-task.agent.md              ← task specification design
│   ├── sda-qa-task.agent.md           ← qa-task.md authoring (coupled + standalone)
│   ├── sda-scribe.agent.md             ← subagent: universal scribe (task.md, qa-task.md, dev-report.md, specs, manifest.md)
│   ├── sda-dev-task-verifier.agent.md      ← subagent: consistency + regression + contract compliance checks
│   ├── sda-code-explore.agent.md       ← subagent: fast read-only codebase exploration
│   ├── sda-web-explore.agent.md        ← subagent: web research for up-to-date API docs and library specs
│   ├── sda-dev.agent.md           ← TDD implementation orchestrator
│   ├── sda-test-writer.agent.md       ← subagent: writes tests (RED phase)
│   ├── sda-coder.agent.md             ← subagent: writes production code (GREEN phase)
│   ├── sda-refactor.agent.md          ← subagent: refactoring pass (REFACTOR phase)
│   ├── sda-dev-quality.agent.md       ← subagent: per-area quality gates (Phase 5); check-and-report only
│   ├── sda-qa.agent.md                 ← runtime acceptance QA (read-only on source; writes qa-report.md)
│   └── sda-diagram-writer.agent.md   ← subagent: renders ASCII diagrams from DIAGRAM blocks
├── prompts/
│   ├── sda.dev.task-verify.prompt.md       ← verify task spec consistency + regression analysis
│   ├── sda.dev.feature-verify.prompt.md   ← verify feature spec consistency + regression analysis
│   ├── sda.qa.session-run.prompt.md       ← trigger sda-qa agent (QA verification for a task)
│   ├── sda.dev.task-implement.prompt.md   ← trigger sda-dev agent (implement a task via TDD)
│   ├── sda.qa.task-create.prompt.md       ← trigger sda-qa-task agent (create a QA task)
│   ├── sda.setup.prompt.md               ← setup SDA tool (with toolchain scan)
│   └── sda.setup.no-scan.prompt.md       ← setup SDA tool (skip toolchain scan)
└── skills/
    └── sda-setup/                     ← project scaffolding skill
        ├── SKILL.md
        └── assets/
            ├── project-config.example.json
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
        ├── tool-discovery/                ← populated by install script from resources/
        └── tool-catalog/                  ← populated by install script from resources/
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
sda-system ──handoff──▸ sda-feature                  design pipeline
sda-system ─delegates─▸ sda-diagram-writer            diagram generation
sda-system ─delegates─▸ sda-scribe                    canonical spec files (§ 7)
sda-feature ─handoff──▸ sda-dev-task                     design pipeline
sda-dev-task ─delegates─▸ sda-code-explore              task design pipeline (research)
sda-dev-task ─delegates─▸ sda-web-explore               task design pipeline (web/API research)
sda-dev-task ─delegates─▸ sda-scribe                     task design pipeline (Phase 6: task.md + specs)
sda-dev-task ─delegates─▸ sda-dev-task-verifier              task design pipeline (Phase 7 + contract compliance)
sda-dev-task-verifier ─delegates─▸ sda-code-explore     file-gathering for structural + regression checks
sda-dev-task ────handoff──▸ sda-dev                  design → implementation

user ──▸ sda-qa-task                                      qa-task.md authoring (standalone / coupled)
sda-qa-task ─delegates─▸ sda-code-explore            standalone entry-point discovery
sda-qa-task ─delegates─▸ sda-scribe                  qa-task.md write (Mode 4: coupled or standalone)

sda-dev ─delegates─▸ sda-test-writer             RED phase
sda-dev ─delegates─▸ sda-coder                   GREEN phase
sda-dev ─delegates─▸ sda-refactor                REFACTOR phase
sda-dev ─delegates─▸ sda-code-explore            ad-hoc provider: codebase exploration
sda-dev ─delegates─▸ sda-scribe                  dev-report.md (Mode 3, at completion)
sda-dev ─delegates─▸ sda-dev-quality             per-area quality gates (Phase 5)
sda-dev ─delegates─▸ sda-qa                      runtime acceptance QA (task provider)
```

### Detailed dependency matrix

| When you change… | Also update… | Why |
|---|---|---|
| `sda-dev` RED/test-writing rules | `sda-test-writer` | `sda-test-writer` executes the RED phase the orchestrator delegates |
| `sda-dev` GREEN/implementation rules | `sda-coder` | `sda-coder` executes the GREEN phase the orchestrator delegates |
| `sda-dev` REFACTOR/refactoring rules | `sda-refactor` | `sda-refactor` executes both refactor scopes (per-unit 4·U, cross-unit 4·X) the orchestrator delegates |
| `sda-dev` delegation format | `sda-test-writer`, `sda-coder`, and `sda-refactor` input contracts | Subagents parse the exact format the orchestrator sends |
| Approval gate structure or output templates | All of: `sda-dev`, `sda-test-writer`, `sda-coder`, `sda-refactor` | Gate outputs must be consistent across the orchestrated flow |
| `read-project-tools.ps1` / `read-project-tools.sh` (area-matching logic) | `sda-dev` (calls it per unit for test/typecheck/format/filter-tool/filter-test-output/validate commands) | Changing area-matching logic, command labels, or output format → update both scripts and sda-dev's command-construction sections |
| `task.md` schema (`task-schema.md`) | `sda-scribe`, `sda-dev`, `sda-test-writer`, `sda-coder` | Scribe produces the schema; implementation agents consume it |
| Integration-unit `Related tests` field (`task-schema.md`) | `sda-dev-task` (identifies runnable tests), `sda-scribe` (writes), `sda-dev` (passes as the test target or omits), `sda-coder` (runs them or skips) | Regression check for integration-only units; when absent, no tests run |
| `Detected shell` (`project-tools.md`, Output Filter Command) | `sda-dev` (passes `Shell:` in every delegation), `sda-coder`, `sda-refactor`, `sda-test-writer` (run commands in that shell; never translate idioms) | Prevents shell-mismatch errors (e.g. `tail` vs `Select-Object`) |
| `standardsSkill` (`project-config.json`) | `sda-dev` (from session context, passes `Standards skill:` in every delegation), `sda-coder`, `sda-refactor`, `sda-test-writer` (load the named skill), `sda-dev-task` (loads it for task.md code examples), **sda-setup skill** (scaffolds default) | Configurable coding-standards skill; default `standards-compliance` (the literal name lives only in `project-config.json` + docs, never in `.agent.md` files) |
| `qa-task.md` schema (`qa-task-schema.md`) | `sda-qa-task` (designs FRs — coupled or standalone), `sda-scribe` (writes — Mode 4), `sda-qa` (reads — sole input) | sda-qa-task designs the QA spec; scribe writes it; sda-qa verifies against it black-box. Standalone specs live under `paths.issues` |
| `dev-report.md` schema (`dev-report-schema.md`) | `sda-dev` (provides facts), `sda-scribe` (writes) | Orchestrator reports what was built; scribe formats it |
| `project-tools.md` schema (`project-tools-schema.md`) | `sda-toolscan` (writes output), `sda-dev` (fetches command labels via read-project-tools script) | Labels are machine-readable keys — renaming breaks script lookups |
| `qa-report.md` format (in `sda-qa`) | `sda-qa` (writes), `sda-dev` (surfaces link only) | Orchestrator posts the link; it never parses or acts on the report |
| Application-run commands (in `project-tools.md`) | `sda-toolscan` (discovers + writes `### Application Run` inside each area block), `sda-qa` (reads to start the app) | sda-qa starts each layer from these long-running commands |
| `paths.issues` in `project-config.json` | `sda-qa-task` (designs standalone `qa-task.md`), `sda-scribe` (Mode 4 numbers + writes there), `sda-qa` (reads standalone specs, writes `qa-report.md` beside them) | Shared root for standalone QA work (no task); default `.sda/issues`. Spec + report co-locate in one `<NNN>-<slug>/` folder |
| `paths.secrets` in `project-config.json` | **sda-setup skill** (scaffolds git-ignored folder + writes `.gitignore`) | No agent resolves this field at runtime — credentials are loaded via `scripts.loadQaSecrets`; default `.sda/secrets` |
| `scripts.qaSessionInit` / `scripts.invokeHttp` in `project-config.json` | `sda-qa` (from session context), **sda-setup skill** (scaffolds scripts) | sda-qa uses session-init path (fallback: `scripts.loadQaSecrets`) and HTTP helper path; defaults `.sda/scripts/qa/qa-session-init.ps1` and `.sda/scripts/qa/invoke-http.ps1` |
| Step 7 required-tools table (in **sda-setup skill**) | `sda-tool-installer` | Installer receives the missing-category list and runs the install commands |
| `sda-dev` QA delegation trigger/format | `sda-qa` input expectations | sda-qa is invoked with the task name/folder when qa-task.md + app-run commands exist |
| `sda-scribe` Mode 4 (QA spec) destination/numbering | `sda-qa-task` (delegates it — coupled or standalone), `sda-qa` (discovers standalone specs in `paths.issues`) | Producer and consumer must agree on the coupled (beside `task.md`) and standalone (`{issues-root}/<NNN>-<slug>/`) layouts |
| `state.json` schema (in `task-schema.md`) | `sda-dev-task` (creates via script), `sda-dev` | Task agent initializes it; the orchestrator updates via `task-state` script |
| `sda-dev-task` Phase 6 delegation format | `sda-scribe` input contract | Scribe parses the exact context sda-dev-task sends |
| `sda-qa-task` FR / read-list rules | `qa-task-schema.md` (authoritative FR rules), `sda-qa` (verifies the resulting FRs) | Designer applies the schema's black-box FR rules; sda-qa executes them |
| `sda-qa-task` delegation format (Mode 4) | `sda-scribe` Mode 4 input contract | Scribe parses the exact QA Task fields sda-qa-task sends — precondition, reproduce, Settle, Expected data, expected outcome, compare, layers, Setup, Credentials |
| `sda-dev-task-verifier` output format | `sda-dev-task` (processes results), `sda.dev.task-verify` prompt | Both depend on the report structure |
| `sda-dev-task-verifier` delegation to `sda-code-explore` | `sda-code-explore` input contract | Verifier sends file lists for structural + regression fact-gathering; explorer returns raw findings |
| Consistency/regression check rules | `sda-dev-task-verifier` | All verification logic lives in the verifier |
| Contract spec file format or storage conventions | `sda-system` (defines policy in § 4, writes canonical specs via sda-scribe), `sda-feature` (identifies affected specs), `sda-dev-task` (designs content), `sda-scribe` (writes files), `sda-dev-task-verifier` (reads for verification) | All planning agents share spec conventions |
| `feature.md` schema (in `sda-feature`) | `sda-dev-task` (reads feature context) | Task designer reads the feature spec |
| `design.md` schema (in `sda-system`) | `sda-feature` (references system design) | Feature designer references system architecture |
| `paths.design` in `project-config.json` | `sda-system` (from session context) | sda-system uses this for all design output paths; default `.sda/design` |
| `paths.specs` in `project-config.json` | `sda-system` (writes canonical specs), `sda-feature` (reads manifest for affected specs), `sda-dev-task` (reads specs during contract trace), `sda-scribe` (writes spec files), `sda-dev-task-verifier` (reads specs for verification) | All planning agents receive this from session context; default `.sda/specs` |
| `manifest.md` format | `sda-system` (adds canonical specs), `sda-feature` (reads for affected specs), `sda-dev-task` (reads for spec discovery), `sda-scribe` (writes/updates rows), `sda-dev-task-verifier` (reads for verification) | Entry point for spec discovery; scribe maintains it |
| `sda-system` diagram delegation format (`DIAGRAM` block) | `sda-diagram-writer` input contract | Subagent parses the exact DIAGRAM block format the orchestrator sends |
| Communication rules (silent-by-default, forbidden phrases) | `sda-dev`, `sda-test-writer`, `sda-coder` | Orchestrator and subagents share identical communication constraints |
| Standards compliance rules | `sda-dev`, `sda-test-writer`, `sda-coder` | All code-producing agents enforce standards |
| Unexpected-failure / troubleshooting handling | `sda-dev` | Troubleshooting is a workflow decision — subagents stop and report; the orchestrator diagnoses and recovers |
| Coding standards skill references | `sda-dev` | References coding standards for output |
| Quality check gates (Phase 5) | `sda-dev-quality` | Phase 5 is a thin delegation; quality agent owns per-area gate execution, reporting, and flagging |
| `sda-dev-quality` report format | `sda-dev` (Phase 5 result relay, Phase 6 verification commands) | Orchestrator relays the quality report verbatim; uses its verification commands in Phase 6 |
| `sda-dev` Flags processing (Phase 5) | `sda-coder`, `sda-test-writer` | Orchestrator routes quality flags to the correct subagent for fixes |
| `task.md` Area field + Area Index in `project-tools.md` | `sda-dev-task` (derives area per unit), `sda-scribe` (writes), `sda-dev` (reads per-unit areas), `sda-dev-quality` (discovers areas) | Area connects task design → implementation → quality gates |
| Init output format (`project-tools.md`) | `sda-toolscan`, `sda-dev`, **sda-setup skill** | The orchestrator, the toolscan agent, and the setup skill depend on project-tools output |
| `models` in `project-config.json` | `sda-setup` skill (asks user, normalizes, resolves, applies to agent frontmatter) | sda-setup resolves family names to versioned models and writes `model:` into `sda-toolscan`, `sda-dev-task`, `sda-qa-task`, `sda-scribe`, `sda-dev-task-verifier`, `sda-code-explore`, `sda-dev`, `sda-dev-quality`, `sda-qa`, `sda-test-writer`, `sda-coder`, `sda-refactor` |
| `unit-file-size` script (parameters or output format) | `sda-dev-task` (Phase 6 Step 1), `sda-dev` (Phase 1 step 3), `sda-dev-task-verifier` (Check 1) | All three agents invoke the script; interface changes break invocations |
| `README.md` | Keep consistent with all agent descriptions and workflow phases | User-facing docs must match agent behavior |

## Rules

### 1. Orchestrator–Subagent Synchronization (highest priority)

`sda-dev` owns the TDD workflow; `sda-test-writer` and `sda-coder` execute the RED and GREEN phases it delegates. When changing workflow logic:

- A RED-phase change in `sda-dev` must be reflected in `sda-test-writer`.
- A GREEN-phase change in `sda-dev` must be reflected in `sda-coder`.
- A change in a subagent's contract must be reflected in the orchestrator's delegation templates.

Before considering any workflow change complete, verify the orchestrator and subagents handle the same scenarios consistently.

### 2. Schema Changes Propagate Downstream

File schemas (`task.md`, `qa-task.md`, `dev-report.md`, `state.json`, `feature.md`, `design.md`, `project-tools.md`, `project-config.json`) are contracts between agents. When changing a schema:

1. Identify every agent that **reads** or **writes** that schema (use the dependency matrix above).
2. Update all affected agents to match the new schema.
3. Update `README.md` if the schema is documented there.

### 3. Subagent Contract Stability

`sda-test-writer` and `sda-coder` have explicit **input contracts** (the format `sda-dev` sends them). When changing delegation format:

1. Update the orchestrator's delegation templates.
2. Update the subagent's input contract section.
3. Verify the subagent's workflow still produces the expected output format.

**Subagents are mechanical workers.** They make domain decisions *within* their assigned unit (how to implement, how to structure tests, which algorithm to use). They do **not** make workflow decisions. When something outside their scope fails (environment error, unexpected tool failure, missing input), they stop immediately and report — they do not troubleshoot, retry with alternatives, or improvise. Recovery is the orchestrator's responsibility.

### 4. Communication Rules Are Shared

`sda-dev`, `sda-test-writer`, and `sda-coder` share identical communication constraints (silent-by-default, output templates, forbidden phrases). When editing communication rules in one, copy the change to the others.

### 5. Keep README.md in Sync

The `README.md` in this folder documents the agent pipeline, setup steps, workflow phases, and configuration paths. When any of these change in the agent files, update `README.md` to match.

### 6. Preserve Existing Patterns

- Follow the formatting conventions already in use (Markdown heading levels, table layout, section numbering, output template style).
- New sections should model their structure after existing peer sections in the same agent file.

### 7. Language-Agnostic Instructions

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

### 8. `.sda` Dependencies Section Required

Every agent or skill that reads or writes files in `.sda/` must include a `.sda dependencies` section with:

- **Heading level:** `###` when nested under a parent constraints section (e.g. `## HARD CONSTRAINTS`), `##` otherwise.
- **Standard preamble:** `".sda/ is a dot-prefixed folder that may be hidden from search tools. Access all files below by exact path from the repo root — never search for them."`
- **Dependency table:** `| File | Path |` listing every `.sda/` file the agent reads or writes, with the exact relative path from the repo root.

### 9. Delegation — Always Pass Full `.sda/` Paths

When delegating to a subagent, pass every `.sda/` file reference with its full path (e.g., `.sda/project-tools.md`, not `project-tools.md`). Subagents must never search for `.sda/` files — if a path is ambiguous, ask the caller.

### 11. Communication Style Placement

Every SDA agent that produces chat output must include a `## Communication style — mandatory` section (or `### Chat output style` when nested). This section is a **global governing rule** — it applies throughout the agent's entire session, not to a single phase or step.

**Placement:** After the constraint sections (HARD CONSTRAINTS, read-list, or equivalent) and **before** the first workflow or phase section. Never place it after workflow sections.

### 10. CLI Script String Encoding

All PowerShell (`.ps1`) and bash (`.sh`) scripts must use only ASCII characters inside string literals — including error messages, warnings, and output strings.

| Forbidden | Use instead |
|---|---|
| Em dash `—` (U+2014) inside `"..."` or `'...'` | Hyphen-minus `-` |
| Any non-ASCII character inside a string literal | Its ASCII equivalent |

Non-ASCII characters in `#` comments are safe. The restriction applies only to characters inside quoted strings. PowerShell 5.1 misparsed UTF-8 em dashes as `â€"`, producing `TerminatorExpectedAtEndOfString` parse errors.

## Boundaries

- ✅ **Always do**: Propagate changes across connected agents, keep schemas consistent, update README.md.
- ⚠️ **Ask first**: Changing a file schema, adding/removing an agent, restructuring the delegation model, changing the approval gate sequence.
- 🚫 **Never do**: Change one branch without checking the other, modify subagent input contracts without updating the orchestrator, break the `task.md`/`state.json` contract that `sda-dev-task` and implementation agents share, hard-code language-specific commands or framework names into agent or skill instructions.
