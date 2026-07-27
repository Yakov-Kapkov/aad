# Coding Standards

## Table of Contents

- [Data Types](#data-types)
- [Naming Conventions](#naming-conventions)
- [Constraints and Validation](#constraints-and-validation)
- [Index Design](#index-design)
- [Migration Structure](#migration-structure)
- [Schema Organization](#schema-organization)

## Data Types (MANDATORY)

**RULE**: Choose the most specific, correct data type for every column. Never default to `VARCHAR` or `INTEGER` without considering alternatives.

| Use case | Use | Not |
|---|---|---|
| Free-form text | `TEXT` | `VARCHAR(n)` (unless max length is a real business rule) |
| Timestamps | `TIMESTAMPTZ` | `TIMESTAMP` (loses timezone info) |
| Money / precision values | `NUMERIC(p,s)` | `FLOAT`, `DOUBLE PRECISION`, `REAL` |
| Internal surrogate keys | `BIGINT` + `GENERATED ALWAYS AS IDENTITY` | `SERIAL` (deprecated pattern) |
| External-facing IDs | `UUID` with `gen_random_uuid()` | Sequential integers (enumerable, guessable) |
| Boolean flags | `BOOLEAN` | `INTEGER` (0/1), `CHAR(1)` ('Y'/'N') |
| JSON with querying needs | `JSONB` | `JSON` (no indexing, no equality) |
| Fixed set of values | `ENUM` type or reference table | Bare strings |
| Date only (no time) | `DATE` | `TIMESTAMPTZ` |
| Time intervals | `INTERVAL` | Integer columns storing seconds/minutes |

```sql
-- ✅ CORRECT
CREATE TABLE documents (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    external_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    title       TEXT        NOT NULL,
    amount      NUMERIC(12,2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE
);

-- ❌ WRONG
CREATE TABLE documents (
    id          SERIAL PRIMARY KEY,
    external_id VARCHAR(36),
    title       VARCHAR(255),
    amount      FLOAT,
    created_at  TIMESTAMP,
    is_active   INTEGER DEFAULT 1
);
```

## Naming Conventions (MANDATORY)

**RULES**:
- ✅ `snake_case` for all identifiers (tables, columns, functions, indexes, constraints)
- ✅ Plural table names: `documents`, `users`, `order_items`
- ✅ Singular column names: `document_id`, `status`, `created_at`
- ✅ Prefix indexes: `idx_{table}_{columns}`
- ✅ Prefix constraints: `pk_`, `fk_`, `uq_`, `chk_`
- ❌ NEVER use camelCase, PascalCase, or UPPER_CASE for identifiers
- ❌ NEVER use reserved words as identifiers (`user`, `order`, `table`, `column`)

```sql
-- ✅ CORRECT
CREATE TABLE order_items (
    id              BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id)
);
CREATE INDEX idx_order_items_order_id ON order_items (order_id);

-- ❌ WRONG
CREATE TABLE OrderItem (
    Id SERIAL PRIMARY KEY,
    OrderId INT,
    Qty INT
);
```

## Constraints and Validation (MANDATORY)

**RULE**: Enforce data integrity at the database level. Application-layer validation is not a substitute.

**RULES**:
- ✅ Every column is `NOT NULL` unless `NULL` is a valid business value — document why nullable
- ✅ Use `CHECK` constraints for **structural validity** — enum-like value sets, type-level invariants
- ✅ Use `FOREIGN KEY` with explicit `ON DELETE` / `ON UPDATE` actions — default to `RESTRICT`
- ❌ NEVER use `CASCADE` unless the business rule genuinely requires automatic deletion/update of child rows — document why
- ✅ Use `UNIQUE` constraints for natural keys and business uniqueness rules
- ❌ NEVER encode **business rules** in `CHECK` constraints (e.g., `quantity > 0`, `amount >= 0`, date ranges) — enforce these in the application layer
- ❌ NEVER rely solely on application code for uniqueness or referential integrity

**Database vs application layer:**

| Database (`CHECK`) | Application layer |
|---|---|
| Value is one of a fixed set (`status IN ('draft', 'sent')`) | Quantity must be positive |
| Column matches a structural format | Amount must be non-negative |
| NOT NULL, UNIQUE, FK | Date/range validations |
| Enum membership | Status transition rules |

```sql
-- ✅ CORRECT: Constraints enforce business rules
CREATE TABLE invoices (
    id          BIGINT GENERATED ALWAYS AS IDENTITY,
    invoice_no  TEXT        NOT NULL,
    status      TEXT        NOT NULL,
    amount      NUMERIC(12,2) NOT NULL,
    due_date    DATE        NOT NULL,
    customer_id BIGINT      NOT NULL,
    cancelled_reason TEXT,  -- nullable: only set when status = 'cancelled'
    CONSTRAINT pk_invoices PRIMARY KEY (id),
    CONSTRAINT uq_invoices_invoice_no UNIQUE (invoice_no),
    CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id)
        REFERENCES customers (id) ON DELETE RESTRICT,
    CONSTRAINT chk_invoices_status CHECK (status IN ('draft', 'sent', 'paid', 'cancelled'))
);
-- NOTE: amount >= 0 is a business rule — enforce in application layer, not here

-- ❌ WRONG: No constraints — integrity depends on application code
CREATE TABLE invoices (
    id          SERIAL PRIMARY KEY,
    invoice_no  TEXT,
    status      TEXT,
    amount      FLOAT,
    customer_id INT
);
```

## Index Design (MANDATORY)

**RULE**: Create indexes deliberately. Every index must serve a known query pattern.

**RULES**:
- ✅ Index columns used in `WHERE`, `JOIN`, `ORDER BY` of frequent queries
- ✅ Composite indexes: place high-selectivity columns first, match query column order
- ✅ Use `CONCURRENTLY` for production index creation (avoids table lock)
- ✅ Use partial indexes when queries filter on a constant condition
- ✅ Use covering indexes (`INCLUDE`) to enable index-only scans
- ❌ NEVER create indexes speculatively — every index has write-cost
- ❌ NEVER duplicate indexes (a composite index on `(a, b)` already covers queries on `a` alone)

```sql
-- ✅ CORRECT: Targeted indexes for known queries
-- Query: WHERE status = 'pending' ORDER BY created_at
CREATE INDEX CONCURRENTLY idx_orders_status_created
    ON orders (status, created_at);

-- Partial index: only 5% of rows are 'pending'
CREATE INDEX CONCURRENTLY idx_orders_pending
    ON orders (created_at)
    WHERE status = 'pending';

-- Covering index: avoids table lookup
CREATE INDEX CONCURRENTLY idx_orders_customer_covering
    ON orders (customer_id)
    INCLUDE (status, total_amount);

-- ❌ WRONG: Redundant and speculative
CREATE INDEX idx_orders_status ON orders (status);          -- redundant with composite above
CREATE INDEX idx_orders_all ON orders (id, status, amount); -- speculative, no known query
```

## Migration Structure (MANDATORY)

**RULE**: Every schema change is a versioned, reviewable migration. No manual DDL in production.

**RULES**:
- ✅ One logical change per migration file
- ✅ Forward-only corrections — to undo a change, write a new migration that reverses it
- ✅ Separate schema changes from data migrations — never mix in one file
- ✅ Use `CONCURRENTLY` for `CREATE INDEX` and `DROP INDEX` on existing tables
- ❌ NEVER combine unrelated changes in a single migration
- ❌ NEVER modify a migration that has been applied to any shared environment
- ❌ NEVER write DOWN/undo migrations — they risk data loss and most tools don't support them reliably

```sql
-- ✅ CORRECT: V003__add_orders_status_index.sql
CREATE INDEX CONCURRENTLY idx_orders_status
    ON orders (status);
```

```sql
-- ✅ CORRECT: V004__add_customer_email_column.sql
ALTER TABLE customers
    ADD COLUMN email TEXT;
```

```sql
-- ✅ CORRECT: V005__revert_customer_email.sql  (forward-only fix)
ALTER TABLE customers
    DROP COLUMN email;
```

```sql
-- ❌ WRONG: Multiple unrelated changes, mixed schema + data
ALTER TABLE customers ADD COLUMN email VARCHAR(255);
ALTER TABLE orders ADD COLUMN priority INT;
CREATE INDEX idx_orders_priority ON orders (priority);
UPDATE orders SET priority = 1;
```

### Locking-Aware DDL

| Operation | Safe approach |
|---|---|
| Add column (nullable, no default) | `ALTER TABLE ... ADD COLUMN` — instant, no lock |
| Add column with default | PG 11+: instant. Pre-11: add column, then backfill in batches |
| Add `NOT NULL` constraint | Add as `NOT VALID`, then `VALIDATE CONSTRAINT` separately |
| Create index | `CREATE INDEX CONCURRENTLY` |
| Drop index | `DROP INDEX CONCURRENTLY` |
| Add enum value | `ALTER TYPE ... ADD VALUE` — not transactional, place outside transaction block |

## Schema Organization (MANDATORY)

**RULE**: Use PostgreSQL schemas to namespace related objects. Do not put everything in `public`.

```sql
-- ✅ CORRECT: Schemas group related objects
CREATE SCHEMA IF NOT EXISTS billing;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE billing.invoices ( /* ... */ );
CREATE TABLE audit.change_log ( /* ... */ );

-- Set search_path for the application role
ALTER ROLE app_user SET search_path TO billing, public;

-- ❌ WRONG: Everything in public
CREATE TABLE invoices ( /* ... */ );
CREATE TABLE audit_change_log ( /* ... */ );  -- prefix instead of schema
```
