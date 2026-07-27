# repo-onboarding

A skill that instantly generates structured onboarding docs for any repo (`tools.md`, `architecture.md`, `summary.md`, `quickstart.md`). Use it when a new developer or agent needs to understand a codebase fast.

---

## Setup

Run the generic skill installer from the root of this repository(or copy the skill folder manually).

**PowerShell (Windows):**
```powershell
.\scripts\powershell\install-skill.ps1 -Name "repo-onboarding"

# Custom target (any folder your IDE loads skills from):
.\scripts\powershell\install-skill.ps1 -Name "repo-onboarding" -TargetBase "$env:USERPROFILE\.copilot"
```

**Bash (macOS / Linux):**
```bash
./scripts/bash/install-skill.sh -n "repo-onboarding"

# Custom target (any folder your IDE loads skills from):
./scripts/bash/install-skill.sh -n "repo-onboarding" -t "$HOME/.copilot"
```

Installs to `~/.copilot/skills/repo-onboarding/` by default.

---

## Usage

Invoke the skill with any of the following:

```
Onboard this repo.
```

```
Create onboarding documentation.
```

---

## Outputs

| File | Contents |
|---|---|
| `tools.md` | All development commands — test, lint, type-check, build, run — derived directly from repo files |
| `architecture.md` | Project structure, core components, tech stack, design patterns, and data flow |
| `summary.md` | Plain-language overview: what the repo does, the problem it solves, and its key features |
| `quickstart.md` | Step-by-step setup guide with prerequisites, install commands, verification steps, and common command examples |

---

## Workflow

1. **Ask** — prompts for the output folder location and the user's OS / shell.
2. **tools.md** — scans package manifests, config files, CI/CD, and scripts to document every development command. Each test layer (e.g. frontend, backend) is treated independently.
3. **architecture.md** — maps directories, entry points, data models, services, and integrations.
4. **summary.md** — reads README and main source files to write a concise repo overview.
5. **quickstart.md** — compiles prerequisites, install commands, verification steps, and one example per common command type.
6. **Confirm** — reports the folder where all files were created.

---

## Rules

- Every command is verified against actual repo files before being documented — nothing is invented.
- Shell syntax matches the user's environment (bash, zsh, PowerShell, etc.).
- File references use markdown links pointing to the exact file and line range.
- All documents are kept concise — no padding or redundant content.
