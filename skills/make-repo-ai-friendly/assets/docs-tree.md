# Default Docs Tree

The **default profile** — a proposal for a repo that declares no layout of its
own. Never a requirement: a repo keeps its own layout, names, and omissions.
The root holds cross-subproject info only; a subproject's info lives in the subproject.

```
<repo-root>/
├── AGENTS.md                  ← AI readme (router) — or CLAUDE.md / .cursorrules
├── README.md                  ← human readme (same outline, human tone)
├── docs/
│   ├── index.md               ← router to the files below
│   ├── architecture.md        ← repo structure, the subproject map, storage
│   ├── vocabulary.md          ← terms a newcomer would guess wrong
│   ├── testing.md             ← how the repo is tested (optional)
│   ├── deployment.md          ← pipeline, environments, triggers (optional)
│   ├── operations.md          ← health, logs, metrics, rollback (optional)
│   ├── cli.md                 ← the root's own commands (optional)
│   ├── requirements/          ← cross-subproject specifications (optional)
│   │   ├── index.md           ← routes to each feature
│   │   ├── nfr.md             ← cross-feature NFRs (optional)
│   │   └── <feature>/         ← index.md + <item>.md, or <concern>/<item>.md
│   ├── coding-standards/      ← cross-subproject rules (optional)
│   │   └── index.md
│   ├── conventions/           ← cross-subproject conventions (optional)
│   │   ├── index.md           ← routes to each feature
│   │   └── <feature>/         ← index.md + <convention>.md
│   ├── adrs/                  ← cross-subproject decisions and why (optional)
│   │   ├── index.md           ← routes to each feature; states the immutability rule
│   │   └── <feature>/         ← index.md + <adr>.md
│   └── diagrams/              ← optional
└── <subproject>/              ← one per package, service, app, library
    ├── AGENTS.md              ← subproject AI readme (router)
    ├── README.md              ← subproject human readme
    └── docs/
        ├── index.md
        ├── architecture.md
        ├── vocabulary.md
        ├── testing.md         ← this subproject's suites and smoke tests (optional)
        ├── deployment.md      ← only when this subproject ships on its own (optional)
        ├── operations.md      ← only when this subproject runs on its own (optional)
        ├── requirements/      ← this subproject's specifications (optional)
        │   ├── index.md
        │   ├── nfr.md
        │   └── <feature>/     ← index.md + <item>.md, or <concern>/<item>.md
        ├── cli.md             ← this subproject's commands (optional)
        ├── coding-standards/  ← this subproject's rules (optional)
        ├── conventions/       ← this subproject's conventions (optional)
        │   ├── index.md       ← routes to each feature
        │   └── <feature>/     ← index.md + <convention>.md
        └── adrs/              ← this subproject's decisions and why (optional)
            ├── index.md       ← routes to each feature; states the immutability rule
            └── <feature>/     ← index.md + <adr>.md
```

## Artifact homes

Every artifact in the `is-repo-ai-friendly` list has exactly the home below at
each level; the profile adds no other node. A repo that declares its own layout
answers the same list its own way.

| Artifact | Root | Subproject |
|---|---|---|
| Vocabulary | `docs/vocabulary.md` — terms met repo-wide | `docs/vocabulary.md` — terms met in the subproject |
| Structure | `docs/architecture.md` — purpose, subproject map, feature → subprojects | `docs/architecture.md` — modules, storage, communication |
| BA context | `docs/requirements/` — cross-subproject FRs and shared NFRs | `docs/requirements/` — the subproject's features |
| Designer context | `docs/architecture.md` — the overall design and cross-subproject contracts; `docs/conventions/`; `docs/adrs/`; `docs/diagrams/` | `docs/architecture.md` — the subproject's design; `docs/conventions/`; `docs/adrs/` |
| Developer context | `docs/coding-standards/` — cross-subproject rules | `docs/coding-standards/` — the subproject's rules |
| Dev commands | `docs/cli.md` — the gate, cross-subproject orchestration, toolchain versions | `docs/cli.md` — the subproject's commands |
| QA context | `docs/testing.md` — strategy, where cases live | `docs/testing.md` — the subproject's suites and smoke tests |
| Deployment | `docs/deployment.md` — pipeline, environments, triggers | only when it ships on its own |
| Run locally | `docs/cli.md` `Start locally` — the whole stack | `docs/cli.md` `Start locally` — the subproject alone |
| Operations | `docs/operations.md` — logs, metrics, health, rollback | only when it runs on its own |
| Docs map | the declaration, routed from the readme | inherited from the root |

- **Dev commands and Run locally share `cli.md`** — `Start locally` is the run
  row; the rest are the working commands.
- The **Docs map** is the declaration itself — a doc of the repo's choice or a
  readme section; the root readme routes to it and a subproject inherits it.
- **How-to detail** belongs in a convention or coding-standards doc — never in a
  router readme or the root architecture doc.
- **Omissions are declared**, never silent: an artifact a level does not carry
  goes in the declaration's Omissions.

## Rules

- The root holds cross-subproject context only; a subproject holds its own.
  Never repeat a root fact in a subproject — route to the root. A repeat that
  adds local detail may stay, but a bare copy is a defect.
- A repo with no subprojects gets no `<subproject>/` level: the root tree is
  the only tree.
- Optional nodes are created only when the repo needs them — never pre-seed
  empty files.
- Every docs folder gets an `index.md` router — including the feature folders
  under `conventions/`, `adrs/`, and `requirements/`.
- `requirements/` splits by subproject like `conventions/` and `adrs/`: root
  `docs/requirements/` holds cross-subproject requirements only; a feature's
  requirements live in the subproject that owns them.
- Readme file name follows the repo's existing convention (`AGENTS.md`,
  `CLAUDE.md`, `.cursorrules`); default `AGENTS.md`.
- This tree is offered, never imposed. A repo that declares its own layout is
  verified against its declaration, not against this tree.
