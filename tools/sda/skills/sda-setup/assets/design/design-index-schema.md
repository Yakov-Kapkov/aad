# Design Index Schema

An `index.md` routes readers to the files and subfolders of a docs folder.
References only — no design content. Two docs folders use it: global
`docs/index.md` (routes to architecture, vocabulary, diagrams) and
`<layer>/docs/index.md` (routes to vocabulary, decisions).

---

## Template

Global `docs/index.md`:

```markdown
# Docs

| Concern | When to read | Document |
|---|---|---|
| Architecture | system layout, layers, storage | [architecture](architecture.md) |
| Vocabulary | shared terminology | [vocabulary](vocabulary.md) |
| Diagrams | visual flows | [diagrams](diagrams/) |
```

`<layer>/docs/index.md`:

```markdown
# {Layer} docs

| Concern | When to read | Document |
|---|---|---|
| Vocabulary | this layer's terms | [vocabulary](vocabulary.md) |
| Decisions | why a design choice was made | [decisions](decisions/index.md) |
```

---

## Schema Rules

- One row per file or subfolder that exists — never list a file that was not
  created.
- `When to read` = trigger phrases; `Document` targets a file or a child
  `index.md`.
- References only. No decision or design content in the index.
