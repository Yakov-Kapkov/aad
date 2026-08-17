# ai

A collection of reusable AI agents, prompt workflows, skills, and language standards.
Everything here is designed to be dropped into a project and used immediately with GitHub Copilot.

---

## Contents

### [`agents/`](agents/)

Copilot chat agents — invokable by name in the agent panel.

| Agent | Description |
|---|---|
| [`copilot-designer`](.github/agents/copilot-designer.agent.md) | Sole steward of this repo's authored artifacts — agent customization files (agents, skills, prompts, instructions) for any agent environment plus dependent schemas, standards, and docs; enforces separation of orchestration- vs entity-level instructions |
| [`ts-tutor`](agents/ts-tutor/) | TypeScript tutor for .NET and Python developers |
| [`commit`](agents/commit/) | Analyzes working directory changes, composes conventional commit messages, and always commits and pushes. Accepts optional `Session context:` to enrich the message body with the caller's stated intent (pinned to Haiku for fast, cheap execution) |

---

### [`prompts/`](prompts/)

File-based prompt workflows — attach as `#file` references in Copilot chat, no agent
setup required.

| Folder | Description |
|---|---|
| [`prompts/commit/`](prompts/commit/) | Two prompts for the commit agent: `/commit` and `/commit-staged` — both infer session context from the conversation to produce richer commit message bodies |

---

### [`skills/`](skills/)

Reusable skills that extend agent capabilities.

| Skill | Description |
|---|---|
| [`repo-onboarding`](skills/repo-onboarding/README.md) | Generates four onboarding docs for a repo: tooling commands, architecture, summary, and quickstart |
| [`software-design-best-practices`](skills/software-design-best-practices/README.md) | Route-table skill mapping topic areas (web API, database, UI, layers) to language-agnostic design best-practice files — consulted at spec-creation and implementation time |
| [`standards-compliance`](skills/standards-compliance/README.md) | Enforces project coding standards on all produced code changes — resolves conflicts between task specs and standards |
| [`troubleshooting`](skills/troubleshooting/) | Troubleshooting dictionary for unexpected command results — test failures, build errors, lint violations, runtime exceptions |

---

### [`tools/`](tools/)

Multi-agent tool suites.

| Tool | Description |
|---|---|
| [`sda`](tools/sda/README.md) | Software Development Assistant — coordinated agents and skills for specification-driven development (setup skill → init → system → feature → task → qa-spec → dev → qa) |

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

