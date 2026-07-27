---
name: agents_md_creator
description: Create and update AGENTS.md files for repositories and folders. AGENTS.md is the README for AI agents, providing context about build commands, testing, code style, and conventions. Use this skill when the user asks to (1) generate an AGENTS.md file for a folder or repository, (2) create AGENTS.md, (3) update existing AGENTS.md files, or (4) improve agent documentation for their codebase.
---

# Agents.md Creator

Generate and maintain AGENTS.md files that provide AI coding agents with the context they need to work effectively on your project.

## What is AGENTS.md?

AGENTS.md is a standardized Markdown file that serves as a "README for AI agents." While README.md targets human developers, AGENTS.md provides AI coding agents with:

- Build and test commands
- Code style conventions
- Testing instructions
- Project structure
- Git workflow guidelines
- Security boundaries

## When to Use This Skill

Use this skill when the user requests:
- "Generate agents.md file for this folder"
- "Create AGENTS.md file for this repo"
- "Update the current Agents.md file"
- "Improve my agent documentation"

## Workflow

### 1. Analyze the Project

Before generating AGENTS.md, analyze the target folder to understand:

- **Technology stack**: Identify languages, frameworks, and their versions
- **Build system**: Find package.json, pom.xml, Cargo.toml, pyproject.toml, etc.
- **Testing setup**: Locate test directories and test commands
- **Code style tools**: Check for .eslintrc, .prettierrc, pyproject.toml, etc.
- **Git conventions**: Look for existing commit patterns in git history
- **Existing documentation**: Check README.md, CONTRIBUTING.md, docs/

### 2. Generate Content

Use `scripts/generate_agents_md.py` to create the initial AGENTS.md file:

```bash
python scripts/generate_agents_md.py <target_folder>
```

The script will:
1. Scan the folder structure
2. Detect technology stack
3. Extract build/test commands
4. Identify code style configuration
5. Generate a complete AGENTS.md file

### 3. Review and Customize

After generation:
- Review the generated content for accuracy
- Add project-specific context that wasn't automatically detected
- Ensure all commands are correct and executable
- Add security boundaries (API keys, secrets, protected files)
- Include examples of good code patterns

### 4. Validate Quality

Check that the AGENTS.md includes:

✅ **Commands early**: Build, test, and lint commands in the first sections
✅ **Specific tech stack**: Include versions (e.g., "React 18 with TypeScript, Vite, Tailwind CSS")
✅ **Code examples**: Show actual code snippets, not just descriptions
✅ **Clear boundaries**: Three-tier system (Always do / Ask first / Never do)
✅ **Concise content**: Aim for ≤150 lines; link to detailed docs instead of duplicating
✅ **Executable commands**: Use code blocks with exact syntax (e.g., `npm test --coverage`)

## Core Sections to Include

Based on analysis of 2,500+ successful AGENTS.md files, include these sections:

### 1. Setup Commands (Required)
```markdown
## Setup Commands
- Install dependencies: `npm install`
- Start dev server: `npm run dev`
- Build production: `npm run build`
```

### 2. Testing Instructions (Required)
```markdown
## Testing
- Run all tests: `npm test`
- Run with coverage: `npm run test:coverage`
- Run specific test: `npm test -- path/to/test.spec.ts`
- Tests must pass before committing
```

### 3. Code Style (Required)
```markdown
## Code Style
- **Language**: TypeScript strict mode
- **Formatting**: Single quotes, no semicolons, 2-space indentation
- **Linter**: `npm run lint --fix` to auto-fix issues
- **Conventions**: camelCase for functions, PascalCase for classes

### Good Example
\```typescript
async function fetchUserById(id: string): Promise<User> {
  if (!id) throw new Error('User ID required')
  const response = await api.get(`/users/${id}`)
  return response.data
}
\```
```

### 4. Project Structure (Recommended)
```markdown
## Project Structure
- `src/` - Application source code
- `tests/` - Unit and integration tests
- `docs/` - Documentation
- `scripts/` - Build and deployment scripts
```

### 5. Git Workflow (Recommended)
```markdown
## Git Workflow
- Branch naming: `feature/description`, `fix/description`
- Commit format: Conventional Commits (e.g., `feat: add user auth`)
- PR requirements: All tests pass, lint clean, description included
```

### 6. Boundaries (Required)
```markdown
## Boundaries
- ✅ **Always do**: Run tests before committing, follow naming conventions, update tests with code changes
- ⚠️ **Ask first**: Database schema changes, adding dependencies, modifying CI/CD config
- 🚫 **Never do**: Commit secrets or API keys, edit `node_modules/` or `vendor/`, remove failing tests
```

## Best Practices

### Keep It Concise
- Aim for ≤150 lines total
- Use bullet points and code blocks
- Link to detailed documentation instead of duplicating content
- Remove redundant or obvious information

### Use Executable Commands
- Write commands exactly as they should run
- Include all necessary flags and options
- Use code blocks for easy copying
- Example: `pytest -v --cov=src tests/` not "run tests with coverage"

### Provide Real Examples
- One code snippet beats three paragraphs
- Show what good output looks like
- Include both good and bad examples when helpful
- Use actual code from the project when possible

### Set Clear Boundaries
- Use three tiers: Always / Ask first / Never
- Be specific about protected files and directories
- Mention secrets and security considerations
- Include deployment restrictions

### Single Source of Truth
- Don't duplicate README or wiki content
- Link to existing technical docs
- Keep only critical information for agents
- Update AGENTS.md when conventions change

## Nested AGENTS.md in Monorepos

For large monorepos, create nested AGENTS.md files:

- Place AGENTS.md at the root with general guidance
- Add package-specific AGENTS.md in each subproject
- The closest AGENTS.md to the edited file takes precedence
- Example: A repo might have 10+ AGENTS.md files for different packages

## Updating Existing AGENTS.md

When updating an existing AGENTS.md:

1. **Read the current file** to understand existing structure
2. **Check for outdated information** (old commands, deprecated tools)
3. **Apply user-requested changes** following best practices
4. **Maintain consistency** with the existing style and format
5. **Validate commands** are still correct
6. **Preserve custom content** that's project-specific

## Reference Materials

For comprehensive best practices and examples, see:
- `references/best_practices.md` - Detailed guide from 2,500+ repos analysis
- `assets/template.md` - Basic template for common project types

## Common Patterns by Project Type

### Web Application (React/Vue/Angular)
Focus on: Dev server commands, build process, component testing, linting

### API/Backend Service
Focus on: Database setup, API testing, environment variables, deployment

### Library/Package
Focus on: Build process, publishing steps, API documentation, versioning

### CLI Tool
Focus on: Installation, usage examples, testing different platforms

### Monorepo
Focus on: Workspace commands, package dependencies, testing across packages
