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

## Rule: Limit rows for single-record queries

When a query should return at most one row, add a limit clause so the
database engine can stop after the first match.

## Application

- ✅ DO: add `LIMIT 1` (MySQL/PostgreSQL/SQLite), `TOP 1` (SQL
  Server/Cosmos DB), `FETCH FIRST 1 ROW ONLY` (DB2/Oracle 12c+),
  or the equivalent clause for your database.
- ✅ DO: in ORMs, chain `.Take(1)` (EF Core), `.limit(1)` (Mongoose/
  Prisma), or `.first()` (SQLAlchemy) on single-record lookups.
- ✅ DO: for NoSQL, use the SDK's native limit parameter (e.g.,
  MongoDB `.limit(1)`, Cosmos DB `TOP 1` in query text).
- ❌ DON'T: omit the limit clause and let the database scan all
  matching rows when only one is needed.
- ❌ DON'T: apply a limit clause to queries that legitimately return
  multiple rows — this rule is for lookups expecting zero or one
  result.

## Rule: Use single-result retrieval methods

When retrieving at most one record, use the SDK/ORM method that stops
after the first result — not the method that materializes all rows.

## Application

- ✅ DO: use `fetchNext()` (Cosmos DB), `FirstOrDefault()` /
  `SingleOrDefault()` (EF Core), `findOne()` (MongoDB/Mongoose),
  `QuerySingleOrDefault()` (Dapper) for single-record lookups.
- ✅ DO: for raw SQL via driver, read only the first row from the
  result set — don't iterate the entire cursor.
- ❌ DON'T: use `fetchAll()` (Cosmos DB), `ToList()` (EF Core),
  `toArray()` (MongoDB), or `Query<T>()` (Dapper) when only one
  record is needed — these materialize every result.
- ❌ DON'T: call a collect-all method and then discard all but the
  first element in application code.
