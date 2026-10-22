# AGENTS.md — is-repo-ai-friendly

Rules for creating and editing this skill's files.

## Folder structure

```
is-repo-ai-friendly/
├── SKILL.md                        ← the artifact list, levels, statuses, workflow, report, ACs
├── README.md                       ← human index
├── AGENTS.md                       ← this file
└── assets/
    └── scripts/
        ├── check-links.ps1
        ├── check-links.sh
        └── _check-links.Tests.ps1  ← development-only, pruned on install
```

## Rules

### 1. Separation of concerns

- `SKILL.md` owns the **artifact list** — what an AI-friendly repo must expose
  — and how it is judged: levels, statuses, workflow, report, ACs.
- `assets/scripts/*` own **mechanics only**: what a check decides from text.
  They never assume a docs layout.

### 2. The list is single-sourced

- The artifact list lives in `SKILL.md` only — never in an asset, never in
  `README.md`.
- Adding, removing, or reordering an artifact → update the `#` column and the
  acceptance criteria in the same edit.
- Adding or removing a script → update the workflow's inputs and steps in
  `SKILL.md`, and the **What's Inside** table in `README.md`.

### 3. Name-free artifacts

- An artifact never *requires* a path, filename, folder, or tool — only that it
  is reachable. Any layout satisfies the list.

### 4. Conciseness

- Tables over paragraphs; one example per rule; no prose that restates a table.
