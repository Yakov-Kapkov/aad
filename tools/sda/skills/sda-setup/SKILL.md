---
name: sda-setup
description: "Sets up or updates the SDA tool in the current project. Use when the user's intent is to install, initialise, configure, or update SDA — even if they don't use those exact words. Triggers include: asking to set up, update, install or reconfigure SDA."
---

# SDA Project Setup

Scaffold the `.sda/` folder in a project so the SDA agents can work.
After scaffolding, hand off to the `sda-toolscan` agent for toolchain scanning.

You do NOT write application code, tests, or scan the toolchain.

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
| project-tools.md | `.sda/project-tools.md` |
| project-config.json | `.sda/project-config.json` |
| project-config.example.json | `.sda/resources/project-config.example.json` |
| tool-catalog.md | `.sda/resources/{language}/tool-catalog.md` |

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

Examples below use a **placeholder path** (`c:\Users\user\scripts\setup.ps1`) to show the command *shape* only. At runtime, substitute the real resolved `<this-skill-folder>` path from Step 3 / Step 5.

- Path has **no spaces** → invoke directly, no `&`, no quotes:
  `c:\Users\user\scripts\setup.ps1 -Language python`
- Path has **spaces** → use call operator + quotes:
  `& "c:\Users\user\My Scripts\setup.ps1" -Language python`

Never assign the path to a variable. Never use `&` unless the path has spaces. Run the literal one-liner from the rules above — nothing else.

- ✅ `c:\Users\user\scripts\setup.ps1 -Language python`
- 🚫 `$skillPath = 'c:\Users\user\scripts\setup.ps1'; & $skillPath -Language python`

**Bash script invocation:**

Same placeholder convention — substitute the real resolved `<this-skill-folder>` path at runtime.

- Always `bash` + quoted path + args. Quotes handle spaces; no variable, no other prefix:
  `bash "/home/user/scripts/setup.sh" python`

- ✅ `bash "/home/user/scripts/setup.sh" python`
- 🚫 `p="/home/user/scripts/setup.sh"; bash "$p" python`

---

## Workflow

**Post on invocation (before any action):**
```
# SDA Setup
```

### Step 1 — Detect setup mode

**Post:** `**Step 1 — Detecting setup mode...**`

Use `read_file` with the **exact literal paths** `.sda/project-tools.md` and `.sda/project-config.json`. If read succeeds the file exists; if it fails the file is missing. The folder must be exactly `.sda`. Do NOT search.

- **Both exist** → **Post:** `Mode: Update` → Skip Step 2. **Go directly to Step 3.**
- **Either missing** → **Post:** `Mode: First-time setup` → **Go to Step 2.**

> Steps 3–8 run for **both** modes. The only difference is that first-time setup runs Step 2 first.

### Step 2 — Detect language

**Post:** `**Step 2 — Detecting language...**`

Read `package.json` (→ `typescript`), `pyproject.toml` / `requirements.txt` (→ `python`), or equivalent. If none found, ask the user. 

**Post:** `Language: {language}`

### Step 3 — Create folder structure and copy resource files

**Post:** `**Step 3 — Updating .sda/ folder.**` (first-time: scaffolds; update: refreshes resource files)

**This step is mandatory for both modes.**

Use the setup script — do NOT read asset files into context and write them back.

Resolve `<this-skill-folder>` to the directory containing this `SKILL.md`.

**Windows:** `<this-skill-folder>\assets\scripts\powershell\setup.ps1 -Language {language}`

If the resolved path contains spaces, use `& "<path>" -Language {language}` instead.

**macOS/Linux:** `bash "<this-skill-folder>/assets/scripts/bash/setup.sh" {language}`

If the script warns that the language-specific tool-discovery spec is missing, relay that warning.

### Step 4 — Configure project

**Post:** `**Step 4 — Configuring project.**`

Read `.sda/resources/project-config.example.json` into `{template}` via `read_file` (exact path — do NOT search). If missing, abort: _"`project-config.example.json` not found — Step 3 may have failed. Re-run setup."_

Test coverage defaults to `enabled: true` on first setup. On update, the existing `tests.coverage.enabled` value is preserved — setup never resets it.

### Step 5 — Normalize project-config.json

**Post:** `**Step 5 — Writing project-config.json.**`

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

### Step 6 — Toolchain scan

**Post:** `**Step 6 — Toolchain scan.**`

- **First-time setup** — run automatically.
- **Update** — ask (title: _"Toolchain scan"_): _"Re-scan to update `project-tools.md`?"_ `Yes` ← default / `No — keep existing`. If `No` → read `.sda/project-tools.md`. If it exists, proceed to Step 7. If missing, skip to Step 8.

Invoke `sda-toolscan`: `"Scan this project's toolchain and generate project-tools.md."`

If agent cannot be invoked: _"Run **sda-toolscan** manually to generate `project-tools.md`."_

### Step 7 — Tool audit

**Post:** `**Step 7 — Auditing required tools.**`

Read `.sda/project-tools.md` using `read_file`. If the file does not exist or cannot be read, skip this step silently.

**Detect missing categories.** Scan each area's `### Detected Tools` sub-section. For each required category, check the corresponding label line. Add the category to `{missing-required}` if the label line is absent **or** contains `❌`.

| Category | Label in `### Detected Tools` |
|---|---|
| Package manager | `**Package Manager**` |
| Test runner | `**Test Framework**` |
| Type checker | `**Type Checking**` |
| Linter | `**Code Quality**` |
| Code formatter | `**Formatters**` |
| Coverage | `**Coverage**` |
| Git hooks | `**Pre-Commit Hooks**` |
| Data format validators | `### Format` section — flag absent or empty |

**Command presence check.** For each category showing `✅` (not flagged above), verify the corresponding section contains the required command label. If the label is absent or its stub body is `# _Not detected._` — the tool is not installed as a standalone tool. Add that category to `{missing-required}`.

| Category | Section to read | Required label |
|---|---|---|
| Test runner | `### Test Execution` | `# test-all` |
| Type checker | `### Type Checking` | `# type-all` |
| Linter | `### Lint` | `# lint-all` |
| Code formatter | `### Format` | `# format-code-path` |
| Coverage | `### Test Execution` | `# test-path-coverage` |

If `{missing-required}` is empty → skip to Step 8.

**Resolve tool choices.** Read `.sda/resources/{language}/tool-catalog.md` using `read_file` (exact path — do NOT search). Remove from `{missing-required}` any category that has **no rows** in the catalog — it is not applicable to this language and should not be flagged. If `{missing-required}` is now empty → skip to Step 8.

For each remaining category, collect all rows where Category matches — in Priority order.

For each missing category that has **more than one row** in the catalog, ask (title: _"{Category}"_):

> _"Which {category} tool?"_
> - `{tool-1}` — {description-1} ← default
> - `{tool-2}` — {description-2}
> - _(one option per catalog row, Priority 1 first)_

For categories with only one catalog row, auto-select silently. If the catalog file itself is missing, skip to Step 8 with a warning: _"`tool-catalog.md` not found — run the install script to populate `.sda/resources/{language}/`._"

Record each selected tool as `{tool-for-category}`.

**Post verbatim**, substituting only the list rows:

```
## ⚠ Required tools missing

| Category | Tool |
|---|---|
{one row per missing category: | {category} | {tool-for-category} |}
```

Ask (title: _"Required tools"_):

> _"Install missing required tools now?"_
> - `Yes` ← default
> - `No`

If `No` → **Post:** `> Install missing tools before running SDA workflows. Re-run sda-setup after installing.` then skip to Step 8.

If `Yes` → **Post:** `**Installing required tools.**`

Delegate to `sda-tool-installer`:

```
Language: {detected language}
Install these required tools:
{one line per missing category: "- {category}: {tool-for-category}"}
```

If agent cannot be invoked → **Post:** `> Cannot invoke sda-tool-installer. Install the following tools manually, then re-run sda-setup:` followed by the `| Category | Tool |` table above.

After `sda-tool-installer` returns → ask (title: _"Toolchain scan"_): _"Re-scan toolchain to update `project-tools.md`?"_ `Yes` ← default / `No`.

If `Yes` → invoke `sda-toolscan` with this exact message (substitute the tool list):
```
Scan this project's toolchain and generate project-tools.md.
Recently installed tools:
{one line per tool from the {missing-required} list: "- {tool-for-category}"}
```
then proceed to Step 8.

If `No` → **Post:** `> Re-run **sda-toolscan** to update project-tools.md with the newly installed tools.`

### Step 8 — Summary

**Post verbatim:**

---
## SDA is ready.

**Test coverage** `enabled = true` on first setup; preserved on update.

---
