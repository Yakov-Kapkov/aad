# Development Workflow and Quality Gates

**INSTRUCTION FOR AI ASSISTANT**: These are MANDATORY rules for the development process, methodology, and quality requirements.

## Test-Driven Development (TDD)

**MANDATORY WORKFLOW**: You MUST use Test-Driven Development for ALL code. Tests FIRST → Implementation SECOND → Refactor THIRD.

### The TDD Cycle
1. **RED**: Write a failing test that describes expected behavior
   - **MANDATORY CHECKPOINT**: After writing or modifying tests, present them to user: "I've written [N] tests covering [list scenarios]. Please confirm these are comprehensive before I implement the code."
   - **WAIT** for explicit user approval before proceeding
   - ⚠️ **RE-APPROVAL REQUIRED**: If the user comments on, revises, or requests changes to the tests — even minor ones — you MUST update the tests and then **ask for approval again** before writing any implementation. Do NOT assume prior approval still holds after any test change.
   - ⚠️ **RE-APPROVAL REQUIRED**: If you add, remove, or modify any tests for any reason (e.g., covering additional edge cases, fixing a test), you MUST present the updated test suite and **wait for explicit approval again** before proceeding to implementation.
2. **GREEN**: Write the simplest code that makes the test pass
3. **REFACTOR**: Clean up code while keeping all tests passing

### Approval Rules Summary

| Situation | Action Required |
|-----------|----------------|
| Tests written for the first time | Ask for approval |
| You add more tests (any reason) | Ask for approval again |
| User comments on or edits tests | Incorporate changes, then ask for approval again |
| User explicitly says "looks good" or approves | Proceed to implementation |
| Any doubt whether approval is still valid | Ask again |

### Absolute Requirements
- ✅ **ALWAYS write tests BEFORE implementation** - every feature, bug fix, and refactoring
- ✅ Each test verifies ONE specific behavior only
- ✅ New code MUST have >95% test coverage
- ✅ All tests MUST pass before and after refactoring
- ✅ **ALWAYS re-request approval after any test modification**, regardless of how small
- ❌ **FORBIDDEN**: Writing implementation first, skipping tests
- ❌ **FORBIDDEN**: Proceeding to implementation after tests were changed without re-approval

## Development Workflow

**FOLLOW THIS ORDER**:
1. **Plan**: Design component architecture and interfaces
2. **RED**: Write failing tests that define expected behavior
3. **MANDATORY CHECKPOINT**: Present tests to user and wait for explicit approval
4. *(If user requests test changes)* → Update tests → **Return to step 3**
5. **GREEN**: Write minimal code to make tests pass (only after approval)
6. **REFACTOR**: Clean up code while keeping tests passing
7. **Document**: Add docstrings and comments
8. **Verify**: Confirm TDD and all coding standards followed

## Code Review Criteria

Verify code meets:
1. **Functionality**: Works correctly, handles edge cases
2. **Standards Compliance**: All rules in `standards/{language}/coding-standards.md`, `standards/{language}/testing-standards.md`, `standards/{language}/code-style.md`
3. **Magic Values**: Zero hardcoded values (see `standards/{language}/coding-standards.md`)
4. **Type Safety**: Proper hints, mypy compliant (see `standards/{language}/coding-standards.md`)
5. **SOLID Principles**: Clean design (see `standards/{language}/coding-standards.md`)
6. **Documentation**: Clear docstrings and comments (see `standards/{language}/code-style.md`)

## Quality Gates

All must pass:
- All tests passing
- >95% code coverage for new code
- mypy static analysis passes
- Zero magic numbers/strings in production code, controlled usage in test code
