# QA Task Document Schema

`qa-task.md` is a **self-contained acceptance spec**. It comes in two shapes:
- **Task-coupled** — lives beside `task.md` in the task folder; verifies that
  task's behaviour. Written during task design.
- **Standalone** — lives alone in `{issues-root}/<NNN>-<area>/` (default
  `.sda/issues`); verifies existing application behaviour when there is no
  task (e.g. checking whether a feature already works).

Either shape, it is executed end to end from this file alone (plus resolved
credentials) — black-box verification against intent, not implementation, so it
stands independent of `task.md` and `dev-report.md`.

---

## Template

```markdown
# QA Task: {name}

## Task
{task-name — the sibling task.md this verifies; or `standalone — {area}`
when there is no task}

## Setup
{How to bring up the system under test. Each layer entry documents the exact start command, working directory, URL, and health check — fetched from project-tools.md via the read-project-tools script. Each layer starts in its own terminal. State the required backing infrastructure as a specific real instance — never "emulator or live".}
- Layers: {e.g. backend, frontend}
- {Layer}: `{start-command}` (dir: `{working-dir}`, URL: {url}, health: {healthcheck})
- Infrastructure: {named real instance(s) the layers require — e.g. the project database}

## Credentials
{Logical names only — never values. Resolved at runtime: environment variable
first, then .sda/secrets/qa.secrets.env. Enumerate every name a step needs — list
each credential value as a separate entry. Omit section if none required.}
- `{CRED_NAME}` — {what it authorizes}

## Functional Requirements

### FR-1 — {black-box, user-observable requirement}
- **Precondition:** {state / seeded data / auth by logical cred name}
- **Reproduce:** {browser flow — name the route + visible control; or the full CLI/HTTP request — method, full URL `http://{host}:{port}/{path}`, headers (incl. how the token is obtained), exact body}
- **Settle (async only):** {if Reproduce returns immediately (e.g. 202 Accepted)
  and a background worker finishes the job later — how to know it finished:
  poll a status endpoint / DB until a completion signal, with a max wait.
  Write `N/A — synchronous` when not async.}
- **Expected data:** {how to obtain the source of truth — SQL query, reference
  endpoint, fixture. Write `N/A — response is self-evident` when the API
  response is the source of truth.}
- **Expected outcome:** {what actual must equal — observable result}
- **Compare:** {actual vs expected — the assertion}
- **Layers:** {frontend | backend | worker | db}

### FR-2 — {…}
- **Precondition:** {…}
- **Reproduce:** {…}
- **Settle (async only):** {… or `N/A — synchronous`}
- **Expected data:** {… or `N/A — response is self-evident`}
- **Expected outcome:** {…}
- **Compare:** {…}
- **Layers:** {…}
```

---

## Schema Rules

### Task
- Single line. Always present.
- **Task-coupled:** the sibling `task.md` filename stem this QA spec verifies.
- **Standalone:** `standalone — {area}` when there is no task — the spec
  verifies existing application behaviour.

### Setup
- Describes how to bring up the system under test.
- **One entry per layer** — each with: start command (in backticks), working directory (`dir:`), URL, and health check.
- Lists which layers must start — each in its own terminal.
- **Concrete per layer:** exact start command, URL, a health check (URL or startup log line that confirms the layer is up), and the required backing infrastructure named as a specific real instance — never "emulator or live".

### Credentials
- Logical names only — **never** values.
- Resolved at runtime: environment variable first, then
  `.sda/secrets/qa.secrets.env`.
- **Two credential types:**
  - **Stored** — present in env or `qa.secrets.env` (e.g. `USERNAME`,
    `PASSWORD`). The verifier stops if any stored credential is missing.
  - **Acquired** — obtained at runtime via a documented request using stored
    credentials (e.g. `API_TOKEN` from a login endpoint). Its acquisition
    request is documented here or in the FR precondition.
- **Enumerate every credential every FR needs.** If any FR requires a
  non-admin login, the Credentials section must list the non-admin
  credentials as stored credentials. An FR that says "log in as non-admin"
  without corresponding stored credentials in this section is incomplete.
- **Credential acquisition:** when an FR uses a credential obtained through a
  request (bearer token, session cookie, OAuth token exchange, API key
  provisioning), this section or the FR's precondition documents the exact
  acquisition request — HTTP method, full URL, request body with credential
  placeholders, and which response field holds the result. The acquired
  credential is never stored in secrets; only its stored prerequisites are.
- Omit section if the task needs no credentials.

### Functional Requirements
- Black-box and user-observable — describe behaviour, not implementation.
- **Self-contained:** each FR must be executable from this file alone (plus
  resolved credentials) — never by exploring the codebase.
- One FR = one verifiable behaviour. Number continuously (`FR-1`, `FR-2`, …).
- **Reachable through a real entry point** — every FR exercises a user-facing
  route/page or a deployed HTTP endpoint. Never verify an isolated component,
  function, or schema in a vacuum (that is a unit test, not acceptance). Fold
  component-level checks into the user flow that exercises them.
- **Unambiguous title & steps** — name the exact route/page and the user-facing
  control by its visible label. Never generic component names ("the Checkbox")
  or "any page".
- **Enumerate all accepted values.** When an expected field has a constrained
  set of values, list every accepted value explicitly — use "must be one of:
  [A, B, C]" never "e.g. A or B". For open-ended values, state the validation
  rule (pattern, range, format). The verifier must be able to decide PASS/FAIL
  without guessing.

**UI FRs — observable signals only.** Assert only what a user sees or the
browser exposes: visible text/labels, field values, navigation/step changes,
toasts/banners, the HTTP requests the page issues (method, URL, payload,
status), and console errors.
- **Forbidden as assertions:** DOM attributes (`data-state`, element counts),
  CSS classes, component props or callbacks ("`onCheckedChange` fired"),
  framework variant names.
- DOM snapshots, console logs, and network traces are **failure evidence**,
  never the pass/fail assertion.

**API FRs — inline the full request.** `Reproduce` carries the complete call:
HTTP method, full URL (`http://{host}:{port}/{path}`), every header (including
how the auth token is obtained), and the exact request body. It is run
verbatim — never constructed or inferred by exploring the codebase. State the
expected status code and response-body shape.

- **Expected data** carries the domain source-of-truth (e.g. the SQL query for
  a report API). Expected-data queries live **here**, never in
  `project-tools.md`.
- **Settle** — include only for asynchronous behaviour where `Reproduce`
  returns immediately and a background worker completes the work later. Names
  the completion signal to poll for and a bounded max wait. The run waits for
  it before reading **Expected data**. Omit for synchronous FRs.
- **Compare** states the assertion: how actual is checked against expected.
- **Layers** lists which layers the FR exercises — indicates where to look for
  evidence on failure.
