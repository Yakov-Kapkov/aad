# Code Style and Documentation

## Table of Contents

- [String Formatting](#string-formatting)
- [File-Level Documentation](#file-level-documentation)
- [API Documentation Standards](#api-documentation-standards)

## String Formatting (MANDATORY)

**RULE**: Wrap variables in single quotes in error/log/user-facing messages.

**Why**: Makes variable boundaries visible, especially for UUIDs, file paths, user input with spaces/special chars.

```python
# ✅ CORRECT
raise ValueError(f"Flow '{flow_id}' not found")
raise ValueError(f"File '{file_path}' does not exist")
logger.error("Failed to process", flow_id=flow_id)  # Structured logging - no quotes in values

# ❌ WRONG
raise ValueError(f"Flow {flow_id} not found")
logger.info("Processing", flow_id=f"'{flow_id}'")  # Don't quote structured logging values
```

## File-Level Documentation (MANDATORY)

**RULE**: Every file MUST begin with a module-level docstring (max 5 lines) summarizing the file's purpose, responsibility, and key constraints. Write it for a developer reading the file for the first time.

**What to include:**
- What this module **is** (one sentence)
- Its primary **responsibility** or role in the system
- Key **constraints or design decisions** worth knowing upfront

```python
# ✅ CORRECT
"""Route handlers for the Admin Logs API.

Thin controller: extracts params, validates input, delegates to AdminLogsService.
No business logic here — authentication is handled by authenticate_snowflake_access middleware.
"""
```

```python
# ❌ WRONG: Restates filename, lists exports, describes implementation
"""admin_logs_routes.py

Contains get_logs, delete_log, update_log functions.
Uses a for-loop to iterate over rows and builds response dicts.
"""
```

**Rules:**
- ✅ Max 5 lines of text (not counting the `"""` delimiters)
- ✅ Plain prose — no structured sections (`Args:`, `Returns:`, `:param:`, etc.)
- ✅ Placed at the **very top of the file**, before any imports
- ❌ Do not restate the filename or list every export
- ❌ Do not describe implementation details — describe purpose and constraints

## API Documentation Standards

**All public classes, functions, and methods must have documentation comments.**

Every documentation comment must include:

1. **Summary** — a concise one-line description
2. **Description** — a fuller explanation of behaviour, lifecycle, or responsibilities (mandatory for classes; use for functions when additional context beyond the summary is needed)

Additional sections as applicable:
- Parameters
- Return values
- Exceptions
- Examples for complex functionality

**Document the symbol itself** — describe what *this* function/class does, not where it is called from. Callers change; the contract is what matters.

**Format:** Google-style docstrings (`Args:`, `Returns:`, `Raises:`).

**Class example:**

```python
# ✅ CORRECT
class SnowflakeServiceProvider:
    """Factory and cache for SnowflakeService instances.

    Maintains a dict keyed by SnowflakeType. On first call for a given type,
    creates the SnowflakeService using the matching config provider and caches it.
    Subsequent calls return the cached instance.
    """

async def process_document(
    document_id: str,
    content: str,
    options: ProcessingOptions | None = None,
) -> ProcessingResult:
    """Extract obligations from a document by ID.

    Validates the document ID, retrieves content from storage, runs the
    obligations extraction pipeline, and returns a structured result.

    Args:
        document_id: Unique identifier for the document.
        content: Raw document content to process.
        options: Optional processing configuration.

    Returns:
        Processing result with extracted obligations.

    Raises:
        DocumentNotFoundError: If document doesn't exist.
    """
```
