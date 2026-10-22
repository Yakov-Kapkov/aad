# Vocabulary Schema

`vocabulary.md` lives at `docs/` (root) and `<subproject>/docs/` (subproject). It collects the
terms a competent newcomer would **guess wrong**: meaning here differs from the
everyday meaning, one word means two things, insider abbreviations. A term whose
meaning is obvious to an outsider needs no entry at all.

Where it goes: the level where the guess happens — the root for terms the root
readme or several subprojects use, the subproject for terms met while working in it.

---

## Template

Global `docs/vocabulary.md`:

```markdown
# Vocabulary

| Term | Definition | Subprojects |
|---|---|---|
| {Term} | {one-line root definition} | [{subproject}]({subproject}/docs/vocabulary.md) |
```

Subproject `<subproject>/docs/vocabulary.md`:

```markdown
# Vocabulary — {Subproject}

| Term | Definition |
|---|---|
| {Term} | {one-line definition} |
```

## Example

`coin` earns an entry only because a newcomer would guess it wrong — it means
pseudo-currency, not real money. Met in one subproject, it is defined once
there, never at the root:

```markdown
# Vocabulary — Frontend

| Term | Definition |
|---|---|
| coin | pseudo-currency, not real money |
```

---

## Schema Rules

- The test for inclusion: would a newcomer guess this wrong? If not, leave it
  out — an obvious term in the table is noise.
- A root term links to every subproject that specialises it; a subproject-only
  term is defined in that subproject, never added to the root table.
- A subproject never restates a root term with the same meaning — route to the
  root.
- One-line definitions. No implementation-level jargon.
- Only create the files the design actually needs — never pre-seed empty files.
