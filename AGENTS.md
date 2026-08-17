# AGENTS.md

Instructions for AI agents working in this repository.

---

## Repository Overview

This repo is a collection of reusable AI agents, prompt workflows, skills, tools, and language-specific coding standards for GitHub Copilot. It is not a runnable application — it produces artifacts (`.agent.md`, `SKILL.md`, `.prompt.md`, standards files) consumed by other projects.

**The Markdown files here are the deliverables.** Agent definitions, skills, and prompts are not documentation about something else — they are the product. Treat changes to them as feature/fix/refactor work, not docs changes.

## Project Structure

```
agents/          — Copilot chat agents (.agent.md files)
prompts/         — File-based prompt workflows (.prompt.md, .md)
skills/          — Reusable skills (SKILL.md + supporting files)
tools/           — Multi-agent tool suites (e.g. sda/)
scripts/         — Installation and update scripts (.bat, .ps1)
```

## Rules

### 1. Keep Documentation in Sync

When you add, remove, rename, or change the purpose of any component in this repo (agent, skill, tool, prompt, resource, or script), you **must** update:

1. **The root [`README.md`](README.md)** — tables, lists, or descriptions that reference the changed component.
2. **The local `README.md`** in the component's folder (if one exists) — keep it accurate and consistent with the change.

Do not consider the change complete until both documentation files are up to date.

### 2. Preserve Existing Style

- Follow the formatting conventions already used in the file you are editing (heading levels, table layout, bullet style).
- When adding a new component, model its documentation after a peer entry in the same section.

### 3. Do Not Introduce Runtime Dependencies

This repo contains only static Markdown, PowerShell/Batch scripts, and JSON config. Do not add package managers, build tools, or runtime dependencies unless explicitly asked.

### 4. One Component per Folder

Each agent, skill, or tool lives in its own subfolder. Do not merge unrelated components into a single directory.

### 5. Boundaries

- ✅ **Always do**: Update docs when changing components, follow existing patterns, keep files concise.
- ⚠️ **Ask first**: Adding a new top-level folder, removing an existing component, changing the repo structure.
- 🚫 **Never do**: Commit secrets or API keys, delete files without confirmation, add runtime dependencies.
