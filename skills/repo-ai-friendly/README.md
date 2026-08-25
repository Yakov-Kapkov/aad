# Repo AI-Friendly — Skill

A Copilot skill that makes a repository navigable for AI agents. It authors
thin routing readmes (`AGENTS.md` / `CLAUDE.md` / `.cursorrules`) and a global
plus per-layer `docs/` tree (architecture, vocabulary, decisions, coding
standards, CLI) — always conversationally, with your approval before it
touches the repo.

---

## Setup

The skill is self-contained — schemas and templates ship inside this folder
and are copied as-is on install.

**PowerShell (Windows):**
```powershell
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "repo-ai-friendly"
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "repo-ai-friendly"
```

Installs to `~/.copilot/skills/repo-ai-friendly/` by default.

---

## Usage

Invoke for any of the three modes:

| Intent | Say |
|---|---|
| New / empty repo | "Make this repo AI-friendly" |
| Existing repo | "Organize this repo's docs" / "Onboard this repo" |
| Docs drifted | "Update the docs after these changes" |

The skill audits before it writes, proposes exact file lists, and waits for
your approval before modifying anything.

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition — conversational workflow, three modes, approval gate |
| `AGENTS.md` | Rules for editing this skill's own files |
| `assets/docs-tree.md` | Canonical global + per-layer folder layout |
| `assets/readme-outline-schema.md` | AI readme + human README outline |
| `assets/docs-index-schema.md` | `index.md` router format (global + layer) |
| `assets/architecture-schema.md` | `architecture.md` format (global + layer) |
| `assets/vocabulary-schema.md` | `vocabulary.md` format (global + layer) |
| `assets/decision-schema.md` | Decision `index.md` + one-decision-per-file format |
| `assets/coding-standards-schema.md` | Coding-standards routing (repo-local or standards skill) |
| `assets/cli-schema.md` | Per-layer command reference format |

---

## Relationship to other skills

- **Coding standards content** — this skill routes the readme's
  "Coding standards" section to `docs/coding-standards/` (repo-local rules)
  or to the [`standards-compliance`](../standards-compliance/) skill when no
  local rules exist. It authors the routing, not the rules themselves.
- **SDA (`tools/sda`)** — `sda-design` / `sda-scribe` load this skill by name
  (`docsSkill`) as their design/decision schema source. SDA adds its own
  workflow schemas (task, qa, toolscan, design report); this skill stays the
  standalone documentation layer with no `.sda/` dependency.
