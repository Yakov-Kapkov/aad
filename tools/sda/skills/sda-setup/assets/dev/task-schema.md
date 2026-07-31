# Task Document Schema

## Template

```markdown
# Task: {name}

## Goal
{1-2 sentences: what and why.}

## Feature
{feature-name — omit this section entirely for standalone tasks}

## QA
**State:** required
**Reason:** {optional — include only when State is `declined`}

## Prerequisites
{Omit if the task has no setup dependencies.}
- [ ] `{ENV_VAR_NAME}` — {what it's for; how to obtain it}
- [ ] {service or tool} — {must be running/configured; how to verify}

## Design Approach
{Omit for small, obvious changes. Subsections must map 1:1 to
Implementation Plan units using the same `Unit N — {name}` headings.
Include `### Summary` for decisions that span multiple units.}

### Summary
{Optional — overall design decisions and rationale that apply across
all units. Omit when every decision fits neatly into a single unit.}

### Unit 1 — {unit name}

**Problem:** {1-2 sentences — what is wrong or missing today.}
— OR —
**Context:** {1-2 sentences — relevant state of affairs for new features
or refactors where nothing is "wrong".}

**Solution:**
- {what to do — one bullet per decision}
- {another action}

**Details:** {optional — omit when the solution is self-explanatory}
- {edge case: what happens when the user submits twice?}
- {backward compat: existing API consumers expect field X — preserve it}
- {concurrency: two users editing simultaneously}
Do NOT list file names, function names, type names, class names,
import paths, or code snippets — those belong in the Implementation Plan.

## Source References
{Omit if not based on external documents.}
- `{file-path}` — {what it contains / why it's relevant}

## Contracts
{Omit if the task has no boundary crossings verified during design.}
- `{specs-root}/{domain}/{file-name}` — {boundary, e.g. UI → Backend}: {one-line description}

## Regression Risks
{Omit if no regression risks were identified.}

- ✅ **{risk name}** — {description of the risk and why it is safe.}
  **Covered:** scenario {N}, Unit {M}

- ⚠️ **{risk name}** — {description and what could break.}
  **Mitigation:** {monitoring, staging validation, manual check, etc.}

- ❌ **{risk name}** — {description and what could break.}
  **Unresolved** — requires discussion

Status prefixes:
- ✅ = covered by a test scenario in this task
- ⚠️ = mitigated but not test-covered (monitoring, staging, manual)
- ❌ = identified risk, no mitigation — must be resolved before saving

## Acceptance Criteria
- [ ] {criterion} _(Unit {N}, scenarios {X}–{Y})_

## Implementation Plan

### Unit 1 — {unit name}
**Type:** tests required
**Area:** {area name}
**Language:** {langs — union of the per-file annotations}
**Source:** 
- `{path-1}` ({langs})
- `{path-2}` ({langs})
**Test:** 
- `{test-path1}` ({langs})
-`{test-path2}` ({langs})

**Scenarios:**

**1. {scenario name}**
- Given: {precondition}
- When: {action}
- Then: {expected outcome}
- Expected (RED): FAIL | vacuous PASS — {reason if vacuous}

**2. {scenario name}**
- Given: {precondition}
- When: {action}
- Then: {expected outcome}
- Expected (RED): FAIL | vacuous PASS — {reason if vacuous}

#### Test Context

**Patterns:**
- {pattern}: {when to use} _(scenarios {N, M})_
- {pattern}: {when to use} _(scenario {X})_

**Object construction:**
Baseline:
\`\`\`{language}
{one assignment per line — shared setup used by most scenarios}
\`\`\`
Variations:
- Scenario {N}: {what differs from baseline and why}
- Scenario {M}: {what differs from baseline and why}

**Mock boundaries:**
- **{target name}** — `{patch path or setup method}`
  - Default: `{response shape}` _(scenarios {N, M})_
  - {variant label}: `{response shape}` _(scenario {X})_
- **{target name}** — `{patch path or setup method}`
  - Default: `{response shape}` _(scenarios {N, M})_

#### Step 1.1 — {what this step does}

**`{ClassName}`** _(new — satisfies scenarios 1–2)_
File: `{path}`
\`\`\`{language}
{class definition with fields and types}
\`\`\`

**`{function_name}`** _(new — satisfies scenarios 1–2)_
File: `{path}`
\`\`\`{language}
{signature with params and return type}
\`\`\`
Implementation:
\`\`\`{language}
{complete function body — include when ≤15 lines, no branching}
\`\`\`

**`{existing_symbol}`** _(modified — satisfies scenarios 1–2)_
File: `{path}`
1. {what to change — anchor with first line of target code}
   \`\`\`{language}
   {replacement code}
   \`\`\`
2. After `{anchor line}`, add:
   \`\`\`{language}
   {new code}
   \`\`\`

#### Step 1.2 — {what this step does}

**`{function_name}`** _(new, non-trivial — satisfies scenario 3)_
File: `{path}`
\`\`\`{language}
{signature}
\`\`\`
Algorithm:
1. {step}
2. If {condition} → {action}, else → {action}
3. Return {result}

### Unit 2 — {unit name}
**Type:** tests only
**Area:** {area name}
**Language:** {langs — union of the per-file annotations}
**Source:** `{source-file-path}` ({langs})
**Test:** `{test-file-path}` ({langs})

**Scenarios:**

**4. {scenario name}**
- Given: {precondition}
- When: {action}
- Then: {expected outcome}

#### Step 2.1 — {what this step does}

**`{symbol_name}`** _(satisfies scenario 4)_
File: `{source-file-path}`
\`\`\`{language}
{signature}
\`\`\`

### Unit 3 — {unit name}
**Type:** integration only
**Area:** {area name}
**Language:** {langs — union of the per-file annotations}
**Source:** `{file-path}` ({langs})
**Related tests:** `{existing-test-path-or-folder}` ({langs})   <!-- optional — existing tests that cover the changed code paths, run as a regression check. Omit the line entirely when none exist. -->

#### Step 3.1 — {what this step does}

**`{symbol_name}`** _(new)_
File: `{file-path}`
\`\`\`{language}
{signature}
\`\`\`
Algorithm:
1. {step}
2. {step}
```

---

## Schema Rules

### Goal
- 1-2 sentences: what the task accomplishes and why it matters.
- Omit implementation details — those belong in Design Approach.

### Feature
- Reference the parent feature by name (exact match to `feature.md` filename stem).
- Omit section entirely for standalone tasks that don't belong to a feature.

### QA
- **`State:`** required — `required` | `declined`. Default `required`.
- **`Reason:`** optional string — include only when `State: declined`.

### Prerequisites
- Checkboxes (`- [ ]`). Omit section if none.
- Each entry: env var or service — name, purpose, how to obtain/verify.
- User marks `- [x]` when complete.
- Do not add setup dependencies to `## Regression Risks`.

### Design Approach
- High-level explanation of the solution — the "what and why" a dev needs before reading the detailed Implementation Plan.
- Subsections map 1:1 to Implementation Plan units: `### Unit N — {name}` (same name as the unit).
- `### Summary` (optional) — overall decisions that span multiple units.
- Per-unit content uses **Problem/Context → Solution → Details** structure.
- **Problem:** for bug fixes and regressions (what is broken today).
- **Context:** for new features and refactors (relevant current state).
- **Solution:** bullet list — one decision per bullet, no justification prose.
- **Details:** optional — edge cases, backward compat, concurrency notes. Conceptual only: describe what could go wrong, not which file or function handles it. No file/function/type/class names, no code snippets, no import paths — those belong in the Implementation Plan.
- Keep per-unit descriptions proportional: trivial units (integration-only, renames) get 2-3 lines; complex units get full Problem/Context + Solution + Details.
- Keep language non-technical — save implementation specifics (file paths, signatures, test details) for the Implementation Plan.

### Source References
- Omit if task is not based on external documents.
- Each entry: file path + brief description of what it contains or why it's relevant.
- Use for: specs, RFCs, issue threads, prior art, migration guides.

### Contracts
- Omit if the task has no boundary crossings.
- One entry per spec file: path relative to repo root, boundary direction, one-line description.

### Regression Risks
- Omit if no regression risks were identified during design.
- Status prefixes:
  - **✅** = covered by a test scenario in this task (safe).
  - **⚠️** = mitigated but not test-covered (monitoring, staging, manual check).
  - **❌** = identified risk, no mitigation — must resolve before saving.
- Each entry: status prefix, risk name, description, and one of:
  - `Covered:` scenario/unit references (for ✅).
  - `Mitigation:` how the risk is addressed (for ⚠️).
  - `Unresolved` — requires discussion (for ❌).

### Units
- Named after the **behaviour** they deliver (`Token refresh`, `Error responses`), not architectural tiers.
- Annotated: **tests required**, **tests only**, or **integration only**.
- **Area:** the project area the unit belongs to (e.g. `Backend`, `Frontend`, `Worker`), derived from the unit's file paths matched against the Area Index in `project-tools.md`. Multi-area units list comma-separated areas (e.g. `Backend, Frontend`). The Area field is mandatory — always present on every unit.
- **Per-file language.** Annotate every Source/Test path with the programming language(s) it contains: `` `src/repo.py` (python, postgres) ``.
- **Language:** header line = deduplicated **union** of the per-file annotations (e.g. `python, postgres`).
  - Fence tags on Changes / Test Context blocks must match the language of the code they contain.
  - Use dialect-specific names (`postgres`, not `sql`).
  - **tests required** — new behaviour: TDD cycle (RED → GREEN).
  - **tests only** — existing behaviour that lacks tests: write tests that pass against existing code.
  - **integration only** — wiring, config, re-exports: no tests, no scenarios. Use step headings with change entries (Symbol layout); use `Algorithm:` for non-trivial logic.
- **Refactoring pattern:** `tests only` for regression scenarios + `integration only` for implementation swap. Reserve `tests required` for genuinely new behavior.
- **Ordering matters.** Foundational behaviour first, dependent behaviour after.
- **Structural prep:** renames, file merges, import rewiring → own integration-only unit before dependent units.

### Changes
- **`tests required` / `tests only` units:** optional — include when: complex algorithms, new type definitions, coordinated multi-file changes, tricky signatures. When omitted, dev agents derive signatures from Source files.
- **`integration only` units:** always required — change entries are the unit's content.
- If duplicates Design Approach content, cross-reference instead: `See Design Approach > {Unit name} for {detail}.`

### Symbol layout
- Line 1: **`symbol_name`** _(new/modified — satisfies scenarios N–M)_ — bold name, operation tag, and scenario reference. Omit the scenario reference for setup-only steps that have no scenarios.
- Line 2: `File: path/to/file.ext` — target file.
- **New symbols:** signature code block, then one of:
  - `Implementation:` + code block (≤15 lines, no branching).
  - `Algorithm:` + numbered prose steps (branching, loops, >5 lines).
  - Omit both for pure type/model definitions.
- **Modified symbols:** numbered modification steps. Anchor with recognizable existing code line. Provide new code in fenced block.
  - For conditional logic / state transitions / cross-method coordination: include `Algorithm:` section.
  - Single-line unconditional insertions: bare "add this call after line X" is sufficient.
- **Imports:** list non-obvious imports (third-party, cross-module) as separate entry or inline. When an existing production utility/helper — in this file or another — already provides logic the unit needs, name it here as **reuse — do not recreate** (symbol + import) so the implementer calls it instead of re-implementing.

### Test Context
- Mandatory for `tests required` and `tests only` units.
- Heading: `#### Test Context` (same level as `#### Step N.M`).
- Three subsections:
  - **Patterns:** one bullet per pattern — description, when to use, scenario numbers.
  - **Object construction:** Baseline (fenced code, shared setup) + Variations (one bullet per differing scenario). When a shared fixture/client/helper already exists for the unit, name it here as **reuse — do not recreate** (symbol + import) instead of re-specifying its construction.
  - **Mock boundaries:** one bullet group per mock target — header + sub-bullets per response variant.
- Source: read test file + source file during plan generation.
- Verify extracted patterns against coding standards. Write compliant version if original is non-compliant.

### Steps
- Heading: `#### Step N.M — {description}`.
- Each step contains Symbol layout entries (see **Symbol layout**). One logical change = one step. Independent changes = multiple steps.
- Entries in units with scenarios carry `— satisfies scenarios N–M` to link back to the `**Scenarios:**` section. Steps with no scenarios omit the annotation.
- Scenario numbering continuous across all steps and units.

### Scenarios
- Applies to `tests required` and `tests only` units only. `integration only` units use step headings with change entries — no scenarios, no Given/When/Then.
- **Location:** Include a `**Scenarios:**` section immediately after the unit header (Type/Language/Source/Test lines), before `#### Test Context`. All scenario definitions live here — scenarios do NOT appear inside steps.
- **Format:** Numbered bold paragraphs `**N. {name}**` with `Given`/`When`/`Then` (flat bullets). Include `Expected (RED):` for `tests required` units.
- Cover happy path, errors, edge cases.

### Expected (RED)
- Required for every scenario in `tests required` units.
- Values:
  - `FAIL` — test should fail because production code doesn't exist yet.
  - `vacuous PASS — {reason}` — test passes trivially (e.g., empty collection, no-op stub, default return). Include reason so reviewer understands why it's not a real pass.
- Omit for `tests only` and `integration only` units.

### Source and Test paths
- The `{langs}` placeholder means **one or more** comma-separated languages — a file may contain several (e.g. `python, postgres`).
- One or more comma-separated file paths, **each annotated in parentheses with the language(s) it contains**: `` `path` (python, postgres) ``.
- The annotation lists every programming language present in that file (dialect-specific: `postgres`, not `sql`).
- New files: creation path. Existing files: modification target.

### Acceptance Criteria
- Every criterion maps to ≥1 scenario or integration step.
- `tests required` / `tests only`: `- [ ] {criterion} _(Unit N, scenarios X–Y)_`
- `integration only`: `- [ ] {criterion} _(Unit N, step N.M)_`
