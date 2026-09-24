# SDA — Software Development Assistant

A suite of coordinated AI agents that implement a Specification-Driven Development workflow. Use it to go from a feature idea to tested, standards-compliant code without manually orchestrating each step.

`sda-ba` (optional front-end) turns a raw requirement into a ready User Story — one Actor + Gherkin — that feeds `sda-dev-task`:

```
sda-ba  →  sda-setup skill  →  sda-toolscan  →  sda-dev-task  →  sda-dev
(story)     (once, skill)       (once)           (tasks)      (implement)
```

---

## Setup

### 1. Run install script

Installs the **sda-setup** skill, the **sda-workflow-guide** skill, SDA agents, and the
supporting skills — [**Standards Compliance**](../../skills/standards-compliance/),
[**Troubleshooting**](../../skills/troubleshooting/),
[**Software Design Best Practices**](../../skills/software-design-best-practices/), and
[**Repo AI-Friendly**](../../skills/repo-ai-friendly/) — into your `.copilot` user folder.

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

### Plan in a workflow — `/sda.workflow.init`

Planning artifacts live in a **workflow**: a numbered container for one requirement.

```
.sda/workflows/
  001. const-refactoring/
    workflow.json          script-written state (stage + start + escalation log)
    issue.md               entry artifact: container name, artifact paths, issue outline
    user-story.md          owner: sda-ba
    design.md              owner: sda-design
    tasks/                 owner: sda-dev-task
      001. ui-refactoring/
        task.md            owner: sda-dev-task
        dev-report.md      owner: sda-dev
    escalations/           one evidence brief per escalation
```

`init` also writes the container's **`issue.md`** — the entry artifact, holding the container
name, the three artifact paths, and the issue in the user's own words: an outline, not a
requirements spec, with no design or implementation detail. Every stage starts from it, so the
work is never re-stated: `/sda.workflow.story.issue` (`sda-ba`),
`/sda.workflow.design.issue` (`sda-design`), `/sda.workflow.task.issue` (`sda-dev-task`), or
`/sda.workflow.dev.issue` (`sda-dev`).

Create one with `/sda.workflow.init`, then start the owning agent on it in its own session. The
`sda-workflow` agent is the advisor surface: it reports where a container sits, names the next
action and its owning agent, and runs `init` and a user-requested `escalate`.
The stage machine is `story → design → tasks → dev → ready`: `init` starts at `story` by default,
or at `design` / `tasks` for pure technical work that has no user-visible change — the stages
before the start are skipped and produce no artifact. `dev` is the implementation stage, and it
counts as complete only when **every** task folder holds its `dev-report.md`, so a container with
an unimplemented task cannot reach `ready`. `advance` moves
forward exactly one stage, and `escalate` moves back — recording why, plus a **brief** holding the
evidence — when the current stage cannot finish on the artifacts it was given. The script refuses
a raise without a brief, so the blocked stage writes it first (`sda-scribe` numbers and names it);
the target stage reads the brief, then the artifact it cites, renews its own artifact, and closes
the escalation with `resolve`. While an escalation is open, `advance` is refused.

A stage agent works a workflow session by following the **`sda-workflow-guide`** skill: the
stage-entry prompt declares the session and points at it. The skill carries the workflow CLI
(`current`, `read`, `advance`, `escalate`, `resolve`), the stage gate, and the
finish/escalate/resolve steps, plus one stage card per producer naming its artifact, input, and
escalation targets — so the producers' own files carry none of that, just a dispatch line and the
escalation-evidence rule. The `sda-workflow` advisor owns `init`, and may raise a user-requested
escalation from any stage with an upstream. Standalone use is unchanged: a producer invoked
without a workflow declaration works its own default paths.

### Capture the requirement — `sda-ba`

```
Draft a story for <raw requirement here>
```

Turns a raw requirement into one **ready User Story** — a single Actor statement
plus Gherkin scenarios (happy / negative / edge) with measurable NFRs — gated by the
Definition of Ready before writing `user-story.md`. One actor per story;
multi-actor requests are split. `sda-ba` captures *what* and *why*, never *how* —
design, implementation, and QA specs belong to the later agents.

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

With a workflow container, start it from the container's `issue.md` with `/sda.workflow.dev.issue`
— that session follows the `sda-workflow-guide` skill and implements **one task folder per
session**: the first that still owes a `dev-report.md`, written beside its `task.md`. The
container advances to `ready` only once every task folder has one; each remaining folder gets its
own session.

### 3. Design — `sda-design`

> Requires `full` install mode.

One agent, two altitudes — detect from the request:

- **System mode** — new app/platform, service boundaries, conventions, vocabulary:
  ```
  Design the architecture for the notification subsystem.
  ```
  Discovers the repo's layers via `sda-code-explore`, then delegates the global
  `docs/` (architecture, vocabulary, index, decisions, diagrams) + one `docs/` per layer, and the
  readme outlines (AI readme + human README each) — to `sda-scribe`.
- **Feature mode** — a specific feature or bounded context:
  ```
  Design a feature for paginated order listing filtered by status.
  ```
  Records design decisions, updates the features section of all readmes, and writes the
  design record (`design.md`).

`sda-design` is conversational. By default it pressure-tests the design **you** propose rather than authoring it — describe the area you're tackling, defend your direction against its push-back on complexity and risk, and iterate together before committing. (Configurable via `designOwnership` — see [project-config.json](#project-configjson).) At the end of every session it writes the design record, `design.md` — inside the workflow folder when the requirement has one, otherwise under `.sda/design/reports/<yyyy-MM-dd_HH-mm_<name>>/` — so the next agent reads a compact record instead of the full conversation.

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
spec of functional requirements). It is always invoked by you — never by
another agent. That spec reaches it two ways:

- **Task-coupled** — written during task design; run the verification
  yourself once the task is complete:

  ```
  QA the current task.
  ```

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
| `sda-ba` | Business Analyst — elicits a raw requirement into one ready User Story (Actor + Gherkin + measurable NFRs) and owns the durable requirements tree, gated by the Definition of Ready | Claude Sonnet 4.6 | read, search, agent, edit, execute |
| `sda-design` | System architecture + feature design — components, contracts, diagrams, decision docs | Claude Sonnet 4.6 | read, search, agent, execute |
| `sda-dev-task` | Designs atomic task specs (`task.md`) with test scenarios and implementation plans | project config | read, search, agent, execute |
| `sda-qa-task` | Authors the black-box acceptance spec (`qa-task.md`) — coupled (from a finalized task) or standalone | Claude Sonnet 4.6 | read, search, agent |
| `sda-dev` | TDD implementation orchestrator — delegates RED/GREEN to subagents to keep context small; routes `docs` units to sda-scribe + sda-docs-check; owns the workflow's `dev` stage | project config | read, edit, execute, agent |
| `sda-qa` | Runtime acceptance QA — starts the app, drives a real browser/CLI through the functional requirements, writes `qa-report.md` (read-only on source) | Claude Sonnet 4.6 | read, edit, search, execute, browser, web |

### Subagents (invoked by pipeline agents)

| Agent | Role | Model | Tools |
|---|---|---|---|
| `sda-scribe` | Universal scribe: writes task.md, qa-task.md, dev-report.md, design-decision docs, design docs, requirements docs, design records, contract specs, manifest.md, and the files of a task's `docs` unit | Claude Haiku 4.5 | read, edit, search |
| `sda-dev-task-verifier` | Consistency checks + regression analysis on task.md. Delegates file-gathering to sda-code-explore for tasks with >3 files. Runs `unit-file-size` for unit size verification. | Claude Sonnet 4.6 | read, search, agent, execute |
| `sda-code-explore` | Fast read-only codebase exploration (invoked by sda-dev-task, sda-dev-task-verifier, sda-qa-task, sda-dev, sda-design) | Claude Haiku 4.5 | read, search |
| `sda-web-explore` | Web research — fetches live API docs and library specs (invoked by sda-dev-task, sda-design) | Claude Haiku 4.5 | web |
| `sda-test-writer` | Writes tests for TDD slices (RED) and tests-only slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-coder` | Implements production code (GREEN) and integration slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-refactor` | Runs the REFACTOR pass without changing behaviour: per-unit (refactors the code each unit added or modified) plus a final cross-unit duplication pass; reverts any change that breaks a test. | project config | read, edit, search, execute |
| `sda-dev-quality` | Runs quality gates (types, lint, tests, coverage, build, pre-merge) in **local** (target files) or **global** (whole area) mode. Check-and-report only — never fixes. Invoked by sda-dev (Phase 5, global) or standalone. | Claude Haiku 4.5 | read, search, execute |
| `sda-docs-check` | Verifies the docs tree (global + per-layer) + decision-doc integrity + drift and AI-readme routing (AGENTS.md/CLAUDE.md links, feature list) against reality. Full scope, or targeted on a `docs` unit's files. Check-and-report only — never fixes. Invoked by sda-design and sda-dev. | Claude Sonnet 4.6 | read, search, execute, agent |
| `sda-tool-installer` | Installs required development tools — reads tool-catalog.md, runs install commands, handles git-hooks init, reports pass/fail per tool. Invoked by sda-setup skill (Step 7). | Claude Haiku 4.5 | read, execute |

**Model configuration:** Implementation agents use models from `project-config.json`. Default: Claude Sonnet. Run sda-setup (or say "update sda") to resolve family names and apply to agent files. See [Model configuration](#model-configuration).

`sda-dev` runs the TDD loop and quality gates, delegating test writing and coding to subagents to keep each context small. A task's `docs` unit routes to `sda-scribe` (write) and then `sda-docs-check` (targeted verification).

`sda-scribe` is the universal scribe for SDA planning and implementation agents — it writes task.md, qa-task.md, dev-report.md, design-decision docs, design docs, requirements docs, design records, contract spec files, and manifest.md. It uses Haiku for cost efficiency since it performs no reasoning — only schema formatting and file I/O. `sda-code-explore` is invoked by `sda-dev-task`, `sda-dev-task-verifier`, `sda-qa-task`, and `sda-dev` for codebase research — also Haiku, since it only reads and reports. `sda-web-explore` is invoked by `sda-dev-task` and `sda-design` for live web/API research when documentation may have changed. `sda-dev-task-verifier` handles Phase 7 (consistency + regression checks) — it can be invoked directly by the user or delegated to by `sda-dev-task`.

All pipeline agents are user-invokable and used as needed.

### Skills

| Skill | Role |
|---|---|
| `sda-setup` | Scaffolds `.sda/` folder with resource files (bootstrap, tool-discovery, config example) |
| `sda-workflow-guide` | Workflow-mode operating instructions for stage agents — the workflow CLI, the stage gate, finish/escalate/resolve steps, and one stage card per producer |

### Prompts

| Prompt | Role |
|---|---|
| `sda.dev.task-verify` | Verifies task spec consistency against the codebase and runs regression analysis |
| `sda.qa.session-run` | Triggers sda-qa agent — runs QA verification for a task |
| `sda.dev.task-implement` | Triggers sda-dev agent — implements a task using TDD workflow |
| `sda.qa.task-create` | Triggers sda-qa-task agent — creates a QA task for a completed task |
| `sda.setup` | Sets up SDA tool — scaffolds `.sda/` and scans the project toolchain |
| `sda.setup.no-scan` | Sets up SDA tool — scaffolds `.sda/` without a toolchain scan |
| `sda.design.reconcile` | Reconciles design docs with code — finds and fixes inconsistencies across the AI readme, global + per-layer docs, and decision docs |
| `sda.workflow.init` | Creates a workflow container for one requirement, then names the start stage's session to run |
| `sda.workflow.status` | Reports where the workflow containers sit, ending with the single next action and the agent that owns it |
| `sda.workflow.advance` | Moves a workflow forward one stage, after showing the state and confirming |
| `sda.workflow.escalate` | Sends a workflow back a stage — elicits what is wrong, writes the evidence brief, then raises |
| `sda.workflow.story.issue` | Starts the story stage from the container's `issue.md` — switches to the sda-ba agent |
| `sda.workflow.design.issue` | Starts the design stage from the container's `issue.md` — switches to the sda-design agent |
| `sda.workflow.task.issue` | Starts the tasks stage from the container's `issue.md` — switches to the sda-dev-task agent |
| `sda.workflow.dev.issue` | Starts the dev stage from the container's `issue.md` — switches to the sda-dev agent |

---

## Workflow phases

```
Setup + task design (before sda-dev execution)

INIT  (once per project)
  sda-toolscan detects OS, shell, and language(s) from project markers.
  Reads all matching tool-discovery specs → scans for test runner, linter, type checker, etc.
  Writes .sda/project-tools.md and .sda/project-config.json.

TASK DESIGN  (sda-dev-task)
  sda-dev-task brainstorms the task with the user.
  Researches the codebase (read-only).
  Verifies consistency with the existing design and assesses regression risks.
  When handed off from sda-design, reads design.md first (the workflow
  record, or the most recent under .sda/design/reports/) instead of the full
  conversation.
  Produces .sda/tasks/<NN>-<task-name>/task.md with test scenarios,
  implementation plan, and state.json for tracking.

sda-dev execution — phases 0–6 (per sda-dev.agent.md)

PHASE 0 — BOOTSTRAP  (once per conversation)
  Verifies tooling, loads standards, detects mode.
  Ad-hoc: explores codebase and derives work unit.
  Task: proceeds to PLAN.

PHASE 1 — PLAN  (task mode, per unit)
  Reads state.json (via task-state script) and task.md.
  Extracts current unit inputs; routes by unit type — RED, GREEN,
  REFACTOR, or DOCS (resume table).

PHASE 2 — RED
  Writes failing tests for every approved scenario.
  Confirms RED state (tests fail as expected).

PHASE 3 — GREEN
  Writes production code to make all tests pass.
  Re-runs tests until fully green.

PHASE 3·D — DOCS  (`docs` unit — always the last unit)
  Delegates the doc files to sda-scribe (full content or anchored delta),
  then verifies them against the code with sda-docs-check (targeted scope).
  No RED, no GREEN, no refactor, no quality gates.

PHASE 4 — REFACTOR
  Refactors each unit's files as it completes (per-unit); after all units,
  a thin cross-unit pass removes inter-unit duplication.

PHASE 5 — QUALITY CHECKS
  Delegates quality gates to sda-dev-quality in global mode — gates run per project area.
  Presents per-area results and exact commands to the user.

PHASE 6 — FINALIZE  (task mode)
  Delegates dev-report.md (what was built + issues encountered + follow-up opportunities) to sda-scribe.
  QA is not part of this phase — you invoke sda-qa yourself afterwards
  (see "Verify acceptance — sda-qa").
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
| User Story schema | `.sda/resources/ba/user-story-schema.md` |
| User Story | `.sda/stories/<slug>/user-story.md` |
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
| Design + decision + requirements schemas | `{docsSkill}` skill (`repo-ai-friendly`) — load it by name; its `SKILL.md` routes to the readme-outline, docs-index, architecture, vocabulary, requirements, decision, and coding-standards schemas |
| Design record schema | `.sda/resources/design/design-record-schema.md` |
| Design record (workflow) | `.sda/workflows/<NNN>. <slug>/design.md` |
| Design record (standalone) | `.sda/design/reports/<yyyy-MM-dd_HH-mm_<short-name>>/design.md` |
| Workflow container | `.sda/workflows/<NNN>. <slug>/` |
| Workflow state | `.sda/workflows/<NNN>. <slug>/workflow.json` |
| Workflow entry artifact | `.sda/workflows/<NNN>. <slug>/issue.md` |
| Dev report (workflow) | `.sda/workflows/<NNN>. <slug>/tasks/<NNN>. <slug>/dev-report.md` — the `dev` stage's artifact |
| Escalation brief | `.sda/workflows/<NNN>. <slug>/escalations/<NNN>. <yyyy-MM-dd_HH-mm>-<from>-to-<to>.md` |
| Workflow schema | `.sda/resources/workflow/workflow-schema.md` |
| Escalation brief schema | `.sda/resources/workflow/escalation-brief-schema.md` |
| Workflow state script | `.sda/scripts/workflow/workflow.ps1` or `.sda/scripts/workflow/workflow.sh` |
| Docs integrity script | `.sda/scripts/docs/docs-integrity.ps1` or `.sda/scripts/docs/docs-integrity.sh` |
| Design docs (global) | `docs/` — `architecture.md`, `vocabulary.md`, `index.md`, `decisions/`, `diagrams/` |
| Design docs (per-layer) | `<layer>/docs/` — `architecture.md`, `index.md`, `vocabulary.md`, `decisions/`, `diagrams/` |
| Decision docs (per-layer) | `<layer>/docs/decisions/<feature>/` — `index.md` + descriptive kebab-case `.md` files (`shared/` for cross-cutting) |
| Requirements docs (per-layer) | `<layer>/docs/requirements/` — `index.md` at every level + `<feature>/[<concern>/]<item>.md` + `nfr.md` |

`{language}` values are inferred from project markers — one or more per project (`package.json` → `typescript`, `pyproject.toml` / `requirements.txt` → `python`, etc.). Multi-language projects (e.g. TypeScript frontend + Python backend) load all matching discovery specs and produce a single `project-tools.md` with sections for each area.

### Model configuration

The `models` section in `project-config.json` controls which AI model each agent uses. Keys match agent names directly. Specify model family names without version numbers.

```json
"models": {
  "sda-workflow": "Claude Sonnet",
  "sda-toolscan": "Claude Haiku",
  "sda-tool-installer": "Claude Haiku",
  "sda-ba": "Claude Sonnet",
  "sda-design": "Claude Sonnet",
  "sda-dev-task": "Claude Sonnet",
  "sda-qa-task": "Claude Sonnet",
  "sda-scribe": "Claude Haiku",
  "sda-dev-task-verifier": "Claude Sonnet",
  "sda-code-explore": "Claude Haiku",
  "sda-web-explore": "Claude Haiku",
  "sda-diagram-writer": "Claude Sonnet",
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
| `sda-workflow` | Workflow advisor: container position, next action, `init` (writes the container's `issue.md`) / `escalate` (`advance` on request) | `Claude Sonnet` |
| `sda-toolscan` | Scans project toolchain | `Claude Haiku` |
| `sda-tool-installer` | Installs required development tools (delegated by sda-setup) | `Claude Haiku` |
| `sda-ba` | Authors User Stories from raw requirements | `Claude Sonnet` |
| `sda-design` | System + feature design; owns the doc tree and readmes | `Claude Sonnet` |
| `sda-dev-task` | Designs task specifications | `Claude Sonnet` |
| `sda-qa-task` | Authors the black-box QA acceptance spec | `Claude Sonnet` |
| `sda-scribe` | Universal scribe: task.md, decision docs, design docs, contract specs, manifest.md | `Claude Haiku` |
| `sda-dev-task-verifier` | Consistency + regression checks | `Claude Sonnet` |
| `sda-code-explore` | Fast codebase exploration | `Claude Haiku` |
| `sda-web-explore` | Web research — live API and library docs | `Claude Haiku` |
| `sda-diagram-writer` | Renders Mermaid diagrams to `.md` files | `Claude Sonnet` |
| `sda-dev` | Orchestrates TDD workflow | `Claude Sonnet` |
| `sda-qa` | Runtime acceptance QA | `Claude Sonnet` |
| `sda-test-writer` | Writes tests (RED phase) | `Claude Sonnet` |
| `sda-coder` | Implements production code (GREEN phase) | `Claude Sonnet` |
| `sda-refactor` | Runs the REFACTOR pass (behaviour-preserving) | `Claude Sonnet` |
| `sda-dev-quality` | Runs per-area quality gates | `Claude Haiku` |
| `sda-docs-check` | Verifies docs tree + decision docs + AI-readme routing | `Claude Sonnet` |

**Resolution:** `sda-setup` resolves family names to the latest available versioned model (e.g., `"Claude Sonnet"` → `"Claude Sonnet 4.6 (copilot)"`) and writes the result into each agent's `model:` frontmatter. Re-run sda-setup (or say "update sda") to pick up new model versions.

If the `models` section is absent, the defaults from the table above are applied.

### project-tools.md

Written by `sda-toolscan` on first run. Contains the commands `sda-dev` uses to run tests, check types, lint, measure coverage, run pre-commit hooks, and run specific files. Must exist before the agent proceeds — a missing file triggers a hard stop.

`project-tools.md` always includes an **Area Index** table mapping each area to its language, working directory, and file patterns. Consuming agents use this to resolve which command section applies to a given file.

Consuming agents run the commands exactly as written here — a runner- or script-prefixed command is never rewritten into a direct binary or entry-point call. A bare binary is valid only when this file prescribes one, or when a troubleshooting entry prescribes it for an unfiltered command with a confirmed non-zero exit code.

Commands that are silent on success (type checkers, formatters, linters) are judged by exit code: no output with exit code `0` is a pass. A filtered findings command (lint, coverage, build, pre-merge) with empty output is also a pass — a clean run has nothing to report. A filtered **test** command with empty output is not a pass: its summary line always prints, so report it as unverified without a re-run.

### project-config.json

Written by the `sda-setup` skill. Stores project-level settings injected into each agent's session context at startup via the `SessionStart` hook (`read-config.ps1` / `read-config.sh`). Enable with VS Code setting `chat.useCustomAgentHooks: true`.

| Field | Type | Default | Description |
|---|---|---|---|
| `designOwnership` | `string` | `user` | Who owns the design decision in `sda-design` and `sda-dev-task`. When `user` (default), the agent never volunteers an approach — it pressure-tests the approach **you** propose and hands the decision back to you; it only proposes options when your message explicitly asks for them. When `ai`, the agent may propose the design itself (legacy behaviour). |
| `standardsSkill` | `string` | `standards-compliance` | Name of the skill carrying coding standards. `sda-dev`, `sda-coder`, `sda-refactor`, `sda-test-writer`, and `sda-dev-task` load it before generating code. |
| `paths.specs` | `string` | `.sda/specs` | Root folder for specification files (OpenAPI, JSON Schema, etc.). Written by sda-scribe; read by sda-dev-task and sda-dev-task-verifier. |
| `paths.issues` | `string` | `.sda/issues` | Root folder for standalone QA work (no task): each `<NNN>-<slug>/` holds a `qa-task.md` authored by sda-qa-task and the `qa-report.md` written by sda-qa. |
| `paths.secrets` | `string` | `.sda/secrets` | Git-ignored folder holding `qa.secrets.env` credentials used by sda-qa. |
| `paths.userStories` | `string` | `.sda/stories` | Root folder for User Stories authored by sda-ba. Written by sda-ba when no output path is given. |
| `paths.workflows` | `string` | `.sda/workflows` | Root folder for workflow containers. Read by the `sda-workflow-guide` skill (in workflow sessions) and the `sda-workflow` advisor. |
| `scripts.loadQaSecrets` | `string` | `.sda/scripts/qa/load-qa-secrets.ps1` | Path to the QA secrets loader script (legacy — superseded by `qaSessionInit`). Still used as a fallback when `qaSessionInit` is absent. Use the `.sh` variant on Bash/Unix. |
| `scripts.listQaSecrets` | `string` | `.sda/scripts/qa/list-qa-secrets.ps1` | Path to the QA secrets lister script. Called by sda-qa-task to discover existing credential key names. Use the `.sh` variant on Bash/Unix. |
| `scripts.qaSessionInit` | `string` | `.sda/scripts/qa/qa-session-init.ps1` | Path to the QA session init script. Dot-sourced by sda-qa at Phase 2; sets UTF-8 encoding and loads credentials. Outputs a combined summary and `var_name \| is_empty` table. Use the `.sh` variant on Bash/Unix. |
| `scripts.docsIntegrity` | `string` | `.sda/scripts/docs/docs-integrity.ps1` | Path to the docs-integrity script. Called by sda-docs-check with a decisions/requirements root (links, orphans, duplicates, one-way `.sda/` rule) or a single document path (links, code fence, non-`.md` path). Use the `.sh` variant on Bash/Unix. |
| `scripts.invokeHttp` | `string` | `.sda/scripts/qa/invoke-http.ps1` | Path to the HTTP helper script. Called by sda-qa for every CLI/HTTP request; outputs `STATUS: N` and `BODY: ...`; supports `-StatusOnly` / `--status-only`. Use the `.sh` variant on Bash/Unix. |
| `scripts.unitFileSize` | `string` | `.sda/scripts/dev/unit-file-size.ps1` | Path to the file line-count script. Called by `sda-dev-task` (Phase 6) and `sda-dev-task-verifier` (Check 1) to measure source file volume. Use the `.sh` variant on Bash/Unix. |
| `scripts.workflow` | `string` | `.sda/scripts/workflow/workflow.ps1` | Path to the workflow state script — the only writer of `workflow.json`. Run by the `sda-workflow` advisor (`/sda.workflow.init` · `.status` · `.advance` · `.escalate`), and by the `sda-workflow-guide` skill that stage agents follow in workflow sessions. `escalate` also takes the path of the escalation brief, which must already exist. Use the `.sh` variant on Bash/Unix. |
| `devTaskUnitSizeLimit` | `number` | `1000` | Maximum total lines across existing Source+Test files in any single unit. Units exceeding this limit require splitting in `sda-dev-task`. |
| `tests.coverage.enabled` | `boolean` | `true` | Whether to run coverage checks in Phase 5 (Quality). When disabled, coverage gate is skipped entirely. |

Example:
```json
{
  "scripts": {
    "taskState": ".sda/scripts/dev/task-state.ps1",
    "unitFileSize": ".sda/scripts/dev/unit-file-size.ps1",
    "workflow": ".sda/scripts/workflow/workflow.ps1"
  },
  "devTaskUnitSizeLimit": 1000,
  "designOwnership": "user",
  "standardsSkill": "standards-compliance",
  "paths": {
    "specs": ".sda/specs",
    "issues": ".sda/issues",
    "secrets": ".sda/secrets",
    "userStories": ".sda/stories",
    "workflows": ".sda/workflows"
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

## Tests

Scripts that ship in `skills/sda-setup/assets/` are covered by tests that live **beside the code
they test**, named `_<subject>.Tests.ps1`. Tests never ship: the skill installers prune
`_*.Tests.*` from the installed copy, and none is copied into a project's `.sda/`.

| Test | Covers | Asserts |
|---|---|---|
| `_twins.Tests.ps1` | `assets/workflow/powershell/workflow.ps1` and `assets/workflow/bash/workflow.sh` | One scenario sequence, run against both twins: stdout, exit code, and the written `workflow.json` must match. A few refusals are also checked against the documented contract, not just against each other — a corrupted container must stop `list` without printing a partial list |

The two workflow scripts are one contract with two implementations, and nothing else compares
them, so a change to either can diverge from the other in silence. Run the harness after
editing one:

```powershell
powershell -NoProfile -File tools/sda/skills/sda-setup/assets/workflow/_twins.Tests.ps1
```

It prints `PASS`/`FAIL` and exits 0/1. Its scratch lives in `.test-scratch/workflow-twins/` —
the shared, gitignored test scratch root — and is removed on a green run, so after a failure the
two temp roots and their step-by-step transcripts are still there to inspect. It needs Git Bash
and `jq`, and skips with a message when either is missing.

Covered today: the stage machine and its artifact gate, the per-task `dev` gate, non-`story` start stages and the skipped
prefix, the escalation brief gate, `--to` jumps, displayed open-ness and LIFO unwind,
container-consistency verification, and CLI misuse.

---

## Key design constraints

- **The `sda-setup` skill and `sda-toolscan` agent run once per project, not per task.** Re-run only if the toolchain changes.
- **`sda-design` is read-only.** It researches and decides content, but never edits any file — all writes are delegated to `sda-scribe`.
- **One docs writer.** `sda-coder` and `sda-refactor` never edit docs. A **mechanical** doc change (new entry in an existing format) goes through a `docs` unit → `sda-scribe` (write) → `sda-docs-check` (targeted verify); a **semantic** one (new concept, decision, vocabulary, tree structure, routing) goes through `sda-design`. At most one `docs` unit per task, always last.
- **One owner per planning artifact.** Story → `sda-ba`, design → `sda-design`, tasks → `sda-dev-task`; every other agent is read-only on them. `workflow.json` and `state.json` are written by their scripts only — never hand-edited.
- **`sda-dev` hard-stops if `project-tools.md` is missing.** There is no fallback — run `sda-setup` + `sda-toolscan` first.
- **Standards are mandatory, always.** `sda-dev` reads all standards files before every session — even for trivial fixes or ad-hoc requests.
- **Quality checks are non-negotiable.** After any code change, `sda-dev` must run and pass all quality gates (tests, coverage, pre-merge, types, lint, full test suite) before finishing.
- **Tests must be failing before GREEN begins.** `sda-dev` confirms the RED state before writing production code.
- **Complexity is proportional.** `sda-design` matches design depth to scope — no patterns, abstractions, or architectural discussions for small, single-file changes.
