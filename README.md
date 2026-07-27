# ai

A collection of reusable AI agents, prompt workflows, skills, and language standards.
Everything here is designed to be dropped into a project and used immediately with GitHub Copilot.

---

## Contents

### [`agents/`](agents/)

Copilot chat agents — invokable by name in the agent panel.

| Agent | Description |
|---|---|
| [`copilot-designer`](agents/copilot-designer/) | Sole steward of this repo's authored artifacts — agent customization files (agents, skills, prompts, instructions) for any agent environment plus dependent schemas, standards, and docs; enforces separation of orchestration- vs entity-level instructions |
| [`feature-designer`](agents/feature-designer/) | Researches, designs, and plans features and tasks for development |
| [`system-designer`](agents/system-designer/) | System design assistant — generates and refactors `design.md` and UML diagrams |
| [`tdd-workflow`](agents/tdd-workflow/README.md) | Orchestrates a full TDD lifecycle across focused subagents — research, test writing, implementation, quality audit |
| [`ts-tutor`](agents/ts-tutor/) | TypeScript tutor for .NET and Python developers |
| [`commit`](agents/commit/) | Analyzes working directory changes, composes conventional commit messages, and always commits and pushes. Accepts optional `Session context:` to enrich the message body with the caller's stated intent (pinned to Haiku for fast, cheap execution) |

---

### [`prompts/`](prompts/)

File-based prompt workflows — attach as `#file` references in Copilot chat, no agent
setup required.

| Folder | Description |
|---|---|
| [`prompts/commit/`](prompts/commit/) | Two prompts for the commit agent: `/commit` and `/commit-staged` — both infer session context from the conversation to produce richer commit message bodies |
| [`prompts/tdd/`](prompts/tdd/README.md) | TDD workflow: tool discovery, standards routing, RED/GREEN/REFACTOR cycle with approval gates |

---

### [`skills/`](skills/)

Reusable skills that extend agent capabilities.

| Skill | Description |
|---|---|
| [`repo-onboarding`](skills/repo-onboarding/README.md) | Generates four onboarding docs for a repo: tooling commands, architecture, summary, and quickstart |
| [`standards-compliance`](skills/standards-compliance/README.md) | Enforces project coding standards on all produced code changes — resolves conflicts between task specs and standards |
| [`troubleshooting`](skills/troubleshooting/) | Troubleshooting dictionary for unexpected command results — test failures, build errors, lint violations, runtime exceptions |

---

### [`tools/`](tools/)

Multi-agent tool suites.

| Tool | Description |
|---|---|
| [`sda`](tools/sda/README.md) | Software Development Assistant — coordinated agents and skills for specification-driven development (setup skill → init → system → feature → task → qa-spec → dev → qa) |

---

### [`resources/`](resources/README.md)

Coding standards and tool-discovery specs — used by both the `tdd-workflow`
agents and the `prompts/tdd/` workflow.

| Resource | Contents |
|---|---|
| `resources/common-standards.md` | Language-agnostic coding rules (SOLID, AAA, behavioral testing, constant reuse, etc.) |
| `resources/csharp/` | `tool-discovery.md`, `coding-standards.md`, `testing-standards.md`, `code-style.md` |
| `resources/java/` | `tool-discovery.md`, `coding-standards.md`, `testing-standards.md`, `code-style.md` |
| `resources/postgresql/` | `coding-standards.md`, `code-style.md` |
| `resources/python/` | `tool-discovery.md`, `coding-standards.md`, `testing-standards.md`, `code-style.md` |
| `resources/typescript/` | `tool-discovery.md`, `coding-standards.md`, `testing-standards.md`, `code-style.md` |

---

### [`scripts/`](scripts/)

Installation scripts — available for both PowerShell (Windows) and Bash (macOS/Linux).

Both `install-skill` and `install-tool` support custom install scripts: if
`{source}/scripts/{cli}/install.{ext}` exists, it is invoked instead of the
default copy logic. This enables skills/tools to run custom assembly steps
(e.g. standards-compliance) or accept extra parameters (e.g. model overrides
for SDA agents).

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

## Agent vs prompt workflow

Both `agents/tdd-workflow` and `prompts/tdd` implement the same TDD process. Choose
based on how you work:

| | `agents/tdd-workflow` | `prompts/tdd` |
|---|---|---|
| How to invoke | Agent panel in Copilot Chat | `#file` reference in chat |
| Setup | Copy `resources/{language}` into `.tdd-workflow/` in your project | Copy `resources/{language}` into `standards/` next to the prompt files |
| Orchestration | Dedicated orchestrator agent with strict phase enforcement | Single file routes the assistant |
| Best for | Complex features, teams wanting enforced workflow | Quick use, minimal setup |
