# Execution Checklist — Real-File Build Order

The single real-file pass that turns the S0–S6 *Open items* into actual agents,
schemas, scripts, and config. Ordered into **verifiable phases** (E0–E6); each phase
is a checkpoint — stop and verify before the next. Per file, the P-item base and its
S1–S5 delta are applied **together** (S6-B layering) so each file reaches its final
state in one step.

Source specs: [implementation plan](00-implementation-plan.md),
[architecture](01-architecture.md),
[DEV+QA internals](07-dev-qa-internals.md), and the five BC specs. Paths are
camelCase; assets are BC-subfoldered under `skills/sda-setup/assets/`.

Dependency rule: **schemas exist before the agents that read them**; the **User Story
schema (E1) precedes every agent that consumes it** (E4).

---

## E0 — Foundation: config paths

- [x] `project-config.example.json` — add camelCase durable roots: `paths.baStandards`, `paths.design`, `paths.qaTestCases`, `paths.devSystemContext`, `paths.baFeatures`, `paths.depContext`; overlay `paths.pendingChanges`; transient `paths.workflows`.
- [x] `project-config.reference.yml` — mirror the same keys with descriptions.
- [x] Confirm existing `paths.design` is repurposed as the durable design ledger (default `.sda/design` → `docs/design`).

**Verify:** config parses; all six durable roots + overlay + transient present, camelCase.

---

## E1 — BA context (upstream; everything consumes it)

- [x] `skills/sda-setup/assets/ba/user-story-schema.md` — Actor statement + Gherkin template (S1-2).
- [x] `skills/sda-setup/assets/ba/definition-of-ready.md` — DoR template (S1-3).
- [x] `skills/sda-setup/assets/ba/definition-of-done.md` — DoD template; references the 5-ledger table (S1-3).
- [x] `skills/sda-setup/assets/ba/global-nfr.md` — global NFR template (S1-3).
- [x] `skills/sda-setup/assets/ba/implemented-feature-schema.md` — BA ledger schema (S1-4).
- [x] `agents/sda-ba.agent.md` — new agent (S1-1): `tools: ["read","search","agent","edit"]`, `user-invocable` + `disable-model-invocation`, DoR/DoD gates, one-actor gate, ledger write.

**Verify:** `sda-ba` frontmatter valid; schemas complete; DoD references (not duplicates) the ledger table.

---

## E2 — Durable schemas for DESIGN / QA / DEP / DEV

- [x] `skills/sda-setup/assets/design/design-doc-schema.md` — durable design ledger + pending lifecycle (S2-2).
- [x] `skills/sda-setup/assets/qa/known-test-case-schema.md` — reusable test-case library (S3-2).
- [x] `skills/sda-setup/assets/dep/deployment-context-schema.md` — per-part deployment ledger (S5-1).
- [x] `skills/sda-setup/assets/dev/system-context-schema.md` — behaviors/decisions/dependency map (P2-1).

**Verify:** four schemas are pure entity docs (no agent/phase/workflow names).

---

## E3 — P2 infrastructure (system context + scripts + scaffolding)

- [x] `skills/sda-setup/assets/dev/task-schema.md` — add `## System Context Impact` section (P2-2).
- [x] `agents/sda-dev-context-writer.agent.md` — new agent (P2-4): post-QA writer for the **system context only** (behavior verified-status, dependency-map, decisions); writes via the system-context CLI scripts (`read` + `execute`); SessionStart hook + read-config manifest entry (`paths.devSystemContext`).
- [x] `agents/sda-qa-context-writer.agent.md` — new agent (S3-2): post-QA writer for the **known-test-case library only**; promotes passed FRs + appends story to Stories (`read` + `edit`); SessionStart hook + read-config manifest entry (`paths.qaTestCases`).
- [x] system-context CLI scripts — source `skills/sda-setup/assets/dev/{powershell,bash}/system-context/`, runtime `.sda/scripts/system-context/` (P2-7). Scripts: `components`, `edges`, `behaviors`, `decisions`, `domains`, `blast-radius` + shared `_sc-common` helper; uniform action verbs `add | update | delete` (no `remove`/`create`; `delete` cascades linked behaviours); each wired to its `scripts.sc*` config key. Dependency-free (Option D surgical YAML edits); PowerShell + bash emit byte-identical canonical YAML (parity-tested); every call takes `-Root`/`--root {paths.devSystemContext}`.
- [x] inner DEV+QA cycle scripts — `dev-qa-cycle-state` + `dev-qa-next-step` (D12/P2-8); source `skills/sda-setup/assets/scripts/{powershell,bash}/workflow/`, runtime `.sda/scripts/workflow/`. `dev-qa-cycle-state` owns `dev-qa-cycle-state.yaml` (init/read/set-sha/set-verdict/bump-run; two-gate status machine implementing→qa-regression→passed / →rework); `dev-qa-next-step` reads it and advises the single next step (housekeeper — never triggers agents). Dependency-free; PowerShell + bash byte-identical (parity-tested).
- [x] outer SDLC-workflow scripts — `workflow-state` (`init`/`read`/`update`/`escalate`) + `workflow-next-step` over `workflow-state.yaml` (BA→DESIGN→DEV→QA→DEP + `ledgers:` + escalations; the advisor walks BA→DESIGN→DEV+QA span→DEP→merge). Named after the state file, mirroring the inner `dev-qa-cycle-state`/`dev-qa-next-step` pair — this **supersedes the architecture's stale `workflow-init`/`workflow-update` three-name list** (now fixed in `01-architecture.md` + `00-implementation-plan.md`). Dependency-free surgical YAML; both engines byte-identical (parity-tested across the full progression). `workflow-state init` records the branch name + creates the per-BC subfolders (`BA/ DESIGN/ DEV/ QA/ DEP/`) but never runs git (owned by the D11 commit-helper) and never triggers an agent. Added to the setup `workflow` copy loop.
- [x] `skills/sda-setup/SKILL.md` — install new scripts (P2-5): done via the setup scripts. SKILL.md has no resource-map table (it lists only the skill's own config/tool-catalog dependencies), so no SKILL.md change was needed. System-context is **not** pre-scaffolded — the `sc-*` scripts self-init `dependency-map.yaml`/`index.yaml` on first `add` (P2-5's empty-file pre-seed dropped).
- [x] **Scaffolding wiring** — `setup.ps1` + `setup.sh` now copy every new BC schema to `.sda/resources/{ba,design,qa,dep,dev}/` and both new script folders (`dev/{powershell,bash}/system-context/` → `.sda/scripts/system-context/`, `scripts/{powershell,bash}/workflow/` → `.sda/scripts/workflow/`), tests excluded by explicit listing. Verified end-to-end on both engines. (Also fixed a latent bug: `read-config` was copied before `.sda/scripts/` existed.)
- [x] **Durable-root seeding decision** — resolved **Option A**: setup seeds the three BA gate templates (`definition-of-ready`, `definition-of-done`, `global-nfr`) into the default `docs/standards` (`paths.baStandards`), **seed-if-absent** so re-runs never clobber project customizations (verified). The durable **ledgers** (system-context, test-cases, design, implemented-features, deployment) are **not** seeded — their writers self-init. A project that reconfigures `baStandards` moves the seeded templates (documented in the setup comment).

**Verify:** scripts have `.ps1` + `.sh` pairs; `sda-dev-context-writer` writes only system context and `sda-qa-context-writer` only the library; both run post-QA from `qa-report.md`; task-schema section renders; a fresh `setup` run scaffolds all new BC resources.

---

## E4 — Agent wiring (P1 + P3 base, S-deltas layered per file)

Each file below reaches final state in one edit (base + delta together):

- [x] `skills/sda-setup/assets/qa/qa-task-schema.md` — P1-1 (folded in): add `## Non-Functional Requirements` section + NFR rules + regression-FR rules (`(regression)` suffix, failure severity, primary/supplement depth). Prerequisite for scribe P1-4.
- [x] `agents/sda-qa-task.agent.md` — P1-2 (NFRs) + P3-2 (pending-reverification regression) + **S3-1** (consume User Story Gherkin as primary FR; Gherkin→FR mapping) + author `qa-task.md ## Retired Behaviours` from the task's `## System Context Impact removed_behaviors` (QA-native retirement signal consumed by `sda-qa-context-writer`). BC-blind (reads system context read-only for regression; never workflow/cycle state). **Regression-only per-run mode** (`runs/run-NN/qa-regression-task.md`) deferred to E4b (workflow-run-coupled — conflicts with the BC-blind/path-agnostic model).
- [x] `agents/sda-qa.agent.md` — P1-3 (folded in): Phase 4b walks `## Non-Functional Requirements` (same Precondition→Reproduce→Compare→Classify→Evidence pipeline) with concern-specific verification (HTTP-contract status codes, payload-shape compare, rate-limiting rapid calls, security-boundary, performance); idempotency FRs stay in Phase 4. Closes the NFR contract end-to-end (schema→qa-task→scribe→qa).
- [x] `agents/sda-scribe.agent.md` — P1-4 (Mode 4 accepts + writes `## Non-Functional Requirements`; also wires the schema's `## Retired Behaviours` write that sda-qa-task now delegates).
- [x] `agents/sda-dev-task.agent.md` — P3-1 (bootstrap + conflict gate + `## System Context Impact`) + **S4-1** (consume User Story; read `paths.design` + `paths.pendingChanges` + `paths.devSystemContext`). Landed with the earlier E4a commit; P3-1 base verified present in the Research phase (system-context read + bootstrap + conflict gate).
- [x] `agents/sda-dev.agent.md` — P3-3 (ad-hoc mode gate): ad-hoc input provider reads the system context read-only before deriving the unit and gates on verified-behaviour/active-decision conflicts; task mode skips the gate (pre-vetted by `sda-dev-task`); no run-awareness. Manifest gains `paths.devSystemContext` (both engines verified).
- [x] `agents/sda-feature.agent.md` — P3-5 (conflict gate) + **S2-1** (consume User Story; output to pending overlay).
- [x] `agents/sda-system.agent.md` — P3-5 (conflict gate) + **S2-1** (same).
- [x] **Config-injection reconciliation** — updated the `read-config` per-agent manifest (`skills/sda-setup/assets/scripts/{powershell,bash}/read-config.*`) so each rewired agent receives the **new** durable path keys (`paths.design` now = `docs/design`; `paths.pendingChanges`, `paths.devSystemContext`, `paths.qaTestCases` added where needed) with matching default-map entries (both engines). Old keys (`paths.tasks`, `paths.features`) retained through E4; **dropped in E4b** (workflow-only creation).

**Verify:** each agent's `.sda dependencies` read-list updated; no DESIGN agent authors `## System Context Impact`; all consume the User Story where specified; config injected via each agent's `SessionStart` hook (no direct `project-config.json` reads); frontmatter valid.

---

## E4.5 — Orchestration assistant (`sda-workflow`)

Depends on the workflow + inner-cycle scripts from E3. New agent; advisor scope (D14).

- [x] `agents/sda-workflow.agent.md` — new agent: `tools: ["read","execute","agent"]` (no `edit`); the sole **consumer** of workflow state — reached **only** via the `workflow-state` script's `read` action (never opens `workflow-state.yaml`; the YAML format is owned by the script, mirroring how `dev-qa-next-step` reads via `dev-qa-cycle-state read`); `read` tool reserved for the governing documents (DoR/DoD, `user-story.md`, `qa-report.md`); verifies each gate line → signal (DoR entering DEV; DoD + `ledgers:` + QA verdict entering `done`); runs `workflow-state` / `workflow-next-step` / `dev-qa-next-step` on human confirmation (including `workflow-state init` to **start a new story** — creates the folder + per-BC subfolders + branch name, no git); **advises** the next functional step with clickable-link evidence, never invokes BC agents; refuses `done` until all five ledgers `done` + both QA gates PASS + coverage/security clean + human merge.
- [x] Added the `SessionStart` read-config hook to `sda-workflow` and registered it in the `read-config` manifest + defaults (both engines) with `paths.workflows` (new default `.sda/workflows`), `paths.baStandards` (gate docs), and the three workflow script keys (`scripts.workflowState`, `scripts.workflowNextStep`, `scripts.devQaNextStep`) per Rule 12 — also added to `project-config.example.json` + `.reference.yml`. Both engines verified emitting the keys with correct `.ps1`/`.sh` extensions.

**Verify:** frontmatter valid; no `edit` tool; DoD/`ledgers:` gate mapping present; refuses `done` unless all five ledgers `done` + QA PASS + human merge; names the next action but does not trigger BC agents; every referenced document rendered as a clickable link (label + link in parentheses).

---

## E4b — Workflow-only task/feature creation + run path coupling

Task, feature, and QA-spec creation happens **only inside a workflow** — there is no
standalone or manual SDA output. `sda-workflow` (E4.5), via `workflow-state init`, creates the
per-BC subfolders (`BA/ DESIGN/ DEV/ QA/ DEP/`); the task-folder agents write into the
caller-provided subfolder. `sda-workflow` is the path **producer**; the task-folder agents
(writers **and** the dev-task verifier that reads `feature.md`) are path **consumers**. The
output path is **mandatory**: an agent invoked without one fails a blocking gate. This
**drops** `paths.tasks` / `paths.features` / `paths.issues` — no root is computed anywhere.

**Design invariant — mandatory coupled destination (apply to every item below):**
- **Required path** — every task/feature/design write takes an explicit caller-provided
  output-folder path (the workflow per-BC subfolder, e.g. `<workflow-dir>/DEV/`). The agent
  writes there directly: no numbering, no root computation, no listing.
- **No path ⇒ blocking error** — the agent refuses to create anything and states that
  task, feature, or QA-spec creation requires a workflow-provided output path. No standalone
  fallback.
- **BC-blindness preserved** — the agent treats the path as opaque; it never learns the path
  came from a workflow run, a branch, or a cycle. No `runs/`, `workflow-state`, or
  `dev-qa-cycle-state` awareness enters any task-folder agent.

- [x] **`agents/sda-scribe.agent.md`** — Step 2 "Resolve target path": collapse the
  create-mode resolver to a **single required-path rule** for `task.md` / `qa-task.md`
  (the scribe's write targets; `feature.md` is written by `sda-feature` directly) —
  write to the provided folder; error if absent. Remove the standalone numbering branch.
  Also accept `qa-regression-task.md` as a QA-spec target filename (reusing
  `qa-task-schema.md` — regression subset; no new schema).
- [x] **`agents/sda-dev-task.agent.md`** — require the caller-provided task-output path; drop
  the `{tasks-root}/<NNN>. <name>/` computation. Replace the "list `{features-root}`, find
  the `<NN>. <name>` folder" feature-context logic with a **read of `feature.md` from the
  provided DESIGN path**. Remove `{tasks-root}` / `{features-root}` placeholders.
- [x] **`agents/sda-qa-task.agent.md`** — require the caller-provided QA-output path; **no
  standalone QA** — drop all `{issues-root}` usage. **Regression-only per-run mode** (the E4
  line-74 deferral): when the caller supplies a per-run output path, delegate to the scribe a
  **regression-scoped** `qa-regression-task.md` (pending-reverification FRs + retired-behaviour
  checks only, no first-pass FRs) written into that path. Treat the path as opaque — never
  construct or parse `runs/run-NN`.
- [x] **`agents/sda-qa.agent.md`** — remove the standalone `{issues-root}` mode entirely: read
  `qa-task.md` and write `qa-report.md` **only** in the caller-provided QA folder; drop the
  "user names an area → list `{issues-root}`" branch and the co-located `<NNN>-<slug>/`
  standalone-spec handling. Remove `{issues-root}`.
- [x] **`agents/sda-feature.agent.md` + `agents/sda-system.agent.md`** — require the
  caller-provided DESIGN-output path for `feature.md` / design docs; drop the
  `{features-root}/<NN>. <name>/` computation. Pending-overlay output (S2-1) unchanged.
- [x] **`agents/sda-dev-task-verifier.agent.md`** — read `feature.md` from the **resolved**
  DESIGN path passed down by `sda-dev-task` instead of recomputing `{features-root}/<NN>.
  <name>/feature.md`. Read-only consumer — writes nothing. Remove `{features-root}`.
- [x] **Sibling-file placement** — `state.json`, `dev-report.md`, and `qa-report.md` (and
  the `task-state` script's `-TaskFolder`) follow the resolved task-folder path. Confirm the
  `.sda/tasks/<NNN>…` tables in the agent bodies read as **illustrative** examples of the
  resolved destination, not hardcoded roots.
- [x] **`skills/sda-setup/assets/qa/qa-task-schema.md`** — remove the **Standalone** location
  bullet; QA specs are coupled-only (they live in the workflow QA subfolder). Entity-doc edit
  — no agent/workflow names added.
- [x] **Config drop** — remove `paths.tasks` + `paths.features` + `paths.issues` from the
  read-config manifests **and** default maps (both engines), `project-config.example.json`,
  and `project-config.reference.yml`. Affected manifests: `sda-dev-task`,
  `sda-dev-task-verifier`, `sda-qa-task`, `sda-feature`, `sda-qa`, `sda-scribe`. Verify no
  `{tasks-root}` / `{features-root}` / `{issues-root}` placeholder survives in any executed
  agent.

**Verify:** every writer refuses to create without a caller path (blocking error) and writes
to the provided path when given one; no agent computes a numbered folder for task/feature/QA;
the scribe has a single required-path resolver and accepts the `qa-regression-task.md`
target; `sda-qa-task` emits `qa-regression-task.md` only in per-run mode and only
regression-scoped FRs; `sda-qa` reads `qa-task.md` and writes `qa-report.md` only in the
caller-provided folder (no `{issues-root}`); the dev-task verifier reads `feature.md` from the
resolved path; `state.json` / `dev-report.md` / `qa-report.md` land in the resolved folder;
**no** task-folder agent references `workflow-state`, `dev-qa-cycle-state`, `runs/`, branches,
or cycles; `paths.tasks` / `paths.features` / `paths.issues` are gone from config and no
`{tasks-root}` / `{features-root}` / `{issues-root}` placeholder remains.

---

## E5 — Doc relocation (S6-1)

- [x] Move `issues/qa_plus_system_context.md` → `issues/sdlc/` **as-is** (no content change).
- [x] Move `issues/ai-sdlc.md` → `issues/sdlc/` **and rework** to the 5-BC model (engine, two nested state loops, two-tier storage); update its two-BC framing + cross-references.

**Verify:** both docs live under `issues/sdlc/` ✅; `ai-sdlc.md` reflects five BCs ✅; no broken links ✅ (2 stale refs in `system-context.md` fixed; all others are intra-folder relatives).

---

## E6 — Housekeeping (docs sync)

- [x] `tools/sda/AGENTS.md` — dependency-matrix rows for `sda-ba`, `sda-workflow`, `sda-dev-context-writer`, `sda-qa-context-writer`, every new schema/script, and the new `paths.*` keys (P1-5/P2-6/P3-4 consolidated); **remove** the `paths.issues` + standalone-QA rows (retired in E4b).
- [x] `tools/sda/README.md` — list the new agent(s), schemas, scripts, and the 5-BC model; **remove** the `paths.issues` standalone-QA config row.
- [x] Root `README.md` — update if it references the SDA agent/asset inventory.

**Verify:** every new/changed component appears in `AGENTS.md` + `README.md`; matrix has no duplicate or orphan rows. ✅

---

## Global verification (after E6)

- [x] No hyphenated `paths.*` remain in executed files. (Hyphenated forms exist only in frozen design docs under `issues/`; all active config/agent files use camelCase.)
- [x] All new agents pass the frontmatter/tools/boundaries checklist. (`sda-ba`, `sda-workflow`, `sda-dev-context-writer`, `sda-qa-context-writer` — YAML valid, descriptions with trigger phrases, tools scoped, boundaries clear.)
- [x] Every BC's durable ledger is scaffolded and referenced by `definition-of-done.md`. (DoD references all 5 BC ledgers; setup seeds BA gate templates; ledgers are self-init by their writers.)
- [x] `sda-setup` scaffolds all new assets + scripts into a target project. (4 workflow scripts + 4 dev-qa-cycle scripts in both PS/bash; BA gate templates; read-config maps all new paths.)
