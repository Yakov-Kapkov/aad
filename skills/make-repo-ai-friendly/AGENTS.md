# AGENTS.md — make-repo-ai-friendly

Rules for creating and editing this skill's files.

## Folder structure

```
make-repo-ai-friendly/
├── SKILL.md                        ← workflow, modes, approval rules
├── README.md                       ← human index
├── AGENTS.md                       ← this file
└── assets/                         ← schemas (entity-level, structure only)
    ├── docs-tree.md                ← default profile (a proposal)
    ├── docs-map-schema.md          ← the docs declaration
    ├── readme-outline-schema.md
    ├── docs-index-schema.md
    ├── architecture-schema.md
    ├── vocabulary-schema.md
    ├── adr-schema.md
    ├── convention-schema.md
    ├── requirements-schema.md
    ├── coding-standards-schema.md
    ├── cli-schema.md
    ├── testing-schema.md
    ├── deployment-schema.md
    ├── operations-schema.md
    └── scripts/
        ├── check-tree.ps1
        ├── check-tree.sh
        └── _check-tree.Tests.ps1
```

## Rules

### 1. Separation of concerns

- `SKILL.md` owns **workflow only**: criteria reference, scope, modes, order of
  steps, approval gate, report, acceptance criteria. It never restates a
  schema's structure — the profile's artifact homes live in `docs-tree.md`.
- `assets/*-schema.md` own **structure only**: a target file's template and
  content rules. They never name agents, modes, or workflow.
- When an edit mixes both, split it: workflow to `SKILL.md`, structure to the
  schema.

### 2. Schema ↔ SKILL.md sync

When you add, remove, or rename an asset:

1. Update the **Assets** table in `SKILL.md` (file type → schema path).
2. Update the **What's Inside** table in `README.md`.
3. Update the folder-structure block above.

When you change a schema's sections, check that no `SKILL.md` step depends on
the old structure.

### 3. Conciseness

- One ✅ example + one ❌ example per rule. No more.
- Bullet points over paragraphs.
- No prose that restates what an example already shows.

### 4. Default, not law

- `assets/docs-tree.md` is a proposal. Never write that a repo *must* follow it,
  and never treat a repo's declared layout as a deviation from a standard.
- The criteria live in the `is-repo-ai-friendly` skill. Never restate a
  criterion here — reference the skill.
