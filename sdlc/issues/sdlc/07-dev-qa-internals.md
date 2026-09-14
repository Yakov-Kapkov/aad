# DEV + QA Internals (S6)

Specifies **S6 spec-first**: how the pre-existing **P1/P2/P3** changeset (QA
pipeline, system-context infrastructure, workflow scripts) folds into the 5-BC SDLC,
and the **layering rule** that reconciles "execute P1/P2/P3 unchanged" with the
BA-linkage deltas authored in S1–S5. No real files are mutated here — this doc plus
the S1–S5 *Open items* define one final execution pass.

Companion to [architecture](01-architecture.md),
the four BC specs ([BA](02-ba-context.md), [DESIGN](03-design-context.md),
[QA](05-qa-context.md), [DEV](04-dev-context.md), [DEP](06-dep-context.md)),
and [implementation plan](00-implementation-plan.md) (roadmap, phase **S6**). The
source changeset is [qa_plus_system_context.md](qa_plus_system_context.md).

---

## Deliverables

| # | Artifact | Kind |
|---|---|---|
| S6-A | Fold P1/P2/P3 into the 5-BC model (this spec) | reconciliation spec |
| S6-B | Layering rule: P-item base → S-spec delta on the same file | execution rule |
| S6-1 | Relocate `qa_plus_system_context.md` into `issues/sdlc/` as-is; relocate + rework `ai-sdlc.md` | doc move + rework |

---

## S6-A — P1/P2/P3 folded into the 5-BC model

The changeset predates the reshape and assumes **two** bounded contexts (DEV + QA).
Folded into five, its 18 items map to these real files. Asset schemas follow the
**BC-subfolder** layout of `skills/sda-setup/assets/` (existing: `dev/`, `qa/`,
`scripts/`; new: `ba/`, `design/`, `dep/`).

### P1 — QA changeset (edits)
| Item | File |
|---|---|
| P1-1 | `skills/sda-setup/assets/qa/qa-task-schema.md` |
| P1-2 | `agents/sda-qa-task.agent.md` |
| P1-3 | `agents/sda-qa.agent.md` |
| P1-4 | `agents/sda-scribe.agent.md` |
| P1-5 | `AGENTS.md` |

### P2 — system-context infra + workflow scripts (new + edits)
| Item | File(s) |
|---|---|
| P2-1 | `skills/sda-setup/assets/dev/system-context-schema.md` (new — DEV asset) |
| P2-2 | `skills/sda-setup/assets/dev/task-schema.md` — add `## System Context Impact` |
| P2-3 | `project-config` schema — add `paths.devSystemContext` (camelCase, see below) |
| P2-4 | `agents/sda-dev-context-writer.agent.md` (new agent — system context only; formerly `sda-context-writer`) |
| P2-5 | `skills/sda-setup` — scaffold system-context + install scripts |
| P2-6 | `AGENTS.md` |
| P2-7 | system-context CLI scripts — source `skills/sda-setup/assets/dev/{powershell,bash}/`, runtime `.sda/scripts/system-context/` |
| P2-8 | workflow-state scripts — source `skills/sda-setup/assets/scripts/{powershell,bash}/`, runtime `.sda/scripts/workflow/`; D12 names `dev-qa-cycle-state`/`dev-qa-next-step` |

### P3 — wire system context into QA (edits)
| Item | File(s) |
|---|---|
| P3-1 | `agents/sda-dev-task.agent.md` |
| P3-2 | `agents/sda-qa-task.agent.md` |
| P3-3 | `agents/sda-dev.agent.md` |
| P3-4 | `AGENTS.md` |
| P3-5 | `agents/sda-feature.agent.md` + `agents/sda-system.agent.md` |

---

## S6-B — Layering rule

The plan's "execute P1/P2/P3 unchanged in substance" is **not literally achievable**
alongside S1–S5: several S-specs rewire the very files P1/P2/P3 produce. Resolve by
**layering**, not by two independent passes:

> **Apply each P-item first as the base layer; immediately apply any S1–S5 delta that
> targets the same file, on top, in the same file.** The S-delta wins where they
> differ.

### Base → delta overlaps

| File | P-item base | S-spec delta (wins) |
|---|---|---|
| `agents/sda-qa-task.agent.md` | P1-2 / P3-2 — consumes `task.md`; NFRs; pending-reverification regression | **S3-1** — consumes User Story Gherkin as primary FR source |
| `agents/sda-dev-task.agent.md` | P3-1 — bootstrap + conflict gate + `## System Context Impact` | **S4-1** — consumes User Story; reads DESIGN docs + pending overlay |
| `agents/sda-dev-context-writer.agent.md` (was `sda-context-writer`) | P2-4 — post-QA system-context verified-status writer | **renamed + scoped to system context only** (OQ-B split); library promotion moves to the new QA agent `sda-qa-context-writer` |
| `agents/sda-feature.agent.md` + `sda-system.agent.md` | P3-5 — conflict-detection gate | **S2-1** — consume User Story; output to pending overlay |
| `project-config` schema | P2-3 — `paths.system-context` (hyphenated) | **S0** — camelCase `paths.devSystemContext` |

### camelCase reconciliation
All `paths.*` keys the changeset introduces (`paths.system-context`, etc.) adopt the
tool's camelCase convention (`paths.devSystemContext`) per
[architecture](01-architecture.md). Global find/replace hyphenated →
camelCase across every executed file. The `00-implementation-plan.md` D-decisions carry
the same reconciliation (amended in S6).

---

## S6-1 — Doc relocation

- **Relocate as-is**: `issues/qa_plus_system_context.md` → `issues/sdlc/`. No content
  change — it remains the authoritative P1/P2/P3 changeset.
- **Relocate + rework**: `issues/ai-sdlc.md` → `issues/sdlc/`, reworked to align with
  the BC design — the D-decisions (engine, two nested state loops, two-tier storage).
  Update its now-outdated two-BC framing to the five-BC model; update cross-references.

---

## Open items for execution

The single final real-file pass (this doc + all S1–S5 *Open items*):

1. Execute P2 → P1 → P3 in the plan's documented order (P2 has no P1 dependency; P3
   requires P2), applying the **S6-B layering rule** at each overlapping file.
2. Apply S1–S5 *Open items* deltas interleaved with their base P-items (per the
   overlap table); create the net-new BC assets under `assets/{ba,design,dep}/`.
3. Global camelCase `paths.*` reconciliation across all executed files + the plan.
4. S6-1 doc moves (relocate `qa_plus_system_context.md`; relocate + rework
   `ai-sdlc.md`).
5. Update `AGENTS.md` dependency matrix + `README.md` for every new/changed agent,
   schema, and script.
