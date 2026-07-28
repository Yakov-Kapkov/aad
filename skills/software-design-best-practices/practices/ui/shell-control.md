# Shell Control Extraction

## Rule

When the same view layout or behavior appears in multiple pages or
controls, extract it into a single Shell control that enforces
consistency.

## Application

- ✅ DO: extract shared visual structure (navigation bar, sidebar,
  breadcrumbs, status bar, notification area) into a Shell component.
- ✅ DO: extract shared behaviors (authentication gate, role-based
  visibility, error boundary, loading overlay) into the Shell.
- ✅ DO: use the Shell as the single root wrapper for all pages —
  pages render only their specific content.
- ✅ DO: when adding a new page that needs the same layout as
  existing pages, use the Shell — do not copy layout from another
  page.
- ❌ DON'T: duplicate navigation markup across pages.
- ❌ DON'T: implement authentication checks independently on each
  page — the Shell should gate all protected content.
- ❌ DON'T: create multiple Shell variants that differ only by a
  single section — parameterize the Shell instead.
