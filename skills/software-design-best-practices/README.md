# Software Design Best Practices — Skill

A Copilot skill that provides language-agnostic design best practices
organized by topic area via a two-level route table. Consulted before
creating development specifications or making architectural decisions
during implementation.

---

## Setup

No custom install scripts required. Copy to your skills folder:

**PowerShell (Windows):**
```powershell
.\scripts\powershell\install-skill.ps1 -SkillName software-design-best-practices
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/install-skill.sh -s software-design-best-practices
```

---

## Usage

Load before creating a dev spec or making design decisions:

```
Implement this task according to design best practices.
```

Or to review existing code for design issues:

```
Review this code against design best practices.
```

---

## Topic Areas

| Area | Concerns |
|---|---|
| Web API | Input validation, DTO mapping, global error handling |
| Database | Query design, entity exposure |
| UI | Shell controls, data source efficiency, loading states |
| Layers | Layer separation, shared resources |
