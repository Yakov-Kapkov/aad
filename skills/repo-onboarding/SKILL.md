---
name: repo-onboarding
description: Comprehensive repository onboarding workflow that creates documentation for new developers. Generates tools.md (commands and tooling), architecture.md (system design with code references), summary.md (repo purpose), and quickstart.md (setup guide with prerequisites). Invoked by requests like "onboard this repo" or "create onboarding documentation".
---

## Invocation examples
- "Onboard this repo"
- "Create onboarding documentation"
- "Generate repository onboarding guide"
- "Help me understand this repository from scratch"

## Workflow

Use the ask_questions tool to collect:
1. Where to create the onboarding folder (e.g. `docs/`, `onboarding/`, hidden folder)
2. User's OS and preferred shell

Then create the folder and generate the four files below.

---

### Step 1 — tools.md

Scan the repo and document all development tooling.

**Scan for:**
- Package manager(s) and lock files
- Command runner per layer (e.g. `poetry run`, `pipenv run`, `npx`, `yarn dlx`) — identify and record before writing any commands
- Test frameworks — identify ALL layers independently
- Type checkers
- Linters and formatters
- Build, run, and deploy scripts
- CI/CD configuration
- Database migration tooling

**Testing section rules (critical):**
- Treat each layer (e.g. frontend, backend) as independent
- For each layer document: framework, verified config file link (see [Link Rules](#link-rules)), test file pattern
- For each layer provide all of: run all, run single file, run by pattern, watch mode, CI mode
- Derive every command from actual repo files; do not invent command syntax
- Use shell syntax matching the user's environment

**Build & Run section rules (critical):**
- App-start commands obey the same command-runner consistency rule as test/lint commands
- If a wrapper was detected, wrap every invocation of a project binary or interpreter — including `uvicorn`, `gunicorn`, `flask`, `node`, `python`, etc.
- Bare runtimes are only valid when **no wrapper was detected**
- Examples:
  - ❌ `python3 api.py`, `uvicorn api:app --reload`, `node server.js` — bare, wrong when a wrapper exists
  - ✅ `poetry run python api.py`, `poetry run uvicorn api:app --reload`, `npx tsx server.ts`

**tools.md structure:**
```
# Development Tools & Commands

## Package Manager
## Testing
  ### [Layer A] — [Framework]
  ### [Layer B] — [Framework]
## Type Checking
## Code Quality
## Build & Run
## Database
## Useful Scripts
## CI/CD
```

---

### Step 2 — architecture.md

Produce a navigation-oriented architecture document that lets a
contributor quickly find where to work and which patterns to follow.

**Scan for:**
- Architectural style — identify which apply: layered, vertical slices,
  hexagonal/ports-and-adapters, clean architecture, DDD, CQRS, MVC,
  microservices, modular monolith, event-driven, REST, GraphQL, other
- Layer boundaries — what are the distinct layers/modules and what is
  each one's single responsibility
- Public API surface — controllers, routers, handlers, resolvers
- Domain/business logic location — services, use-cases, domain models
- Infrastructure concerns — persistence, external integrations, messaging
- Cross-cutting concerns — auth, logging, validation, error handling

**Per-layer documentation rules:**
- For each layer: name, responsibility (one sentence), folder link,
  key files with verified links
- Document the pattern each layer follows (e.g., "one controller per
  resource", "one use-case class per operation", "repository per
  aggregate")
- Show a representative example file for the pattern with a line link

**Navigation paths (critical):**
For each common contribution type detected in the repo, write a short
"How to add…" path. Scan for at least these:
- Add a new API endpoint / route
- Add a new domain entity or aggregate
- Add a new integration (external service, DB table)
- Add a new background job / event handler

Each path: 3–6 numbered steps, each step links to the layer/file to
touch and names the pattern to follow.

**All references must be verified links** (see [Link Rules](#link-rules)).

**architecture.md structure:**
```
# Architecture Overview

## Architectural Style
  (Name the style(s). One paragraph explaining the approach.)

## Layer Map
  ### [Layer name]
  - Responsibility: …
  - Folder: [link]
  - Pattern: …
  - Example: [link to representative file#lines]
  (repeat per layer)

## Technology Stack

## Data Flow
  (Request lifecycle or event flow, referencing layers above)

## Navigation Paths
  ### Adding a new API endpoint
  1. …
  ### Adding a new domain entity
  1. …
  ### Adding a new integration
  1. …

## Cross-Cutting Concerns
  (Auth, validation, error handling — where they live, how to extend)
```

---

### Step 3 — summary.md

Write a short plain-language overview.

- Read README, package manifests, and main source files
- Describe what the repo does, what problem it solves, and its main features
- Keep it under one page

**summary.md structure:**
```
# Repository Summary
## What is this?
## Purpose
## Key Features
## Technology Stack
## Repository Type
```

---

### Step 4 — quickstart.md

Write a practical setup guide.

- List prerequisites (tools, credentials, config files) as checkboxes
- Provide exact install commands
- Include verification steps (tests, type check, lint, build)
- Document "Common Commands" with one example per command type per layer:
  - Run all tests
  - Run tests for one layer
  - Run a single test file
  - Run tests matching a folder or pattern
  - Start the app locally

**Running Locally section rules (critical):**
- Apply command-runner consistency here too — app-start commands are **not** exempt
- Bare runtimes (`python3 api.py`, `uvicorn ...`, `node server.js`) are only valid when no wrapper was detected
- Examples:
  - ❌ `uvicorn api:app --reload`, `node server.js` — bare, wrong when a wrapper exists
  - ✅ `poetry run uvicorn api:app --reload`, `npx tsx server.ts`

**quickstart.md structure:**
```
# Quick Start Guide
## Prerequisites
## Installation
## Verification
## Running Locally
## Common Commands
## Troubleshooting
```

---

## Link Rules

Every file reference in generated docs must be a clickable relative
markdown link pointing to a real file (and optionally real lines).

| Rule | Detail |
|---|---|
| Path basis | Relative from the generated file's folder to the target file |
| Verify before linking | Read the target file to confirm it exists; read the specific lines before adding `#L` references |
| Line format | `#L10` (single line) or `#L10-L20` (range) — only after confirming those lines contain what's described |
| Display text | Use the filename (or a short label), not the full relative path |
| No dead links | Never guess a path or line number — if you cannot verify it, link to the file without a line anchor |
| Config files | Link to the actual config file (e.g. `[jest.config.ts](../../jest.config.ts)`) |

**Process for each link:**
1. Identify the target file path in the repo.
2. Read the file (or the relevant line range) to verify it exists and contains the expected content.
3. Compute the relative path from the output folder to the target.
4. Write the link with verified line anchors.

---

## General rules

- Verify every command exists in the repo before documenting it
- Use the user's shell syntax throughout
- All file references must follow [Link Rules](#link-rules)
- Keep all documents concise — no padding or redundancy
- Use ask_questions when uncertain about repo details
- **Command runner consistency**: if a layer has a runtime wrapper (e.g. `poetry run`, `pipenv run`, `npx`, `yarn dlx`, `bundle exec`), every command that invokes any project binary or interpreter must use it in all four output files — this includes test, lint, type-check, **app-start**, migration, and utility-script commands; the only exceptions are the package manager's own sub-commands (e.g. `poetry install`) and infrastructure-level tools that run outside the project environment (e.g. `docker`, `kubectl`); bare runtimes (e.g. `python3 api.py`, `uvicorn ...`, `node index.js`) are only valid when no wrapper was detected; do a cross-file consistency pass before reporting completion
  - Examples: ❌ `python3 api.py`, `uvicorn api:app --reload`, `node server.js` (bare — wrong when a wrapper exists) / ✅ `poetry run python api.py`, `poetry run uvicorn api:app --reload`, `npx tsx server.ts`

## Workflow Summary

1. ASK — folder location, OS, shell
2. CREATE — tools.md
3. CREATE — architecture.md
4. CREATE — summary.md
5. CREATE — quickstart.md
6. CONFIRM — "Onboarding complete! Files are in [folder]/"