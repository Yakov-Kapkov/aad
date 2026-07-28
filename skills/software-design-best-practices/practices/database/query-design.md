# Query Design

## Rule

Select only the columns needed for the current operation — never use
`SELECT *` or fetch entire rows when only a subset of columns is
required.

## Application

- ✅ DO: list explicit column names in every query. If an ORM is
  used, configure projections (`.Select()`, `.ProjectTo<>()`) that
  fetch only needed columns.
- ✅ DO: create dedicated read models (lightweight DTOs/projections)
  for queries — not the full entity.
- ✅ DO: for list/page queries, return only summary fields. Fetch
  full details in a separate query when the user selects an item.
- ❌ DON'T: use `SELECT *` in any production query.
- ❌ DON'T: fetch entire entity graphs (all relations) when only the
  parent entity's fields are needed.
- ❌ DON'T: reuse a "full entity" query and discard unused fields in
  application code — the waste already happened at the database.
