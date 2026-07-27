# Standards Compliance — Skill

A Copilot skill that enforces language-specific coding, testing, and style rules on every code change. Bundles global standards (C#, Java, Python, TypeScript) and picks up local project overrides automatically. Load it before writing any code.

---

## Setup

Run the install script from the root of this repository. It assembles the skill from two source locations and copies the result into your `.copilot` user folder:

- `skills/standards-compliance/` — the skill definition (`SKILL.md`)
- `resources/{language}/standards/` — the standards files for each language

After install, both live together under `~/.copilot/skills/standards-compliance/standards/`.

**PowerShell (Windows):**
```powershell
.\scripts\powershell\update-standards-compliance.ps1

# Custom target (any folder your IDE loads skills from):
.\scripts\powershell\update-standards-compliance.ps1 -TargetBase "$env:USERPROFILE\.copilot"
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/update-standards-compliance.sh

# Custom target (any folder your IDE loads skills from):
./scripts/bash/update-standards-compliance.sh -t "$HOME/.copilot"
```

Installs to `~/.copilot/skills/standards-compliance/` by default.

---

## Usage

Load before writing code (primary use) so all decisions follow the rules from the start:

```
Implement this task according to coding standards.
```

Or to bring existing code into compliance:

```
Bring this code in compliance with coding standards.
```

Also use when resolving conflicts between a task spec and standards, or to validate code examples in task documents.


### How standards are resolved

1. **Global standards** are read from the `standards/{language}/` folders bundled with this skill.
2. **Local standards** are discovered automatically if the workspace contains its own coding-standards files (referenced by readme files, agent configuration, etc.).
3. When a rule exists in both global and local, **local wins**.

### Scope-specific application

| What you're writing | Standards applied |
|---|---|
| All code | `common-standards.md` (always loaded) |
| Production code | `coding-standards.md` + `code-style.md` |
| Test code | `testing-standards.md` + `code-style.md` |
| Stubs | All production standards |

---

## What's Inside

Standards files **live in `resources/` in this repository** and are assembled into the skill folder on install. After install, the layout under `standards-compliance/` is:

| File / Folder | Source in this repo | Purpose |
|---|---|---|
| `SKILL.md` | `skills/standards-compliance/SKILL.md` | Skill definition — behavioral rules for standards enforcement |
| `standards/common-standards.md` | `resources/common-standards.md` | Language-agnostic rules loaded for every language (SOLID, AAA, unit test scope) |
| `standards/{language}/` | `resources/{language}/standards/` | Language-specific standards files |

Each language folder contains up to three standards files (not all are required):

| File | Scope | Required? |
|---|---|---|
| `coding-standards.md` | Production-code rules (types, error handling, naming, structure) | Yes |
| `testing-standards.md` | Test-code rules (arrange/act/assert, mocking, coverage) | No — omit if N/A (e.g., SQL) |
| `code-style.md` | Style rules (formatting, comments, imports) | Yes |

---

## Adding a New Language

1. Create `resources/{language}/standards/` in this repository with the applicable files:
   - `coding-standards.md` (required)
   - `code-style.md` (required)
   - `testing-standards.md` (only if the language has its own test patterns)
2. Re-run the install script — it auto-discovers all language folders under `resources/` and copies them into the installed skill.
3. The skill will pick up the new language automatically — no changes to `SKILL.md` required.
