# Implemented-Feature Schema

The **BA durable contribution**: a human- and AI-readable record of *what exists* from
the BA view, updated per completed story. Lives under `paths.baFeatures`.

## Template

```markdown
# Implemented Features

## {feature-area}

### {feature-name}
- **Story:** {slug} ({workflow-id})
- **Actor:** {role}
- **Capability:** {one line — what the actor can now do}
- **Scenarios:** FR-1…FR-n  (see user-story.md)
- **Global NFRs:** {referenced ids}
- **Status:** implemented  ·  {date}
```

## Rules

- One entry per completed story, grouped by feature area.
- Links back to the source `user-story.md` — not a copy of its scenarios.
- Append-only per story; supersede an entry only when the capability changes.
- Entity doc — describes only the ledger document.
