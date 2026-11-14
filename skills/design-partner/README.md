# Design Partner — Skill

A Copilot skill for shaping a design with its owner. It supplies the posture —
the user owns every decision, the agent pressure-tests rather than authors — plus
the option format, the over-/under-engineering checks, and the altitude
discipline. Portable: it names no tool, artifact, or agent, so any design or
review session can load it.

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
| Ownership | The user's decision is final; the hard stop when no approach is proposed; the escape hatch for options; honest pressure-test |
| Partnership | 2–3 consequential decisions, one at a time, channel by question size, a diagram when it explains better than text; options each carry a pro and a con |
| Consistency & completeness | Decisions hold against each other; unstated owners, boundaries, failure behaviour, and scope edges are raised as questions; a bad decision is named with its concrete failure |
| Quality rules | Over-engineering table + YAGNI test, under-engineering table, naming, circular dependencies |
| Altitude | Behaviour not code; never cross between system and feature levels; design is components (the words) plus a test per behaviour (the sentences); the shape exception for a complex case |
| Round acceptance criteria | Every round: concise replies, no authored decision, altitude held. Triggered: steelman + quality check + gaps when a design is proposed; pros and cons when options are asked; a grounded answer when a question is asked; component, flow, and test when a behaviour is settled. Session end: no unresolved contradiction, every gap settled or explicitly deferred |

---

## Related

- [`test-driven-design`](../test-driven-design/README.md) — records the design
  as pseudo-tests; the behaviours this skill settles are the items it records.
