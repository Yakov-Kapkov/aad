# Common Standards

Language-agnostic rules. Loaded alongside every language's standards files.

## Table of Contents

- [SOLID Design Principles](#solid-design-principles)
- [Constant Reuse](#constant-reuse)
- [Unit Test Scope](#unit-test-scope)
- [Behavioral Testing](#behavioral-testing)
- [Test Structure: AAA](#test-structure-aaa)
- [Test Constants](#test-constants)
- [Derive Expected Values from Mocked Data](#derive-expected-values-from-mocked-data)
- [Clean Code Practices](#clean-code-practices)
- [Comments: Explain Why Not What](#comments-explain-why-not-what)
- [Anti-Patterns](#anti-patterns)

## SOLID Design Principles

- **Single Responsibility**: Each class/function has one clear purpose
- **Open/Closed**: Extensible without modification
- **Liskov Substitution**: Derived classes are substitutable for base classes
- **Interface Segregation**: Clean, focused interfaces
- **Dependency Inversion**: Depend on abstractions, not implementations

## Constant Reuse

**RULE**: One constant, one value. Before defining a new constant,
check whether one already exists for that conceptual value. Reuse it.

- Exists in same module → reference it.
- Exists in another module → promote to shared location, import.
- No equivalent exists → create new.

## Unit Test Scope

**RULE**: Unit tests MUST test only ONE module. All other modules MUST be mocked.

**Mock:** External APIs, databases, file system, other codebase modules, time/date.
**Do not mock:** Standard library data structures, the module under test, simple value objects.

**No real I/O:** No HTTP requests, sockets, or DB connections. Every external endpoint must be mocked.

**No real config or credentials:** Use hardcoded fake values for URLs, API keys, tokens, connection strings. Never load from real config files or environment.

## Behavioral Testing

**RULE**: Tests MUST verify **observable behavior**, NOT internal implementation.

**Avoid asserting on:** SQL text, internal call counts (unless the call *is* the behavior), private state, argument shapes between layers.

**Assert on:** Return values, HTTP status/body, observable side effects, error messages shown to the user.

## Test Structure: AAA

**RULE**: Every test MUST use `Arrange`, `Act`, `Assert` comments. Blank line before each section (except the first). Combine when a standalone section would be empty (`Act & Assert`, `Arrange & Act`). No freeform text after the label.

## Test Constants

**LOCAL constants**: Expected/assertion values used in ONE test only.
**DIRECT literals**: In parameterized-test arrays, mock-only values (never asserted on), simple setup.
**GLOBAL/MODULE constants**: Value asserted in 2+ tests, shared fixture values, test infrastructure.

**Production constants in tests:** When a production constant is the
source of truth for parameterized values, import and reuse it — do not duplicate its values as raw
strings. This follows the Constant Reuse rule.

**Avoid:**
- Global for single-test values
- Math with globals (`GLOBAL + 1`)
- Test-only globals just for parameterize (import the production constant instead)
- Globals for coincidentally identical values testing different things

**Atomic replacement**: When creating a constant, replace ALL occurrences or don't create it.

## Derive Expected Values from Mocked Data

**RULE**: Every assertion value originating from a mock, fixture, or
test constant MUST be referenced from that source — never re-typed
as a literal.

- If the same value appears in both mock setup and assertion, extract
  it into a LOCAL constant and reference it in both places.
- "Mock-only values" (DIRECT tier) are values consumed by the mock
  but never checked in any assertion — those may remain as literals.

## Clean Code Practices

- **Descriptive Naming**: Names clearly express intent
- **Small Functions/Methods**: Single responsibility, <20 lines
- **Type Annotations**: Full annotation — see language `coding-standards.md`
- **Documentation**: Doc comments for public APIs — see language `coding-standards.md`
- **Error Handling**: Defensive programming with custom exceptions
- **Import Organization**: All imports at file top — see language `coding-standards.md`

## Comments: Explain Why Not What

**Explain:** WHY (algorithm choice, design decisions), edge cases, business logic.
**Do not comment:** Magic numbers (use constants), bad code (refactor), obvious code.

**Domain language only.** Use domain terminology — not workflow identifiers ("Slice 1", "Phase RED").

## Anti-Patterns

- **Magic Numbers/Strings**: Use named constants — see language `coding-standards.md`
- **God Objects**: Classes doing too many things
- **Deep Nesting**: >3 levels of indentation
- **Tight Coupling**: Classes knowing too much about internals
- **Untested Code**: Missing unit tests
- **Orphaned Constants**: Never used (delete), used once (make local), or partially used (complete refactoring)
