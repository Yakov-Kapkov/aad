---
name: sda-setup
description: "Sets up or updates the SDA tool in the current project. Use when the user's intent is to install, initialise, configure, or update SDA — even if they don't use those exact words. Triggers include: asking to set up, update, install or reconfigure SDA."
---

# SDA Project Setup

Scaffold the `.sda/` folder in a project so the SDA agents can work.

You do NOT write application code or tests.

## Invocation examples
- "setup sda tool"
- "Set up sda for this project"
- "Init sda"
- "Initialize the development workflow"
- "Set up the TDD workflow for this project"

---

## .sda dependencies

`.sda/` is a dot-prefixed folder that may be hidden from search tools.
Access all files below by exact path from the repo root — never search for them.

| File | Path |
|---|---|
| project-config.json | `.sda/project-config.json` |
| project-config.example.json | `.sda/resources/project-config.example.json` |

## Communication rules

- Output **only** prescribed **Post:** lines and required question UI. Nothing else.
- Forbidden: "Let me...", "I will...", "Analyzing...", "Proceeding...", or any equivalent narration.
- Forbidden: echoing or summarizing user answers (no "Q: ... A: ..." output).
- Forbidden: describing what you just did or are about to do.
- Every step has a mandatory **Post:** line — output it **verbatim**, then act immediately.
- Script labels are mandatory — post them **immediately before** running the script, nothing else.

**Script labels:**

| Script | Label to post |
|---|---|
| `setup.ps1` / `setup.sh` | `**Scaffolding .sda/ folder.**` |
| `write-config.ps1` / `write-config.sh` | `**Writing project-config.json.**` |

**PowerShell script invocation:**

Examples below use a **placeholder path** (`c:\Users\user\scripts\setup.ps1`) to show the command *shape* only. At runtime, substitute the real resolved `<this-skill-folder>` path from Step 2 / Step 4.

- Path has **no spaces** → invoke directly, no `&`, no quotes:
  `c:\Users\user\scripts\setup.ps1`
- Path has **spaces** → use call operator + quotes:
  `& "c:\Users\user\My Scripts\setup.ps1"`

Never assign the path to a variable. Never use `&` unless the path has spaces. Run the literal one-liner from the rules above — nothing else.

- ✅ `c:\Users\user\scripts\setup.ps1`
- 🚫 `$skillPath = 'c:\Users\user\scripts\setup.ps1'; & $skillPath`

**Bash script invocation:**

Same placeholder convention — substitute the real resolved `<this-skill-folder>` path at runtime.

- Always `bash` + quoted path. Quotes handle spaces; no variable, no other prefix:
  `bash "/home/user/scripts/setup.sh"`

- ✅ `bash "/home/user/scripts/setup.sh"`
- 🚫 `p="/home/user/scripts/setup.sh"; bash "$p"`

---

## Workflow

**Post on invocation (before any action):**
```
# SDA Setup
```

### Step 1 — Detect setup mode

**Post:** `**Step 1 — Detecting setup mode...**`

Use `read_file` with the **exact literal path** `.sda/project-config.json`. If read succeeds the file exists; if it fails the file is missing. The folder must be exactly `.sda`. Do NOT search.

- **Exists** → **Post:** `Mode: Update` → **Go directly to Step 2.**
- **Missing** → **Post:** `Mode: First-time setup` → **Go to Step 2.**

> Steps 2–5 run for **both** modes.

### Step 2 — Create folder structure and copy resource files

**Post:** `**Step 2 — Updating .sda/ folder.**` (first-time: scaffolds; update: refreshes resource files)

**This step is mandatory for both modes.**

Use the setup script — do NOT read asset files into context and write them back.

Resolve `<this-skill-folder>` to the directory containing this `SKILL.md`.

**Windows:** `<this-skill-folder>\assets\scripts\powershell\setup.ps1`

If the resolved path contains spaces, use `& "<path>"` instead.

**macOS/Linux:** `bash "<this-skill-folder>/assets/scripts/bash/setup.sh"`

On update, the script also deletes paths retired by earlier versions — it prints one `Removed retired path:` line per deletion. Relay those lines.

### Step 3 — Configure project

**Post:** `**Step 3 — Configuring project.**`

Read `.sda/resources/project-config.example.json` into `{template}` via `read_file` (exact path — do NOT search). If missing, abort: _"`project-config.example.json` not found — Step 2 may have failed. Re-run setup."_

### Step 4 — Normalize project-config.json

**Post:** `**Step 4 — Writing project-config.json.**`

Run the write-config script. It adds missing fields and preserves existing values.

**Windows (PowerShell):**
```
<this-skill-folder>\assets\scripts\powershell\write-config.ps1 `
    -TemplateFile  ".sda/resources/project-config.example.json" `
    -ConfigFile    ".sda/project-config.json"
```

If the resolved path contains spaces, prefix with `&` and quote the script path.

**macOS / Linux (bash):**
```
bash "<this-skill-folder>/assets/scripts/bash/write-config.sh" \
    ".sda/resources/project-config.example.json" \
    ".sda/project-config.json"
```

Adds missing fields, preserves existing values. **Mandatory — do not skip.**

### Step 5 — Summary

**Post verbatim:**

---
## SDA is ready.

---
