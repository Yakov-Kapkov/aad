# SDA — Get Started

Start-to-done walkthrough of the SDA 5-BC workflow. You drive; agents advise and
produce. The CLI scripts track state so you never lose your place.

---

## 1. Install

From the repo root, one command. Copies agents, skills, and prompts into your
Copilot folder.

**Windows (PowerShell):**
```powershell
.\scripts\powershell\install-dev-suite.ps1 -Mode full
```

**macOS / Linux (Bash):**
```bash
./scripts/bash/install-dev-suite.sh full
```

Restart VS Code. SDA agents appear in the agent picker.

---

## 2. Init a project

In a Copilot chat, pick the **sda-setup** skill and say:

```
Setup sda tool
```

This scaffolds `.sda/` with scripts, schemas, config, and workflow state
managers. It then hands off to `sda-toolscan` to discover your toolchain
(test runner, linter, type checker, build commands) and write
`project-config.json`.

You now have:

```
.sda/
├── project-config.json        ← paths, models, scripts
├── project-tools.md           ← discovered tool commands
├── resources/                 ← schemas for every BC
├── scripts/
│   ├── workflow/              ← workflow-state, workflow-next-step,
│   │                            dev-qa-cycle-state, dev-qa-next-step
│   ├── system-context/        ← components, edges, behaviors, …
│   ├── dev/                   ← task-state, unit-file-size
│   └── qa/                    ← load-qa-secrets, invoke-http
└── workflows/                 ← transient per-story workspaces
```

---

## 3. Start a story

Pick the **sda-workflow** agent and say:

```
Start a story for: users can reset their password via email link
```

`sda-workflow` runs `workflow-state init`, creates a workspace, and tells you
what to do next. It **advises** — you invoke each BC agent yourself.

Every story lives under `.sda/workflows/workflow-<id>/`:

```
workflow-01/
├── workflow-state.yaml        ← outer-loop state (the truth)
├── BA/                        ← User Story output
├── DESIGN/                    ← design docs (pending overlay)
├── DEV/                       ← task.md, dev-qa-cycle-state.yaml, runs/
└── QA/                        ← qa-task.md, qa-report.md
```

---

## 4. The 5-BC journey

Each bounded context has one job. You run the agent, review its output, and
record the result. Then `sda-workflow` tells you what's next.

### BA — Author the User Story

Agent: **`sda-ba`**

```
Draft a user story for password reset via email link.
Output to: .sda/workflows/workflow-01/BA/
```

Produces `BA/user-story.md` — one Actor statement + Gherkin scenarios. Enforces
the Definition of Ready. Rejects multi-actor requests.

**After BA completes**, record it — the script writes `BA/implemented-feature.md`
to the durable ledger (`docs/features/`) and advances the outer state to DESIGN:

```powershell
.sda/scripts/workflow/workflow-state.ps1 update `
  -Dir .sda/workflows/workflow-01 `
  -Bc BA -Status done -Ledger done `
  -Output BA/
```

Then ask `sda-workflow` "what's next?" — it'll point you to DESIGN.

### DESIGN — Architect the solution

Agents: **`sda-system`** (system-level), **`sda-feature`** (feature-level)

```
Design the architecture for the password-reset feature.
The User Story is at .sda/workflows/workflow-01/BA/user-story.md
Output to: .sda/workflows/workflow-01/DESIGN/
```

`sda-system` produces `design.md` with components, contracts, and diagrams.
Hands off to `sda-feature` for feature-level breakdown.

Design output is **staged** in the pending overlay (`.sda/pending/`) — it merges
into the durable `docs/design/` only when the story completes.

**After DESIGN**, record:

```powershell
.sda/scripts/workflow/workflow-state.ps1 update `
  -Dir .sda/workflows/workflow-01 `
  -Bc DESIGN -Status done -Ledger done `
  -Output DESIGN/
```

### DEV — Implement the task

Agents: **`sda-dev-task`** (spec), **`sda-dev`** (implement), **`sda-dev-context-writer`** (ledger)

This is the start of the **DEV+QA inner loop** — implement → verify → rework →
repeat until both QA gates pass.

#### Step 1 — Author the dev task

`sda-workflow` tells you the DEV output folder. Pass it:

```
Design a task for password-reset email link.
The User Story is at .sda/workflows/workflow-01/BA/user-story.md
Output to: .sda/workflows/workflow-01/DEV/
```

`sda-dev-task` writes `DEV/task.md` with slices, test scenarios, and plan.

#### Step 2 — Author the QA spec

Agent: **`sda-qa-task`**

```
Author a QA spec for .sda/workflows/workflow-01/DEV/task.md
Output to: .sda/workflows/workflow-01/QA/
```

Produces `QA/qa-task.md` — black-box functional requirements, NFRs, regression
checks. Stable — authored once and reused across every run.

#### Step 3 — Init the inner cycle

```powershell
.sda/scripts/workflow/dev-qa-cycle-state.ps1 init `
  -Dir .sda/workflows/workflow-01/DEV `
  -Task password-reset-email `
  -Spec DEV/task.md
```

Creates `dev-qa-cycle-state.yaml` and `runs/run-01/`.

#### Step 4 — Run the inner cycle

Ask `sda-workflow` "what's next?" or run the housekeeper directly:

```powershell
.sda/scripts/workflow/dev-qa-next-step.ps1 `
  -Dir .sda/workflows/workflow-01/DEV
```

The cycle inside DEV:

```
implementing  →  sda-dev implements task.md → record SHA
   │
   ▼
qa-primary    →  sda-qa runs qa-task.md → PASS/FAIL
   │                    │
   │              FAIL  →  rework (new run, back to implementing)
   ▼
qa-regression →  sda-qa runs regression FRs → PASS/FAIL
   │                    │
   │              FAIL  →  rework
   ▼
passed        →  cycle complete
```

Each rework creates a new `runs/run-NN/`. Every run is a normal `task.md` — the
dev agents can't tell a fix from an original.

#### Record each run's result

After implementation:
```powershell
.sda/scripts/workflow/dev-qa-cycle-state.ps1 set-sha `
  -Dir .sda/workflows/workflow-01/DEV -Sha <commit-sha>
```

After primary QA:
```powershell
.sda/scripts/workflow/dev-qa-cycle-state.ps1 set-verdict `
  -Dir .sda/workflows/workflow-01/DEV `
  -Gate primary -Verdict PASS
```

After regression QA:
```powershell
.sda/scripts/workflow/dev-qa-cycle-state.ps1 set-verdict `
  -Dir .sda/workflows/workflow-01/DEV `
  -Gate regression -Verdict PASS
```

#### Step 5 — Update the ledgers

When the inner cycle reaches `passed`, update the durable ledgers:

```powershell
# DEV context writer — records behaviors + decisions
# (invoke sda-dev-context-writer, then:)

# QA context writer — promotes passed cases to the test-case library
# (invoke sda-qa-context-writer, then:)
```

#### Step 6 — Close the DEV+QA span

```powershell
.sda/scripts/workflow/workflow-state.ps1 update `
  -Dir .sda/workflows/workflow-01 `
  -Bc DEV -Status done -Ledger done

.sda/scripts/workflow/workflow-state.ps1 update `
  -Dir .sda/workflows/workflow-01 `
  -Bc QA -Status done -Ledger done
```

### DEP — Deploy

Reserved. No agents yet. Record when ready:

```powershell
.sda/scripts/workflow/workflow-state.ps1 update `
  -Dir .sda/workflows/workflow-01 `
  -Bc DEP -Status done -Ledger done
```

---

## 5. Check where you are

At any point, ask `sda-workflow`:

```
What's next for workflow-01?
```

Or run the housekeeper yourself:

```powershell
.sda/scripts/workflow/workflow-next-step.ps1 `
  -Dir .sda/workflows/workflow-01
```

Read state directly:

```powershell
.sda/scripts/workflow/workflow-state.ps1 read `
  -Dir .sda/workflows/workflow-01

# One field:
.sda/scripts/workflow/workflow-state.ps1 read `
  -Dir .sda/workflows/workflow-01 -Field current-bc
```

---

## 6. Git model

- **Branch per story** — `feature/password-reset-email`. Created when you start;
  PR/CI view of the whole story.
- **Runs = commits** — every DEV run's SHA is recorded in
  `dev-qa-cycle-state.yaml`.
- **Durable ledgers are committed** — `docs/features/`, `docs/design/`,
  `docs/system-context/`, `docs/test-cases/`, `docs/deployment/`.
- **Transient workspace is gitignored** — `.sda/` (by default).

---

## 7. Escalations

A BC can reject its input and send the story back one BC:

```
QA finds the User Story untestable → back to BA.
DEV finds the design infeasible → back to DESIGN.
```

`sda-workflow` records the escalation:

```powershell
.sda/scripts/workflow/workflow-state.ps1 escalate `
  -Dir .sda/workflows/workflow-01 `
  -From QA -To BA -Reason "Gherkin scenarios untestable — ambiguous preconditions"
```

The story rewinds; you re-enter at the target BC.

---

## 8. Definition of Done

A story is `done` when ALL of these hold:

- Every BC ledger is `done` (BA, DESIGN, DEV, QA, DEP)
- Both QA gates (primary + regression) PASS
- Coverage meets threshold; security scan clean
- Human approves the merge

`sda-workflow` checks DoD before advising "done." The `ledgers:` block in
`workflow-state.yaml` tracks each BC.

---

## Quick reference

| I want to… | Agent / Command |
|---|---|
| Set up SDA in a project | `sda-setup` skill: "Setup sda tool" |
| Start a story | `sda-workflow`: "Start a story for…" |
| See where I am | `sda-workflow`: "What's next for workflow-01?" |
| Author the User Story | `sda-ba` + output folder |
| Design architecture | `sda-system` / `sda-feature` |
| Author a dev task | `sda-dev-task` + output folder |
| Author the QA spec | `sda-qa-task` + output folder |
| Implement the task | `sda-dev` + `DEV/task.md` |
| Run acceptance QA | `sda-qa` + `QA/qa-task.md` |
| Update DEV ledger | `sda-dev-context-writer` |
| Update QA ledger | `sda-qa-context-writer` |
| Record BC completion | `workflow-state update -Bc <BC> -Status done` |
| Record QA verdict | `dev-qa-cycle-state set-verdict -Gate … -Verdict PASS/FAIL` |
| Escalate back a BC | `workflow-state escalate -From <BC> -To <BC>` |
