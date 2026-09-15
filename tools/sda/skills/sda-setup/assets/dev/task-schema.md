# Task Document Schema

## Template

```markdown
# Task: {name}

## Goal
{1-2 sentences: what and why.}

## Context
{Omit entirely for a standalone task.}
- **Workflow:** {id}. {slug}
- **Design:** [design.md](../../design.md)

## Scope
Feature: {feature-name}
Layer: {layer-name}

## Prerequisites
{Omit if the task has no setup dependencies.}
- [ ] `{ENV_VAR_NAME}` — {what it's for; how to obtain it}
- [ ] {service or tool} — {must be running/configured; how to verify}

## Design Approach
{Omit for small, obvious changes. Subsections must map 1:1 to
Implementation Plan units using the same `Unit N — {name}` headings;
`docs` units are exempt. Include `### Summary` for decisions that span
multiple units.}

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

### Unit 4 — {unit name}
**Type:** refactoring
**Area:** {area name}
**Language:** {langs — union of the per-file annotations}
**Source:** `{file-path}` ({langs})
**Related tests:** `{existing-test-path-or-folder}` ({langs})   <!-- optional — existing tests that cover the changed code paths, run as a regression check. Omit the line entirely when none exist. -->

#### Step 4.1 — {what this step does}

**`{symbol_name}`** _(rename to `{new_name}`)_
File: `{file-path}`

### Unit 5 — {unit name}
**Type:** docs
**Area:** {layer the doc belongs to, or `Global`}
**Language:** markdown

#### Step 5.1 — {file being written}

File: `{docs-path}`
Kind: {file type — e.g. `readme`, `index`, `cli`, `architecture`}
\`\`\`markdown
{complete file content — or, for an existing file, the anchor line plus the new content}
\`\`\`
```

---

## Schema Rules

### Goal
- 1-2 sentences: what the task accomplishes and why it matters.
- Omit implementation details — those belong in Design Approach.

### Context
- Placed directly above `## Scope` — `## Goal` stays the document's opening section.
- Workflow mode only: the workflow id + slug, and a relative link to the design record.
  Links are relative, so `../../design.md` resolves from the task's own folder.
- Omit the section entirely for a standalone task — never write an empty header.

### Scope
- Required. First line: `Feature: {name}` (exact match to a feature listed in
  the repo's `AGENTS.md` features section) or `Global` (cross-cutting /
  maintenance work not tied to a feature).
- Second line: `Layer: {layer}` — the architectural layer the task primarily
  touches (from the AI readme's architecture section / `architecture.md`),
  e.g. `Backend`, `Persistence`.

### Prerequisites
- Checkboxes (`- [ ]`). Omit section if none.
- Each entry: env var or service — name, purpose, how to obtain/verify.
- User marks `- [x]` when complete.
- Do not add setup dependencies to `## Regression Risks`.

### Design Approach
- High-level explanation of the solution — the "what and why" a dev needs before reading the detailed Implementation Plan.
- Subsections map 1:1 to Implementation Plan units: `### Unit N — {name}` (same name as the unit). `docs` units are exempt — their content is the file text itself.
- `### Summary` (optional) — overall decisions that span multiple units.
- Per-unit content uses **Problem/Context → Solution → Details** structure.
- **Problem:** for bug fixes and regressions (what is broken today).
- **Context:** for new features and refactors (relevant current state).
- **Solution:** bullet list — one decision per bullet, no justification prose.
- **Details:** optional — edge cases, backward compat, concurrency notes. Conceptual only: describe what could go wrong, not which file or function handles it. No file/function/type/class names, no code snippets, no import paths — those belong in the Implementation Plan.
- Keep per-unit descriptions proportional: trivial units (`integration only`, `refactoring`) get 2-3 lines; complex units get full Problem/Context + Solution + Details.
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
- Annotated: **tests required**, **tests only**, **integration only**, **refactoring**, or **docs**.
- **Area:** the project area the unit belongs to (e.g. `Backend`, `Frontend`, `Worker`), derived from the unit's file paths matched against the Area Index in `project-tools.md`. Multi-area units list comma-separated areas (e.g. `Backend, Frontend`). The Area field is mandatory — always present on every unit.
  - `docs` units: the layer the doc belongs to (`<layer>/docs/...`, `<layer>/README.md` → that layer); `Global` for repo-root readmes and the root `docs/` tree.
- **Per-file language.** Annotate every Source/Test path with the programming language(s) it contains: `` `src/repo.py` (python, postgres) ``.
- **Language:** header line = deduplicated **union** of the per-file annotations (e.g. `python, postgres`).
  - Fence tags on Changes / Test Context blocks must match the language of the code they contain.
  - Use dialect-specific names (`postgres`, not `sql`).
  - `docs` units: always `markdown` — docs units have no Source/Test paths to annotate.
- **Unit types:**
  - **tests required** — new behaviour: TDD cycle (RED → GREEN).
  - **tests only** — existing behaviour that lacks tests: write tests that pass against existing code.
  - **integration only** — wiring, config, re-exports: no scenarios, no new tests. Use step headings with change entries (Symbol layout); use `Algorithm:` for non-trivial logic.
  - **refactoring** — pure structural transformations: renames, file moves, extraction, restructure. No behaviour change, no new tests, no scenarios. Existing tests must pass. Changes blocks required. Use step headings with change entries.
  - **docs** — documentation this task's own changes make stale: AI readmes and the docs tree — never the requirements tree. **At most one per task, always the last unit.** Step entries carry the file content (see [Docs unit layout](#docs-unit-layout)). Exempt from [Unit sizing](#unit-sizing) caps.
- **Refactoring tasks:** use `refactoring` units for renames, extraction, and structural changes. For high-risk refactoring, precede with a `tests only` unit as a regression safety net. Reserve `tests required` for genuinely new behavior.
- **Ordering matters.** Foundational behaviour first, dependent behaviour after.
- **Structural prep:** renames, file merges, import rewiring → own `refactoring` unit before dependent units.

### Changes
- **`tests required` / `tests only` units:** optional — include when: complex algorithms, new type definitions, coordinated multi-file changes, tricky signatures. When omitted, dev agents derive signatures from Source files.
- **`integration only` and `refactoring` units:** always required — change entries are the unit's content.
- **`docs` units:** never used — the step entries are the unit's content (see [Docs unit layout](#docs-unit-layout)).
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

### Docs unit layout
- One step per file written. Heading: `#### Step N.M — {file being written}`.
- Entry:
  - `File: {path}` — repo-relative target path.
  - `Kind: {file type}` — e.g. `readme`, `index`, `cli`, `architecture`.
  - Content — one of:
    - **Full file** — fenced block with the complete file content (new files, or full rewrites).
    - **Anchored delta** — the anchor line from the existing file plus the new content in a fenced block (existing files). Mirrors **Modified symbols** in [Symbol layout](#symbol-layout).

### Test Context
- Mandatory for `tests required` and `tests only` units. Omit for `integration only`, `refactoring`, and `docs` units.
- Heading: `#### Test Context` (same level as `#### Step N.M`).
- Three subsections:
  - **Patterns:** one bullet per pattern — description, when to use, scenario numbers.
  - **Object construction:** Baseline (fenced code, shared setup) + Variations (one bullet per differing scenario). When a shared fixture/client/helper already exists for the unit, name it here as **reuse — do not recreate** (symbol + import) instead of re-specifying its construction.
  - **Mock boundaries:** one bullet group per mock target — header + sub-bullets per response variant.
- Source: read test file + source file during plan generation.
- Verify extracted patterns against coding standards. Write compliant version if original is non-compliant.

### Steps
- Heading: `#### Step N.M — {description}`.
- Each step contains Symbol layout entries (see **Symbol layout**) — or Docs unit layout entries for `docs` units. One logical change = one step. Independent changes = multiple steps.
- Entries in units with scenarios carry `— satisfies scenarios N–M` to link back to the `**Scenarios:**` section. Steps with no scenarios omit the annotation.
- Scenario numbering continuous across all steps and units.

### Scenarios
- Applies to `tests required` and `tests only` units only. `integration only`, `refactoring`, and `docs` units use step headings — no scenarios, no Given/When/Then.
- **Location:** Include a `**Scenarios:**` section immediately after the unit header (Type/Language/Source/Test lines), before `#### Test Context`. All scenario definitions live here — scenarios do NOT appear inside steps.
- **Format:** Numbered bold paragraphs `**N. {name}**` with `Given`/`When`/`Then` (flat bullets). Include `Expected (RED):` for `tests required` units.
- Cover happy path, errors, edge cases.

### Expected (RED)
- Required for every scenario in `tests required` units.
- Values:
  - `FAIL` — test should fail because production code doesn't exist yet.
  - `vacuous PASS — {reason}` — test passes trivially (e.g., empty collection, no-op stub, default return). Include reason so reviewer understands why it's not a real pass.
- Omit for `tests only`, `integration only`, `refactoring`, and `docs` units.

### Source and Test paths
- The `{langs}` placeholder means **one or more** comma-separated languages — a file may contain several (e.g. `python, postgres`).
- One or more comma-separated file paths, **each annotated in parentheses with the language(s) it contains**: `` `path` (python, postgres) ``.
- The annotation lists every programming language present in that file (dialect-specific: `postgres`, not `sql`).
- New files: creation path. Existing files: modification target.

### Acceptance Criteria
- Every criterion maps to ≥1 scenario or integration step.
- `tests required` / `tests only`: `- [ ] {criterion} _(Unit N, scenarios X–Y)_`
- `integration only` / `refactoring` / `docs`: `- [ ] {criterion} _(Unit N, step N.M)_`

### Scenarios test behaviour, never structure
Assert **observable behaviour**, never that a symbol exists or has a shape
(constant/type/field defined, importable, or signature-correct). Such checks
are tautologies — they pass the moment the symbol is typed.

Pure declarations (constants, types, enums, re-exports) are **`integration only`**
(no tests). Test a constant only through the behaviour that consumes it
(e.g. "request missing a required field is rejected" — not "`REQUIRED_FIELDS`
contains `name`").

When a scenario verifies a response/entity shape (which fields are
present/absent), it must also assert the returned **values** match the
source data from `Given:`. A shape-only check passes even when every
field is the wrong value.

| ✅ Do (behaviour) | 🚫 Don't (structure) |
|---|---|
| `GET /api/items returns 200 with items` | `ItemsController has a getItems method` |
| `Removing a method still serves the endpoint` | `findAll is not a property of the instance` |
| `Error returns 500` | `ErrorHandler class exists` |
| `Then: body[0] fields match createMockDoc() values; nameEn, descriptionEn absent` | `Then: body[0] has id, name; no descriptionEn` |

### Unit sizing
- Cap each unit at **6 scenarios**. When a behaviour needs more, split into
  multiple sequential units sharing the same Source/Test files.
- Number units with **plain integers only** (Unit 1, Unit 2) — never letters
  or suffixes (`2a`, `2b`).
- Split along behavioural seams (happy path, validation, edge cases) — never
  mid-behaviour.
- Renumber all later units so the sequence stays contiguous.
- Scenario numbering is continuous across all units — never resets per unit.
- Units are split by **boundary** and **size** only — never by language.
  A single unit may span multiple languages.
- **`docs` units are exempt from both caps.** They carry file content, not
  behaviour — one unit covers every affected doc file.

### Source-change, test, and docs consistency
When a `tests required` unit modifies source behaviour in ways that cause
pre-existing tests to fail, those tests must be addressed within the same
unit — never deferred to a later `tests only` unit.

- List the affected tests explicitly in the unit's scope.
- Include their removal or update in the unit's Changes alongside the
  source changes.

A `docs` unit's content is written from the **predicted** state in the code
units' Changes blocks — it has no test to catch a mismatch. When an
implementation deviates from its Changes block in a way that changes a fact
the `docs` unit states (symbol name, path, signature, default value,
flag/config/env key, observable behaviour), the `docs` unit's content must be
re-synced **before** that unit runs.

- Facts the `docs` unit does not mention are unaffected — no action.
- Correct replacement text cannot be determined → stop and escalate.

### End-to-end deliverability
Every task must produce a **self-consistent, reachable result** — not dead
code. Before finalizing the implementation plan, verify:
- All layers required for the feature to be invocable end-to-end are covered
  (UI, API, persistence, localization, routing, etc.).
- No unit produces code that nothing calls or renders.
- If a layer is intentionally deferred to a follow-up task, state this
  explicitly in Design Approach with a reference to the planned task.

**Self-check:** _"After implementing this task, can a user (or system) actually
trigger the new behavior through the normal entry point?"_ If no, the task is
incomplete.

**Exception — maintenance tasks:** Bugfixes, test coverage, and refactors are
exempt.

### Self-containment
`task.md` must be **self-contained for implementation**. Dev agents work from
`task.md` alone — they do not read design docs or explore the codebase for
design decisions.

**Intra-document references satisfy self-containment.** When multiple units
follow the same mechanical pattern, define it fully in the first unit;
subsequent units reference it by name and specify only deltas (different
routes, schemas, constants). The implementer reads Unit 1 for the full
definition — no external file is needed.
