# QA Bounded Context

Specifies how QA wires to BA: `sda-qa-task` takes the BA **User Story's Gherkin
scenarios** as its primary functional-requirement source, and QA's durable
contribution — the **known-test-case library** — is populated post-QA from passed
FRs.

Companion to [architecture](01-architecture.md),
[BA context](02-ba-context.md) (upstream BC), and
[implementation plan](00-implementation-plan.md) (roadmap, phase **S3**). QA's
internal machinery (two-gate verification, regression, `sda-qa-context-writer`) is
defined in the P1/P2/P3 changeset of
[qa_plus_system_context.md](qa_plus_system_context.md) and executed in **S6**; this
doc only adds the BA linkage and the durable library.

---

## Deliverables

| # | Artifact | Target | Kind |
|---|---|---|---|
| S3-1 | `sda-qa-task` consumes User Story Gherkin | `agents/sda-qa-task.agent.md` | agent edit |
| S3-2 | Known-test-case library schema + post-QA promotion & retirement | `skills/sda-setup/assets/qa/known-test-case-schema.md`; new `sda-qa-context-writer` agent | new entity doc + new agent |

---

## S3-1 — `sda-qa-task` consumes the User Story

### Input change
- **Primary FR source** becomes the User Story's **Gherkin scenarios** (today: the
  coupled `task.md`). Each scenario (`FR-n`) is the acceptance intent QA must verify.
- `sda-qa-task` **expands** each Gherkin scenario into a full black-box `qa-task.md`
  FR (precondition → reproduce → Settle → expected data → expected outcome → compare →
  layers). The Gherkin is the *intent*; the qa-task FR is the *executable* form.

### Gherkin → black-box FR mapping

| Gherkin clause | qa-task FR field |
|---|---|
| `Given` | precondition + Setup / Settle |
| `When` | reproduce |
| `Then` | expected outcome + compare |

### NFR coverage
- **Compliance vs verification.** All global NFRs are always in force (a change may
  never violate one); QA *verifies* only the story's referenced global NFRs plus
  regression re-verification of affected behaviours' NFRs.
- **Local NFRs** (LNFR-n on the story) → verified as NFRs on the mapped FRs.
- **Global NFRs** referenced by the story (GNFR-ids) → pulled from `global-nfr.md` and
  verified as system-wide NFRs.
- Keep the existing NFR generation (P1-2): HTTP-contract, payload-validation,
  rate-limiting, security-boundary, idempotency, boundary-input FRs.

### Regression (unchanged)
- Keep P3-2: mandatory regression FRs from `pending-reverification` behaviors in
  affected domains (full-assertion depth) + the three-source supplement (smoke depth).

### Retired behaviours (library retirement signal)
- When the task retires behaviours (`task.md ## System Context Impact removed_behaviors`),
  `sda-qa-task` copies those behaviour keys into `qa-task.md ## Retired Behaviours`.
- This is the **QA-native channel** the library writer consumes to retire cases, so
  `sda-qa-context-writer` never reads the DEV-owned system context. Not an executable FR.

### Contract & boundaries
- **BC-blind:** receives the User Story + an output path; never reads the workflow id
  or any state file.
- DO NOT implement, run, or verify (that is `sda-qa`); DO NOT design or author the
  story; DO NOT write system context or the known-test-case library directly.

---

## S3-2 — Known-test-case library (QA durable contribution)

A reusable, durable library of **executable test-case definitions**, under
`paths.qaTestCases`. It is QA's per-story ledger contribution.

### Ownership split (OQ-B)
- **QA owns the test-case definition.** A passed qa-task FR is promoted into a durable,
  reusable case in the library.
- **System context records verification.** Each system-context behavior records *which
  case verifies it* (a link) + its verified status — it does not duplicate the case.

### Who writes it, and when
- Written **post-QA** by `sda-qa-context-writer` — the QA-owned durable writer. It reads
  `qa-report.md` (promote passed FRs) and `qa-task.md ## Retired Behaviours` (retire
  removed behaviours' cases), writing the library only (`read` + `edit`).
- Runs at the same post-QA step as the DEV writer (`sda-dev-context-writer`, which sets
  system-context verified-status), from the same `qa-report.md`, but **independently**:
  the case id derives from the behavior key, so DEV records the behavior→case link and QA
  creates the case without either blocking the other.
- `sda-qa-context-writer` never writes system context; `sda-dev-context-writer` never
  writes the library.

### Promotion + retirement rule
```
sda-qa-context-writer (library only):
  for each FR in qa-report.md with verdict PASS:
      upsert a reusable case in paths.qaTestCases (keyed by behavior)
      append the current story to the case's Stories (dedup)
  FR with verdict FAIL → no promotion
  for each behavior key in qa-task.md ## Retired Behaviours:
      delete its keyed case (retirement — behavior no longer exists)
```
The retirement list is **QA-native**: `sda-qa-task` authors `qa-task.md ## Retired
Behaviours` from the task's `## System Context Impact removed_behaviors`, so the QA writer
never reads the DEV-owned system context. The behavior→case link + verified status are
written to the **system context** by `sda-dev-context-writer` — the QA writer never touches
system context. A case is keyed by behavior, so its id is deterministic from the behavior
key (the two writers agree without ordering).

### Template

```markdown
# Known Test Cases

## {domain}

### TC-{id} — {behavior name}
- **Behavior:** {system-context behavior key it verifies}
- **Stories:** [{slug} (wf), …]   # provenance: introducing story first, append re-verifying stories; may be empty / `supplement`
- **Given / When / Then:** {black-box steps, reusable}
- **Layers:** {observable surfaces — e.g. ui, api, data, worker[:name], scheduler, consumer, cli, external}
- **Last verified:** {sha} · {date}
```

### Rules
- Entity doc — describes only the library document + promotion contract; the *writer*
  identity lives in the agent files, not here.
- One case per verified behavior; re-verification updates `Last verified`, never
  duplicates.
- A case links back to its source `user-story.md` scenario; it does not restate global
  NFRs.

---

## Open items for execution (S3)
- Edit `sda-qa-task`: primary FR source = User Story Gherkin; add the mapping table;
  keep P1-2 / P3-2 logic; add the BC-blind + boundary rules.
- Author `sda-qa-context-writer` (new QA agent): the post-QA promotion rule; add
  `known-test-case-schema.md` to its read-list.
- Update [AGENTS.md](../../AGENTS.md): dependency-matrix rows for the User-Story FR
  source, `known-test-case-schema.md`, `paths.qaTestCases`; note QA now derives FRs
  from the story.
- Update tool [README.md](../../README.md): QA verifies against the User Story; add the
  known-test-case library to the durable outputs.
- Add `paths.qaTestCases` to `project-config.example.json` / `.reference.yml`;
  add `known-test-case-schema.md` to sda-setup assets.
