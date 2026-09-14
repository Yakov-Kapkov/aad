# System Context Schema

The **system context** — the DEV bounded context's durable contribution: an
accumulating record of *what the system is confirmed to do* and *why*, under
`paths.devSystemContext`. Committed and version-controlled alongside code (visible in
the repo, not hidden in `.sda/`).

## Core principle

> System context captures **WHY** and **WHAT IS VERIFIED** — never **WHAT EXISTS**.

- **Forbidden:** file listings, class/method inventories, schema dumps — anything
  derivable by reading the code.
- **Allowed:** verified behavioural claims, architectural decisions + rationale, and a
  coarse-grained component dependency graph (for regression blast-radius analysis).

## File structure

```
{paths.devSystemContext}/
  index.yaml              — domain registry (no behaviors/decisions)
  dependency-map.yaml     — coarse-grained component graph (intra + cross-domain)
  {domain}.yaml           — per-domain: decisions + verified behaviors
  cross-domain.yaml       — behaviors spanning ≥2 domains
```

### `index.yaml` — domain registry

```yaml
project: my-app
last_updated: {date}
domains:
  - name: {domain}
    file: {paths.devSystemContext}/{domain}.yaml
```

### `dependency-map.yaml` — component graph

Only behaviourally significant components (entry points + components whose change can
alter observable behaviour). Curated, not exhaustive. `path` is a **locator**, never a
matching key.

```yaml
components:
  - id: {component-id}
    type: {api | service | repository | external | ui | worker | job}
    path: {locator}
    domain: {domain}
dependencies:
  - from: {component-id}
    to: [{component-id}, ...]        # may cross domains
```

Regression walk: a changed component → reverse-traverse edges → all dependents at risk.

### `{domain}.yaml` — decisions + behaviors

```yaml
decisions:
  - id: D001
    summary: {architectural choice}
    rationale: {why}
    status: active                   # active | superseded
    superseded_by: null              # decision id when superseded
behaviors:
  - id: B001
    claim: {verified observable behaviour}
    via: {component-id}
    status: verified                 # verified | pending-reverification
    verified_by: null                # known-test-case id that verifies it; set when verified
    note: null                       # reason when pending-reverification
```

### `cross-domain.yaml` — spanning behaviors

Same as domain `behaviors`, but `via` is an array and `domains` lists the spanned
domains.

```yaml
behaviors:
  - id: XB001
    claim: {verified behaviour}
    via: [{component-id}, {component-id}]
    domains: [{domain}, {domain}]
    status: verified
    verified_by: null
```

## Rules

- Node types: `api`, `service`, `repository`, `external`, `ui`, `worker`
  (queue/event-triggered), `job` (scheduled/cron).
- Behavior status: `verified` (confirmed by an acceptance run) or
  `pending-reverification` (in a recent change's blast radius, not yet re-verified).
- `verified_by` links a behavior to the known-test-case (QA ledger) that verifies it.
  The case is keyed by the behavior, so the id is deterministic from the behavior key.
- Decision status: `active` or `superseded` (with `superseded_by`).
- Entity doc — describes only the system-context documents; names no agent or workflow
  phase.
