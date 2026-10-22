# Make Repo AI-Friendly — Skill

A Copilot skill that makes a repository AI-friendly — easy to read, maintain,
and navigate. It authors
thin routing readmes (`AGENTS.md` / `CLAUDE.md` / `.cursorrules`) and a docs
tree (architecture, vocabulary, testing, deployment, operations, requirements,
design conventions, ADRs, coding standards, commands, run instructions, the docs declaration),
adapting the tree to whatever the repo declares — always conversationally, with
your approval before it touches the repo.

It loads the [`is-repo-ai-friendly`](../is-repo-ai-friendly/) skill for the
criteria and the link checker.

---

## Setup

The skill is self-contained — schemas and templates ship inside this folder
and are copied as-is on install.

**PowerShell (Windows):**
```powershell
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "make-repo-ai-friendly"
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "make-repo-ai-friendly"
```

Installs to `~/.copilot/skills/make-repo-ai-friendly/` by default.

---

## Usage

Invoke for any of the three modes:

| Intent | Say |
|---|---|
| New / empty repo | "Make this repo AI-friendly" |
| Existing repo | "Organize this repo's docs" / "Onboard this repo" |
| Docs drifted | "Update the docs after these changes" |

The skill assesses before it writes, proposes exact file lists, and waits for
your approval before modifying anything. It never imposes the default tree on
a repo that declares its own layout.

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition — criteria reference, scope, three modes, workflow, report, acceptance criteria |
| `AGENTS.md` | Rules for editing this skill's own files |
| `assets/docs-tree.md` | Default root + per-subproject layout, and where each artifact lives — a proposal, not a requirement |
| `assets/docs-map-schema.md` | Docs map declaration — layout, naming, omissions, housekeeping |
| `assets/readme-outline-schema.md` | AI readme + human README outline |
| `assets/docs-index-schema.md` | `index.md` router format (root + subproject) |
| `assets/architecture-schema.md` | `architecture.md` format (root + subproject) |
| `assets/vocabulary-schema.md` | `vocabulary.md` format (root + subproject) — terms a newcomer would guess wrong |
| `assets/convention-schema.md` | Convention tree — per-level `index.md` + one-convention-per-file format |
| `assets/adr-schema.md` | ADR tree — per-level `index.md` + one-decision-per-ADR format |
| `assets/requirements-schema.md` | Requirements tree — per-level `index.md`, `<feature>/[<concern>/]<item>.md`, `nfr.md` |
| `assets/coding-standards-schema.md` | Coding-standards routing (repo-local or standards skill) |
| `assets/cli-schema.md` | Per-level command reference — bootstrap, commands, the pre-merge gate |
| `assets/testing-schema.md` | `testing.md` format — strategy, test cases, smoke tests, not-covered |
| `assets/deployment-schema.md` | `deployment.md` format — pipeline, environments, triggers |
| `assets/operations-schema.md` | `operations.md` format — health, logs, metrics, rollback |
| `assets/scripts/check-tree.ps1` | Default-profile tree checker (PowerShell) — broken link, duplicate row, orphan |
| `assets/scripts/check-tree.sh` | Default-profile tree checker (Bash) |
| `assets/scripts/_check-tree.Tests.ps1` | Differential twin test — dev-only, pruned on install |

---

## Relationship to other skills

- **Coding standards content** — this skill routes the readme's
  "Coding standards" section to `docs/coding-standards/` (repo-local rules)
  or to the [`standards-compliance`](../standards-compliance/) skill when no
  local rules exist. It authors the routing, not the rules themselves.
- **`is-repo-ai-friendly`** — the criteria and the model-free link checker.
  This skill loads it; it never loads this skill. Assessment reports come from
  it, and this skill applies the fixes.
