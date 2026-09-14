# Known Test Case Schema

The **known-test-case library** — the QA bounded context's durable contribution: a
reusable set of **executable, black-box test-case definitions** under
`paths.qaTestCases`, promoted from passed QA runs.

## Template

```markdown
# Known Test Cases

## {domain}

### TC-{id} — {behavior name}
- **Behavior:** {system-context behavior key it verifies}
- **Stories:** [{slug} (wf), …]   # provenance: introducing story first, append each re-verifying story; may be empty or `supplement` for regression-derived cases
- **Given / When / Then:** {black-box steps, reusable}
- **Layers:** {observable surfaces — e.g. ui, api, data, worker[:name], scheduler, consumer, cli, external}
- **Last verified:** {sha} · {date}
```

## Promotion contract

A case is promoted from a passed acceptance run — **library writes only**:

```
for each FR with verdict PASS:
    upsert a reusable case (keyed by behavior)
    append the current story to the case's Stories (dedup)
FR with verdict FAIL → no promotion

for each retired behavior key:
    delete its keyed case (the behavior no longer exists)
```

The behavior→case link and the behavior's verified status live in the **system context**
(DEV ledger), not here. Because a case is **keyed by its behavior**, its id is
deterministic from the behavior key — so the DEV ledger can reference the case without
this library having been written first.

## Rules

- Entity doc — describes only the library document + promotion contract; the *writer*
  identity lives in the agent files, not here.
- One case per verified behavior — the behavior key is the stable anchor. Many stories
  may touch it over time; each re-verification updates `Stories` + `Last verified`,
  never a duplicate.
- A case is **retired** (deleted) when its behavior is retired — the library never keeps
  a case for a behavior that no longer exists.
- Provenance is a list: `Stories` holds the introducing story first, then any that
  re-verify/extend it; it may be empty or `supplement` for regression-derived cases.
- `Layers` is an open, extensible set of observable surfaces (ui, api, data,
  worker[:name], scheduler, consumer, cli, external) — name a specific worker as
  `worker:{name}` when several exist.
- A case is black-box and reusable — no implementation-structural assertions — and does
  not restate global NFRs.
