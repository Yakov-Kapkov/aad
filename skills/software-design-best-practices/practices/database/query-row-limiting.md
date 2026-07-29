# Row Limiting

## Rule

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
