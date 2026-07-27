# Development Guidance

How to develop software — process, methodology, and decision-making
strategy. Language-agnostic. Loaded alongside coding standards
(which define *what good code looks like*).

## Table of Contents

- [Test-Driven Development](#test-driven-development)
- [Development Workflow](#development-workflow)
- [Diagnostic Strategy](#diagnostic-strategy)
- [Standards-First Decision Making](#standards-first-decision-making)
- [Constant Management Strategy](#constant-management-strategy)
- [Quality Gates](#quality-gates)
- [Code Review Criteria](#code-review-criteria)

## Test-Driven Development

**MANDATORY WORKFLOW**: Use Test-Driven Development for ALL code.

**The only acceptable workflow**: Test FIRST → Implementation SECOND →
Refactor THIRD.

### The TDD Cycle

1. **RED**: Write a failing test that describes the desired behavior
2. **GREEN**: Write the simplest code that makes the test pass
3. **REFACTOR**: Clean up code while keeping all tests passing

### When to Use TDD

- ✅ **ALWAYS** — every new feature, every bug fix
- ✅ Bug fix requires a failing test first, then the fix
- ✅ Before refactoring, ensure tests pass; after, ensure they still pass

### Absolute Requirements

- ✅ Write the test BEFORE writing any implementation
- ✅ Each test verifies ONE specific behavior
- ✅ New code MUST have >95% test coverage
- ❌ FORBIDDEN: Writing implementation first, then adding tests
- ❌ FORBIDDEN: Skipping tests for any reason

## Development Workflow

**Follow this order:**

1. **Plan** — design the component architecture and interfaces
2. **RED** — write a failing test defining expected behavior
3. **GREEN** — write minimal code to make the test pass
4. **REFACTOR** — clean up while keeping tests passing
5. **Document** — add documentation comments
6. **Verify** — confirm TDD was followed and all standards are met

## Diagnostic Strategy

**RULE**: When a command (test run, build, lint, type check) produces
an unexpected result, diagnose before acting:

1. Re-read applicable standards (testing, coding, style) — look for
   a rule that covers the symptom.
2. Check available skills for diagnostic/troubleshooting guidance.
3. Fix the root cause in code (fixtures, imports, mocks, type
   annotations). Never work around with shell commands, environment
   manipulation, or ad-hoc scripts.

**Do not guess.** Unexpected failures have a cause. Read the error,
match it to a known pattern, then fix.

## Standards-First Decision Making

**RULE**: Consult loaded coding standards *before* making implementation
choices — not only after, for verification.

Standards apply to process decisions too — how to run tests, how to
resolve failures, which approach to take — not only to code output.

When facing a choice:

1. Check whether a loaded standard covers the situation.
2. If yes → follow the standard. Do not evaluate alternatives.
3. If no → evaluate once, choose, execute. Do not revisit.

## Constant Management Strategy

**RULE**: Before creating a new constant, search for an existing one
with the same conceptual value.

**Process:**

1. **Search** — look in the current file, related modules, and shared
   constant files for a constant representing the same value.
2. **Reuse** — if one exists, import it. Do not define a duplicate.
3. **Promote** — if it exists in another module and is now needed in
   two places, move it to a shared location.
4. **Create** — only when no equivalent exists. Follow naming
   conventions from the language's `coding-standards.md`.

**Atomic replacement:** When creating a constant, replace ALL
occurrences of that literal in scope — or do not create it.

## Quality Gates

All gates must pass before work is considered complete.

- All tests must pass
- >95% code coverage for new code
- Static type checker passes in strict mode
- Zero magic numbers/strings in production code, controlled usage
  in test code

## Code Review Criteria

1. **Functionality** — works correctly, handles edge cases
2. **Standards** — follows all loaded coding standards
3. **Magic Values** — zero hardcoded numbers/strings in production code
4. **Type Safety** — proper type annotations, no untyped parameters
5. **SOLID Principles** — clean design patterns
6. **Documentation** — clear, up-to-date documentation comments
