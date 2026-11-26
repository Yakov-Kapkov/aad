# Design Partner — Skill

A Copilot skill for shaping a design with its owner. It supplies the posture —
the user owns every decision, the agent pressure-tests rather than authors — plus
the option format, how to show an idea back as flows and diagrams instead of
prose, the risk classes each flow is attacked against, the
over-/under-engineering checks, and the altitude discipline. Portable: it names
no tool, artifact, or agent, so any design or review session can load it.

---

## Setup

The skill is self-contained — the method ships inside this folder and is copied
as-is on install. Install it with the dev-suite installer or on its own.

**PowerShell (Windows):**

```powershell
# Install the full dev suite (all skills, including this one)
.\scripts\powershell\install-dev-suite.ps1

# Install only this skill
.\scripts\powershell\install-skill.ps1 -TargetBase "$env:USERPROFILE\.copilot" -Name "design-partner"
```

**Bash (macOS / Linux):**

```bash
# Install the full dev suite
./scripts/bash/install-dev-suite.sh

# Install only this skill
./scripts/bash/install-skill.sh -t "$HOME/.copilot" -n "design-partner"
```

Installs to `~/.copilot/skills/design-partner/` by default.

---

## Usage

Load it at the start of any design session — before the design settles:

- Wording an architecture or a feature with its owner.
- Reviewing a proposed design for over- or under-engineering.
- Deciding between options without letting the agent pick.

Say: _"Be my design partner — pressure-test what I propose."_

---

## What it carries

| Section | Content |
|---|---|
| Goal | A fully developed design in technical language, ready for a development agent: no unresolved contradiction, every gap settled or explicitly deferred |
| Rules | Prohibitions that hold every round: the user owns every decision; never volunteer a design; the hard stop when no approach is proposed; never a single take-it-or-leave-it answer; never manufacture objections; never withhold the toolkit |
| Method | Ground the idea in what exists (present vs missing), one decision per round, render widest-first before judging, steelman then attack — with the option format as a subsection |
| Design language | The vocabulary, read outside-in: requirement → criterion → flow → steps → components, with contracts at the seams and a test per outcome (design language, never run); a flow without a failure outcome is unfinished; a step with no component is not yet designed |
| Altitude | Behaviour not code; never cross between system and feature levels; the shape exception for a complex case |
| Consistency & completeness | Decisions hold against each other; unstated owners, boundaries, failure behaviour, and scope edges are raised as questions; a bad decision is named with its concrete failure |
| Risk classes | Each flow attacked against nine classes — idempotency, concurrency, partial failure, migration and its way back, and the rest; each answered, deferred, or raised ([assets/risk-classes.md](assets/risk-classes.md)) |
| Quality rules | Over-engineering table + YAGNI test, under-engineering table, naming, circular dependencies |
| Acceptance criteria | Every round: concise replies, no authored decision, altitude held. Triggered: widest-first render + steelman + quality check + gaps raised when a design is proposed; pros and cons when options are asked; a grounded answer when a question is asked; trigger, steps, both outcomes, and tests when a flow is settled |

---

## Related

- [`test-driven-design`](../test-driven-design/README.md) — records the design
  as pseudo-tests; the behaviours this skill settles are the items it records.
