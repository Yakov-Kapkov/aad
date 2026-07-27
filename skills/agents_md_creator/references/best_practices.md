# AGENTS.md Best Practices

This guide compiles insights from analyzing 2,500+ AGENTS.md files and expert recommendations from the AI coding community.

## Table of Contents

- [Core Principles](#core-principles)
- [What Works in Practice](#what-works-in-practice)
- [File Structure](#file-structure)
- [Key Sections](#key-sections)
- [Writing Guidelines](#writing-guidelines)
- [Common Mistakes](#common-mistakes)
- [Examples](#examples)

## Core Principles

### AGENTS.md vs README.md

- **README.md**: For humans - quick starts, project descriptions, contribution guidelines
- **AGENTS.md**: For AI agents - build steps, tests, detailed conventions, boundaries

Keep them separate to:
- Give agents a clear, predictable place for instructions
- Keep READMEs concise and focused on human contributors
- Provide precise, agent-focused guidance without cluttering README

### Single Source of Truth

- Don't duplicate README or wiki content
- Link to existing documentation
- Keep only critical information for agents
- Update when conventions change

### Treat as Living Documentation

- Update AGENTS.md in the same PR as code changes
- Reviewers should check AGENTS.md quality
- Test that commands still work
- Remove outdated information promptly

## What Works in Practice

Based on analysis of 2,500+ repositories, successful AGENTS.md files share these characteristics:

### 1. Put Commands Early

Place executable commands in early sections:
```markdown
## Setup
- Install: `pnpm install`
- Dev server: `pnpm dev`
- Tests: `pnpm test`
- Build: `pnpm build`
```

**Why it works**: Agents reference commands frequently. Early placement reduces context search time.

### 2. Code Examples Over Explanations

One real code snippet beats three paragraphs:

**Bad**:
```markdown
Functions should have descriptive names, proper error handling, and return types.
```

**Good**:
```markdown
## Code Style

### Good Example
\```typescript
async function fetchUserById(id: string): Promise<User> {
  if (!id) throw new Error('User ID required')
  const response = await api.get(`/users/${id}`)
  return response.data
}
\```

### Bad Example
\```typescript
async function get(x) {
  return await api.get('/users/' + x).data
}
\```
```

### 3. Set Clear Boundaries

Use a three-tier system:

```markdown
## Boundaries

- ✅ **Always do**: Write tests for new features, run linter before commit, follow naming conventions
- ⚠️ **Ask first**: Database schema changes, adding dependencies, modifying CI/CD
- 🚫 **Never do**: Commit secrets/API keys, edit `node_modules/`, remove failing tests
```

**Why it matters**: "Never commit secrets" was the most common constraint in successful files.

### 4. Be Specific About Tech Stack

**Bad**: "React project"

**Good**: "React 18 with TypeScript 5.2, Vite 5.0, Tailwind CSS 3.4"

Include:
- Framework versions
- Key dependencies
- Build tools
- Testing framework

### 5. Cover Six Core Areas

Top-tier AGENTS.md files include:

1. **Commands**: Build, test, lint, dev server
2. **Testing**: How to run, frameworks used, coverage requirements
3. **Project structure**: Key directories and their purposes
4. **Code style**: Naming conventions, formatting, patterns
5. **Git workflow**: Branching, commits, PR requirements
6. **Boundaries**: What agents can/can't do

### 6. Keep It Concise

Target ≤150 lines:
- Use bullet points and code blocks
- Link to detailed docs instead of duplicating
- Remove obvious or redundant information
- Be value-dense

## File Structure

### Required Sections

#### Setup Commands
```markdown
## Setup

- Install dependencies: `npm install`
- Start dev server: `npm run dev`
- Build: `npm run build`
```

#### Testing
```markdown
## Testing

- Run all tests: `npm test`
- Run with coverage: `npm test -- --coverage`
- Run specific test: `npm test path/to/test.spec.ts`
- All tests must pass before PR merge
```

#### Boundaries
```markdown
## Boundaries

- ✅ **Always**: Run tests, update docs, follow style guide
- ⚠️ **Ask first**: Schema changes, new dependencies
- 🚫 **Never**: Commit secrets, modify config without approval
```

### Recommended Sections

#### Project Overview
```markdown
## Project Overview

This is a customer-facing dashboard built with React and TypeScript.
It connects to a GraphQL API and displays real-time analytics.

**Tech Stack**: React 18, TypeScript 5.2, Vite, Apollo Client, Tailwind CSS
```

#### Code Style
```markdown
## Code Style

- **Language**: TypeScript strict mode
- **Formatting**: Prettier with single quotes, no semicolons
- **Linting**: ESLint with React and TypeScript rules
- **Naming**:
  - Functions/variables: camelCase
  - Components/Classes: PascalCase
  - Constants: UPPER_SNAKE_CASE
  - Files: kebab-case
```

#### Git Workflow
```markdown
## Git Workflow

- **Branches**: `feature/description`, `fix/description`, `docs/description`
- **Commits**: Use Conventional Commits format
  - `feat: add user authentication`
  - `fix: resolve login timeout issue`
  - `docs: update API documentation`
- **PRs**: Must include description, pass tests, and have at least one approval
```

#### Security
```markdown
## Security

- **Secrets**: Never commit to repo. Use `.env.local` (gitignored)
- **API Keys**: Store in environment variables
- **Dependencies**: Run `npm audit` before adding packages
- **Authentication**: All API calls require valid JWT token
```

### Optional Sections

#### Project Structure
```markdown
## Project Structure

- `src/components/` - React components
- `src/hooks/` - Custom React hooks
- `src/services/` - API service layer
- `src/utils/` - Utility functions
- `tests/` - Unit and integration tests
- `docs/` - Additional documentation
```

#### Deployment
```markdown
## Deployment

- **Dev**: Auto-deploys from `develop` branch to dev.example.com
- **Staging**: Manual deploy from `staging` branch
- **Production**: Only via release tags, requires approval

Build for production: `npm run build`
Preview build: `npm run preview`
```

## Key Sections

### Commands Section

**Best practices**:
- Include exact commands with all flags
- Group by purpose (setup, testing, building, deployment)
- Add brief descriptions
- Use code blocks for easy copying

**Example**:
```markdown
## Commands

### Setup
- Install dependencies: `pnpm install`
- Install specific package: `pnpm install --filter <package_name>`

### Development
- Start dev server: `pnpm dev`
- Start with debugging: `pnpm dev --debug`
- Navigate to package: `pnpm dlx turbo run where <project_name>`

### Testing
- Run all tests: `pnpm test`
- Run with coverage: `pnpm test -- --coverage`
- Run specific test: `pnpm vitest run -t "<test name>"`
- Watch mode: `pnpm test -- --watch`

### Building
- Build for production: `pnpm build`
- Build specific package: `pnpm turbo run build --filter <package_name>`
- Clean build: `pnpm clean && pnpm build`

### Linting
- Check code: `pnpm lint`
- Auto-fix issues: `pnpm lint --fix`
- Check formatting: `pnpm format:check`
```

### Testing Section

**Best practices**:
- Specify test framework and version
- Include coverage requirements
- Explain how to run different test types
- Link to CI configuration

**Example**:
```markdown
## Testing

**Framework**: Jest 29 with React Testing Library

### Running Tests
- All tests: `npm test`
- Watch mode: `npm test -- --watch`
- Coverage: `npm test -- --coverage` (minimum 80% required)
- Specific file: `npm test -- path/to/test.spec.ts`
- Update snapshots: `npm test -- -u`

### Test Organization
- Unit tests: `*.spec.ts` files next to source
- Integration tests: `tests/integration/`
- E2E tests: `tests/e2e/` (run with `npm run test:e2e`)

### Best Practices
- Write tests for all new features
- Update tests when modifying code
- Mock external dependencies
- Use descriptive test names

### CI
Tests run automatically on PR creation. See `.github/workflows/test.yml`.
```

### Code Style Section

**Best practices**:
- Show examples, don't just list rules
- Include both good and bad examples
- Cover naming conventions
- Reference linter configuration

**Example**:
```markdown
## Code Style

**Linter**: ESLint + Prettier
**Config**: See `.eslintrc.json` and `.prettierrc`

### Formatting
- Quotes: Single
- Semicolons: No
- Indentation: 2 spaces
- Line length: 100 characters max

### Naming Conventions
- Functions/variables: `camelCase`
- Components/Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Files: `kebab-case.ts`
- Test files: `component-name.spec.ts`

### Good Examples

\```typescript
// Component with proper typing
interface UserProfileProps {
  userId: string
  onUpdate: (user: User) => void
}

export function UserProfile({ userId, onUpdate }: UserProfileProps) {
  const [user, setUser] = useState<User | null>(null)
  
  useEffect(() => {
    fetchUser(userId).then(setUser)
  }, [userId])
  
  return <div>{user?.name}</div>
}
\```

\```typescript
// Async function with proper error handling
async function fetchUserData(id: string): Promise<User> {
  if (!id) {
    throw new Error('User ID is required')
  }
  
  try {
    const response = await api.get(`/users/${id}`)
    return response.data
  } catch (error) {
    logger.error('Failed to fetch user', { id, error })
    throw error
  }
}
\```

### Bad Examples

\```typescript
// ❌ Vague names, no types, no error handling
async function get(x) {
  return await api.get('/users/' + x).data
}
\```

\```typescript
// ❌ No prop types, inline styles, missing key
function List(props) {
  return (
    <div style={{ padding: '10px' }}>
      {props.items.map(i => <div>{i}</div>)}
    </div>
  )
}
\```

### Patterns to Follow
- Use functional components with hooks
- Prefer composition over inheritance
- Keep components small and focused
- Extract custom hooks for reusable logic
- Use TypeScript strict mode
```

### Boundaries Section

**Best practices**:
- Use three tiers: Always / Ask first / Never
- Be specific and actionable
- Include security considerations
- Mention protected files/directories

**Example**:
```markdown
## Boundaries

### ✅ Always Do
- Run `npm test` before committing
- Run `npm run lint --fix` to auto-fix style issues
- Write or update tests for code changes
- Follow naming conventions
- Update documentation when changing APIs
- Use TypeScript strict types
- Add JSDoc comments for exported functions

### ⚠️ Ask First
- Database schema changes (discuss with backend team)
- Adding new dependencies (consider bundle size)
- Modifying CI/CD configuration
- Changing build configuration (webpack, vite, etc.)
- Modifying Docker files
- Large refactoring that affects multiple components
- Changing authentication/authorization logic

### 🚫 Never Do
- Commit secrets, API keys, or credentials
- Edit files in `node_modules/` or `vendor/`
- Remove failing tests without fixing the underlying issue
- Disable TypeScript strict mode
- Commit directly to `main` or `production` branches
- Push code that doesn't pass linting
- Modify database schema in production without migration
- Hard-code environment-specific values
```

## Writing Guidelines

### Use Imperative Voice

Write instructions as commands:
- ✅ "Run `npm test` before committing"
- ❌ "Tests should be run before committing"

### Be Specific and Executable

Every command should work exactly as written:
- ✅ `pytest -v --cov=src tests/`
- ❌ "Run tests with coverage"

### Group Related Information

Use clear headings and subheadings:
```markdown
## Development

### Setup
...

### Running Locally
...

### Debugging
...
```

### Use Code Blocks Liberally

Wrap all commands and code in backticks:
- Inline: `npm install`
- Block:
```bash
npm install
npm run dev
```

### Link to Detailed Docs

Don't duplicate extensive documentation:
```markdown
## API Documentation

For detailed API docs, see [docs/api.md](docs/api.md).

Quick reference:
- Base URL: `https://api.example.com`
- Auth: Bearer token in `Authorization` header
- Rate limit: 1000 requests/hour
```

## Common Mistakes

### Too Vague

❌ "Follow best practices"
✅ "Use camelCase for functions, PascalCase for classes"

❌ "Run tests"
✅ "`npm test -- --coverage` (must maintain 80% coverage)"

### Too Long

❌ 500 lines duplicating README and wiki content
✅ ≤150 lines with links to detailed documentation

### Missing Commands

❌ "Build the project before deploying"
✅ "Build: `npm run build && npm run test:e2e`"

### No Examples

❌ "Write clean, maintainable code"
✅ [Show example of clean vs. messy code]

### Weak Boundaries

❌ "Be careful with secrets"
✅ "🚫 Never commit secrets, API keys, or `.env` files. Use `.env.local` (gitignored) for local development."

### Outdated Information

❌ Commands that no longer work
✅ Regularly verify and update commands

## Examples

### Minimal AGENTS.md (Small Project)

```markdown
# AGENTS.md

## Setup
- Install: `npm install`
- Dev: `npm run dev`
- Build: `npm run build`

## Testing
- Run tests: `npm test`
- Coverage: `npm test -- --coverage`

## Code Style
- TypeScript strict mode
- Prettier: single quotes, no semicolons
- Run `npm run lint --fix` before committing

## Boundaries
- ✅ Run tests before committing
- 🚫 Never commit secrets or edit `node_modules/`
```

### Comprehensive AGENTS.md (Large Project)

```markdown
# AGENTS.md

## Overview

React 18 + TypeScript 5.2 customer dashboard with real-time analytics.

**Stack**: Vite, Apollo Client, Tailwind CSS, Jest, React Testing Library

## Setup Commands

- Install: `pnpm install`
- Dev server: `pnpm dev` (runs on http://localhost:5173)
- Build: `pnpm build`
- Preview: `pnpm preview`

## Testing

**Framework**: Jest 29 + React Testing Library

- All tests: `pnpm test`
- Watch: `pnpm test -- --watch`
- Coverage: `pnpm test -- --coverage` (min 80% required)
- E2E: `pnpm test:e2e` (requires dev server running)

Tests must pass before PR merge. CI config: `.github/workflows/test.yml`

## Project Structure

- `src/components/` - React components
- `src/hooks/` - Custom hooks
- `src/services/` - API layer (Apollo Client)
- `src/utils/` - Helper functions
- `tests/` - Test files

## Code Style

**Linter**: ESLint + Prettier (see `.eslintrc.json`)

### Conventions
- Functions: camelCase
- Components: PascalCase
- Constants: UPPER_SNAKE_CASE
- Files: kebab-case.tsx

### Good Example
\```typescript
interface UserCardProps {
  userId: string
  onSelect: (id: string) => void
}

export function UserCard({ userId, onSelect }: UserCardProps) {
  const { data, loading } = useQuery(GET_USER, { variables: { userId } })
  
  if (loading) return <Spinner />
  
  return (
    <div className="user-card" onClick={() => onSelect(userId)}>
      <h3>{data.user.name}</h3>
    </div>
  )
}
\```

### Bad Example
\```typescript
// ❌ No types, inline handler, missing error state
export function Card(props) {
  const { data } = useQuery(GET_USER)
  return <div onClick={() => props.cb(props.id)}>{data.user.name}</div>
}
\```

## Git Workflow

- Branches: `feature/`, `fix/`, `docs/`
- Commits: Conventional Commits format
  - `feat: add user search`
  - `fix: resolve infinite loop in dashboard`
- PRs: Description required, all tests must pass

## Security

- **Secrets**: Use `.env.local` (gitignored), never commit
- **API**: GraphQL endpoint in `VITE_API_URL` env var
- **Auth**: JWT tokens stored in httpOnly cookies

## Boundaries

### ✅ Always
- Run tests and linter before committing
- Update tests when modifying components
- Use TypeScript strict types
- Follow Conventional Commits format

### ⚠️ Ask First
- Adding dependencies (check bundle size)
- GraphQL schema changes
- Modifying Vite config
- Changing CI/CD workflows

### 🚫 Never
- Commit secrets or API keys
- Edit `node_modules/`
- Disable TypeScript strict mode
- Remove failing tests without fixing code
- Push directly to `main`
```

### Monorepo AGENTS.md (Root Level)

```markdown
# AGENTS.md

This is a monorepo with multiple packages. Each package has its own AGENTS.md.

## Workspace Commands

- Install all: `pnpm install`
- Build all: `pnpm turbo run build`
- Test all: `pnpm turbo run test`
- Navigate: `pnpm dlx turbo run where <package_name>`

## Package-Specific Work

Each package has detailed instructions in its own AGENTS.md:
- `packages/web-app/AGENTS.md` - React frontend
- `packages/api/AGENTS.md` - Express API
- `packages/shared/AGENTS.md` - Shared utilities

When working on a specific package, read its AGENTS.md for detailed guidance.

## Global Conventions

- **Commits**: Conventional Commits with package scope
  - `feat(web-app): add user profile`
  - `fix(api): resolve auth timeout`
- **Testing**: All packages must pass tests before merge
- **TypeScript**: Strict mode enabled in all packages

## Boundaries

- ✅ Work within package boundaries
- ⚠️ Ask before changes affecting multiple packages
- 🚫 Never edit shared configs without team discussion
```

### Framework-Specific Examples

#### Python/Django Project

```markdown
# AGENTS.md

## Setup

- Create venv: `python -m venv venv`
- Activate: `source venv/bin/activate` (or `venv\Scripts\activate` on Windows)
- Install: `pip install -r requirements.txt`
- Migrate DB: `python manage.py migrate`
- Run server: `python manage.py runserver`

## Testing

- All tests: `pytest`
- Coverage: `pytest --cov=src --cov-report=html`
- Specific test: `pytest tests/test_views.py::test_user_creation`
- Min coverage: 85%

## Code Style

**Linter**: Black + flake8 + isort

- Format: `black .`
- Lint: `flake8 src/`
- Imports: `isort .`
- Type check: `mypy src/`

### Conventions
- Functions/variables: snake_case
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Always use type hints

## Boundaries

- ✅ Always: Use type hints, write tests, run migrations
- ⚠️ Ask first: Schema changes, new dependencies
- 🚫 Never: Commit migrations to main, push code failing mypy
```

#### Go Project

```markdown
# AGENTS.md

## Setup

- Install deps: `go mod download`
- Build: `go build -o bin/app cmd/main.go`
- Run: `go run cmd/main.go`
- Watch: `air` (requires air: `go install github.com/cosmtrek/air@latest`)

## Testing

- All tests: `go test ./...`
- Coverage: `go test -cover ./...`
- Verbose: `go test -v ./...`
- Specific package: `go test ./internal/users`

## Code Style

**Linter**: golangci-lint

- Lint: `golangci-lint run`
- Format: `gofmt -w .` or `goimports -w .`

### Conventions
- Exported: PascalCase (e.g., `UserService`)
- Unexported: camelCase (e.g., `fetchUser`)
- Interfaces: end with -er (e.g., `Reader`, `Writer`)
- Error vars: start with `Err` (e.g., `ErrNotFound`)

## Boundaries

- ✅ Always: Run tests, handle errors explicitly, use contexts for cancellation
- ⚠️ Ask first: Adding goroutines, changing DB schema
- 🚫 Never: Ignore errors, use panic in library code
```

## Summary Checklist

Before finalizing AGENTS.md, verify:

- [ ] Commands are executable and tested
- [ ] Tech stack includes versions
- [ ] Code examples show good vs. bad patterns
- [ ] Boundaries use three-tier system
- [ ] File is ≤150 lines (or links to detailed docs)
- [ ] All sections use code blocks for commands
- [ ] Naming conventions are specific
- [ ] Testing requirements are clear
- [ ] Security considerations are included
- [ ] Git workflow is documented
- [ ] No duplicate content from README
- [ ] Information is current and accurate
