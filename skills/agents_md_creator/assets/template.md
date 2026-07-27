# AGENTS.md

## Overview

[Brief description of the project and its purpose]

**Tech Stack**: [List main technologies with versions, e.g., React 18, TypeScript 5.2, Vite]

## Setup Commands

- Install dependencies: `[package manager] install`
- Start dev server: `[package manager] dev`
- Build: `[package manager] build`

## Testing

**Framework**: [Testing framework name]

- Run all tests: `[test command]`
- Watch mode: `[test command with watch flag]`
- Coverage: `[test command with coverage flag]`

All tests must pass before committing.

## Project Structure

- `src/` - [Description]
- `tests/` - [Description]
- `docs/` - [Description]
- `[other-dir]/` - [Description]

## Code Style

**Linter**: [Linter name and config file]
**Formatter**: [Formatter name]

### Naming Conventions
- Functions/variables: [convention]
- Components/Classes: [convention]
- Constants: [convention]
- Files: [convention]

### Good Example

```[language]
// Example of good code following project conventions
```

### Bad Example

```[language]
// Example of what to avoid
```

### Patterns to Follow
- [Pattern 1]
- [Pattern 2]
- [Pattern 3]

## Git Workflow

- **Branches**: [Naming convention, e.g., feature/, fix/, docs/]
- **Commits**: [Format, e.g., Conventional Commits]
  - `feat: description`
  - `fix: description`
  - `docs: description`
- **PRs**: [Requirements, e.g., all tests pass, description included]

## Security

- **Secrets**: [How to handle secrets, e.g., use .env.local]
- **API Keys**: [Where to store API keys]
- **Authentication**: [Auth approach]

## Boundaries

### ✅ Always Do
- Run tests before committing
- Follow naming conventions
- Update tests with code changes
- Use proper types/type hints
- Add documentation for public APIs

### ⚠️ Ask First
- Database schema changes
- Adding new dependencies
- Modifying CI/CD configuration
- Large refactoring affecting multiple modules
- Changing build or deployment processes

### 🚫 Never Do
- Commit secrets, API keys, or credentials
- Edit `node_modules/` or dependency directories
- Remove failing tests without fixing the underlying issue
- Push code that fails linting or tests
- Modify production configuration without review
