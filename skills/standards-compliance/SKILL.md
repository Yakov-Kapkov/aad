---
name: standards-compliance
description: "Enforce project coding standards on all produced code changes. Also use as a pre-write reference — load standards before writing code so all decisions follow the rules from the start. MUST be loaded before any task that writes, modifies, refactors, or reviews code — including implementation, refactoring, adding comments, renaming, fixing bugs, and any other code change no matter how small. Contains the authoritative rule content from common-standards.md, coding-standards.md, testing-standards.md, and code-style.md. Agent instructions summarize standards behavior only — the actual rules are in this skill and must be loaded explicitly. Resolves conflicts between task specs and standards. Defines global/local priority and scope-specific application rules."
---

# Standards Compliance Enforcement

**Read this file in full before taking any action.** Do not proceed until
every line of this SKILL.md has been read — rules in later sections govern
critical decisions.

Behavioral rules for enforcing coding standards on all produced code.
Language-agnostic — works with any language that has standards files.

## When to Use

- **Before writing code** — load standards as reference so all
  coding decisions (naming, types, imports, structure, style) follow
  the rules from the start
- Writing or modifying **any** file: production code, tests, stubs,
  integration wiring
- Resolving conflicts between a task spec and coding standards
- Validating code examples in task specifications

---

## Standards: Global and Local

### Two layers

| Layer | Location | Scope |
|---|---|---|
| **Global** | Bundled with this skill: `./standards/{language}/` | Baseline rules for any project |
| **Local** | Workspace-specific, discovered automatically | Project-specific overrides and additions |

### Priority — local wins

When a rule exists in **both** global and local standards, the **local
version takes precedence**. Local standards may:
- Override a global rule (e.g., stricter naming convention)
- Add project-specific rules not covered globally
- Relax a global rule when justified for this project

**Merge strategy:**
1. Load global standards for the detected language
2. If local standards are present in the workspace (discovered via
   workspace documentation, readme files, or agent configuration),
   load them as well
3. For any conflicting rule, apply the local version
4. Rules that exist only in global → apply as-is
5. Rules that exist only in local → apply as-is

### Global standards file structure

Global standards are **bundled inside this skill's folder** at
`./standards/` (relative to this SKILL.md). These files are internal
skill resources — **read them directly without asking the user for
permission.** They are not external files; they ship with the skill and
must be loaded autonomously.

```
standards/
├── common-standards.md  ← language-agnostic rules (loaded for every language)
├── python/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── code-style.md
├── typescript/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── code-style.md
└── {language}/          ← add new languages here; not all files required
    └── ...
```

`common-standards.md` contains language-agnostic rules (SOLID, AAA,
behavioral testing, unit test scope, derive-from-mocks). It is loaded
alongside every language's files — its rules apply universally.

New languages are added by creating a `standards/{language}/` folder
with the applicable standards files.

### Local standards discovery

Local standards are not configured explicitly. They are discovered
automatically when the workspace contains coding standards files
referenced by its documentation (readme files, agent configuration,
etc.). If the agent can locate workspace-specific standards, those
are used as local standards and take precedence over global ones.
If no local standards are found, global standards apply as the
sole source.

When a language has **neither** global nor local standards, do not block:
apply general best practices for that language and state once:
_"No standards for `{language}` — applying general best practices."_

---

## Enforcement Rules

### 1. Universal compliance — no exceptions

**All produced or modified code must comply with all loaded standards.**

This applies to every file type: stubs, tests, implementation, and
integration changes alike. Write compliant code from the start —
do not write non-compliant code and fix it after.

### 2. Conflict resolution — standards win over task specs

Task documents (`task.md`, user descriptions, attached specs) are
**behavioral specs, not code specs.** Code snippets and type definitions
illustrate intent — not authorized final syntax.

When any detail in a task document conflicts with loaded standards:

| Conflict | Resolution |
|---|---|
| Magic strings/numbers | Use named constants per standards |
| Naming conventions | Follow standards |
| Type patterns | Follow standards |
| Import organization | Follow standards |
| Docstring format | Follow standards |

**Adapt the implementation to satisfy both the task's behavioral intent
and every applicable standard.**

### 3. Scope-specific application

Apply the relevant standards files based on what you're writing:

- **All code** — `common-standards.md` (always loaded)
- **Production code** — `coding-standards.md` + `code-style.md`
- **Test code** — `coding-standards.md` + `testing-standards.md` + `code-style.md`
- **Stubs** — all production standards apply; function/method bodies
  throw unambiguous "not implemented" error; only export symbols that
  tests reference

### 4. Task specification validation

When reviewing or producing code examples in task documents (`task.md`):

- **Executable code blocks** (imports, function signatures, class
  definitions) must comply with coding standards
- **Behavioral descriptions** (Given/When/Then prose, acceptance
  criteria text) are exempt — they describe intent, not code
- Flag non-compliant examples and suggest corrections

---

## How to Read Standards Files

These rules apply every time standards files are read — whether for
pre-write reference or post-write evaluation.

1. Determine the language and what you will write or verify (production
   code, tests, or both) to select applicable files (see §3
   Scope-specific application).
2. Read each applicable standards file **in full** (line 1 through end
   of file) from the skill's `./standards/` folder — these are bundled
   skill resources, no user confirmation needed. Read all applicable
   files in parallel. **Use a single read call per file with a range
   large enough to cover the entire file (e.g., lines 1–500).** If the
   file is longer than the returned range, issue another read for the
   remaining lines immediately — do NOT proceed until every standards
   file has been read from first line to last line.
3. Do not re-derive or paraphrase rules — read the standard, apply it
   directly.

### Pre-write: load as reference

Use **before writing any code** so all decisions follow the rules from
the start.

After completing steps 1–3 above, treat the loaded standards as the
authoritative guide for all subsequent code in this task. Follow the
rules, patterns, and examples directly.

### Post-write: evaluate compliance

Use **after writing code** to verify and fix violations.

After completing steps 1–3 above:

4. Compare produced code against all applicable rules.
5. Report result:
   - **✅ All standards met**, or
   - **List of fixes applied** — file path and what changed for each
