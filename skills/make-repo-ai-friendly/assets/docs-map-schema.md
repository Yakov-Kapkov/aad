# Docs Map Schema

The document in which a repo states how its documentation is organised and
maintained. This is the **Docs map** — the repo's docs contract.

The declaration's own name and location are the repo's choice: a dedicated doc
(when the readme must stay thin) or a section of the readme itself.

---

## Template

```markdown
# {Docs map}

## Layout
- {path} — {what it holds}
- {path} — {what it holds}

## Naming
- {rule} — e.g. "every docs folder has an `index.md`"
- One file per {subproject}: {naming pattern}

## Omissions
- {what the repo deliberately does not document} — {why, one clause}

## Housekeeping

| Action | Rule |
|---|---|
| Add a doc | {where it goes, who does it} |
| Update a doc | {what triggers it} |
| Retire a doc | {what happens to inbound links} |
```

---

## Schema Rules

- Declare what is true today, not what is planned.
- Naming rules are concrete — a reader must place a new doc without asking.
- Omissions are explicit; silence is not a declaration.
- Housekeeping covers all three actions: add, update, retire.
- A declaration states *implementation*. It never waives a criterion — those
  live in the `is-repo-ai-friendly` skill.
- Name-free: this schema never prescribes the declaration's filename or folder.
