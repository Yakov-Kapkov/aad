# Bash Scripts

Installation scripts for macOS and Linux.

## Quick Start

```bash
cd <repo-root>/scripts/bash
chmod +x *.sh
./install-dev-suite.sh          # core agents → ~/.copilot
./install-dev-suite.sh full     # all agents  → ~/.copilot
./install-dev-suite.sh -t ./.copilot  # → workspace folder
./install-dev-suite.sh -m "sda-dev=Claude Sonnet 4.6"  # with model overrides
./install-dev-suite.sh -m "commit=Claude Haiku 4.5"  # override commit agent model
./install-dev-suite.sh uninstall  # remove all dev suite files
```

## Scripts

| Script | Description |
|---|---|
| `install-dev-suite.sh` | Installs or uninstalls the full dev suite (SDA tool + all skills) |
| `install-tool.sh` | Installs a single tool's agents and prompts |
| `install-skill.sh` | Installs a single skill folder |
| `set-agent-models.sh` | Patches `model:` lines in installed agent frontmatter |

## Usage

```bash
# Install dev suite to user-level .copilot (default)
./install-dev-suite.sh

# Install with all SDA agents
./install-dev-suite.sh full

# Install with custom models for SDA agents
./install-dev-suite.sh -m "sda-dev=Claude Sonnet 4.6" -m "sda-coder=Claude Opus 4"

# Override model for all SDA agents at once
./install-dev-suite.sh \
    -m "sda-dev-task=Claude Opus 4.6" \
    -m "sda-coder=Claude Haiku 4.5" \
    -m "sda-test-writer=Claude Haiku 4.5" \
    -m "sda-dev=Claude Sonnet 4.6" \
    -m "sda-toolscan=Claude Sonnet 4.6"

# Override model for commit agent
./install-dev-suite.sh -m "commit=Claude Haiku 4.5"

# Combine mode + models
./install-dev-suite.sh -m "sda-dev=Claude Sonnet 4.6" full

# Install to a workspace-level folder
./install-dev-suite.sh -t ./.copilot

# Uninstall the dev suite
./install-dev-suite.sh uninstall

# Uninstall from a specific folder
./install-dev-suite.sh -t ./.copilot uninstall

# Install a single skill to a custom location
./install-skill.sh -n "troubleshooting" -t ./.copilot

# Install a single tool to a custom location
./install-tool.sh -n "sda" -t ./.copilot

# Install a single skill
./install-skill.sh -n "commit"

# Install a single tool
./install-tool.sh -n "sda"

# Install a tool with only specific agents
./install-tool.sh -n "sda" -a "sda-toolscan,sda-dev"

# Install a tool with model overrides (passed to custom install script)
./install-tool.sh -n "sda" -- --models "sda-dev=Claude Sonnet 4.6" "sda-coder=Claude Opus 4"
```

## Custom Install Scripts

Both `install-skill.sh` and `install-tool.sh` check for a custom install
script at `{source}/_installation/bash/install.sh`. If found, it is invoked instead of
the default copy logic. Arguments after `--` are passed through.

| Component | Custom script location |
|---|---|
| Skill | `skills/{name}/_installation/bash/install.sh` |
| Tool | `tools/{name}/_installation/bash/install.sh` |

Custom skill scripts receive: `<dest-folder> [extra args...]`
Custom tool scripts receive: `<target-base> [-a <filter>] [extra args...]`

## Common Options

| Option | Description | Default |
|---|---|---|
| `-t` | Path to the `.copilot` folder | `$HOME/.copilot` |
| `-n` | Component name (skill or tool) | *(required)* |
| `-m` | Model assignment for SDA agents (install-dev-suite, repeatable) | *(none)* |
| `-s` | Override source folder for a skill | `skills/{name}` |
| `-a` | Comma-separated agent basenames to install (install-tool only) | *(all)* |

The positional arguments for `install-dev-suite.sh` are action (`install`/`uninstall`, default: `install`) and mode (`full`/`short`, default: `short`). They can appear in any order.
