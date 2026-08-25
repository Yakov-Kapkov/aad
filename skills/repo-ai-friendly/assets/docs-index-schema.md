# Design Index Schema

An `index.md` routes readers to the files and subfolders of a docs folder.
References only — no design content. Two docs folders use it: global
`docs/index.md` and `<layer>/docs/index.md`.

---

## Template

Global `docs/index.md`:

```markdown
# Docs

| Concern | When to read | Document |
|---|---|---|
| Architecture | system layout, layers, storage | [architecture](architecture.md) |
| Vocabulary | shared terminology | [vocabulary](vocabulary.md) |
| Coding standards | repo-wide rules | [coding-standards](coding-standards/index.md) |
| Diagrams | visual flows | [diagrams](diagrams/) |
| Decisions | why a design choice was made | [decisions](decisions/index.md) |
```

`<layer>/docs/index.md`:

```markdown
# {Layer} docs

| Concern | When to read | Document |
|---|---|---|
| Architecture | this layer's modules, ownership, communication, storage | [architecture](architecture.md) |
| Vocabulary | this layer's terms | [vocabulary](vocabulary.md) |
| CLI | commands to run this layer | [cli](cli.md) |
| Coding standards | this layer's rules | [coding-standards](coding-standards/index.md) |
| Diagrams | this layer's visual flows | [diagrams](diagrams/) |
| Decisions | why a design choice was made | [decisions](decisions/index.md) |
```

---

## Schema Rules

- One row per file or subfolder that exists — never list a file that was not
  created.
- `When to read` = trigger phrases; `Document` targets a file or a child
  `index.md`.
- References only. No decision or design content in the index.
- The `CLI` row appears in layer indexes only, and only when `cli.md` exists.
- The `Coding standards` row appears only when the `coding-standards/` folder
  exists.
