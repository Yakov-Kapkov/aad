# AGENTS.md — repo-ai-friendly

Rules for creating and editing this skill's files.

## Folder structure

```
repo-ai-friendly/
├── SKILL.md                        ← workflow, modes, approval rules
├── README.md                       ← human index
├── AGENTS.md                       ← this file
└── assets/                         ← schemas (entity-level, structure only)
    ├── docs-tree.md
    ├── readme-outline-schema.md
    ├── docs-index-schema.md
    ├── architecture-schema.md
    ├── vocabulary-schema.md
    ├── decision-schema.md
    ├── coding-standards-schema.md
    └── cli-schema.md
```

## Rules

### 1. Separation of concerns

- `SKILL.md` owns **workflow only**: modes, order of steps, approval gate,
  interview rules. It never restates a schema's structure.
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
