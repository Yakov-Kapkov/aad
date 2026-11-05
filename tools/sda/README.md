# SDA — Software Development Assistant

A suite of coordinated AI agents that implement a Specification-Driven Development workflow. Use it to go from a feature idea to tested, standards-compliant code without manually orchestrating each step.

`sda-ba` (optional front-end) turns a raw requirement into a ready User Story — one Actor + Gherkin — that feeds `sda-design`:

```
sda-setup skill  →  sda-ba  →  sda-design  →  sda-dev
(once, skill)       (story)     (design)        (implement)
```

---

## Setup

### 1. Run install script

Installs the **sda-setup** skill, the **sda-workflow-guide** skill, the **sda-spec-guide**
skill, SDA agents, and the
supporting skills — [**CLI Tool Scan**](../../skills/cli-tool-scan/),
[**Standards Compliance**](../../skills/standards-compliance/),
[**Troubleshooting**](../../skills/troubleshooting/),
[**Software Design Best Practices**](../../skills/software-design-best-practices/),
[**Is Repo AI-Friendly**](../../skills/is-repo-ai-friendly/), and
[**Make Repo AI-Friendly**](../../skills/make-repo-ai-friendly/) — into your `.copilot` user folder.

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

The `sda-setup` skill scaffolds `.sda/` with resource files and writes `project-config.json`. Commands come from your repo's own context — the AI readme and the docs it routes to; when nothing is documented, the agents infer from the repo's own files.

---

## Usage

### Plan in a workflow — `/sda.workflow.init`

Planning artifacts live in a **workflow**: a numbered container for one requirement.

```
.sda/workflows/
  001. const-refactoring/
    workflow.json          script-written state (stage + start + escalation log)
    issue.md               entry artifact: container name, artifact paths, issue outline
    assets/                optional: context the user attached (files, text, excerpts)
    user-story.md          owner: sda-ba
    design.md              owner: sda-design
    dev-report.md          owner: sda-dev
    escalations/           one evidence brief per escalation
```

`init` also writes the container's **`issue.md`** — the entry artifact, holding the container
name, the three artifact paths, the issue in the user's own words, and a link to each asset the
user attached: an outline, not a requirements spec, with no design or implementation detail.
Files, text, or excerpts the user attaches are saved under the container's `assets/` folder and
linked from `issue.md`. Every stage starts from it, so the work is never re-stated:
`/sda.workflow.story.issue` (`sda-ba`),
`/sda.workflow.design.issue` (`sda-design`), or `/sda.workflow.dev.issue` (`sda-dev`).

Create one with `/sda.workflow.init`, then start the owning agent on it in its own session. The
`sda-workflow` agent is the advisor surface: it reports where a container sits, names the next
action and its owning agent, and runs `init`, a user-requested `escalate`, and a user-requested
`commit` — delegating the commit to `commit` with links to the workflow's artifacts as the recorded intention, which it reads to ground the message.
The stage machine is `story → design → dev → ready`: `init` starts at `story` by default, or at
`design` / `dev` for pure technical work that has no user-visible change — the stages before the
start are skipped and produce no artifact. `dev` is the single implementation stage: it counts as
complete once `dev-report.md` exists at the container root, so a container cannot reach `ready`
without one. `advance` moves forward exactly one stage, and `escalate` moves back — recording why, plus a **brief** holding the
evidence — when the current stage cannot finish on the artifacts it was given. The script refuses
a raise without a brief, so the blocked stage writes it first (`sda-scribe` numbers and names it);
the target stage reads the brief, then the artifact it cites, renews its own artifact, and closes
the escalation with `resolve`. While an escalation is open, `advance` is refused.

A stage agent works a workflow session by following the **`sda-workflow-guide`** skill: the
stage-entry prompt declares the session and points at it. The skill carries the workflow CLI
(`current`, `read`, `advance`, `escalate`, `resolve`), the stage gate, and the
finish/escalate/resolve steps, plus one stage card per stage naming its artifact, input, and
escalation targets — so the producers' own files
carry none of that, just a dispatch line and the escalation-evidence rule. The `sda-workflow` advisor owns `init`, and may raise a user-requested
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

### Implement — `sda-dev`

```
Implement the order-list endpoint.
```

For quick, one-off changes:

```
Fix the bug where createOrder throws when quantity is 0.
```

`sda-dev` orchestrates the TDD loop (RED → GREEN → refactor) and owns quality checks. It delegates test writing, coding, refactoring, and gate execution to subagents to keep each context small and reasoning sharp.

With a workflow container, start it from the container's `issue.md` with `/sda.workflow.dev.issue`
— that session follows the `sda-workflow-guide` skill and writes the container's `dev-report.md`.
The container advances to `ready` only once that report exists.

### Design — `sda-design`

> Requires `full` install mode.

One agent, any altitude — judged from what is being discussed:

- **Whole-system work** — new app/platform, service boundaries, conventions, vocabulary:
  ```
  Design the architecture for the notification subproject.
  ```
  Discovers the repo's subprojects via `sda-code-explore`, then delegates the
  global `docs/` (architecture, vocabulary, index, conventions, adrs,
  diagrams) + one `docs/` per subproject, the
  readme outlines (AI readme + human README each), and a spec file for every
  boundary it documents — to `sda-scribe`.
- **Feature work** — a specific feature or bounded context:
  ```
  Design a feature for paginated order listing filtered by status.
  ```
  Records conventions and ADRs, updates the features section of all readmes, writes a spec
  file for every boundary the feature crosses, and writes the design record
  (`design.md`).

`sda-design` is conversational. By default it pressure-tests the design **you** propose rather than authoring it — describe the area you're tackling, defend your direction against its push-back on complexity and risk, and iterate together before committing. (Configurable via `designOwnership` — see [project-config.json](#project-configjson).) At the end of every session it writes the design record, `design.md` — inside the workflow folder when the requirement has one, otherwise under `.sda/design/reports/<yyyy-MM-dd_HH-mm_<name>>/` — so the next agent reads a compact record instead of the full conversation.

### Author the QA acceptance spec — `sda-qa-task`

`sda-qa-task` writes the black-box `qa-task.md` that `sda-qa` verifies. Invoke it
directly to spec **existing** behaviour:

```
Author a QA spec to verify the order-list page shows new orders after creation.
```

It translates user-observable acceptance intent into reachable, black-box
functional requirements — never DOM- or implementation-level assertions — and
delegates the file write to `sda-scribe`. Specs live under `.sda/issues/`.

### Verify acceptance — `sda-qa`

`sda-qa` verifies a running application against a `qa-task.md` (its black-box
spec of functional requirements). It is always invoked by you — never by
another agent. First author the spec with
[`sda-qa-task`](#author-the-qa-acceptance-spec--sda-qa-task), then run the
verification:

```
QA the order-list spec.
```

`sda-qa` starts the app, drives a real browser/CLI through the functional
requirements, and writes a `qa-report.md` (beside the spec) with per-requirement
PASS/FAIL and evidence. It is read-only on source code and never fixes what it
finds — it reports, and leaves routing to you.

---

## Agents

### Pipeline agents

| Agent | Role | Model | Tools |
|---|---|---|---|
| `sda-ba` | Business Analyst — elicits a raw requirement into one ready User Story (Actor + Gherkin + measurable NFRs) and owns the durable requirements tree, gated by the Definition of Ready | Claude Sonnet 5 | read, search, agent, edit, execute |
| `sda-design` | System architecture + feature design — components, contracts, diagrams, convention + ADR docs | Claude Sonnet 5 | read, search, agent, execute |
| `sda-qa-task` | Authors the black-box acceptance spec (`qa-task.md`) for existing behaviour | Claude Sonnet 5 | read, search, execute, agent |
| `sda-dev` | TDD implementation orchestrator — delegates RED/GREEN to subagents to keep context small; routes `docs` units to sda-scribe + sda-docs-check; owns the workflow's `dev` stage | project config | read, execute, agent |
| `sda-qa` | Runtime acceptance QA — starts the app, drives a real browser/CLI through the functional requirements, writes `qa-report.md` (read-only on source) | Claude Sonnet 5 | read, edit, search, execute, browser |
| `sda-workflow` | Workflow advisor surface — reports where a container sits, names the single next action and its owner, owns `init`, a user-requested escalation, and a user-requested commit (delegated to `commit` with links to the workflow's artifacts), and delegates the escalation brief to sda-scribe. Never triggers a producer, never resolves an escalation | Claude Sonnet 5 | read, edit, agent, execute |

### Subagents (invoked by pipeline agents)

| Agent | Role | Model | Tools |
|---|---|---|---|
| `sda-scribe` | Universal scribe: writes qa-task.md, dev-report.md, convention + ADR docs, design docs, requirements docs, design records, contract specs, manifest.md, and the files of a `docs` unit | Claude Haiku 4.5 | read, edit, search |
| `sda-code-explore` | Fast read-only codebase exploration (invoked by sda-qa-task, sda-dev, sda-design) | Claude Haiku 4.5 | read, search |
| `sda-web-explore` | Web research — fetches live API docs and library specs (invoked by sda-design) | Claude Haiku 4.5 | web |
| `sda-test-writer` | Writes tests for TDD slices (RED) and tests-only slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-coder` | Implements production code (GREEN) and integration slices. Mechanical worker: makes domain decisions within the assigned unit; stops and reports anything outside scope. | project config | read, edit, search, execute |
| `sda-refactor` | Runs the REFACTOR pass without changing behaviour: per-unit (refactors the code each unit added or modified) plus a final cross-unit duplication pass; reverts any change that breaks a test. | project config | read, edit, search, execute |
| `sda-dev-quality` | Runs quality gates (types, lint, tests, coverage, build, pre-merge) in **local** (target files) or **global** (whole scope) mode. Check-and-report only — never fixes. Invoked by sda-dev (Phase 5, global) or standalone. | Claude Haiku 4.5 | execute |
| `sda-docs-check` | Verifies the docs tree (global + per-subproject) + convention/ADR-doc integrity + drift and AI-readme routing (AGENTS.md/CLAUDE.md links, feature list) against reality. Full scope, or targeted on a `docs` unit's files. Check-and-report only — never fixes. Invoked by sda-design and sda-dev. | Claude Sonnet 5 | read, search, execute, agent |
| `sda-diagram-writer` | Renders Mermaid diagrams from structured `DIAGRAM` blocks into `.md` files, returning the written path. Invoked by sda-design. | Claude Sonnet 5 | edit |


**Model configuration:** Implementation agents use models from `project-config.json`. Default: Claude Sonnet. Run sda-setup (or say "update sda") to resolve family names and apply to agent files. See [Model configuration](#model-configuration).

`sda-dev` orchestrates the TDD loop and owns quality checks, delegating test writing, coding, refactoring, and gate execution to subagents to keep each context small. A `docs` unit routes to `sda-scribe` (write) and then `sda-docs-check` (targeted verification).

`sda-scribe` is the universal scribe for SDA planning and implementation agents — it writes qa-task.md, dev-report.md, convention + ADR docs, design docs, requirements docs, design records, contract spec files, and manifest.md. It uses Haiku for cost efficiency since it performs no reasoning — only schema formatting and file I/O. `sda-code-explore` is invoked by `sda-qa-task`, `sda-dev`, and `sda-design` for codebase research — also Haiku, since it only reads and reports. `sda-web-explore` is invoked by `sda-design` for live web/API research when documentation may have changed.

All pipeline agents are user-invokable and used as needed.

### Skills

| Skill | Role |
|---|---|
| `sda-setup` | Scaffolds `.sda/` folder with resource files — schemas, scripts, and config example |
| `sda-workflow-guide` | Workflow-mode operating instructions for stage agents — the workflow CLI, the stage gate, finish/escalate/resolve steps, and one stage card per producer |
| `sda-spec-guide` | Contract spec conventions — the spec model, storage layout, metadata, and content rules |

### Prompts

| Prompt | Role |
|---|---|
| `sda.qa.session-run` | Triggers sda-qa agent — runs QA verification |
| `sda.qa.task-create` | Triggers sda-qa-task agent — creates a QA spec |
| `sda.setup` | Sets up SDA tool — scaffolds `.sda/` and writes `project-config.json` |
| `sda.design.reconcile` | Reconciles design docs with code — finds and fixes inconsistencies across the AI readme, global + per-subproject docs, and convention + ADR docs |
| `sda.workflow.init` | Creates a workflow container for one requirement, saves any attached assets, then names the start stage's session to run |
| `sda.workflow.status` | Reports where the workflow containers sit, ending with the single next action and the agent that owns it |
| `sda.workflow.advance` | Moves a workflow forward one stage, after showing the state and confirming |
| `sda.workflow.escalate` | Sends a workflow back a stage — elicits what is wrong, writes the evidence brief, then raises |
| `sda.workflow.handle-escalation` | Handles the open escalation in the current session — the escalated-to stage agent runs its resolve steps |
| `sda.workflow.story.issue` | Starts the story stage from the container's `issue.md` — switches to the sda-ba agent |
| `sda.workflow.design.issue` | Starts the design stage from the container's `issue.md` — switches to the sda-design agent |
| `sda.workflow.dev.issue` | Starts the dev stage from the container's `issue.md` — switches to the sda-dev agent |

---

## Workflow phases

```
INIT  (once per project)
  sda-setup scaffolds .sda/ and writes .sda/project-config.json.
  Commands are read at run time from the repo's own context.

sda-dev execution — phases 0–6 (per sda-dev.agent.md)

PHASE 0 — BOOTSTRAP  (once per conversation)
  Retains shell + project config from session context; detects mode.
  Workflow: works from the container's design.md.
  Ad-hoc: delegates exploration, then derives the work unit.

PHASE 1 — PLAN  (per unit)
  Derives the work unit; routes by unit type — RED, GREEN,
  REFACTOR, or DOCS.

PHASE 2 — RED
  Delegates test writing to sda-test-writer.
  Presents the RED gate — new tests fail, pre-existing tests pass.

PHASE 3 — GREEN
  Delegates implementation to sda-coder until all tests pass.
  Presents the GREEN gate.

PHASE 3·D — DOCS  (`docs` unit)
  Delegates the doc files to sda-scribe (full content or anchored delta),
  then verifies them against the code with sda-docs-check (targeted scope).
  No RED, no GREEN, no refactor, no quality gates.

PHASE 4 — REFACTOR
  Delegates each unit's files to sda-refactor as it completes (per-unit);
  after all units, a thin cross-unit pass removes inter-unit duplication.

PHASE 5 — QUALITY CHECKS
  Delegates quality gates to sda-dev-quality in global mode — gates run per project scope.
  Presents per-scope results.

PHASE 6 — FINALIZE  (workflow mode)
  Delegates dev-report.md (what was built + issues encountered + follow-up opportunities) to sda-scribe.
  QA is not part of this phase — you invoke sda-qa yourself afterwards
  (see "Verify acceptance — sda-qa").
```

### Mode routing (sda-dev)

| Invocation | Mode | Behaviour |
|---|---|---|
| The request names a workflow container, or its entry prompt declares one | `workflow` | Full TDD workflow — RED → GREEN → refactor → quality checks — writing `<wf>/dev-report.md` |
| Any other coding request | `ad-hoc` | Implement directly — standards and quality checks still enforced |

---

## Configuration

All resources are read from a `.sda/` folder in the project root (may be git-ignored). Agents always use exact literal paths — they never search for these files.

| Resource | Path |
|---|---|
| Project config | `.sda/project-config.json` |
| Project config reference | `.sda/project-config.reference.yml` |
| User Story schema | `.sda/resources/ba/user-story-schema.md` |
| User Story | `.sda/stories/<slug>/user-story.md` |
| QA acceptance spec | `.sda/issues/<NNN>-<slug>/qa-task.md` |
| QA report | `.sda/issues/<NNN>-<slug>/qa-report.md` |
| QA credentials | `.sda/secrets/qa.secrets.env` (git-ignored) |
| Config injection script | `.sda/scripts/read-config.ps1` or `.sda/scripts/read-config.sh` |
| Design + convention + ADR + requirements schemas | `{docsSkill}` skill (`make-repo-ai-friendly`) — load it by name; its `SKILL.md` routes to the readme-outline, docs-index, architecture, vocabulary, requirements, convention, ADR, coding-standards, and docs-map schemas |
| AI-friendliness artifact list + link checker | `is-repo-ai-friendly` skill — load it by name; `SKILL.md` holds the artifact list, and `assets/scripts/check-links.*` resolves links |
| Design record schema | `.sda/resources/design/design-record-schema.md` |
| Design record (workflow) | `.sda/workflows/<NNN>. <slug>/design.md` |
| Design record (standalone) | `.sda/design/reports/<yyyy-MM-dd_HH-mm_<short-name>>/design.md` |
| Workflow container | `.sda/workflows/<NNN>. <slug>/` |
| Workflow state | `.sda/workflows/<NNN>. <slug>/workflow.json` |
| Workflow entry artifact | `.sda/workflows/<NNN>. <slug>/issue.md` |
| Workflow assets | `.sda/workflows/<NNN>. <slug>/assets/` — context the user attached at init |
| Dev report (workflow) | `.sda/workflows/<NNN>. <slug>/dev-report.md` — the `dev` stage's artifact |
| Escalation brief | `.sda/workflows/<NNN>. <slug>/escalations/<NNN>. <yyyy-MM-dd_HH-mm>-<from>-to-<to>.md` |
| Workflow schema | `.sda/resources/workflow/workflow-schema.md` |
| Escalation brief schema | `.sda/resources/workflow/escalation-brief-schema.md` |
| Workflow state script | `.sda/scripts/workflow/workflow.ps1` or `.sda/scripts/workflow/workflow.sh` |
| Link checker | `check-links` in the `is-repo-ai-friendly` skill — links resolve; `-NoFence`, `-NoPathToken`, `-Forbid` |
| Tree checker | `check-tree` in the `{docsSkill}` skill — `index.md` routing, orphan, duplicate row |
| Design docs (global) | `docs/` — `architecture.md`, `vocabulary.md`, `index.md`, `conventions/`, `adrs/`, `diagrams/` |
| Design docs (per-subproject) | `<subproject>/docs/` — `architecture.md`, `index.md`, `vocabulary.md`, `conventions/`, `adrs/`, `diagrams/` |
| Convention docs (per-subproject) | `<subproject>/docs/conventions/<feature>/` — `index.md` + descriptive kebab-case `.md` files (`shared/` for cross-cutting) |
| ADR docs (per-subproject) | `<subproject>/docs/adrs/<feature>/` — `index.md` + descriptive kebab-case `.md` files (`shared/` for cross-cutting) |
| Requirements docs (per-subproject) | `<subproject>/docs/requirements/` — `index.md` at every level + `<feature>/[<concern>/]<item>.md` + `nfr.md` |

On macOS/Linux, `setup.sh` marks every `*.sh` it copies into `.sda/scripts/` executable, so the
workflow CLI (`{workflow}`) and every script run by path is invoked by its raw relative path — never
with a `bash`/`sh`/`zsh` prefix. The only `bash`-prefixed invocations are the per-agent frontmatter
hooks, the installers, and third-party executables.

### Model configuration

The `models` section in `project-config.json` controls which AI model each agent uses. Keys match agent names directly. Specify model family names without version numbers.

```json
"models": {
  "sda-workflow": "Claude Sonnet",
  "sda-ba": "Claude Sonnet",
  "sda-design": "Claude Sonnet",
  "sda-qa-task": "Claude Sonnet",
  "sda-scribe": "Claude Haiku",
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
| `sda-workflow` | Workflow advisor: container position, next action, `init` (writes `issue.md` + attached `assets/`) / `escalate` / `commit` (`advance` on request) | `Claude Sonnet` |
| `sda-ba` | Authors User Stories from raw requirements | `Claude Sonnet` |
| `sda-design` | System + feature design; owns the doc tree and readmes | `Claude Sonnet` |
| `sda-qa-task` | Authors the black-box QA acceptance spec | `Claude Sonnet` |
| `sda-scribe` | Universal scribe: qa-task.md, dev-report.md, convention + ADR docs, design docs, contract specs, manifest.md | `Claude Haiku` |
| `sda-code-explore` | Fast codebase exploration | `Claude Haiku` |
| `sda-web-explore` | Web research — live API and library docs | `Claude Haiku` |
| `sda-diagram-writer` | Renders Mermaid diagrams to `.md` files | `Claude Sonnet` |
| `sda-dev` | Orchestrates TDD workflow | `Claude Sonnet` |
| `sda-qa` | Runtime acceptance QA | `Claude Sonnet` |
| `sda-test-writer` | Writes tests (RED phase) | `Claude Sonnet` |
| `sda-coder` | Implements production code (GREEN phase) | `Claude Sonnet` |
| `sda-refactor` | Runs the REFACTOR pass (behaviour-preserving) | `Claude Sonnet` |
| `sda-dev-quality` | Runs per-scope quality gates | `Claude Haiku` |
| `sda-docs-check` | Verifies docs tree + convention/ADR docs + AI-readme routing | `Claude Sonnet` |

**Resolution:** `sda-setup` resolves family names to the latest available versioned model (e.g., `"Claude Sonnet"` → `"Claude Sonnet 5 (copilot)"`) and writes the result into each agent's `model:` frontmatter. Re-run sda-setup (or say "update sda") to pick up new model versions.

If the `models` section is absent, the defaults from the table above are applied.

### Where checks come from

Agents run the repository's own checks. Each phase and gate reports pass/fail;
a check the repo does not provide is reported `❌ unable to verify`.

### project-config.json

Written by the `sda-setup` skill. Stores project-level settings injected into each agent's session context at startup via the `SessionStart` hook (`read-config.ps1` / `read-config.sh`). Enable with VS Code setting `chat.useCustomAgentHooks: true`.

| Field | Type | Default | Description |
|---|---|---|---|
| `designOwnership` | `string` | `user` | Who owns the design decision in `sda-design`. When `user` (default), the agent never volunteers an approach — it pressure-tests the approach **you** propose and hands the decision back to you; it only proposes options when your message explicitly asks for them. When `ai`, the agent may propose the design itself (legacy behaviour). |
| `standardsSkill` | `string` | `standards-compliance` | Name of the skill carrying coding standards. `sda-dev`, `sda-coder`, `sda-refactor`, and `sda-test-writer` load it before generating code. |
| `docsSkill` | `string` | `make-repo-ai-friendly` | Name of the skill carrying the docs-map schema, the default tree profile, and the doc schemas. Loaded by `sda-design`, `sda-scribe`, `sda-ba`, and `sda-docs-check`. |
| `paths.specs` | `string` | `.sda/specs` | Root folder for specification files (OpenAPI, JSON Schema, etc.). Written by sda-scribe — `sda-design` creates specs, a `docs` unit amends an existing one. Read by sda-design, sda-qa-task, and sda-docs-check. |
| `paths.issues` | `string` | `.sda/issues` | Root folder for QA specs: each `<NNN>-<slug>/` holds a `qa-task.md` authored by sda-qa-task and the `qa-report.md` written by sda-qa. |
| `paths.secrets` | `string` | `.sda/secrets` | Git-ignored folder holding `qa.secrets.env` credentials used by sda-qa. |
| `paths.userStories` | `string` | `.sda/stories` | Root folder for User Stories authored by sda-ba. Written by sda-ba when no output path is given. |
| `paths.workflows` | `string` | `.sda/workflows` | Root folder for workflow containers. Read by the `sda-workflow-guide` skill (in workflow sessions) and the `sda-workflow` advisor. |
| `scripts.loadQaSecrets` | `string` | `.sda/scripts/qa/load-qa-secrets.ps1` | Path to the QA secrets loader script (legacy — superseded by `qaSessionInit`). Still used as a fallback when `qaSessionInit` is absent. Use the `.sh` variant on Bash/Unix. |
| `scripts.listQaSecrets` | `string` | `.sda/scripts/qa/list-qa-secrets.ps1` | Path to the QA secrets lister script. Called by sda-qa-task to discover existing credential key names. Use the `.sh` variant on Bash/Unix. |
| `scripts.qaSessionInit` | `string` | `.sda/scripts/qa/qa-session-init.ps1` | Path to the QA session init script. Dot-sourced by sda-qa at Phase 2; sets UTF-8 encoding and loads credentials. Outputs a combined summary and `var_name \| is_empty` table. Use the `.sh` variant on Bash/Unix. |
| `docsCheck.enabled` | `boolean` | `true` | Turns `sda-docs-check` off for a repo whose docs must not be maintained or verified. When false the agent reports `docs-check disabled` and runs nothing. |
| `scripts.invokeHttp` | `string` | `.sda/scripts/qa/invoke-http.ps1` | Path to the HTTP helper script. Called by sda-qa for every CLI/HTTP request; outputs `STATUS: N` and `BODY: ...`; supports `-StatusOnly` / `--status-only`. Use the `.sh` variant on Bash/Unix. |
| `scripts.workflow` | `string` | `.sda/scripts/workflow/workflow.ps1` | Path to the workflow state script — the only writer of `workflow.json`. Run by the `sda-workflow` advisor (`/sda.workflow.init` · `.status` · `.advance` · `.escalate`), and by the `sda-workflow-guide` skill that stage agents follow in workflow sessions. `escalate` also takes the path of the escalation brief, which must already exist. Use the `.sh` variant on Bash/Unix. |
| `tests.coverage.enabled` | `boolean` | `true` | Whether to run coverage checks in Phase 5 (Quality). When disabled, coverage gate is skipped entirely. |

Example:
```json
{
  "scripts": {
    "loadQaSecrets": ".sda/scripts/qa/load-qa-secrets.ps1",
    "workflow": ".sda/scripts/workflow/workflow.ps1"
  },
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

Loaded by the code-producing agents — `sda-test-writer`, `sda-coder`, and `sda-refactor` — from the `standardsSkill` name `sda-dev` passes in every delegation, before any code is written. Every rule is treated as mandatory; there are no optional guidelines.

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

Covered today: the stage machine and its artifact gate, the `dev` gate over the container's `dev-report.md`, non-`story` start stages and the skipped
prefix, the escalation brief gate, `--to` jumps, displayed open-ness and LIFO unwind,
container-consistency verification, and CLI misuse.

---

## Key design constraints

- **The `sda-setup` skill runs once per project, not per change.** Re-run it to refresh config or scripts.
- **`sda-design` is read-only.** It researches and decides content, but never edits any file — all writes are delegated to `sda-scribe`.
- **One docs writer.** `sda-coder` and `sda-refactor` never edit docs. A **mechanical** doc change (new entry in an existing format) goes through a `docs` unit → `sda-scribe` (write) → `sda-docs-check` (targeted verify); a **semantic** one (new concept, convention, ADR, vocabulary, tree structure, routing) goes through `sda-design`. At most one `docs` unit per session, last in the route.
- **One owner per planning artifact.** Story → `sda-ba`, design → `sda-design`, dev report → `sda-dev`; every other agent is read-only on them. `workflow.json` is written by its script only — never hand-edited.
- **One spec creator.** `sda-design` creates a spec for every boundary a feature crosses, before implementation begins; implementation may only amend an existing spec through a `docs` unit, never create one. A missing spec hard-stops implementation.
- **An undocumented command is reported `❌ unable to verify`.** Never invent a substitute.
- **Standards are mandatory, always.** Every code-producing agent loads the `standardsSkill` skill before writing — `sda-dev` passes the skill name in every delegation, even for trivial fixes or ad-hoc requests.
- **Quality checks are non-negotiable.** After any code change, all quality gates (tests, coverage, pre-merge, types, lint, full test suite) must run and pass before finishing. `sda-dev` delegates them to `sda-dev-quality` (Phase 5) and never runs a gate itself.
- **Tests must be failing before GREEN begins.** `sda-dev` presents the RED gate — new tests fail, pre-existing tests pass — before delegating GREEN to `sda-coder`.
- **Complexity is proportional.** `sda-design` matches design depth to scope — no patterns, abstractions, or architectural discussions for small, single-file changes.
