---
name: development-guidance
description: "Development methodology and workflow guidance. MUST be loaded before any task that involves developing new features, fixing bugs, refactoring code, or running TDD workflows. Covers: TDD cycle (RED → GREEN → REFACTOR), diagnostic strategy for unexpected failures, standards-first decision making, constant management, quality gates, and code review criteria. Complements standards-compliance (which defines what good code looks like) by defining how to produce good code. Do NOT use for: trivial edits (renaming, formatting), pure documentation changes, or code review without implementation."
---

# Development Guidance

Behavioral rules for following development methodology when
producing code. Language-agnostic — works with any language.

## When to Use

- Implementing a new feature or fixing a bug
- Running a TDD workflow (RED → GREEN → REFACTOR)
- Refactoring existing code
- Diagnosing unexpected command results (test failures, build
  errors, lint violations)

---

## Guidance: Global and Local

### Two layers

| Layer | Location | Scope |
|---|---|---|
| **Global** | Bundled with this skill: `./resources/` | Baseline process for any project |
| **Local** | Workspace-specific, discovered automatically | Project-specific workflow overrides |

### Priority — local wins

When a process rule exists in **both** global and local guidance,
the **local version takes precedence**. Local guidance may:
- Add project-specific workflow steps
- Override a global process rule when justified
- Extend quality gates with project-specific checks

### Global guidance file structure

Global guidance is **bundled inside this skill's folder** at
`./resources/` (relative to this SKILL.md). These files are internal
skill resources — **read them directly without asking the user for
permission.**

```
resources/
└── development-guidance.md  ← process rules (loaded for every task)
```

### Local guidance discovery

Local guidance is discovered automatically when the workspace contains
development workflow files referenced by its documentation (readme
files, agent configuration, etc.). If found, local guidance takes
precedence over global.

---

## Application Rules

### 1. TDD is mandatory

All code changes follow the TDD cycle described in the guidance.
Test first, implement second, refactor third. No exceptions.

### 2. Relationship with coding standards

This skill defines **how** to develop. The `standards-compliance`
skill defines **what** good code looks like. Both apply simultaneously:

- Development guidance governs **process** — workflow order,
  diagnostic strategy, decision-making approach.
- Coding standards govern **output** — type annotations, naming,
  imports, test structure, magic number prevention.

When both are loaded, follow the development process from this skill
and write code that complies with loaded standards.

### 3. Diagnostic strategy overrides guessing

When a command produces an unexpected result, follow the diagnostic
process in the guidance. Do not guess, retry blindly, or work around
with shell commands.

### 4. Quality gates are non-negotiable

All quality gates defined in the guidance must pass before work is
considered complete. If a gate fails, diagnose and fix — do not skip.

---

## How to Apply

1. Read the guidance file **in full** from `./resources/` — it is a
   bundled skill resource, no user confirmation needed.
2. Follow the TDD cycle for all code changes.
3. Apply the diagnostic strategy when commands produce unexpected
   results.
4. Consult loaded coding standards before making implementation
   choices (standards-first decision making).
5. Run all quality gates before declaring work complete.
