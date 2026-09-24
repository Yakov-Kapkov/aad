---
name: sda-spec-guide
description: "Contract spec conventions for SDA planning and implementation agents — the spec model, storage layout, metadata, and content rules. Use when: a session touches a boundary contract — `sda-design` writing or extracting a spec, `sda-dev-task` running the contract trace, `sda-dev-task-verifier` check 4, `sda-docs-check` verifying a written spec, or `sda-qa-task` tracing contract regressions. Otherwise never load it."
---

# Contract Specs

A **spec** is a firm description of one boundary crossing. It lives under
`{specs-root}` (default `.sda/specs`).

This skill holds the **conventions**: a spec's role, its storage, its content,
and its lifecycle. Your own phase steps — tracing, verifying, reading — stay in
your agent file.

## One creator

A spec is created once, before task design begins — never downstream. A spec
is either **designed** — the boundary the feature introduces — or
**extracted**, from code that already exists; the `# EXTRACTED` marker tells
them apart.

A spec is a **constraint** the downstream stages conform to. A task therefore
records its own boundary change as an **anchored delta** into a spec that
already exists — never as a new file.

Who may write what — the cross-agent ownership map — lives in the tool's
`AGENTS.md` (`## Rules` → *Contract Spec Ownership*).

## Storage

| Artifact | Path |
|---|---|
| Spec file | `{specs-root}/{domain}/{file-name}` — one file per boundary |
| Manifest | `{specs-root}/manifest.md` — the discovery index |

- `{specs-root}` is a session-context placeholder. **The writer resolves it** —
  callers pass it through unresolved, exactly as written in their input.
- The spec's **format** is the project's own convention, recorded in the
  project's architecture doc (OpenAPI for REST, AsyncAPI for events, JSON Schema
  for shared models). Read that convention — never assume a format.

## Metadata

The write supplies four fields; together they produce the manifest row.

| Field | Meaning |
|---|---|
| Domain | subdirectory name |
| Boundary | direction, e.g. `UI → Backend` |
| Format | e.g. `OpenAPI 3.1` |
| Description | one line, for the manifest |

## Content

A spec states the boundary — what crosses it — not the system behind it.

- **Field names, types, optionality** — as each crosses.
- **Error shapes and codes** — including the cases the code documents poorly.
- **Completeness** — every field one side produces is consumed, or explicitly
  ignored, by the other.

An **extracted** spec — written from code that already exists, rather than
designed before it — opens with `# EXTRACTED — verify against implementation`.

## Read path

Discovery starts at `manifest.md`. Read a spec to:

1. **Conform** an implementation to a spec.
2. **Trace** a data flow — check what actually crosses against the spec.
3. **Find consumers** of a boundary a task changes.

## Verification

A spec is checked twice, and the two checks see different things:

| Check | When | Against |
|---|---|---|
| Conformance — `task.md` against a spec that exists | Before implementation | the specs in `## Contracts`, judged by its [Content](#content) obligations |
| The written spec against the code | After the write | its [Content](#content) obligations, plus Domain placement and the `manifest.md` row |

An extracted spec is verified **after** it is written — there is nothing to
check it against beforehand.

## Boundaries

Not covered here: the contract-trace steps, any agent's phase order, the
`docs`-unit entry shape (`task-schema.md`), and the `manifest.md` table format
(`sda-scribe` — its write step).
