# BA Bounded Context

Specifies the **first** bounded context of the SDLC: BA turns a raw requirement into
a **User Story** (one Actor statement + Gherkin scenarios), enforces the Definition of
Ready, and owns the implemented-feature ledger.

Companion to [architecture](01-architecture.md)
and [implementation plan](00-implementation-plan.md) (the roadmap, phase **S1**). This
doc is the BA-BC design spec; the execution pass turns each block below into the real
tool file at the noted target path.

---

## Deliverables

| # | Artifact | Target file | Kind |
|---|---|---|---|
| S1-1 | `sda-ba` agent | `agents/sda-ba.agent.md` | new agent |
| S1-2 | User Story schema | `skills/sda-setup/assets/ba/user-story-schema.md` | new entity doc |
| S1-3 | Global gate assets | `skills/sda-setup/assets/ba/definition-of-ready.md`, `definition-of-done.md`, `global-nfr.md` | project templates (scaffolded to `paths.baStandards`) |
| S1-4 | Implemented-feature ledger schema | `skills/sda-setup/assets/ba/implemented-feature-schema.md` | new entity doc |

---

## S1-1 — `sda-ba` agent

### Frontmatter

```yaml
---
name: sda-ba
description: "Turns a raw requirement into a User Story — one Actor statement plus Gherkin scenarios — and enforces the Definition of Ready. Rejects multi-actor requests and forces a split. Does not design, implement, or author QA specs."
argument-hint: Describe the requirement, or say "draft a story for X".
tools: ["read", "search", "agent", "edit"]
agents: ["sda-code-explore", "sda-web-explore"]
model: Claude Sonnet 4.6
hooks:
  SessionStart:
    - type: command
      command: "bash .sda/scripts/read-config.sh sda-ba"
      windows: "powershell -NoProfile -ExecutionPolicy Bypass -File .sda/scripts/read-config.ps1 -Agent sda-ba"
user-invocable: true
disable-model-invocation: true
---
```

- `edit` — writes `user-story.md` + the implemented-feature ledger.
- No `execute` — BA never runs commands.
- Delegates only for research (explore agents); never chains to another BC's agent.
- **Config injection** — `paths.baStandards` / `paths.baFeatures` arrive via the
  `SessionStart` read-config hook; `sda-ba` must be registered in the read-config
  per-agent manifest (`read-config.ps1` / `.sh`). BA never reads `project-config.json`
  directly.

### Persona
Senior business analyst — requirement elicitation, story slicing, acceptance-criteria
authoring. Shapes *what* and *why*; never *how*. Produces a testable User Story and
hands off.

### Read-list (exact paths, never searched)

Config (`paths.baStandards`, `paths.baFeatures`) is injected via the read-config hook —
not read from `project-config.json`.

| File | Path |
|---|---|
| user-story-schema.md | `.sda/resources/ba/user-story-schema.md` |
| definition-of-ready.md | `{paths.baStandards}/definition-of-ready.md` |
| global-nfr.md | `{paths.baStandards}/global-nfr.md` |
| implemented-feature-schema.md | `.sda/resources/ba/implemented-feature-schema.md` |

### Workflow
1. **Elicit** — clarify the requirement through dialogue; resolve ambiguity.
2. **One-actor gate** — exactly one Actor per story. Multi-actor request → **reject**,
   propose a split into one story per actor, stop until the user picks one.
3. **Author story** — one Layer-1 Actor statement + Layer-2 Gherkin scenarios
   (≥1 happy, ≥1 negative, ≥1 edge), per `user-story-schema.md`.
4. **NFRs** — **inject local NFRs** (feature-specific) onto scenarios; **reference the
   global NFRs** whose guardrail these scenarios can affect, by id from `global-nfr.md`
   (link, never copy). Referencing selects what QA *verifies* — not what the change must
   *comply with* (every global NFR stays in force).
5. **DoR gate** — verify every `definition-of-ready.md` item; refuse to mark the story
   `ready` until all pass. Report the failing items otherwise.
6. **Ledger** — on story completion, update the implemented-feature ledger
   (BA durable contribution) per `implemented-feature-schema.md`.
7. **Write** — `user-story.md` to the output path the orchestrator provided; return.

### Boundaries (DO NOT)
- Design architecture, choose tech, or write code.
- Author QA specs (`qa-task.md`) or run tests.
- Touch `workflow-state.yaml` or read the workflow id — BA is blind (receives only a
  requirement + an output path).
- Author global NFRs — reference them; global NFRs are edited directly, not per story.

---

## S1-2 — User Story schema

Two layers: one Actor statement, then machine-readable Gherkin scenarios.

### Template

```markdown
# User Story: {slug}

## Actor statement
As a {role}, I want {action}, so that {benefit}.

## Scenarios

### FR-1 — {scenario name}  {happy}
```gherkin
Given {precondition}
When {action}
Then {observable outcome}
```

### FR-2 — {scenario name}  {negative}
```gherkin
Given {precondition}
When {invalid action}
Then {graceful rejection}
```

### FR-3 — {scenario name}  {edge}
```gherkin
Given {boundary precondition}
When {action}
Then {outcome}
```

## Local NFRs
- **LNFR-1** — {feature-specific quality constraint} → applies to FR-{n}

## Global NFRs (referenced)
- {GNFR-id} — {one-line name}  (see global-nfr.md)
```

### Rules
- **Exactly one** Actor statement (Layer 1). More than one actor → not a single story.
- **≥1 negative and ≥1 edge** scenario in addition to the happy path.
- Each scenario is a single Gherkin `Given/When/Then` block (machine-readable).
- Local NFRs are authored here and attached to specific FRs.
- Global NFRs are **referenced by id** only — never restated. A story references the
  global NFRs its scenarios can affect (verification scope); all global NFRs remain in
  force regardless.
- This is an **entity doc** — it describes only the User Story document; it names no
  agent, phase, or workflow.

---

## S1-3 — Global gate assets

Durable, project-level templates scaffolded to `paths.baStandards`. Authored/edited
directly (not per story).

### `definition-of-ready.md` (BA hand-off gate)

```markdown
# Definition of Ready

A User Story may be marked `ready` only when ALL hold:
- [ ] Single Actor statement (one role).
- [ ] ≥1 happy, ≥1 negative, ≥1 edge Gherkin scenario.
- [ ] Every scenario is unambiguous and independently testable.
- [ ] Local NFRs attached where relevant; global NFRs referenced by id.
- [ ] No unresolved external blocker (dependency, access, decision).
```

### `definition-of-done.md` (system-wide completion gate)

```markdown
# Definition of Done

A User Story is `done` only when ALL hold:
- [ ] Both QA gates PASS (primary + regression).
- [ ] Coverage meets the project threshold; security scan clean.
- [ ] Merge approved by a human.
- [ ] Every durable ledger updated (see the contribution model in
      01-architecture.md): BA feature ledger, DESIGN design docs,
      DEV system context, QA known-test-case library, DEP deployment context.
```

The five-ledger row is the SDLC definition of done; it references — does not
duplicate — the contribution table in
[architecture](01-architecture.md).

### `global-nfr.md` (system-wide guardrails)

```markdown
# Global NFRs

System-wide quality guardrails. Each has a stable id so a story can reference it
without restating.

**How they apply**
- **Always in force (compliance).** Every change complies with *all* global NFRs —
  none may be violated.
- **Verified where relevant.** A story verifies only the global NFRs its scenarios /
  changed surface can affect; regression re-verifies affected behaviours' NFRs.

### GNFR-AUTH — Authentication boundary
{Every protected route enforces auth; unauthenticated → 401.}

### GNFR-PERF — Baseline latency
{p95 response under {limit} for standard endpoints.}

### GNFR-SEC — Input safety
{All external input validated; no injection surface.}

### GNFR-COMPLIANCE — Data handling
{PII handling / retention / audit rules.}
```

---

## S1-4 — Implemented-feature ledger schema

The **BA durable contribution**: a human- + AI-readable record of *what exists* from
the BA view, updated per completed story. Lives under `paths.baFeatures`.

### Template

```markdown
# Implemented Features

## {feature-area}

### {feature-name}
- **Story:** {slug} ({workflow-id})
- **Actor:** {role}
- **Capability:** {one line — what the actor can now do}
- **Scenarios:** FR-1…FR-n  (see user-story.md)
- **Global NFRs:** {referenced ids}
- **Status:** implemented  ·  {date}
```

### Rules
- One entry per completed story, grouped by feature area.
- Links back to the source `user-story.md` (not a copy of its scenarios).
- Append-only per story; supersede an entry only when the capability changes.
- Entity doc — describes only the ledger document.

---

## Open items for execution (S1)
- Register `sda-ba` in [AGENTS.md](../../AGENTS.md) (folder structure, agent list,
  dependency matrix rows for `user-story-schema.md` and the new `paths.*` keys) and in
  the tool [README.md](../../README.md) pipeline.
- Add `sda-ba` to the `models` resolution list in the sda-setup skill.
- Scaffold the three global templates + `implemented-feature-schema.md` via sda-setup;
  add `paths.baStandards` and `paths.baFeatures` to
  `project-config.example.json` / `.reference.yml`.
