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
```

## Scripts

| Script | Description |
|---|---|
| `install-dev-suite.ps1` | Installs or uninstalls the full dev suite (SDA tool + all skills) |
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
    'sda-dev-task=Claude Opus 4.6', 
    'sda-coder=Claude Haiku 4.5', 
    'sda-test-writer=Claude Haiku 4.5', 
    'sda-dev=Claude Sonnet 4.6', 
    'sda-toolscan=Claude Sonnet 4.6'
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
.\install-tool.ps1 -Name "sda" -AgentFilter @('sda-toolscan','sda-dev')

# Install a tool, excluding specific agents
.\install-tool.ps1 -Name "sda" -AgentExclude @('sda-qa')

# Install a tool with model overrides (passed to the custom install script)
.\install-tool.ps1 -Name "sda" -ScriptArgs 'sda-dev=Claude Opus 4 (Copilot)'
```

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
| `-SourcePath` | Override source folder for a skill (install-skill) | `skills/{Name}` |
| `-AgentFilter` | Array of agent basenames to install (install-tool) | *(all)* |
| `-AgentExclude` | Array of agent basenames to exclude, applied after `-AgentFilter` (install-tool) | *(none)* |
| `-ScriptArgs` | Opaque string passed to a custom install script (install-skill / install-tool) | `''` |
