# Design Index Schema

An `index.md` routes readers to the files and subfolders of a docs folder.
References only — no design content. Two docs folders use it: global
`docs/index.md` (root), plus `<subproject>/docs/index.md` in each subproject.

---

## Template

Root `docs/index.md`:

```markdown
# Docs

| Concern | When to read | Document |
|---|---|---|
| Architecture | system layout, the subprojects, storage | [architecture](architecture.md) |
| Vocabulary | terms a newcomer would guess wrong | [vocabulary](vocabulary.md) |
| Testing | how the system is verified | [testing](testing.md) |
| Deployment | how a change reaches users | [deployment](deployment.md) |
| Operations | health, logs, metrics, rollback | [operations](operations.md) |
| Commands | how to build, test, lint, and run it | [cli](cli.md) |
| Requirements | what the system shall do — FRs and cross-subproject NFRs | [requirements](requirements/index.md) |
| Coding standards | repo-wide rules | [coding-standards](coding-standards/index.md) |
| Diagrams | visual flows | [diagrams](diagrams/) |
| Conventions | how to apply a chosen direction — read while building | [conventions](conventions/index.md) |
| ADRs | which direction was chosen and why — read while questioning | [adrs](adrs/index.md) |
```

Subproject `<subproject>/docs/index.md`:

```markdown
# {Subproject} docs

| Concern | When to read | Document |
|---|---|---|
| Architecture | this subproject's modules, ownership, communication, storage | [architecture](architecture.md) |
| Vocabulary | this subproject's terms | [vocabulary](vocabulary.md) |
| Testing | this subproject's suites and smoke tests | [testing](testing.md) |
| Commands | how to build, test, lint, and run this subproject | [cli](cli.md) |
| Requirements | what this subproject's features shall do | [requirements](requirements/index.md) |
| Coding standards | this subproject's rules | [coding-standards](coding-standards/index.md) |
| Diagrams | this subproject's visual flows | [diagrams](diagrams/) |
| Conventions | how to apply a chosen direction — read while building | [conventions](conventions/index.md) |
| ADRs | which direction was chosen and why — read while questioning | [adrs](adrs/index.md) |
```

---

## Schema Rules

- One row per file or subfolder that exists — never list a file that was not
  created.
- `When to read` = trigger phrases; `Document` targets a file or a child
  `index.md`.
- References only. No convention, ADR, or design content in the index.
- The `Commands` row appears only when `cli.md` exists at that level — the root
  has one when the root has commands of its own.
- A `Testing` row appears only when `testing.md` exists; a level gets a
  `Deployment` or `Operations` row only when it has that file.
- The `Coding standards` row appears only when the `coding-standards/` folder
  exists.
- A `Conventions` row appears only when `conventions/` exists; an `ADRs` row
  only when `adrs/` exists.
- The `Requirements` row appears only when the `requirements/` folder exists.
