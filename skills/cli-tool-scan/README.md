# CLI Tool Scan — Skill

A Copilot skill that scans the CLI tools a repository's own commands need,
reports the missing ones, and installs only the ones the user approves.

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition plus the tool list → probe → propose → install workflow |

---

## Setup

The skill is self-contained — the workflow ships inside this folder and is
copied as-is on install. Install it with the dev-suite installer or on its own.

**PowerShell (Windows):**
```powershell
# Install the full dev suite (all skills, including this one)
.\scripts\powershell\install-dev-suite.ps1

# Install only this skill
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "cli-tool-scan"
```

**Bash (macOS / Linux):**
```bash
# Install the full dev suite
./scripts/bash/install-dev-suite.sh

# Install only this skill
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "cli-tool-scan"
```

Installs to `~/.copilot/skills/cli-tool-scan/` by default.

---

## Usage

Ask when a documented command will not run, or when a fresh checkout needs
setting up:

```
Scan this repo's CLI tools and tell me what's missing.
```

The skill:

- collects the executables the repo's documented commands invoke — never a
  hardcoded list;
- probes each one once and reports version or `missing`;
- proposes one install command per missing tool, derived from the repo's own
  package manager and the host OS;
- installs only the tools the user selects, then re-checks each one.

It never writes files, edits manifests, or installs without approval.

---

## Output

```
## Tools
| Tool | Needed for | Status |
|---|---|---|
| {name} | {command it serves} | ✅ {version} · ✗ missing |
```

When nothing is missing, the table is the whole report.
