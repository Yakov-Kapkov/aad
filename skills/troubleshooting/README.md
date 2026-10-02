# Troubleshooting — Skill

A Copilot skill that provides a troubleshooting dictionary for unexpected command results — test failures, build errors, lint violations, and runtime exceptions.

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition plus the symptom → cause → fix dictionary |

---

## Setup

Copy the `skills/troubleshooting/` folder into your target project's Copilot skills directory (typically `.github/copilot/skills/` or wherever your workspace loads skills from):

```
<your-project>/
└── .github/
    └── copilot/
        └── skills/
            └── troubleshooting/
                └── SKILL.md
```

---

## Usage

The skill activates when a command returns a confirmed failure. The agent checks
the exit code first — empty output with exit code `0` is a success for silent
tools and ends troubleshooting of the current issue immediately. Only a confirmed non-zero exit code (from
an unfiltered run) or unexpected output reaches a dictionary lookup.

A keyword match only routes the agent to a section — it is not evidence. The
agent verifies every condition in the matched row before applying its fix; a
partial match is treated as no match.

If no symptom matches, the agent diagnoses and solves normally — the dictionary is a shortcut, not a constraint.

---

## Adding New Entries

Add rows to the appropriate category table in `SKILL.md`. Each entry needs:

| Column | Content |
|---|---|
| Symptom | Every condition the agent must verify before applying the fix |
| Cause | Why it happens |
| Fix | What to do about it |
