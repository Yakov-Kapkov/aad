# PowerShell Scripts

Installation scripts for Windows (PowerShell 5.1+).

## Quick Start

```powershell
cd <repo-root>/scripts/powershell
.\install-dev-suite.ps1              # core agents → ~/.copilot
.\install-dev-suite.ps1 -Mode full   # all agents  → ~/.copilot
.\install-dev-suite.ps1 -TargetBase ".\.copilot"  # → workspace folder
.\install-dev-suite.ps1 -Models @('sda-dev=Claude Opus 4 (Copilot)')  # with model overrides
.\install-dev-suite.ps1 -Models @('commit=Claude Haiku 4.5')  # override commit agent model
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

# Install with all SDA agents
.\install-dev-suite.ps1 -Mode full

# Install with custom models for SDA agents
.\install-dev-suite.ps1 -Models @('sda-dev=Claude Opus 4 (Copilot)', 'sda-coder=Claude Opus 4 (Copilot)')

# Override model for all SDA agents at once
.\install-dev-suite.ps1 -Models @(
    'sda-dev-task=Claude Opus 4.6', 
    'sda-coder=Claude Haiku 4.5', 
    'sda-test-writer=Claude Haiku 4.5', 
    'sda-dev=Claude Sonnet 4.6', 
    'sda-toolscan=Claude Haiku 4.5'
)

# Override model for commit agent
.\install-dev-suite.ps1 -Models @('commit=Claude Haiku 4.5')

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
.\install-skill.ps1 -Name "commit"

# Install a single tool
.\install-tool.ps1 -Name "sda"

# Install a tool with only specific agents
.\install-tool.ps1 -Name "sda" -AgentFilter @('sda-toolscan','sda-dev')

# Install a tool with model overrides (passed to custom install script)
.\install-tool.ps1 -Name "sda" -Models @('sda-dev=Claude Opus 4 (Copilot)')
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
Custom tool scripts receive: `-TargetBase <path> [-AgentFilter <list>] [-ScriptArgs <string>]`

## Common Parameters

| Parameter | Description | Default |
|---|---|---|
| `-TargetBase` | Path to the `.copilot` folder | `$env:USERPROFILE\.copilot` |
| `-Name` | Component name (skill or tool) | *(required)* |
| `-Action` | `install` or `uninstall` (install-dev-suite only) | `install` |
| `-Mode` | `full` or `short` (install-dev-suite only) | `short` |
| `-Models` | Agent model overrides (install-dev-suite / install-tool) | *(none)* |
| `-SourcePath` | Override source folder for a skill | `skills/{Name}` |
| `-AgentFilter` | Array of agent basenames to install (install-tool only) | *(all)* |
