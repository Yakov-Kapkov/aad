# Method of Work - AI Assistant Task Router

**INSTRUCTION FOR AI ASSISTANT**: This file routes you to the correct standards documents based on task type. You MUST read the ENTIRE content of ALL referenced files (not just the first 50 lines). Use multiple read_file operations with appropriate line ranges to ensure complete coverage of each document.
---

## ⛔ MANDATORY FIRST STEP — Before ANYTHING Else

**CHECK**: Does `project-tools.md` exist in the same directory as this file?

- **YES** → Continue to the sections below.
- **NO** → **STOP. You MUST run `tool-discovery.md` now.**
  - Read and execute `tool-discovery.md` in full.
  - Wait for user approval and confirmation that `project-tools.md` has been created.
  - **Only then** return here and continue.

> ⚠️ Skipping this step is **FORBIDDEN**. No task (feature, bug fix, refactoring, code review) may begin without a `project-tools.md` present.

---

## 🔧 Project Commands Reference

**Always consult `project-tools.md` for exact commands. Never assume standard commands.**

This file contains project-specific information about:
- **Package manager** (poetry, uv, pip, etc.)
- **Test framework commands** (pytest execution, coverage, specific files)
- **Type checking commands** (mypy, pyright, etc.)
- **Code quality tools** (ruff, black, pre-commit, etc.)
- **Poe tasks** (pre-configured task shortcuts like `poe pre-commit-checks`, `poe test`, `poe lint`)

**After ANY code change, run commands from `project-tools.md` in this order:**
1. Type checking
2. Tests
3. Code quality (if configured)

---

## Task Type Identification

When given any development task (coding, bug fixing, refactoring, or code review), identify the task type and load the specified files COMPLETELY(you must read entire files):

**FILES TO LOAD FOR ALL TASK TYPES**:
- `development-workflow.md` (TDD process, safe refactoring)
- `standards/{language}/coding-standards.md` (Type safety, SOLID, constants)
- `standards/{language}/testing-standards.md` (AAA, fixtures, mocking)
- `standards/{language}/code-style.md` (Documentation, formatting)

**COMMON RULE FOR ALL TASK TYPES**: All rules in the loaded files are MANDATORY

### 1. New Feature Implementation
**Key Requirements**:
- Follow TDD cycle: RED → GREEN → REFACTOR
- Tests MUST be written BEFORE implementation

---

### 2. Bug Fix
**Key Requirements**:
- Write failing test that reproduces the bug FIRST
- Fix implementation to make test pass
- Follow all testing standards

---

### 3. Refactoring
**Key Requirements**:
- Ensure tests exist and pass BEFORE refactoring
- Make incremental changes, run tests after each
- Follow all coding standards in the loaded files

---

### 4. Code Review
**Key Requirements**:
- Use checklists from each loaded file
- Verify compliance with ALL rules marked MANDATORY
- Check quality gates pass
