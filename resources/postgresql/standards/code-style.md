# Code Style and Documentation

## Table of Contents

- [SQL Formatting](#sql-formatting)
- [File-Level Documentation](#file-level-documentation)
- [Object Documentation](#object-documentation)

## SQL Formatting (MANDATORY)

**RULE**: Consistent formatting makes SQL reviewable and diffable.

**RULES**:
- ✅ UPPERCASE SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`, `INSERT`, `CREATE`, `ALTER`
- ✅ lowercase identifiers: table names, column names, aliases
- ✅ One column per line in `SELECT`, `INSERT`, `CREATE TABLE`
- ✅ Align `JOIN` / `ON`, `AND` / `OR` at the same indentation level
- ✅ Trailing commas in column lists (where syntax allows)
- ✅ Use table aliases in multi-table queries — short, meaningful (`o` for `orders`, `c` for `customers`)
- ❌ NEVER write entire queries on one line (except trivial single-column selects)

```sql
-- ✅ CORRECT
SELECT
    o.id,
    o.status,
    o.total_amount,
    c.name AS customer_name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'pending'
    AND o.created_at >= now() - INTERVAL '30 days'
ORDER BY o.created_at DESC;

-- ❌ WRONG
select o.id, o.status, o.total_amount, c.name from orders o join customers c on c.id = o.customer_id where o.status = 'pending' and o.created_at >= now() - interval '30 days' order by o.created_at desc;
```

### DDL Formatting

```sql
-- ✅ CORRECT: Aligned, one column per line, constraints at bottom
CREATE TABLE invoices (
    id              BIGINT GENERATED ALWAYS AS IDENTITY,
    invoice_no      TEXT        NOT NULL,
    customer_id     BIGINT      NOT NULL,
    amount          NUMERIC(12,2) NOT NULL,
    status          TEXT        NOT NULL DEFAULT 'draft',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_invoices PRIMARY KEY (id),
    CONSTRAINT uq_invoices_invoice_no UNIQUE (invoice_no),
    CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id)
        REFERENCES customers (id) ON DELETE RESTRICT,
    CONSTRAINT chk_invoices_amount CHECK (amount >= 0)
);

-- ❌ WRONG: Inline constraints, inconsistent spacing
CREATE TABLE invoices (
id SERIAL PRIMARY KEY, invoice_no TEXT UNIQUE,
customer_id INT REFERENCES customers(id),
amount FLOAT, status TEXT DEFAULT 'draft',
created_at TIMESTAMP DEFAULT now());
```

## File-Level Documentation (MANDATORY)

**RULE**: Every migration file MUST begin with a comment block stating what it does and why.

```sql
-- ✅ CORRECT
-- V005__add_orders_status_index.sql
--
-- Adds a partial index on orders.status for the pending-orders dashboard query.
-- Only indexes 'pending' rows (~5% of table) to minimize index size.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_pending
    ON orders (created_at)
    WHERE status = 'pending';

-- ❌ WRONG: No explanation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_pending
    ON orders (created_at)
    WHERE status = 'pending';
```

**Rules**:
- ✅ State the migration filename on the first line
- ✅ Explain the business reason or query pattern the change supports
- ✅ Note any locking or performance implications for large tables
- ❌ Do not restate the SQL — describe purpose and constraints

## Object Documentation (MANDATORY)

**RULE**: Document tables and non-obvious columns using `COMMENT ON`.

```sql
-- ✅ CORRECT
COMMENT ON TABLE invoices IS 'Customer invoices generated from completed orders.';
COMMENT ON COLUMN invoices.status IS 'Lifecycle state: draft → sent → paid → cancelled.';
COMMENT ON COLUMN invoices.cancelled_reason IS 'Free-text reason, required when status = cancelled.';
COMMENT ON INDEX idx_orders_pending IS 'Partial index for pending-orders dashboard query.';

-- ❌ WRONG: No documentation — schema is self-documenting (it is not)
```

**Document**: Every table, nullable columns (explain when NULL is valid), columns with `CHECK` constraints (explain the rule), non-obvious indexes (explain the query pattern).
**Do not document**: Self-evident columns (`id`, `created_at`, `updated_at`), primary key indexes.
