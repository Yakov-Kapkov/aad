# Requirements Schema

Requirements are one file per capability, nested under a feature, with an
`index.md` at every level. The tree lives at `docs/requirements/` (global,
cross-layer only) and `<layer>/docs/requirements/` (one layer).

---

## Layout

```
{requirements-root}/
├── index.md                     ← routes to each feature
├── nfr.md                       ← cross-feature NFRs (optional)
└── <feature>/
    ├── index.md                 ← routes to each concern, or each item
    ├── nfr.md                   ← feature-scoped NFRs (optional)
    ├── <item>.md                ← no concern level when the feature has one slice
    └── <concern>/
        ├── index.md             ← routes to each item
        ├── nfr.md               ← concern-scoped NFRs (optional)
        └── <item>.md
```

- `<feature>` is one bounded context — the same name used by a task's
  `Feature:` scope and the readme's implemented-features list.
- `<concern>` is one coherent slice of the feature: an audience (`admin/`,
  `user/`) or a capability (`scheduling/`). **Optional** — a single-slice
  feature puts its items one level up.
- `<item>` is one capability or outcome.
- **Max depth three.** `<feature>/<concern>/<item>.md` is the floor.

---

## Requirements index

`{requirements-root}/index.md` — routes to features:

```markdown
# Requirements

| Feature | When it applies | Document |
|---|---|---|
| {Feature} | {trigger phrase} | [mining-tasks/index.md](mining-tasks/index.md) |
| Cross-feature NFRs | performance, security, availability | [nfr.md](nfr.md) |
```

`<feature>/index.md` — routes to concerns, or straight to items when there is
no concern level:

```markdown
# {Feature} requirements

| Concern | When it applies | Document |
|---|---|---|
| Admin | managing mining tasks | [admin/index.md](admin/index.md) |
| User | running mining tasks | [user/index.md](user/index.md) |
| Feature NFRs | — | [nfr.md](nfr.md) |
```

`<feature>/<concern>/index.md` — routes to items:

```markdown
# {Feature} · {concern}

| Item | When it applies | Document |
|---|---|---|
| Task list | browsing and filtering tasks | [task-list.md](task-list.md) |
| Mining session | configuring and running a task | [mining-session.md](mining-session.md) |
```

The first column names the level the index routes to.

## Item file

`<feature>/[<concern>/]<item>.md`:

```markdown
# {Item}

## AUTH-001 {Short title}
{One sentence: the system shall {behaviour}.}

## AUTH-002 {Short title}
{One sentence: the system shall {behaviour}.}

## NFRs
- **AUTH-NFR-001** — {quality} {operator} {value} {unit} under {condition}; measured by {method}; applies to AUTH-001
```

## NFR file

`nfr.md` at any level holds the NFRs scoped to that level:

```markdown
# {Scope} NFRs

- **GLOBAL-NFR-001** — {quality} {operator} {value} {unit} under {condition}; measured by {method}; applies to {scope}
```

---

## Schema Rules

### IDs
- FRs: `<FEATURE-SLUG>-<NNN>`, uppercased — `AUTH-003`. The slug is the
  **feature** folder — never a concern or an item name.
- **Append-only.** Never renumbered, never reused — even after an entry is
  removed. Moving a file between concerns does not change its ids.
- Feature- and concern-scoped NFRs: `<FEATURE-SLUG>-NFR-<NNN>`.
- Tree-scoped NFRs (a tree's root `nfr.md`): `<SCOPE>-NFR-<NNN>` —
  `GLOBAL-NFR-001`, `BACKEND-NFR-003`. The scope prefix is what keeps ids
  unique across the global tree and every layer tree.
- The `NFR-` infix is what shape checking keys on.

### Entries
- One entry per requirement: heading = id + short title, body = one sentence
  starting "The system shall …".
- One obligation per entry. A sentence joining two obligations with "and" is
  two entries.
- Cite an entry by its id. Any other document that restates a requirement
  cites the entry instead — one home per requirement.
- An item serving two concerns still has **one** home; the other concern's
  index routes to it rather than duplicating it.

### NFR placement
- An NFR constrains a surface — put it in the `## NFRs` section of the item it
  constrains.
- Scoped to a whole feature but not one item → `<feature>/nfr.md`.
- Scoped to a whole concern → `<concern>/nfr.md`.
- Applies beyond one feature → the tree's root `nfr.md`.
- An NFR is measurable when it carries all five: **metric**, **threshold**
  (operator + value + unit), **measurement method**, **condition**
  (load / dataset / environment), and **applies-to**.
- Two failure modes: *unmeasurable* (no metric, or no threshold) and
  *unfalsifiable* (a threshold with no method or no condition).

### Routing
- Every folder has an `index.md`; every child is routed by its **parent's**
  index — exactly one router per document (two = duplicate row, none = orphan).
- Inside a file, FRs come first, then a single `## NFRs` section.

### Naming
- Files and folders are kebab-case.
- Name items by **capability or outcome** — `task-list`, `mining-session`,
  `crediting`. Never by UI surface: a screen gets redesigned, a capability
  survives it.
- Name concerns by the slice's real name — an audience (`admin/`, `user/`) or a
  capability (`scheduling/`). Never `misc/`, `other/`, or a single-slice
  `default/`; a single-slice feature has no concern level.

### Splitting
- Split a file when it passes ~15 entries; split an `nfr.md` the same way.
- Add a concern level when a feature has two or more distinct slices.

### Placement — global is global only
- Global `docs/requirements/` holds **only** cross-layer requirements.
- A requirement touching one subsystem lives in that subsystem's
  `<layer>/docs/requirements/`.
- ✅ auth spans frontend + backend → `docs/requirements/auth/`
- ❌ backend-only ordering rules in `docs/requirements/` → belongs in
  `backend/docs/requirements/`
- A requirement with no user-visible surface does not belong in a feature tree
  — it goes to the owning layer's tree.

### No status, no delivery link
- **No status field.** The tree records what is specified; what is implemented
  is read from the readmes' implemented-features section.
- **No "delivered by" link.** A durable → transient pointer would dangle.
