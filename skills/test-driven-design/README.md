# Test-Driven Design — Skill

A Copilot skill for recording a design as tests: take the vocabulary of participant components
the user names, group the behaviour the change must produce by level, pressure-test the user's
design against it, and record it as short pseudo-tests before the design settles. Written in the
project's own language with the noise removed — read, not run.

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

- a four-step method — record the participant vocabulary, build the list of tests grouped by level, develop each item into a pseudo-test, and loop back until neither changes;
- the participant vocabulary — abstract classes, interfaces and other symbols the user names, tested by simplicity and separation of concerns;
- levels — app, middleware, component, or whatever the system actually has — each level's pseudo-tests written in that level's abstractions;
- what earns an item, and what belongs to a unit test or an interface contract instead — including the two-pseudo-tests-per-new-seam threshold;
- reuse, extend or abandon an existing component before inventing one;
- pinning the behaviour of code you are about to restructure, including how to treat a defect you pin;
- two rules (one outcome per pseudo-test; a new seam needs two), a worked example in a project's own format, and anti-pattern tables for both stages;
- asserting the observable outcome, never the internals — gray box at the seam, black box for asserting.

---

## Boundaries

This skill is **method only**. It does not define where pseudo-tests are stored, what fields they carry,
or what a project calls them — a project that wants those conventions defines them in its own
documentation standard.
