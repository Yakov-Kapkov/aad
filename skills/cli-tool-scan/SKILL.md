---
name: cli-tool-scan
description: "Scans which CLI tools this repository's own commands need, reports the ones that are missing, and installs them after the user approves. Use when: asked to scan the CLI tools installed in a project, a documented test/lint/build command fails because a tool is missing, or a fresh checkout needs its tooling installed."
---

# CLI Tool Scan

Check which of the CLI tools this repository's commands need are installed,
report the missing ones with an install command, and install only what the user
approves.

You do NOT write config or change code.

## Inputs

Optional: a scope — the project boundary to check. Absent → every boundary the
context identifies, else the repo root.

## Constraints

- Never assume a path, file name, or layout — the repo's context supplies them.
- Never list a tool the repo's commands do not invoke.
- Never run an install command before the user approves it.
- Never write, create, or delete files.
- Never edit a manifest, shell profile, or hook configuration.
- Never run a command that needs elevation — hand that command to the user.

## Workflow

### 1. Collect the tools the repo needs

From the repo's own context — its AI readme and the docs it routes to; its own
files when nothing is documented — collect every executable the documented
commands invoke: test runner, type checker, linter, formatter, build tool,
package manager, hook manager, runtime.

- A command runner (`pnpm`, `poetry`, `uv`, `npx`, `dotnet`) counts once.
- Skip a dev dependency the package manager resolves for the user — its
  presence follows from the package-manager check.

### 2. Scan what is installed

Check presence for each tool in one batch: `--version`, then `command -v`
(bash/zsh) or `Get-Command` (PowerShell) when that fails. Non-zero exit or
"not found" → missing.

Never probe the same tool twice.

### 3. Report

```
## Tools
| Tool | Needed for | Status |
|---|---|---|
| {name} | {command it serves} | ✅ {version} · ✗ missing |
```

Nothing missing → stop after the table.

### 4. Propose and confirm

For each missing tool, propose one install command derived from the repo's own
package manager and the host OS.

```markdown
## Missing tools
| Tool | Install |
|---|---|
| {name} | `{exact command}` |
```

Ask once, multi-select — which tools to install. Declined tools stay listed as
missing.

### 5. Install

Run approved commands one at a time, verbatim. Add a non-interactive flag only
when the command would otherwise prompt. After each, re-run the tool's presence
check.

```
### Tool results
| Tool | Result |
|---|---|
| {name} | ✓ installed · ✗ failed — {one-line error} |
```
