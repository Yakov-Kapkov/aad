# Code Style and Documentation

## Table of Contents

- [String Formatting](#string-formatting)
- [File-Level Documentation](#file-level-documentation)
- [API Documentation Standards](#api-documentation-standards)

## String Formatting (MANDATORY)

**RULE**: Wrap variables in single quotes in error/log/user-facing messages.

**Why**: Makes variable boundaries visible, especially for UUIDs, file paths, user input with spaces/special chars.

```java
// ✅ CORRECT
throw new IllegalArgumentException(String.format("Flow '%s' not found", flowId));
throw new IllegalStateException(String.format("File '%s' does not exist", filePath));
logger.error("Failed to process flow", Map.of("flowId", flowId, "status", flowStatus));

// ❌ WRONG
throw new IllegalArgumentException("Flow " + flowId + " not found");
logger.info("Processing flow", Map.of("flowId", "'" + flowId + "'")); // Don't quote structured logging values
```

## File-Level Documentation

**Do not add file-level header block comments.** Documentation comments
apply to exported classes, methods, and fields only — not to files.
Each Java source file contains exactly one top-level class; the class-level
Javadoc serves as the file's documentation.

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

**Format:** Javadoc tags in order: `@param`, `@return`, `@throws`, `@deprecated`.

```java
// ✅ CORRECT
/**
 * Factory and cache for SnowflakeService instances.
 *
 * <p>Maintains a static map keyed by SnowflakeType. On first call for a
 * given type, creates the SnowflakeService using the matching config provider and
 * caches it. Subsequent calls return the cached instance.
 */
public class SnowflakeServiceProvider { /* … */ }

/**
 * Extracts obligations from a document by ID.
 *
 * <p>Validates the document ID, retrieves content from storage, runs the
 * obligations extraction pipeline, and returns a structured result.
 *
 * @param documentId unique identifier for the document
 * @param content    raw document content to process
 * @param options    optional processing configuration, may be {@code null}
 * @return processing result with extracted obligations
 * @throws DocumentNotFoundException if document doesn't exist
 */
public ProcessingResult processDocument(
        String documentId,
        String content,
        ProcessingOptions options) {
    // Implementation
}
```
