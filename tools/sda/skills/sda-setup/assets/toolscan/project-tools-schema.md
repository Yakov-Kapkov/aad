# project-tools.md Schema

Defines the structure and content rules for `project-tools.md` — the machine-readable command registry written by `sda-toolscan` and consumed by SDA agents.

---

## Content rules

- **Command labels** (e.g. `# test-path`, `# format-code-path`) are machine-readable keys. SDA agents look up commands by these exact labels — do not rename them.
- **A command slot may hold multiple invocations.** When one label maps to several independent tools/hooks (e.g. `black` + `isort` behind `format-code-path`), the value is those complete invocations joined by the detected shell command separator (`;` PowerShell / `&&` bash/zsh). Each invocation is self-contained; selectors are never combined into one call, and any path placeholder repeats in every invocation.
- **Always render every section and Detected-Tools line** — never omit one because its tool is missing. When a tool, validator, hook manager, or runnable layer is absent, render the heading and write the marker `_Not detected._` (add a brief reason when useful) in place of its commands. Detected-Tools lines (inside each area's `### Detected Tools` sub-section) use `❌` / `None` instead.
- **A not-detected command stub always keeps its label.** Emit every `#`-labeled stub defined by the schema; when the tool is absent, write `# _Not detected._` on the immediately following line — no executable command. Consuming scripts skip lines that start with `#`, so the stub is treated as absent at runtime while remaining visible for manual editing without a schema lookup.
- **Working directory** — stated once per area at the `##` heading level; applies to all `###` sub-sections within that area. Always `./`-prefixed, relative to workspace root.
- **Area headings** — always use `## {Area name}` with a functional domain label (Backend, Frontend, API, Worker) — not folder names. Single-area projects use one block (e.g. `## Application`, `## Backend`). Multi-area projects use one block per area (Backend first, Frontend second, others alphabetically). Each block contains `### Detected Tools`, `### Thresholds`, and command sub-sections.
- **Area Index** — always render at the top of the file, before any area blocks. One row per area. Consuming agents use it to map file paths to area working directories and command blocks.
- **Shell code blocks** — use the detected shell's language identifier (`powershell`, `bash`, `zsh`).
- **Undetermined commands** — use `# TODO` and flag in the scan response.
- **Pre-commit hook count** — the N in the **Pre-Commit Hooks** line in each area's `### Detected Tools` must equal the total number of hooks enumerated in the project-global `## Pre-Commit Checks` section.

---

## Template

<project-tools-template>
# Project Tools

**Last scanned:** {Month DD, YYYY, HH:mm}  
**Monorepo:** {Yes — {description} | No}

---

## Area Index

<!-- Always render — before any area blocks.
     Consuming agents use this table to map a file path to its area — finding the
     working directory and the correct `## {Area name}` command block.
     Single-area projects: one row. Multi-area: Backend first, Frontend second, others alphabetically. -->

| Area | Language | Working directory | File patterns |
|---|---|---|---|
| {area label} | {language} | `{./path}` | `{*.ext, *.ext}` |

---

## {Area name}

<!-- One `## {Area name}` block per area.
     Single-area: one block (e.g. `## Application`, `## Backend`).
     Multi-area: one block per area (Backend first, Frontend second, others alphabetically).
     Working directory is stated once at the `##` level — applies to all `###` sub-sections. -->

**Working directory:** `{./path}`   <!-- ./prefixed; relative to workspace root -->

### Detected Tools

<!-- Always render all lines; use `❌` / `None` when a tool is absent. -->

- **Package Manager**   : {manager} ({lock file}, {runtime version constraint})
- **Language/Runtime**  : {language + version}
- **Test Framework**    : {✅ | ❌} {name + version} ({scope / environment notes})
- **Type Checking**     : {✅ | ❌} {name} ({key config flags})
- **Code Quality**      : {✅ | ❌} {linter + version} ({plugins})
- **Formatters**        : {✅ | ❌} {formatter + version} ({config file})
- **Coverage**          : {✅ | ❌} {provider} (threshold: {N}% | Not configured — {scope})
- **Pre-Commit Hooks**  : {✅ {hook manager} ({config file} — {N} hooks configured) | ❌ None}
- **CI/CD**             : {✅ {platform} ({workflow file names}) | ❌ None}
- **Version Control**   : {tool name | "None"}

---

### Thresholds

<!-- Detected policy values — not commands. Always include all threshold lines; write "Not configured" when no threshold is set. -->

- **Coverage**      : {threshold per runner, e.g. "Jest: 80%, Vitest: 75%"} | Not configured
- **Lint warnings** : {max warnings, e.g. "max 0"} | No strict threshold enforced

---

### Test Execution

<!-- [always render] If no test framework detected, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them.
     test-path accepts both a file path and a folder path — one command covers both.
     test-path-coverage: threshold enforced automatically from project config.
     Project-level coverage injection: some runners embed coverage flags in project config,
     causing every invocation to trigger full-codebase coverage. When a discovery spec flags
     this pattern, scoped commands must include the language-appropriate override flags.
     Full-suite commands inherit project config unchanged. -->

```{shell}
# test-all (run entire test suite)
{command}

# test-path (run specific file or folder, no coverage)
{command} path/to/test_file_or_folder

# test-path-coverage (run specific file or folder with coverage, threshold from config)
{command} path/to/test_file_or_folder {--cov-flags}
```

---

### Type Checking

<!-- [always render] If no type checker detected, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them. -->

```{shell}
# type-all (check entire codebase)
{command}

# type-path (check specific folder or file)
{command} path/to/folder_or_file
```

---

### Lint

<!-- [always render] If no standalone linter detected, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them. -->

```{shell}
# lint-all (lint entire codebase)
{command}

# lint-path (lint specific folder or file)
{command} path/to/folder_or_file

# lint-all-fix (lint entire codebase with auto-fix)
{command} --fix

# lint-path-fix (lint specific folder or file with auto-fix)
{command} path/to/folder_or_file --fix
```

---

### Format

<!-- [always render] If no formatter detected, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them. -->

```{shell}
# format-code-all (format entire codebase — writes in place)
{command}

# format-code-path (format specific file or folder — writes in place)
{command} path/to/folder_or_file
```

---

### Application Run

<!-- [always render] If no runnable layer detected for this area, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them.
     Long-running command — do NOT add single-run flags. -->

```{shell}
# app-run-start (start the application)
{command}

# app-run-url
{url or port — "not applicable" for workers — or "not detected"}

# app-run-healthcheck
{url — "not applicable" for workers — or "not detected"}
```

---

### Build

<!-- [always render] If no build command detected for this area, render the full code block with `# _Not detected._` under the label.
     Command label is a machine-readable key — do not rename it.
     A build command compiles or bundles source into deployable artifacts (e.g. tsc, vite build, dotnet build).
     It must exit 0 on success and must NOT start a long-running process. -->

```{shell}
# build-all (compile/bundle the entire project)
{command}
```

---

<!-- Repeat the `## {Area name}` block above for each additional area -->

## Validators

<!-- Project-global. Render once after all area blocks.
     Always include all four format labels; emit `# _Not detected._` for any format with no detected validator. -->

```{shell}
# validate-json-path (validate a JSON file — substitute path at runtime)
{command} '{path}'

# validate-yaml-path (validate a YAML/YML file — substitute path at runtime)
{command} '{path}'

# validate-xml-path (validate an XML file — substitute path at runtime)
{command} '{path}'

# validate-toml-path (validate a TOML file — substitute path at runtime)
{command} '{path}'
```

---

## Output Filter Command

<!-- Project-global. Command labels are machine-readable keys — do not rename them. -->

**Detected shell:** {PowerShell | bash | zsh | other}
**Command Separator:** {; (PowerShell) | && (bash/zsh)}

<!-- Two filter labels are consumed by SDA agents:
     filter-last-n  — caps output length (used for test-all baseline).
     filter-test-output — composed at runtime by sda-dev/sda-dev-quality
     per area from Language→regex mapping; not stored in project-tools.md. -->

```{shell}
# filter-last-n (keep last N lines of output — N is supplied by the caller)
<command> 2>&1 | {last-n-lines-tool} {N}
```

<!-- <command>: placeholder — substitute the actual command being filtered -->
<!-- {last-n-lines-tool}: PowerShell → `Select-Object -Last` | bash/zsh → `tail -n` -->

---

## Pre-Commit Checks

<!-- Project-global. Always render. If no hook manager detected, render the full code block with `# _Not detected._` under each label.
     Command labels are machine-readable keys — do not rename them.
     Hook count here must equal the N in each area's `### Detected Tools` Pre-Commit Hooks line. -->

```{shell}
# precommit-staged (run all hooks on staged files)
{command}

# precommit-all (run all hooks on all files)
{command}
```

Hooks run in this order:
1. `{hook-name}` — {description}
2. ...

</project-tools-template>
