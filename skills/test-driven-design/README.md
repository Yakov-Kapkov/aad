# Test-Driven Design — Skill

A Copilot skill for designers who want to design with tests: derive the behaviour a change must
produce, pressure-test the design against it, and record that behaviour as short pseudo-code
cases before the design settles. Language- and framework-agnostic — the cases are read, not run.

---

## Setup

The skill is self-contained — the method ships inside this folder and is copied as-is on install.
Install it with the dev-suite installer or on its own.

**PowerShell (Windows):**
```powershell
# Install the full dev suite (all skills, including this one)
.\scripts\powershell\install-dev-suite.ps1

# Install only this skill
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "test-driven-design"
```

**Bash (macOS / Linux):**
```bash
# Install the full dev suite
./scripts/bash/install-dev-suite.sh

# Install only this skill
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "test-driven-design"
```

Installs to `~/.copilot/skills/test-driven-design/` by default.

---

## Usage

Load it while shaping a design — before the design settles:

```
Help me design this change with tests.
```

Or when you are about to restructure code and want its behaviour pinned first:

```
Pin the current behaviour before I refactor this.
```

The skill supplies:

- a three-step method — build a short list of tests, develop each item into a case, and loop back to the list until it stops changing;
- what earns an item, and what belongs to a unit test or an interface contract instead;
- reuse, extend or abandon an existing component before inventing one;
- pinning the behaviour of code you are about to restructure, including how to treat a defect you pin;
- one case rule (one outcome per case), a worked example in a project's own format, and anti-pattern tables for both stages;
- asserting the observable outcome, never the internals — gray box for mocking, black box for asserting.

---

## Boundaries

This skill is **method only**. It does not define where cases are stored, what fields they carry,
or what a project calls them — a project that wants those conventions defines them in its own
documentation standard.
