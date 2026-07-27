# QA + System Context — Combined Design & Implementation Plan

Consolidates the expert's QA improvements and the system context design into a single implementation roadmap.

---

## Combined Vision

Two complementary layers:

| Layer | Provided by | Benefit |
|---|---|---|
| **Task-local quality** | Expert's changeset (NFRs + implicit requirements) | Every qa-task.md covers non-happy-path concerns from day one, no prerequisites |
| **Project-global memory** | System context (pending-reverification + dependency map) | Regression coverage grows automatically as tasks accumulate; architectural decisions drive QA |

They are additive, not competing. The task-local layer works on an empty system. The global layer makes it smarter over time.

---

## Design Decisions

### System context is always required

System context is a **hard prerequisite** for all pipeline agents on repos with existing code — not optional, not a soft recommendation.

**Bootstrap check (applies to `sda-dev-task`, `sda-qa-task`, `sda-dev` ad-hoc) — same pattern as `bootstrap.md` in `sda-dev`:**

```
1. Read paths.system-context from project-config.json
2. Check if system-context/index.yaml exists
   a. EXISTS → proceed
   b. DOES NOT EXIST + brand new repo (no application code) → proceed with empty context
   c. DOES NOT EXIST + existing code → STOP and instruct the human:
      "⚠️ System context not found. Run sda-context-writer (setup mode) to
       reconstruct it, then re-invoke this agent."
      (No agent invokes another — the human runs sda-context-writer, then resumes.)
```

Recovery is **active, not a dead end** — but human-triggered. `sda-context-writer` in setup mode is a scan-and-reconstruct operation — similar to how `sda-toolscan` probes an existing project to produce `project-tools.md`. The result: valid structure (decisions from design docs, components from specs/manifest), empty `behaviors` tables. Behaviors are only populated through actual QA runs.

An initialized-but-empty context (brand new project after `sda-setup`, or freshly recovered) is a valid state — no behaviors verified yet, which is correct.

Staleness detection (context exists but code has drifted silently) is deferred — see OQ-3.

### Why the three supplement sources are permanent

System context captures what has been **formally verified and modeled**. The supplement sources catch what it hasn't captured yet:

| Source | What it finds that system context misses |
|---|---|
| Contract-driven | Spec consumers that exist but have no verified behavior in context yet |
| Route-adjacent | Informal proximity: routes sharing a controller, middleware, or auth guard — not in dependency map unless explicitly added |
| User-declared | Tacit knowledge — things the developer suspects but that have never been formally modeled |

As context matures, the supplement produces fewer *new* FRs — pending-reverification already covers most blast-radius candidates. But it never produces zero: new routes have no verified behaviors yet, the dependency map is curated not exhaustive by design, and developer intuition captures things no graph models. The supplement becomes less *critical* over time, never *redundant*.

### pending-reverification — who sets it, who clears it

`pending-reverification` marks a behavior that may have been affected by a change but has not been re-verified. It is **never cleared silently** — accumulated pending behaviors are visible regression debt.

**Set by `sda-context-writer`** after a QA run:
```
sda-context-writer (post-QA)
  reads: current spec ## System Context Impact → affected_components
  walks: dependency-map.yaml reverse-edges → blast-radius
  reads: qa-report.md → behaviors covered (PASS / FAIL / absent)
  writes: via CLI scripts only

  for each behavior in blast-radius:
    covered + PASS   → status: verified
    covered + FAIL   → status: pending-reverification  (+ failure note)
    not covered      → status: pending-reverification  (+ "not in this QA run")
```

**Cleared by `sda-context-writer`** after a regression QA run:
```
  regression PASS → status: verified   (pending cleared)
  regression FAIL → status: pending-reverification retained
                    surface: "Regression confirmed — {behaviors}. Code fix required."
```

**Read by `blast-radius.ps1/sh`** at three points (same script, no hook):
- Pre-implementation: `sda-dev-task`'s first step — populates `## Regression Risks`, warns about existing debt in affected domains; human confirms to proceed.
- Design-time QA spec: `sda-qa-task` runs it against `task.md`'s `affected_components` to get the pending set for design-time regression FRs in `qa-task.md`.
- Regression gate: the human runs it after primary QA passes to decide whether the regression gate fires and what is at risk.

Gate sequencing and who invokes what is defined in [Workflow Execution Model](#workflow-execution-model).

**sda-qa-task authors two kinds of QA spec:**

| Mode | Input | Output | Contains |
|---|---|---|---|
| Full (task design) | `task.md` | `qa-task.md` (stable) | New FRs + NFRs + design-time regression |
| Regression-only | pending set from `blast-radius.ps1/sh` | `runs/run-NN/qa-regression-task.md` (per-run) | Regression FRs only for the current pending set |

### Regression FRs — source and format

**Primary source:** `pending-reverification` statuses from system context. `sda-qa-task` generates mandatory regression FRs from pending behaviors in affected domains.

**Supplement (always, on top of primary):** Expert's three-source approach — catches regressions system context hasn't captured yet:
- Contract-driven: trace specs → find consumers via `manifest.md` → smoke-test FRs
- Route-adjacent: delegate to `sda-code-explore` for sibling routes → smoke-test FRs
- User-declared: "What else might break?" prompt → smoke-test FRs

**On empty context (brand new project):** no pending behaviors exist → supplement sources are the only regression input. This is correct — nothing has been verified yet, so nothing can be pending.

**Format:** Regression FRs live in `## Functional Requirements` with `(regression)` suffix in title. **Primary** regression FRs (from pending-reverification) use **full assertion depth**; **supplement** regression FRs (three-source) use **smoke-test depth** ("still returns 200 / still shows data"). New-behavior FRs use full assertion depth.

### NFRs — source

Expert's changeset defines systematic NFR categories. When system context exists, `decisions` entries in domain files are the authoritative source for NFR *content* (rate-limit policy, auth enforcement rules). Whether `sda-qa-task` **auto-derives** NFRs from decisions or the author writes them referencing decisions is a Phase 3 candidate (see OQ-2). On empty context (brand new project), NFRs are authored fresh per task per the expert's rules.

### Regression FR format

```markdown
### FR-N — {behavior title} (regression)
- **Precondition:** ...
- **Reproduce:** ...
- **Expected outcome:** ...
- **Compare:** ...
- **Layers:** ...
- **Failure severity:** blocker
```

---

## Workflow Execution Model

No orchestrator agent exists yet — **humans orchestrate**. Agents are single-responsibility leaves; a human invokes each one at the right time, guided by a playbook and a transition script. The execution engine (Copilot CLI, MCP-based, or custom) is undecided, so the model is **engine-agnostic**: the workflow is expressed as **data + a transition script**, executable by a human today and by an automated driver later with zero rework.

### Two bounded contexts

| Context | Agents | Job | Owns | Knows about |
|---|---|---|---|---|
| **Dev** | `sda-dev-task` + `sda-dev` | requirement → `task.md` → implemented code | `task.md`, `task-dev-agent-state.json` | nothing about QA, runs, regression, or `cycle-state` |
| **QA / Workflow** | `sda-qa-task`, `sda-qa`, `sda-context-writer`, workflow scripts, human | verify a dev task; drive the loop; request fixes | `qa-task.md`, QA reports, `cycle-state.yaml`, system context | consumes Dev output; requests new dev tasks |

**A fix is just another dev task.** When QA fails, the QA/Workflow context writes a fix requirement and requests a **normal dev task** from the Dev context — the Dev context cannot tell an original from a fix. There is no "rework mode" and no special `bugfix-task.md`: every dev task is a `task.md`.

### Responsibility boundaries

| Agent | Single responsibility | Produces |
|---|---|---|
| `sda-dev-task` | Author dev task specs (every dev task is a normal task) | `task.md` |
| `sda-dev` | Development (owns internal TDD micro-loop + its own `task-dev-agent-state.json`) | working code (in the repo) |
| `sda-qa-task` | Author QA specs (full + regression-only) | `qa-task.md`, `qa-regression-task.md` |
| `sda-qa` | Execute QA, verify | `qa-report.md`, `qa-regression-report.md` |
| `sda-context-writer` | Update system context | domain files, dependency-map |

No leaf agent invokes another leaf agent. Each does one job and returns. `sda-dev` orchestrates only its own TDD sub-agents (`sda-coder`, `sda-test-writer`, `sda-refactor`) — one black-box step from the workflow's view.

**`sda-dev` is fully encapsulated and NOT run-aware.** It is invoked with a `task.md`, implements it, and owns its private `task-dev-agent-state.json`. Nothing outside `sda-dev` reads or writes that state, and the run structure never reaches into it. Its output is **code in the repo** — the workflow records each attempt as a git SHA (see `cycle-state.yaml`), not as a run-folder artifact.

> Authoring note: `sda-dev-task`/`sda-qa-task` author spec *content*; `sda-scribe` (Mode 4) writes `qa-task.md` and `qa-regression-task.md` to the path it is given.

### Task cycle workspace — multi-run structure

One task cycle can require multiple implement/QA iterations. Each iteration is an immutable run folder.

```
{paths.specs}/{task-name}/
  qa-task.md                    ← QA spec (stable: own FRs + NFRs + design-time regression)
  cycle-state.yaml              ← workflow/QA state (current run, verdicts, open-failures, per-run SHA)
  runs/
    run-01/
      task.md                   ← dev task (original) — a normal task, from sda-dev-task
      qa-report.md              ← primary QA verdict
    run-02/
      task.md                   ← dev task (fix) — just another normal task, from sda-dev-task
      qa-report.md
      qa-regression-task.md     ← sda-qa-task regression-only (if regression gate fired)
      qa-regression-report.md   ← sda-qa regression verdict
```

Rules:
- `qa-task.md` is authored once from run-01's `task.md`, then **stable** — every subsequent dev task is re-verified against it (a fix's job is to make the original FRs pass).
- **Each dev task is a normal `task.md`.** run-01 holds the original; runs N≥2 hold a fix task — the Dev context authors it identically, unaware it is a "fix." No `bugfix-task.md`, no rework mode.
- **Implementation is not a run artifact.** `sda-dev` writes code to the repo and owns its own `task-dev-agent-state.json`; the workflow records each run's implementation as a git SHA in `cycle-state.yaml`. Run folders hold only spec + QA artifacts.
- Regression specs/reports are per-run (transient), never persisted to the stable `qa-task.md`.

### Two-gate QA — per run, short-circuiting

Each run's QA has two gates. Regression (Gate 2) runs **only after** primary (Gate 1) passes — never verify neighbors against a known-broken implementation.

```
Gate 1  PRIMARY QA   sda-qa ← current spec → qa-report.md
          FAIL → run verdict FAIL, skip Gate 2 → REWORK
          PASS → continue
        context update   sda-context-writer → may mark behaviors pending-reverification
Gate 2  REGRESSION QA (only if blast-radius has pending)
          blast-radius.ps1/sh → collect ALL pending in blast-radius
                                 (pre-existing debt + newly-pending)
          none → run PASS
          some → sda-qa-task (regression-only) → qa-regression-task.md
                 sda-qa → qa-regression-report.md
                 sda-context-writer → clear/retain pending
                 FAIL → run verdict FAIL → REWORK
                 PASS → run PASS
```

A regression failure is a defect like any other — it feeds the same rework loop. A rework re-runs **both** gates (a regression fix can re-break primary).

### Human playbook — one task cycle

```
STEP 1  Author task     → sda-dev-task            → runs/run-NN/task.md (+ ## System Context Impact)
STEP 2  Author QA spec  → sda-qa-task         → qa-task.md   (run-01 only; stable thereafter)
STEP 3  Implement       → sda-dev         → working code (repo); record SHA (cycle-state.ps1/sh)
STEP 4  PRIMARY QA      → sda-qa (qa-task.md, out → runs/run-NN/) → qa-report.md
                          record verdict (cycle-state.ps1/sh)
                          FAIL → STEP 7 ; PASS → STEP 5
STEP 5  Update context  → sda-context-writer  → pending statuses
STEP 6  REGRESSION QA   → blast-radius.ps1/sh
                          none → CYCLE DONE
                          some → sda-qa-task (regression-only) → sda-qa → sda-context-writer
                                 FAIL → STEP 7 ; PASS → CYCLE DONE
STEP 7  NEW FIX TASK    → write fix requirement from failures → sda-dev-task → runs/run-(NN+1)/task.md → STEP 3
```

The human resolves each per-run output folder (`runs/run-NN/`) from `cycle-state.ps1/sh --action read` (or `next-step.ps1/sh`) and passes it when invoking `sda-dev-task` / `sda-qa` / `sda-qa-task`. The Dev context receives only a requirement + an output path — never the run number or `cycle-state.yaml`.

### State machine as data + transition script

The workflow is **not** hard-coded into an orchestrator. It is:
- **`cycle-state.yaml`** — the single source of truth for "where am I": current run, run-folder path, status, open-failures, per-run SHA.
- **`next-step.ps1/sh`** — the transition function as a script (the "housekeeper"). Reads `cycle-state.yaml` + signals (last QA verdict, blast-radius) → computes and reports the single next action, optionally advancing state.

**Two state files, two owners — no overlap:**

| File | Owner | Scope | Who touches it |
|---|---|---|---|
| `task-dev-agent-state.json` | `sda-dev` | Implementation progress of the current task | `sda-dev` only — encapsulated, off-limits to all else |
| `cycle-state.yaml` | Workflow layer | Run loop: current run, verdicts, open-failures, SHAs | Human + `cycle-state.ps1/sh` + `next-step.ps1/sh` |

Leaf functional agents (`sda-qa`, `sda-qa-task`, `sda-context-writer`) never write `cycle-state.yaml`. They MAY *read* the resolved run-folder path (via `cycle-state.ps1/sh --action read`) but never advance state. `sda-dev` touches neither the run structure nor `cycle-state.yaml`.

```
next-step.ps1/sh
  reads: cycle-state.yaml (+ last qa-report verdict, + blast-radius signal)
  outputs: "NEXT → invoke sda-qa with runs/run-02/qa-task.md"
  optionally: advances cycle-state.yaml
```

Evolution path (zero rework):
```
Today:  human runs next-step.ps1/sh → reads the next action → performs it
Later:  an engine / hook / MCP runs the SAME script → performs the action automatically
```

### Housekeeper guardrail

`next-step.ps1/sh` (and any future housekeeper) **MAY**: update `cycle-state.yaml`, run `blast-radius.ps1/sh`, record verdicts, run `sda-context-writer` scripts, compute + report the next functional step.

It **MUST NOT**: trigger the next functional agent (`sda-dev-task`, `sda-dev`, `sda-qa-task`, `sda-qa`). Bookkeeping and "here is what is next" only — the human (or a future engine) executes the next functional step. This keeps humans in control, prevents runaway agent chains, and keeps every agent single-responsibility and non-chaining.

### cycle-state.yaml

```yaml
task: add-user-auth
current-run: 3
status: passed          # implementing | qa-primary | qa-regression | rework | passed
runs:
  - run: 1
    spec: runs/run-01/task.md
    sha: a1b2c3d          # implementation commit for this run
    verdict: FAIL
    failures: [FR-3, NFR-1]
  - run: 2
    spec: runs/run-02/task.md
    sha: e4f5g6h
    verdict: FAIL
    failures: [FR-3]
  - run: 3
    spec: runs/run-03/task.md
    sha: i7j8k9l
    verdict: PASS
open-failures: []       # hand-off contract between QA and rework
```

Written only via `cycle-state.ps1/sh`, by the human (or `next-step.ps1/sh`). No leaf functional agent writes it; per-run agents may read the current run-folder path via `--action read`.

---

## Phase 1 — Expert's Changeset (no prerequisites)

Implements NFRs, implicit requirements, and supplement regression sources. Works immediately; complement to system context (not a replacement).

### P1-1: `qa-task-schema.md`

Add after `## Functional Requirements`:

```markdown
## Non-Functional Requirements

### NFR-N — {cross-cutting quality attribute}
- **Concern:** {HTTP contract | payload validation | rate limiting | security boundary | performance}
- **Reproduce:** {the request(s)}
- **Expected outcome:** {observable quality result — status code, header, timing}
- **Compare:** {assertion}
- **Layers:** {…}
```

Add regression FR rules:
- Regression FRs live in `## Functional Requirements` with `(regression)` suffix in title.
- Regression FRs use smoke-test depth.
- Failure severity: `blocker`.

Add NFR-specific rules:
- HTTP contract accuracy: verify status codes for missing auth, bad permissions, malformed input.
- Payload validation: verify strict schema matching on response shape.
- Rate limiting: verify behaviour under ≥5 rapid successive calls within 1 second.
- Security boundaries: verify auth enforcement across protected route families.

### P1-2: `sda-qa-task.agent.md`

1. Extend `description` to mention NFRs and regression.
2. Add NFR & Regression pass step between "Coverage thinking" and "FR self-check":

```
NFR & Regression pass:
  a. NFRs — for each contract spec the task touches, generate:
     - HTTP contract accuracy NFRs (status codes for auth/permission/malformed-input boundaries)
     - Payload validation NFRs (response shape matches spec)
     - Rate-limiting NFRs (rapid successive calls)
  b. Regression supplement (always — catches what system context hasn't captured yet):
     - Contract-driven: trace specs → find consumers via manifest.md → smoke-test FRs
     - Route-adjacent: delegate to sda-code-explore for sibling routes → smoke-test FRs
     - User-declared: ask "What else might break?" → smoke-test FRs
  c. Implicit requirements:
     - Idempotency: for any mutation endpoint → FR: send 5× rapidly → only one effect
     - Boundary inputs: for any input-accepting endpoint → FR: malformed/oversized/missing-field payload → graceful rejection
```

3. Add `manifest.md` to MAY read list.
4. Extend Mode 4 delegation block to include NFRs alongside FRs.
5. Add FR self-check rules: every contract spec → ≥1 NFR; every mutation endpoint → ≥1 idempotency FR.

### P1-3: `sda-qa.agent.md`

Extend Phase 4 to walk `## Non-Functional Requirements` using the same Reproduce → Compare → Evidence pipeline.

Add NFR-specific verification behaviours:
- Rate-limiting: send N requests in rapid sequence, verify rate-limit headers or rejection responses.
- Payload validation: send request, compare response shape against expected schema.
- Idempotency FRs: execute Reproduce 5× in rapid succession, verify only one state change.

### P1-4: `sda-scribe.agent.md`

Mode 4 input contract — extend to accept NFRs:
```
- Non-Functional Requirements — per NFR: concern, reproduce, expected outcome, compare, layers.
```

Step 6 (Write qa-task.md) — add `## Non-Functional Requirements` section after `## Functional Requirements`. Omit section if caller provides none.

### P1-5: `AGENTS.md` (tools/sda/)

Add dependency matrix rows:

| When you change… | Also update… | Why |
|---|---|---|
| `qa-task-schema.md` NFR section | `sda-qa-task` (designs NFRs), `sda-scribe` (writes — Mode 4), `sda-qa` (verifies) | All three agents consume the NFR schema |
| `sda-qa-task` regression pass rules | `qa-task-schema.md` regression FR rules, `sda-qa` | Designer, schema, and verifier must agree on regression FR format |
| `sda-qa-task` Mode 4 delegation format | `sda-scribe` Mode 4 input contract | Scribe parses the expanded QA Task fields including NFRs |

**P1 dependency order:** P1-1 → P1-2 → P1-3 → P1-4 → P1-5 (schema first; agents second; dependency map last).

---

## Phase 2 — System Context Infrastructure (no Phase 1 dependency)

Creates the system context scaffolding. Can run in parallel with Phase 1.

### P2-1: `system-context-schema.md` (new, in `tools/sda/skills/sda-setup/assets/`)

Defines schemas for:
- `index.yaml` — domain registry
- `dependency-map.yaml` — component graph (nodes: id, type, path, domain; edges: from/to)
- `{domain}.yaml` — behaviors (id, claim, via, status, note) + decisions (id, summary, rationale, status, superseded_by)
- `cross-domain.yaml` — behaviors spanning ≥2 domains (via is array)

Node types: `api`, `service`, `repository`, `external`, `ui`.
Behavior statuses: `verified`, `pending-reverification`.
Decision statuses: `active`, `superseded`.

### P2-2: `task-schema.md` — add `## System Context Impact` section

```markdown
## System Context Impact
affected_components: []          # existing component IDs whose behaviour may change
new_components: []               # new component IDs to register in dependency-map.yaml
new_domain:                      # name of new domain file to create (omit if none)
decisions_affected: []           # decision IDs being superseded or amended
```

Rules:
- Omitted entirely for tasks with no system context overlap.
- `new_components`: `sda-context-writer` resolves definition (type, path, depends_on) from `## Design Approach`.
- `affected_components`: triggers pending-reverification blast-radius walk post-QA.

### P2-3: `project-config.json` schema — add `paths.system-context`

Default: `system-context/`. Configurable per project.

### P2-4: `sda-context-writer.agent.md` (new agent)

Tools: `read`, `execute` (all writes via CLI scripts; git diff as secondary signal).

Three invocation modes:
- **Post-task** (STEP 5, human-invoked): reads current spec `## System Context Impact` + `qa-report.md` → updates domain files and dependency map, marks pending-reverification
- **Manual**: user provides affected component IDs; agent may suggest candidates from git diff; user confirms
- **Setup**: reads `design.md` if exists → bootstraps skeleton domain files with decisions; empty behaviors tables

Logic (post-task):
1. Read `## System Context Impact` → affected_components + new_components
2. Walk `dependency-map.yaml` reverse-edges → expand blast radius
3. Read `qa-report.md` → find covered behaviors (PASS/FAIL)
4. For behaviors in blast radius:
   - Covered, PASS → `status: verified`
   - Covered, FAIL → `status: pending-reverification` + failure note
   - Not covered → `status: pending-reverification` + "not covered by this QA run"
5. Add new_components nodes + edges to `dependency-map.yaml`
6. Create domain file if new_domain specified; register in `index.yaml`

**All file writes go through CLI scripts (see P2-7) — agent reasons about what to write; scripts enforce schema and format.**

### P2-5: `sda-setup` skill — scaffold `system-context/` and install scripts

On project init:
- Create `system-context/index.yaml` (empty registry) and `system-context/dependency-map.yaml` (empty graph)
- Install CLI scripts from P2-7 into `.sda/scripts/system-context/` (same pattern as `task-state.ps1/sh`)
- Install workflow scripts from P2-8 into `.sda/scripts/workflow/`
- Establish the `runs/` convention (task cycle workspace — see [Workflow Execution Model](#workflow-execution-model))
- If `design.md` exists, delegate to `sda-context-writer` setup mode

### P2-6: `AGENTS.md` (tools/sda/) — add P2 rows

| When you change… | Also update… | Why |
|---|---|---|
| `system-context-schema.md` | `sda-context-writer`, `sda-dev-task`, `sda-qa-task` | All three read or write system context files |
| `task-schema.md` System Context Impact section | `sda-dev-task` (authors it), `sda-context-writer` (reads it) | Writer parses exact fields task produces |
| `paths.system-context` in `project-config.json` | `sda-dev-task`, `sda-qa-task`, `sda-context-writer`, `sda-setup` skill | All agents resolve the context root from this field |
| `sda-context-writer` update logic | `sda-dev-task` System Context Impact section | Writer parses the exact fields task produces |
| `cycle-state.yaml` schema | `cycle-state.ps1/sh`, `next-step.ps1/sh`, workflow playbook | State producers and consumers must agree |

**P2 dependency order:** P2-1 → P2-7 → P2-8 → P2-2 → P2-3 → P2-4 (requires P2-7) → P2-5 (requires P2-7, P2-8) → P2-6.

### P2-7: CLI scripts for system context writes (in `.sda/scripts/system-context/`)

All system context file I/O goes through scripts. Agent reasons about what to write; scripts enforce schema and formatting. Each script ships as a PowerShell (`.ps1`) and Bash (`.sh`) pair. Each script accepts `--action` as first parameter.

**Dependency-map — components:**
`components.ps1 / components.sh --action [add|update|delete]`
- `add` — add new node + edges to dependency-map.yaml
- `update` — update path, type, or domain of existing node
- `delete` — remove node + all inbound/outbound edges; **cascade deletes linked behaviors**; outputs list of everything removed

**Dependency-map — edges:**
`edges.ps1 / edges.sh --action [add|remove]`
- `add` — add dependency edge between two existing nodes
- `remove` — remove a specific edge

**Domain files — behaviors:**
`behaviors.ps1 / behaviors.sh --action [add|update|delete]`
- `add` — add new behavior entry
- `update` — update status, claim, note, or via
- `delete` — remove a behavior (endpoint removed, feature dropped)

**Domain files — decisions:**
`decisions.ps1 / decisions.sh --action [add|update]`
- `add` — add new architectural decision
- `update` — supersede or amend existing decision (no delete — decisions are superseded, not removed)

**Domain lifecycle:**
`domains.ps1 / domains.sh --action [create|delete]`
- `create` — create domain file + register in index.yaml
- `delete` — remove domain file + unregister from index.yaml + cascade delete behaviors

**Blast-radius query (read-only):**
`blast-radius.ps1 / blast-radius.sh` — reads affected_components from task.md, traverses dependency-map reverse edges, queries pending-reverification; outputs structured report (no `--action` needed)

**Cascade delete rule:** `components.ps1/sh --action delete` and `domains.ps1/sh --action delete` cascade to linked behaviors automatically. No silent drops — output always lists everything removed.

### P2-8: Workflow state scripts (in `.sda/scripts/workflow/`)

Engine-agnostic infrastructure for the human-orchestrated workflow (see [Workflow Execution Model](#workflow-execution-model)). Each ships as a PowerShell (`.ps1`) and Bash (`.sh`) pair.

**Cycle state:**
`cycle-state.ps1/sh --action [init|set-verdict|bump-run|read]`
- `init` — create `cycle-state.yaml` for a task
- `set-verdict` — record a run's verdict + failures; update `open-failures`
- `bump-run` — advance `current-run`, create `runs/run-NN/` folder
- `read` — print current state

**Transition function (housekeeper):**
`next-step.ps1/sh` — reads `cycle-state.yaml` + last QA verdict + `blast-radius.ps1/sh` signal; outputs the single next action; optionally advances state. **MUST NOT** trigger the next functional agent (see [Housekeeper guardrail](#housekeeper-guardrail)).

---

## Phase 3 — Wire System Context into QA Pipeline (requires Phase 2)

Connects system context to design and QA agents, activating the cumulative regression layer.

### P3-1: `sda-dev-task.agent.md`

Add bootstrap instructions:
1. Read `index.yaml` + domain files for task's affected domains
2. Read `dependency-map.yaml`
3. Apply conflict detection gate before finalising any spec section
4. Include blast-radius domains in `## Regression Risks`
5. Author `## System Context Impact` section

Conflict detection gate (hard stop):
```
⚠️ System Context Conflict
This request contradicts:
  Decision {ID}: "{summary}" [{domain}.yaml]
  Verified behaviors at risk: {IDs}
  Downstream impact: {component} depends on {component} (dependency-map)

Proceeding will require:
  — {ID} marked superseded
  — {behaviors} marked pending-reverification
  — Regression check on {domains}

Confirm to proceed, or revise the request.
```

### P3-2: `sda-qa-task.agent.md` — add primary regression source

Extend regression step to primary + supplement logic:

```
Regression pass:
  1. Short-circuit check — system context must exist (see Design Decisions).
  2. Primary — pending-reverification behaviors in affected domains:
     - Read pending-reverification behaviors from system context
     - Generate mandatory regression FR for each — full assertion depth, failure severity: blocker
     - Include cross-domain.yaml behaviors if task touches cross-domain components
  3. Supplement (always, on top of primary) — Phase 1 three-source approach:
     - Contract-driven, route-adjacent, user-declared
     - Smoke-test depth
     - On empty context (brand new project): this is the only regression input
```

Add `dependency-map.yaml` to MAY read list (alongside `manifest.md`).

**Regression-only mode** (invoked by the human during the regression gate — STEP 6):
- Input: pending set from `blast-radius.ps1/sh` (pre-existing debt + newly-pending)
- Skip: new-behavior FR authoring, NFR generation, supplement three-source pass
- Generate: regression FRs only from the pending set — full assertion depth, failure severity: `blocker`
- Output: `runs/run-NN/qa-regression-task.md` (per-run, transient) using `qa-task-schema.md` format

### P3-3: `sda-dev.agent.md` — ad-hoc mode gate

In ad-hoc mode only (no task.md): read system context before implementing. Apply conflict detection gate if the ad-hoc change touches a component with verified behaviors or contradicts a decision.

In task mode: no gate — task was already vetted by `sda-dev-task`.

**No run-awareness.** `sda-dev` is invoked identically with any `task.md` — the original (run-01) or a fix (run N≥2) are indistinguishable to it; it does not read the run structure or `cycle-state.yaml`, and it keeps its private `task-dev-agent-state.json`. Its output is code in the repo — the workflow records the resulting SHA in `cycle-state.yaml`.

### P3-4: `AGENTS.md` (tools/sda/) — add P3 rows

| When you change… | Also update… | Why |
|---|---|---|
| `sda-context-writer` pending-reverification logic | `sda-qa-task` regression pass | qa-task derives regression FRs from pending statuses; both must agree |
| System context conflict gate format | `sda-dev-task`, `sda-dev` (ad-hoc) | Both agents use the same gate format |
| `sda-qa-task` primary/supplement regression logic | `qa-task-schema.md` regression FR rules | Designer and schema must agree on FR format and sourcing |
| `blast-radius.ps1/sh` output format | `sda-dev-task` (reads pre-impl), workflow playbook (regression gate) | Both read and act on the script report |
| `cycle-state.yaml` schema | `cycle-state.ps1/sh`, `next-step.ps1/sh`, workflow playbook | State producers and consumers must agree |

**P3 dependency order:** P3-1 and P3-2 can run in parallel. P3-3 after P3-2. P3-4, P3-5, P3-6 last.

### P3-5: `sda-feature.agent.md` + `sda-system.agent.md` — conflict detection gate

Same gate pattern as `sda-dev-task` (P3-1). Both agents read system context at bootstrap and apply the conflict detection gate before proposing or finalising design decisions.

- `sda-feature`: gate fires when feature scope overlaps a decision constraint or would alter a verified behavior's entry point
- `sda-system`: gate fires when system-level change contradicts an active decision

Neither agent authors `## System Context Impact` (that belongs to `sda-dev-task`). They only read context and gate on conflicts.

### P3-6: Workflow playbook (human-facing doc)

Author the human orchestration playbook based on [Workflow Execution Model](#workflow-execution-model): STEP 1–7, two-gate QA, multi-run structure, `cycle-state.yaml`, `next-step.ps1/sh` usage. Location: `tools/sda/` docs (alongside `AGENTS.md`) or the sda `README.md`. No orchestrator agent — humans execute steps; `next-step.ps1/sh` advises the next action.

---

## Full Execution Order

```
Phase 1 (immediate, no prerequisites):
  P1-1  qa-task-schema.md — NFR section + regression FR rules
  P1-2  sda-qa-task.agent.md — NFR pass + supplement regression + implicit requirements
  P1-3  sda-qa.agent.md — NFR verification
  P1-4  sda-scribe.agent.md — Mode 4 NFR support
  P1-5  AGENTS.md — P1 dependency rows

Phase 2 (parallel with Phase 1):
  P2-1  system-context-schema.md (new)
  P2-7  system-context CLI scripts (.sda/scripts/system-context/)
  P2-8  workflow state scripts (.sda/scripts/workflow/) — cycle-state, next-step
  P2-2  task-schema.md — System Context Impact section
  P2-3  project-config.json schema — paths.system-context
  P2-4  sda-context-writer.agent.md (new)
  P2-5  sda-setup skill — scaffold system-context/ + runs/ + install scripts
  P2-6  AGENTS.md — P2 dependency rows

Phase 3 (requires Phase 2 complete):
  P3-1  sda-dev-task.agent.md — bootstrap + gate + System Context Impact
  P3-2  sda-qa-task.agent.md — primary regression + regression-only mode
  P3-3  sda-dev.agent.md — ad-hoc mode gate
  P3-4  AGENTS.md — P3 dependency rows
  P3-5  sda-feature.agent.md + sda-system.agent.md — conflict detection gate
  P3-6  Workflow playbook (human-facing doc)
```

---

## Open Questions

- **OQ-1** ✅ RESOLVED: `pending-reverification` enforces two gates, both human-driven (no orchestrator):
  (1) Pre-implementation: `sda-dev-task` runs `blast-radius.ps1/sh` as its first step; surfaces existing debt in `## Regression Risks`; human confirms to proceed.
  (2) Regression gate (STEP 6): after primary QA passes, the human runs `blast-radius.ps1/sh` and the regression loop resolves or explicitly acknowledges every pending behavior before the cycle closes.
- **OQ-2**: When system context decisions exist, should `sda-qa-task` auto-derive NFRs from them (e.g., rate-limit decision → NFR generated automatically)? Phase 3 candidate.
- **OQ-3**: Staleness detection — context exists but code has drifted silently (changes made outside the SDA pipeline). How to detect and signal that context may be stale? Possible approaches: timestamp-based warning, git-diff comparison at bootstrap, or manual `sda-context-writer audit` mode. See `ai-sdlc.md`.
