# Code Style and Documentation

## Table of Contents

- [String Formatting](#string-formatting)
- [File-Level Documentation](#file-level-documentation)
- [API Documentation Standards](#api-documentation-standards)

## String Formatting (MANDATORY)

**RULE**: Wrap variables in single quotes in error/log/user-facing messages.

**Why**: Makes variable boundaries visible, especially for UUIDs, file paths, user input with spaces/special chars.

```typescript
// ✅ CORRECT
throw new Error(`Flow '${flowId}' not found`);
throw new Error(`File '${filePath}' does not exist`);
logger.error(`Failed to process flow`, { flowId, status: flowStatus });

// ❌ WRONG
throw new Error(`Flow ${flowId} not found`);
logger.info("Processing flow", { flowId: `'${flowId}'` });  // Don't quote structured logging values
```

## File-Level Documentation

**Do not add file-level header block comments.** Documentation comments
apply to exported functions, classes, and methods only — not to files.

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

**Format:** TSDoc tags (`@param`, `@returns`, `@throws`).

```typescript
// ✅ CORRECT
/**
 * Factory and cache for SnowflakeService instances.
 *
 * @description Maintains a static map keyed by SnowflakeType. On first call for a
 * given type, creates the SnowflakeService using the matching config provider and
 * caches it. Subsequent calls return the cached instance.
 */
export class SnowflakeServiceProvider { /* … */ }

/**
 * Extract obligations from a document by ID.
 *
 * @description Validates the document ID, retrieves content from storage, runs the
 * obligations extraction pipeline, and returns a structured result.
 *
 * @param documentId - Unique identifier for the document
 * @param content - Raw document content to process
 * @param options - Optional processing configuration
 * @returns Processing result with extracted obligations
 * @throws {DocumentNotFoundError} If document doesn't exist
 */
async function processDocument(
  documentId: string,
  content: string,
  options?: ProcessingOptions
): Promise<ProcessingResult> {
  // Implementation
}
```
