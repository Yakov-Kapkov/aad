# Single-Result Retrieval Methods

## Rule

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
