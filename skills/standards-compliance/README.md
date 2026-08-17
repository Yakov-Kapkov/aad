# Standards Compliance — Skill

A Copilot skill that enforces language-specific coding, testing, and style rules on every code change. Bundles global standards (C#, Java, Python, TypeScript) and picks up local project overrides automatically. Load it before writing any code.

---

## Setup

The skill is self-contained — the standards files ship inside this folder and
are copied as-is on install. Install it with the dev-suite installer or on its own.

**PowerShell (Windows):**
```powershell
# Install the full dev suite (SDA tool + all skills, including this one)
.\scripts\powershell\install-dev-suite.ps1

# Install only this skill
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "standards-compliance"
```

**Bash (macOS / Linux):**
```bash
# Install the full dev suite
./scripts/bash/install-dev-suite.sh

# Install only this skill
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "standards-compliance"
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

The skill is self-contained — all files below live in this folder and are copied
as-is on install:

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition — behavioral rules for standards enforcement |
| `AGENTS.md` | Rules for editing the standards files (cross-language sync, section order) |
| `standards/common-standards.md` | Language-agnostic rules loaded for every language (SOLID, AAA, unit test scope) |
| `standards/{language}/` | Language-specific standards files |
| `standards/README.md` | Human index — quick navigation, decision tree, per-file summaries |

Each language folder contains up to three standards files (not all are required):

| File | Scope | Required? |
|---|---|---|
| `coding-standards.md` | Production-code rules (types, error handling, naming, structure) | Yes |
| `testing-standards.md` | Test-code rules (arrange/act/assert, mocking, coverage) | No — omit if N/A (e.g., SQL) |
| `code-style.md` | Style rules (formatting, comments, imports) | Yes |

---

## Adding a New Language

1. Create `standards/{language}/` in this skill with the applicable files:
   - `coding-standards.md` (required)
   - `code-style.md` (required)
   - `testing-standards.md` (only if the language has its own test patterns)
2. Follow the section order in `AGENTS.md` and reuse rule text from an existing language — change only code examples.
3. Re-run the install script — the skill folder (including the new language) is copied as-is.
4. The skill will pick up the new language automatically — no changes to `SKILL.md` required.
