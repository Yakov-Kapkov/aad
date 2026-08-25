# Docs Tree

Canonical folder layout for an AI-friendly repo. Global holds repo-wide info
only; layer info lives in the layer.

```
<repo-root>/
├── AGENTS.md                  ← AI readme (router) — or CLAUDE.md / .cursorrules
├── README.md                  ← human readme (same outline, human tone)
├── docs/
│   ├── index.md               ← router to the files below
│   ├── architecture.md        ← repo structure, layers, storage, cross-cutting
│   ├── vocabulary.md          ← terms used across layers
│   ├── coding-standards/      ← cross-layer rules (optional)
│   │   └── index.md
│   ├── decisions/             ← cross-layer decisions (optional)
│   │   ├── index.md
│   │   └── <feature>/<decision>.md
│   └── diagrams/              ← optional
└── <layer>/                   ← one per subsystem: backend/, frontend/, worker/ …
    ├── AGENTS.md              ← layer AI readme (router)
    ├── README.md              ← layer human readme
    └── docs/
        ├── index.md
        ├── architecture.md
        ├── vocabulary.md
        ├── cli.md             ← this layer's commands (per-layer only)
        ├── coding-standards/  ← this layer's rules (optional)
        └── decisions/         ← this layer's decisions (optional)
```

## Rules

- A repo with no subsystems gets only the global tree (no `<layer>/`).
- `cli.md` is **per-layer only** — never global. Layers use different tools;
  the readme's "run locally" section routes to each layer's `cli.md`.
- Optional nodes are created only when the repo needs them — never pre-seed
  empty files.
- Every docs folder gets an `index.md` router.
- Readme file name follows the repo's existing convention (`AGENTS.md`,
  `CLAUDE.md`, `.cursorrules`); default `AGENTS.md`.
