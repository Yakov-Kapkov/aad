# Is Repo AI-Friendly — Skill

A Copilot skill that defines what makes a repository AI-friendly and assesses
every subproject of a repo against that list, one artifact at a time. Read-only — it
reports, it never writes.

AI-friendly means **easy to read, maintain, onboard onto, and change** — not
only navigable. The docs must hand an agent a working table of contents.

The list is **name-free**: no folder, filename, or tool is prescribed. A repo
qualifies with any layout that exposes the artifacts.

---

## Setup

The skill is self-contained — criteria and scripts ship inside this folder and
are copied as-is on install.

**PowerShell (Windows):**
```powershell
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "is-repo-ai-friendly"
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "is-repo-ai-friendly"
```

Installs to `~/.copilot/skills/is-repo-ai-friendly/` by default.

---

## Usage

| Intent | Say |
|---|---|
| Whole repo | "Is this repo AI-friendly?" / "Audit our docs" |
| Specific files | "Check whether these docs are AI-friendly" + paths |

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | The artifact list, its levels and statuses, the workflow, the report shape, the acceptance criteria |
| `AGENTS.md` | Rules for editing this skill's own files |
| `assets/scripts/check-links.ps1` | Model-free markdown checker (PowerShell) |
| `assets/scripts/check-links.sh` | Model-free markdown checker (Bash) |
| `assets/scripts/_check-links.Tests.ps1` | Differential twin test — dev-only, pruned on install |

---

## Relationship to other skills

- **`make-repo-ai-friendly`** — the docs-authoring skill. It loads this skill
  for the criteria and the link checker, and it is where fixes belong. The
  dependency is one-way: this skill never names it.
- **`sda-docs-check`** — loads this skill for the criteria and the model-free
  checker, and adds its own SDA-specific checks.
