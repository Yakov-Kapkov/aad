# tdd prompts

Instruction files that enforce a TDD development workflow when attached as AI assistant context. Use these as `#file` references in Copilot chat — no agent framework required.

> For the agent-based version of this workflow see [`agents/tdd-workflow/`](../../agents/tdd-workflow/README.md).

---

## Files

| File | Purpose |
|---|---|
| `method-of-work.md` | Entry point — checks for `project-tools.md`, identifies task type, and routes to the correct standards files |
| `development-workflow.md` | TDD cycle rules, approval checkpoints, quality gates, and code review criteria |
| `tool-discovery.md` | Scans the project for build/test/lint tooling and writes `project-tools.md` |

---

## How it works

### 1. Entry point — `method-of-work.md`

Always attach this file first. It acts as a router:

1. **Checks for `project-tools.md`** in the same directory. If missing, runs `tool-discovery.md` before anything else.
2. **Identifies the task type** — new feature, bug fix, refactoring, or code review.
3. **Loads the relevant standards files** from `standards/{language}/` relative to its own location (i.e. `prompts/tdd/standards/{language}/`).

### 2. Tool discovery — `tool-discovery.md`

Scans the project root for package manager, test framework, type checker, linters, and
project scripts. Presents a discovery report for user approval, then writes the approved
commands to `project-tools.md`. Must complete before any development task begins.

### 3. Development workflow — `development-workflow.md`

Defines the mandatory TDD cycle:

- **RED** — write failing tests, present to user, wait for explicit approval
- **GREEN** — write minimal code to make tests pass
- **REFACTOR** — clean up while keeping tests green

Re-approval is required after any test change, no matter how small.
Quality gates (>95% coverage, type checking, zero magic values) must pass before the task is complete.

---

## Setup

The folder where you place `method-of-work.md` must contain a `standards/` directory
for the detected language. Copy the relevant folder from this repo's
[`resources/`](../../resources/):

```
<your-project>/
└── <wherever you place the prompts>/
    ├── method-of-work.md
    ├── development-workflow.md
    ├── tool-discovery.md
    └── standards/
        └── typescript/          # or python/
            ├── coding-standards.md
            ├── testing-standards.md
            └── code-style.md
```

`project-tools.md` does **not** need to be copied — it is generated automatically by
`tool-discovery.md` on first run and written to the same folder.

---

## Usage

Attach `method-of-work.md` to your Copilot chat context when starting any development task:

```
implement current task according to #method-of-work.md
```

```
#file:prompts/tdd/method-of-work.md  Add input validation to the registration form.
```

The assistant will check for `project-tools.md`, load the applicable standards, and
follow the TDD workflow automatically.
