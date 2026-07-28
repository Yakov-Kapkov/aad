# Data Source Efficiency

## Rule

Request only the data needed for the current view. Fetch item details
on demand — not in the list query.

## Application

- ✅ DO: list endpoints/queries return only summary fields (id, title,
  status, date) — enough to render the list row.
- ✅ DO: on click/tap of a list item, request the full detail from
  the backend (separate endpoint or query).
- ✅ DO: cache detail responses for the current session to avoid
  re-fetching if the user revisits the same item.
- ✅ DO: paginate list results — never return unbounded collections.
- ❌ DON'T: include nested child collections or large text/blob
  fields in list query results.
- ❌ DON'T: pre-fetch details for all visible list items — fetch only
  what the user explicitly selects.
- ❌ DON'T: return redundant data that the view doesn't render.
