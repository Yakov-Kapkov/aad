# PowerShell Scripts

Installation scripts for Windows (PowerShell 5.1+).

## Quick Start

```powershell
cd <repo-root>/scripts/powershell
.\install-dev-suite.ps1              # full dev suite → ~/.copilot
.\install-dev-suite.ps1 -Mode full   # same as default (mode reserved for future filtering)
.\install-dev-suite.ps1 -TargetBase ".\.copilot"  # → workspace folder
.\install-dev-suite.ps1 -Models @('sda-dev=Claude Opus 4 (Copilot)')  # with model overrides
.\install-dev-suite.ps1 -Models @('commit=Claude Haiku 4.5')  # override commit agent model
.\install-dev-suite.ps1 -Exclude commit  # skip commit agent + its prompts
.\install-dev-suite.ps1 -Action uninstall  # remove all dev suite files
.\pull-dev-suite.ps1             # copy edited artifacts back from ~/.copilot into this repo
.\pull-dev-suite.ps1 -WhatIf     # preview a pull
```

## Scripts

| Script | Description |
|---|---|
| `install-dev-suite.ps1` | Installs or uninstalls the full dev suite (SDA tool + all skills) |
| `pull-dev-suite.ps1` | Pulls dev-suite artifacts from an installed folder back into the repo (reverse install) |
| `install-tool.ps1` | Installs a single tool's agents and prompts |
| `install-skill.ps1` | Installs a single skill folder |
| `set-agent-models.ps1` | Patches `model:` lines in installed agent frontmatter |

## Usage

```powershell
# Install dev suite to user-level .copilot (default)
.\install-dev-suite.ps1

# Install with mode full (reserved — same as default)
.\install-dev-suite.ps1 -Mode full

# Install with custom models for SDA agents
.\install-dev-suite.ps1 -Models @('sda-dev=Claude Opus 4 (Copilot)', 'sda-coder=Claude Opus 4 (Copilot)')

# Override model for all SDA agents at once
.\install-dev-suite.ps1 -Models @(
    'sda-design=Claude Opus 4.6', 
    'sda-coder=Claude Haiku 4.5', 
    'sda-test-writer=Claude Haiku 4.5', 
    'sda-dev=Claude Sonnet 5'
)

# Override model for commit agent
.\install-dev-suite.ps1 -Models @('commit=Claude Haiku 4.5')

# Install without the commit agent and its prompts
.\install-dev-suite.ps1 -Exclude commit

# Combine mode + models
.\install-dev-suite.ps1 -Mode full -Models @('sda-dev=Claude Opus 4 (Copilot)')

# Install to a workspace-level folder
.\install-dev-suite.ps1 -TargetBase ".\.copilot"

# Uninstall the dev suite
.\install-dev-suite.ps1 -Action uninstall

# Uninstall from a specific folder
.\install-dev-suite.ps1 -Action uninstall -TargetBase ".\.copilot"

# Install a single skill to a custom location
.\install-skill.ps1 -Name "troubleshooting" -TargetBase ".\.copilot"

# Install a single tool to a custom location
.\install-tool.ps1 -Name "sda" -TargetBase ".\.copilot"

# Install a single skill
.\install-skill.ps1 -Name "troubleshooting"

# Install a single tool
.\install-tool.ps1 -Name "sda"

# Install a tool with only specific agents
.\install-tool.ps1 -Name "sda" -AgentFilter @('sda-ba','sda-dev')

# Install a tool, excluding specific agents
.\install-tool.ps1 -Name "sda" -AgentExclude @('sda-qa')

# Install a tool with model overrides (passed to the custom install script)
.\install-tool.ps1 -Name "sda" -ScriptArgs 'sda-dev=Claude Opus 4 (Copilot)'
```

## Pulling changes back

`pull-dev-suite.ps1` is the reverse of `install-dev-suite.ps1`. Edit the installed copy
while using it, then pull the artifacts back into this repo to persist them.

Example:

```powershell
# Pull from the default install location
.\pull-dev-suite.ps1

# Pull from a workspace-level install, previewing first
.\pull-dev-suite.ps1 -SourceBase "C:\my\.copilot" -WhatIf

# Also pull `model:`-only differences
.\pull-dev-suite.ps1 -IncludeModels

# Also delete repo skill files that the installed copy no longer has
.\pull-dev-suite.ps1 -Prune
```

Rules:

- **Map mirrors the installer** — SDA agents and prompts go back to `tools/sda/`,
  `commit.agent.md` to `agents/commit/`, `commit*.prompt.md` to `prompts/commit/`,
  and each skill to its source folder (`skills/{name}` or `tools/sda/skills/{name}`).
- **Only dev-suite artifacts are pulled** — anything else in the source base is listed
  and left alone. New files matching the maps are added.
- **`_installation\` and `_*.Tests.*` are never pulled or pruned** — they exist only in
  the repo.
- **`model:`-only differences are skipped** — so `-Models` overrides used at install
  time do not overwrite the repo's default models. Use `-IncludeModels` to pull them.
- **Deletions need `-Prune`** — without it, repo-only skill files are reported and kept.
- **`-WhatIf` previews** — nothing is written.

In this repo, the `/sync-changes` prompt runs the pull from the folder named in
`.sync/source_path.txt` (gitignored), then runs the dev tests and checks the pulled
changes against the repo's quality rules.

## Custom Install Scripts

Both `install-skill.ps1` and `install-tool.ps1` check for a custom install
script at `{source}/_installation/powershell/install.ps1`. If found, it is invoked instead of
the default copy logic. Any extra arguments (`ScriptArgs`) are passed through.

| Component | Custom script location |
|---|---|
| Skill | `skills/{name}/_installation/powershell/install.ps1` |
| Tool | `tools/{name}/_installation/powershell/install.ps1` |

Custom skill scripts receive: `-DestFolder <path> [-ScriptArgs <string>]`
Custom tool scripts receive: `-TargetBase <path> [-AgentFilter <list>] [-AgentExclude <list>] [-ScriptArgs <string>]`

## Tests are never installed

Both installers prune files named `_*.Tests.*` from the installed copy — at any depth, and on
both the default and custom paths. Tests live beside the code they test and are development-only.

## Common Parameters

| Parameter | Description | Default |
|---|---|---|
| `-TargetBase` | Path to the `.copilot` folder | `$env:USERPROFILE\.copilot` (install-dev-suite); *(required)* otherwise |
| `-Name` | Component name (skill or tool) | *(required)* |
| `-Action` | `install` or `uninstall` (install-dev-suite) | `install` |
| `-Mode` | `full` or `short` (install-dev-suite) | `short` |
| `-Exclude` | Dev-suite components to skip; supported: `commit` (install-dev-suite) | *(none)* |
| `-Models` | Agent model overrides (install-dev-suite) | *(none)* |
| `-SourceBase` | Installed `.copilot` folder to pull from (pull-dev-suite) | `$env:USERPROFILE\.copilot` |
| `-RepoRoot` | Repo root to pull into (pull-dev-suite) | this repo |
| `-IncludeModels` | Also pull `model:`-only diffs (pull-dev-suite) | off |
| `-Prune` | Delete repo skill files absent from the source base (pull-dev-suite) | off |
| `-SourcePath` | Override source folder for a skill (install-skill) | `skills/{Name}` |
| `-AgentFilter` | Array of agent basenames to install (install-tool) | *(all)* |
| `-AgentExclude` | Array of agent basenames to exclude, applied after `-AgentFilter` (install-tool) | *(none)* |
| `-ScriptArgs` | Opaque string passed to a custom install script (install-skill / install-tool) | `''` |
