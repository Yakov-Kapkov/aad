# Troubleshooting — Skill

A Copilot skill that provides a troubleshooting dictionary for unexpected command results — test failures, build errors, lint violations, and runtime exceptions.

---

## What's Inside

| File / Folder | Purpose |
|---|---|
| `SKILL.md` | Skill definition — when and how to use the dictionary |
| `references/troubleshooting.md` | Symptom → cause → fix dictionary |

---

## Setup

Copy the `skills/troubleshooting/` folder into your target project's Copilot skills directory (typically `.github/copilot/skills/` or wherever your workspace loads skills from):

```
<your-project>/
└── .github/
    └── copilot/
        └── skills/
            └── troubleshooting/
                ├── SKILL.md
                └── references/
                    └── troubleshooting.md
```

---

## Usage

The skill activates when a command (test run, build, lint, type check) produces an unexpected result. The agent consults the dictionary, matches the symptom, and applies the prescribed fix.

If no symptom matches, the agent diagnoses and solves normally — the dictionary is a shortcut, not a constraint.

---

## Adding New Entries

Add rows to the appropriate category table in `references/troubleshooting.md`. Each entry needs:

| Column | Content |
|---|---|
| Symptom | Observable error message or behavior |
| Cause | Why it happens |
| Fix | What to do about it |
