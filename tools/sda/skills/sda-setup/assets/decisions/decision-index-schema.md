# Decision Index Schema

An `index.md` routes readers to decision topics or child indexes. It is the
navigation layer of the decision tree — references only, no decision content.
It lives at the root of `{paths.decisions}` and optionally at deeper levels.

---

## Template

```markdown
# {Area Name}

| Concern | When to read | Document |
|---|---|---|
| {concern} | {trigger phrases} | [{file}]({path}) |
```

---

## Schema Rules

### Routing table
- One row per concern or child index.
- `When to read` = trigger phrases — "adding a DB repository", "new API
  endpoint", "inter-BC communication". This is the matching surface agents
  self-route on before making a design choice.
- `Document` targets a topic file **or** a child `index.md` — recursion by
  target, not by a second schema.

### References only
- No decision content in an index. Each row routes; the target holds the
  content.
- No duplicates — the same concern/target appears in one row only.
