# SDA — Software Development Assistant

A suite of coordinated AI agents that implement a Specification-Driven Development workflow. Use it to go from a feature idea to tested, standards-compliant code without manually orchestrating each step.

```
sda-setup skill  →  sda-toolscan  →  sda-dev-task  →  sda-dev  →  sda-qa
(once, skill)       (once)           (tasks)      (implement)     (verify)
```

---

## Setup

### 1. Run install script

Installs the **sda-setup** skill, SDA agents, and the [**Standards Compliance**](../../skills/standards-compliance/) skill into your `.copilot` user folder.

| OS | Default install location |
|---|---|
| Windows | `%USERPROFILE%\.copilot` |
| macOS / Linux | `~/.copilot` |

**PowerShell (Windows):**
```powershell
# Default — core agents only
.\scripts\powershell\install-dev-suite.ps1

# All agents
.\scripts\powershell\install-dev-suite.ps1 -Mode full

# Custom install location
.\scripts\powershell\install-dev-suite.ps1 -TargetBase "C:\my\.copilot" -Mode full
```

**Bash (macOS/Linux):**
```bash
# Default — core agents only
./scripts/bash/install-dev-suite.sh

# All agents
./scripts/bash/install-dev-suite.sh full

# Custom install location
./scripts/bash/install-dev-suite.sh -t ~/.my-copilot full
```

| Mode | Description | Agents installed |
|---|---|---|
| `short` (default) | All SDA agents — design (`sda-design`) and docs verification (`sda-docs-check`) included | All SDA agents |
| `full` | Same as `short` — mode reserved for future filtering | All SDA agents |

> **Note:** Make sure your IDE is configured to load agents, skills, and prompts from the install location.

### 2. Initialize the project

In a new Copilot chat, say:

```
Setup sda tool
```

The `sda-setup` skill scaffolds `.sda/` with resource files, then automatically invokes `sda-toolscan` to scan your toolchain and write `project-tools.md` and `project-config.json`.

---

## Usage

### 1. Design a task — `sda-dev-task`

```
Design a task for <task description here>
```

Produces a `task.md` with test scenarios, implementation plan, and `state.json` for tracking.

`sda-dev-task` is conversational — talk through the task to shape its scope, verify consistency with the existing design, and assess regression risks before implementation begins.

### 2. Implement — `sda-dev`

```
Implement the current task.
```

```
Implement task 03-order-list-endpoint.
```

For quick, one-off changes without a task spec (ad-hoc mode):

```
Fix the bug where createOrder throws when quantity is 0.
```

`sda-dev` runs the TDD loop (RED → GREEN → refactor) and enforces the quality gates. It delegates test writing and coding to subagents to keep each context small and reasoning sharp.

### 3. Design — `sda-design`

> Requires `full` install mode.

One agent, two altitudes — detect from the request:

- **System mode** — new app/platform, service boundaries, conventions, domain model:
  ```
  Design the architecture for the notification subsystem.
  ```
  Writes design topic files under `docs/design/` and updates all readmes (all AI readmes + human README).
- **Feature mode** — a specific feature or bounded context:
  ```
  Design a feature for paginated order listing filtered by status.
  ```
  Records design decisions and updates §4 of all readmes, then hands off
  to `sda-dev-task` to split into tasks.

`sda-design` is conversational. By default it pressure-tests the design **you** propose rather than authoring it — describe the area you're tackling, defend your direction against its push-back on complexity and risk, and iterate together before committing. (Configurable via `designOwnership` — see [project-config.json](#project-configjson).)

### Author the QA acceptance spec — `sda-qa-task`

`sda-qa-task` writes the black-box `qa-task.md` that `sda-qa` verifies. It runs
two ways:

- **Coupled** — invoked once a task is finalized, producing a `qa-task.md` beside the
  task's `task.md`.
- **Standalone** — invoke it directly to spec **existing** behaviour with no
  task:

  ```
  Author a QA spec to verify the order-list page shows new orders after creation.
  ```

It translates user-observable acceptance intent into reachable, black-box
functional requirements — never DOM- or implementation-level assertions — and
delegates the file write to `sda-scribe`.

### Verify acceptance — `sda-qa`

`sda-qa` verifies a running application against a `qa-task.md` (its black-box
spec of functional requirements). That spec reaches it two ways:

- **Task-coupled** — written during task design and verified automatically:
  `sda-dev` invokes `sda-qa` at the end of a task when a `qa-task.md` and
  app-run commands both exist.
- **Standalone** — for checking **existing** behaviour when there is no task
  (e.g. "does feature X already work?"). First author the spec with
  [`sda-qa-task`](#author-the-qa-acceptance-spec--sda-qa-task), then run the
  verification:

  ```
  QA the order-list spec.
  ```

`sda-qa` starts the app, drives a real browser/CLI through the functional
requirements, and writes a `qa-report.md` (beside the spec) with per-requirement
PASS/FAIL and evidence. It is read-only on source code and never fixes what it
finds — it reports, and leaves routing (sda-dev-task vs ad-hoc sda-dev) to you.

---

## Agents

### Pipeline agents

| Agent | Role | Model | Tools |
|---|---|---|---|
| `sda-toolscan` | Scans toolchain, writes `project-tools.md` | project config | read, search, edit, execute |
| `sda-design` | System architecture + feature design — components, contracts, diagrams, decision docs | Claude Sonnet 4.6 | read, edit, search, agent |
| `sda-dev-task` | Designs atomic task specs (`task.md`) with test scenarios and implementation plans | project config | read, search, agent, execute |
| `sda-qa-task` | Authors the black-box acceptance spec (`qa-task.md`) — coupled (from a finalized task) or standalone | Claude Sonnet 4.6 | read, search, agent |
| `sda-dev` | TDD implementation orchestrator — delegates RED/GREEN to subagents to keep context small | project config | read, edit, execute, agent |
| `sda-qa` | Runtime acceptance QA — starts the app, drives a real browser/CLI through the functional requirements, writes `qa-report.md` (read-only on source) | Claude Sonnet 4.6 | read, edit, search, execute, browser, web |

### Subagents (invoked by pipeline agents)

| Agent | Role | Model | Tools |
|---|---|---|---|
| `sda-scribe` | Universal scribe: writes task.md, qa-task.md, dev-report.md, design-decision docs, contract specs, and manifest.md | Claude Haiku 4.5 | read, edit, search, execute |
| `sda-dev-task-verifier` | Consistency checks + regression analysis on task.md. Delegates file-gathering to sda-code-explore for tasks with >3 files. Runs `unit-file-size` for unit size verification. | Claude Sonnet 4.6 | read, search, agent, execute |
| `sda-code-explore` | Fast read-only codebase exploration (invoked by sda-dev-task, sda-dev-task-verifier, sda-qa-task, sda-dev, sda-design) | Claude Haiku 4.5 | read, search |
| `sda-web-explore` | Web research — fetches live API docs and library specs (invoked by sda-dev-task, sda-design) | Claude Haiku 4.5 | web |
| `sda-test-writer` | Writes tests for TDD slices (RED) and tests-only slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-coder` | Implements production code (GREEN) and integration slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-refactor` | Runs the REFACTOR pass without changing behaviour: per-unit (refactors the code each unit added or modified) plus a final cross-unit duplication pass; reverts any change that breaks a test. | project config | read, edit, search, execute |
| `sda-dev-quality` | Runs per-area quality gates (types, lint, tests, coverage, build, pre-merge). Check-and-report only — never fixes. Invoked by sda-dev (Phase 5) or standalone. | Claude Haiku 4.5 | read, search, execute |
| `sda-docs-check` | Verifies decision-doc integrity + drift and AI-readme routing (AGENTS.md/CLAUDE.md §3–§6 links, feature list, standards) against reality. Check-and-report only — never fixes. Invoked by sda-design. | Claude Sonnet 4.6 | read, search, execute, agent |
| `sda-tool-installer` | Installs required development tools — reads tool-catalog.md, runs install commands, handles git-hooks init, reports pass/fail per tool. Invoked by sda-setup skill (Step 7). | Claude Haiku 4.5 | read, execute |

**Model configuration:** Implementation agents use models from `project-config.json`. Default: Claude Sonnet. Run sda-setup (or say "update sda") to resolve family names and apply to agent files. See [Model configuration](#model-configuration).

`sda-dev` runs the TDD loop and quality gates, delegating test writing and coding to subagents to keep each context small.

`sda-scribe` is the universal scribe for SDA planning and implementation agents — it writes task.md, qa-task.md, dev-report.md, design-decision docs, contract spec files, and manifest.md. It uses Haiku for cost efficiency since it performs no reasoning — only schema formatting and file I/O. `sda-code-explore` is invoked by `sda-dev-task`, `sda-dev-task-verifier`, `sda-qa-task`, and `sda-dev` for codebase research — also Haiku, since it only reads and reports. `sda-web-explore` is invoked by `sda-dev-task` and `sda-design` for live web/API research when documentation may have changed. `sda-dev-task-verifier` handles Phase 7 (consistency + regression checks) — it can be invoked directly by the user or delegated to by `sda-dev-task`.

All pipeline agents are user-invokable and used as needed.

### Skills

| Skill | Role |
|---|---|
| `sda-setup` | Scaffolds `.sda/` folder with resource files (bootstrap, tool-discovery, config example) |

### Prompts

| Prompt | Role |
|---|---|
| `sda.dev.task-verify` | Verifies task spec consistency against the codebase and runs regression analysis |
| `sda.qa.session-run` | Triggers sda-qa agent — runs QA verification for a task |
| `sda.dev.task-implement` | Triggers sda-dev agent — implements a task using TDD workflow |
| `sda.qa.task-create` | Triggers sda-qa-task agent — creates a QA task for a completed task |
| `sda.setup` | Sets up SDA tool — scaffolds `.sda/` and scans the project toolchain |
| `sda.setup.no-scan` | Sets up SDA tool — scaffolds `.sda/` without a toolchain scan |
| `sda.design.reconcile` | Reconciles design docs with code — finds and fixes inconsistencies across the AI readme, design topic files, and decision docs |

---

## Workflow phases

```
PHASE 0 — INIT  (once per project)
  sda-toolscan detects OS, shell, and language(s) from project markers.
  Reads all matching tool-discovery specs → scans for test runner, linter, type checker, etc.
  Writes .sda/project-tools.md and .sda/project-config.json.

PHASE 1 — TASK DESIGN  (sda-dev-task)
  sda-dev-task brainstorms the task with the user.
  Researches the codebase (read-only).
  Verifies consistency with the existing design and assesses regression risks.
  Produces .sda/tasks/<NN>-<task-name>/task.md with test scenarios,
  implementation plan, and state.json for tracking.

PHASE 2 — BOOTSTRAP  (once per conversation, sda-dev)
  Verifies tooling, loads standards, detects mode.
  Ad-hoc: explores codebase and derives work unit.
  Task: proceeds to PLAN.

PHASE 3 — PLAN  (task mode, per slice)
  Reads state.json (via task-state script) and task.md.
  Extracts current slice inputs.
  Routes to RED or GREEN.

PHASE 4 — RED
  Writes failing tests for every approved scenario.
  Confirms RED state (tests fail as expected).

PHASE 5 — GREEN
  Writes production code to make all tests pass.
  Re-runs tests until fully green.

PHASE 6 — REFACTOR + QUALITY CHECKS
  Refactors the code each slice added or modified as it completes (per-unit); after all slices,
  a thin cross-unit pass removes duplication spanning slices.
  Delegates quality gates to sda-dev-quality — gates run per project area (Backend, Frontend, etc.).
  Presents per-area results and exact commands to the user.

PHASE 7 — DEV REPORT + ACCEPTANCE QA  (task mode, sda-dev)
  Delegates dev-report.md (what was built + issues encountered + follow-up opportunities) to sda-scribe.
  If qa-task.md and app-run commands exist, delegates to sda-qa:
  sda-qa starts the app, drives a real browser/CLI through each functional
  requirement, and writes qa-report.md (per-FR PASS/FAIL + evidence).
  sda-dev posts the clickable report link — it never auto-fixes findings.
```

### Mode routing (sda-dev)

| Invocation | Mode | Behaviour |
|---|---|---|
| Task name / "implement the current task" / attached `task.md` | `task` | Full TDD workflow — RED → GREEN → refactor → quality checks |
| Coding request without a task folder | `ad-hoc` | Implement directly — standards and quality checks still enforced |

---

## Configuration

All resources are read from a `.sda/` folder in the project root (may be git-ignored). Agents always use exact literal paths — they never search for these files.

| Resource | Path |
|---|---|
| Project tools (commands) | `.sda/project-tools.md` |
| Project config | `.sda/project-config.json` |
| Project config reference | `.sda/project-config.reference.yml` |
| Tool-discovery spec | `.sda/resources/{language}/tool-discovery.md` |
| Task spec | `.sda/tasks/<NN>-<task-name>/task.md` |
| QA acceptance spec | `.sda/tasks/<NN>-<task-name>/qa-task.md` |
| Dev report | `.sda/tasks/<NN>-<task-name>/dev-report.md` |
| QA report (task) | `.sda/tasks/<NN>-<task-name>/qa-report.md` |
| QA spec (standalone) | `.sda/issues/<NNN>-<slug>/qa-task.md` |
| QA report (standalone) | `.sda/issues/<NNN>-<slug>/qa-report.md` |
| QA credentials | `.sda/secrets/qa.secrets.env` (git-ignored) |
| Task progress state | `.sda/tasks/<NN>-<task-name>/state.json` |
| State management script | `.sda/scripts/dev/task-state.ps1` or `.sda/scripts/dev/task-state.sh` |
| File line-count check script | `.sda/scripts/dev/unit-file-size.ps1` or `.sda/scripts/dev/unit-file-size.sh` |
| Config injection script | `.sda/scripts/read-config.ps1` or `.sda/scripts/read-config.sh` |
| Project-tools command lookup | `.sda/scripts/read-project-tools.ps1` or `.sda/scripts/read-project-tools.sh` |
| Toolchain scan scripts | `.sda/scripts/toolscan/` (cleanup, timestamp, probe-validators) |
| Decision topic schema | `.sda/resources/decisions/decision-topic-schema.md` |
| Decision index schema | `.sda/resources/decisions/decision-index-schema.md` |
| Docs integrity script | `.sda/scripts/decisions/docs-integrity.ps1` or `.sda/scripts/decisions/docs-integrity.sh` |
| Design-decision docs | `docs/design/decisions/` (derived from `paths.design`) |

`{language}` values are inferred from project markers — one or more per project (`package.json` → `typescript`, `pyproject.toml` / `requirements.txt` → `python`, etc.). Multi-language projects (e.g. TypeScript frontend + Python backend) load all matching discovery specs and produce a single `project-tools.md` with sections for each area.

### Model configuration

The `models` section in `project-config.json` controls which AI model each agent uses. Keys match agent names directly. Specify model family names without version numbers.

```json
"models": {
  "sda-toolscan": "Claude Haiku",
  "sda-dev-task": "Claude Sonnet",
  "sda-scribe": "Claude Haiku",
  "sda-dev-task-verifier": "Claude Sonnet",
  "sda-code-explore": "Claude Haiku",
  "sda-dev": "Claude Sonnet",
  "sda-qa": "Claude Sonnet",
  "sda-test-writer": "Claude Sonnet",
  "sda-coder": "Claude Sonnet",
  "sda-refactor": "Claude Sonnet",
  "sda-docs-check": "Claude Sonnet",
  "sda-dev-quality": "Claude Haiku"
}
```

| Key | Role | Default |
|---|---|---|
| `sda-toolscan` | Scans project toolchain | `Claude Haiku` |
| `sda-dev-task` | Designs task specifications | `Claude Sonnet` |
| `sda-scribe` | Universal scribe: writes task.md, contract specs, manifest.md | `Claude Haiku` |
| `sda-dev-task-verifier` | Consistency + regression checks | `Claude Sonnet` |
| `sda-code-explore` | Fast codebase exploration | `Claude Haiku` |
| `sda-dev` | Orchestrates TDD workflow | `Claude Sonnet` |
| `sda-qa` | Runtime acceptance QA | `Claude Sonnet` |
| `sda-test-writer` | Writes tests (RED phase) | `Claude Sonnet` |
| `sda-coder` | Implements production code (GREEN phase) | `Claude Sonnet` |
| `sda-refactor` | Runs the REFACTOR pass (behaviour-preserving) | `Claude Sonnet` |
| `sda-dev-quality` | Runs per-area quality gates | `Claude Haiku` |
| `sda-docs-check` | Verifies decision docs + AI-readme routing | `Claude Sonnet` |

**Resolution:** `sda-setup` resolves family names to the latest available versioned model (e.g., `"Claude Sonnet"` → `"Claude Sonnet 4.6 (copilot)"`) and writes the result into each agent's `model:` frontmatter. Re-run sda-setup (or say "update sda") to pick up new model versions.

If the `models` section is absent, the defaults from the table above are applied.

### project-tools.md

Written by `sda-toolscan` on first run. Contains the commands `sda-dev` uses to run tests, check types, lint, measure coverage, run pre-commit hooks, and run specific files. Must exist before the agent proceeds — a missing file triggers a hard stop.

`project-tools.md` always includes an **Area Index** table mapping each area to its language, working directory, and file patterns. Consuming agents use this to resolve which command section applies to a given file.

### project-config.json

Written by the `sda-setup` skill. Stores project-level settings injected into each agent's session context at startup via the `SessionStart` hook (`read-config.ps1` / `read-config.sh`). Enable with VS Code setting `chat.useCustomAgentHooks: true`.

| Field | Type | Default | Description |
|---|---|---|---|
| `designOwnership` | `string` | `user` | Who owns the design decision in `sda-design` and `sda-dev-task`. When `user` (default), the agent never volunteers an approach — it pressure-tests the approach **you** propose and hands the decision back to you; it only proposes options when your message explicitly asks for them. When `ai`, the agent may propose the design itself (legacy behaviour). |
| `standardsSkill` | `string` | `standards-compliance` | Name of the skill carrying coding standards. `sda-dev`, `sda-coder`, `sda-refactor`, `sda-test-writer`, and `sda-dev-task` load it before generating code. |
| `paths.design` | `string` | `docs/design` | Root folder for sda-design output (design topic files). Decision docs derive from it: `<design>/decisions` — no separate field. |
| `paths.specs` | `string` | `.sda/specs` | Root folder for specification files (OpenAPI, JSON Schema, etc.). Written by sda-scribe; read by sda-dev-task and sda-dev-task-verifier. |
| `paths.issues` | `string` | `.sda/issues` | Root folder for standalone QA work (no task): each `<NNN>-<slug>/` holds a `qa-task.md` authored by sda-qa-task and the `qa-report.md` written by sda-qa. |
| `paths.secrets` | `string` | `.sda/secrets` | Git-ignored folder holding `qa.secrets.env` credentials used by sda-qa. |
| `scripts.loadQaSecrets` | `string` | `.sda/scripts/qa/load-qa-secrets.ps1` | Path to the QA secrets loader script (legacy — superseded by `qaSessionInit`). Still used as a fallback when `qaSessionInit` is absent. Use the `.sh` variant on Bash/Unix. |
| `scripts.listQaSecrets` | `string` | `.sda/scripts/qa/list-qa-secrets.ps1` | Path to the QA secrets lister script. Called by sda-qa-task to discover existing credential key names. Use the `.sh` variant on Bash/Unix. |
| `scripts.qaSessionInit` | `string` | `.sda/scripts/qa/qa-session-init.ps1` | Path to the QA session init script. Dot-sourced by sda-qa at Phase 2; sets UTF-8 encoding and loads credentials. Outputs a combined summary and `var_name \| is_empty` table. Use the `.sh` variant on Bash/Unix. |
| `scripts.docsIntegrity` | `string` | `.sda/scripts/decisions/docs-integrity.ps1` | Path to the docs-integrity script. Called by sda-docs-check to verify decision-doc links, orphans, and duplicate index rows. Use the `.sh` variant on Bash/Unix. |
| `scripts.invokeHttp` | `string` | `.sda/scripts/qa/invoke-http.ps1` | Path to the HTTP helper script. Called by sda-qa for every CLI/HTTP request; outputs `STATUS: N` and `BODY: ...`; supports `-StatusOnly` / `--status-only`. Use the `.sh` variant on Bash/Unix. |
| `scripts.unitFileSize` | `string` | `.sda/scripts/dev/unit-file-size.ps1` | Path to the file line-count script. Called by `sda-dev-task` (Phase 6) and `sda-dev-task-verifier` (Check 1) to measure source file volume. Use the `.sh` variant on Bash/Unix. |
| `devTaskUnitSizeLimit` | `number` | `1000` | Maximum total lines across existing Source+Test files in any single unit. Units exceeding this limit require splitting in `sda-dev-task`. |
| `tests.coverage.enabled` | `boolean` | `true` | Whether to run coverage checks in Phase 5 (Quality). When disabled, coverage gate is skipped entirely. |

Example:
```json
{
  "scripts": {
    "taskState": ".sda/scripts/dev/task-state.ps1",
    "unitFileSize": ".sda/scripts/dev/unit-file-size.ps1"
  },
  "devTaskUnitSizeLimit": 1000,
  "designOwnership": "user",
  "standardsSkill": "standards-compliance",
  "paths": {
    "design": "docs/design",
    "specs": ".sda/specs",
    "issues": ".sda/issues",
    "secrets": ".sda/secrets"
  },
  "tests": {
    "coverage": {
      "enabled": true
    }
  }
}
```

### Standards files

Read in full by `sda-dev` at the start of every session — before any source file is read or written. Every rule is treated as mandatory; there are no optional guidelines.

---

## Key design constraints

- **The `sda-setup` skill and `sda-toolscan` agent run once per project, not per task.** Re-run only if the toolchain changes.
- **`sda-design` is read-only on the codebase.** It researches but never edits source files. Edits are scoped to design artifacts (design topic files, feature detail docs, decision docs, all readmes).
- **`sda-dev` hard-stops if `project-tools.md` is missing.** There is no fallback — run `sda-setup` + `sda-toolscan` first.
- **Standards are mandatory, always.** `sda-dev` reads all standards files before every session — even for trivial fixes or ad-hoc requests.
- **Quality checks are non-negotiable.** After any code change, `sda-dev` must run and pass all quality gates (tests, coverage, pre-merge, types, lint, full test suite) before finishing.
- **Tests must be failing before GREEN begins.** `sda-dev` confirms the RED state before writing production code.
- **Complexity is proportional.** `sda-design` matches design depth to scope — no patterns, abstractions, or architectural discussions for small, single-file changes.
