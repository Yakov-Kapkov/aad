# ai

A collection of reusable AI agents, prompt workflows, skills, and language standards.
Everything here is designed to be dropped into a project and used immediately with GitHub Copilot.

---

## Contents

### [`agents/`](agents/)

Copilot chat agents — invokable by name in the agent panel.

| Agent | Description |
|---|---|
| [`repo-author`](.github/agents/repo-author.agent.md) | Sole authoring agent for this repo's artifacts — agents, skills, prompts, instructions, plus dependent schemas, standards, docs, and scripts; applies prompt-engineering craft and enforces separation of orchestration- vs entity-level instructions |
| [`ts-tutor`](agents/ts-tutor/) | TypeScript tutor for .NET and Python developers |
| [`commit`](agents/commit/) | Analyzes working directory changes, composes conventional commit messages, and always commits and pushes. An optional `Session context:` governs the message; the agent decides single commit vs. split itself (pinned to Haiku for fast, cheap execution) |

---

### [`prompts/`](prompts/)

File-based prompt workflows — attach as `#file` references in Copilot chat, no agent
setup required.

| Folder | Description |
|---|---|
| [`prompts/commit/`](prompts/commit/) | Two prompts for the commit agent: `/commit` and `/commit-staged` — both infer session context from the conversation to govern the commit message |
| [`anything-else`](.github/prompts/anything-else.prompt.md) | End-of-task completeness review — prompts the agent to catch anything forgotten (dependents, docs, cleanup) before finishing |

---

### [`skills/`](skills/)

Reusable skills that extend agent capabilities.

| Skill | Description |
|---|---|
| [`repo-ai-friendly`](skills/repo-ai-friendly/README.md) | Makes a repository AI-friendly — authors routing readmes (AGENTS.md/CLAUDE.md) and a global + per-layer docs/ tree (architecture, vocabulary, requirements, decisions, coding standards, CLI) |
| [`software-design-best-practices`](skills/software-design-best-practices/README.md) | Route-table skill mapping topic areas (web API, database, UI, layers) to language-agnostic design best-practice files — consulted at spec-creation and implementation time |
| [`standards-compliance`](skills/standards-compliance/README.md) | Enforces project coding standards on all produced code changes — resolves conflicts between task specs and standards |
| [`troubleshooting`](skills/troubleshooting/) | Troubleshooting dictionary for unexpected command results — test failures, build errors, lint violations, runtime exceptions |

---

### [`tools/`](tools/)

Multi-agent tool suites.

| Tool | Description |
|---|---|
| [`sda`](tools/sda/README.md) | Software Development Assistant — coordinated agents and skills for specification-driven development (sda-ba user story → setup → design → task → qa-spec → dev → qa). Planning artifacts live in numbered workflow containers (`.sda/workflows/<NNN>. <slug>/`) whose stage is held by a state script and run by the `sda-workflow` advisor |

---

Language standards ship with the [`standards-compliance`](skills/standards-compliance/README.md)
skill — `standards/common-standards.md` plus `standards/{language}/`. Toolchain specs
(`tool-discovery.md`, `tool-catalog.md`) ship with the
[`sda-setup`](tools/sda/skills/sda-setup/) skill.

---

### [`scripts/`](scripts/)

Installation scripts — available for both PowerShell (Windows) and Bash (macOS/Linux).

Both `install-skill` and `install-tool` support custom install scripts: if
`{source}/_installation/{cli}/install.{ext}` exists, it is invoked instead of the
default copy logic. This enables skills/tools to run custom assembly steps
or accept extra parameters (e.g. model overrides for SDA agents).

#### [`scripts/powershell/`](scripts/powershell/)

| Script | Description |
|---|---|
| `install-dev-suite.ps1` | Installs or uninstalls the dev suite (SDA tool + all skills) |
| `install-skill.ps1` | Installs a skill (delegates to custom script if present) |
| `install-tool.ps1` | Installs a tool (delegates to custom script if present) |

#### [`scripts/bash/`](scripts/bash/)

| Script | Description |
|---|---|
| `install-dev-suite.sh` | Installs or uninstalls the dev suite (SDA tool + all skills) |
| `install-skill.sh` | Installs a skill (delegates to custom script if present) |
| `install-tool.sh` | Installs a tool (delegates to custom script if present) |

---

