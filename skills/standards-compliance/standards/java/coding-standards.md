# Coding Standards

## Table of Contents

- [Type Safety and Strongly-Typed Patterns](#type-safety-and-strongly-typed-patterns)
- [Magic Number/String Prevention](#magic-numberstring-prevention)
- [Import Organization](#import-organization)

## Type Safety and Strongly-Typed Patterns

### Data Models: Use Records or Validated Classes (MANDATORY)

**RULE**: For ALL data models, API models, and configuration objects, use Java records, immutable classes, or classes with Bean Validation — not plain `Map<String, Object>`.

**Why**: Runtime/compile-time validation, IDE autocomplete, type safety, serialization support.

```java
// ✅ CORRECT: Record with Bean Validation for API models
public record DocumentRequest(
        @NotBlank String documentId,
        @NotBlank @Size(min = 1) String content
) {}

// ❌ WRONG: Plain Map - no validation, typos undetected
Map<String, Object> requestData = Map.of("documentId", "123", "conent", "text"); // Typo undetected!
```

**Use records for**: Immutable DTOs, API responses, value objects.
**Use classes with Bean Validation for**: API requests, configuration requiring runtime validation.
**Use plain classes/POJOs for**: Mutable domain entities, JPA entities.

### Type Annotations (MANDATORY)

**RULE**: EVERY method parameter and return type MUST be explicitly typed. NEVER use raw generic types. NEVER use `Object` as a catch-all type. Zero exceptions.

```java
// ✅ CORRECT: All parameters and return types annotated, generics parameterized
public ProcessingResult processDocuments(
        List<Document> documents,
        ProcessingContext context,
        int timeout) {
    // Implementation
}

// ❌ WRONG: Raw types and missing specificity
public Object processDocuments(List documents, Map context, int timeout) { // Raw types!
    // Implementation
}
```

**Applies to**: All production code, test functions. Use `void` for procedures, `Optional<T>` for nullable returns, bounded wildcards (`<? extends T>`, `<? super T>`) for API flexibility.

### Prefer `Optional` Over Nullable Returns (MANDATORY)

**RULE**: Use `Optional<T>` for return types that may have no value. Do not use `Optional` for fields, parameters, or collections.

| Instead of | Use |
|---|---|
| `return null` when nothing is found | `Optional.empty()` or `Optional.ofNullable(value)` |
| `@Nullable` return type | `Optional<T>` return type |
| Checking `result != null` at call sites | `result.ifPresent(...)` or `result.orElse(...)` |

```java
// ✅ CORRECT: Optional signals intentional absence
public Optional<User> findUser(String id) {
    User row = db.query(id);
    return Optional.ofNullable(row);
}

// ❌ AVOID: null as return value
public User findUser(String id) {
    return db.query(id); // null leaks from implementation detail
}
```

**Exceptions**: JPA entity fields, method parameters (use `@Nullable` annotations), collection return types (return empty collection instead).

### Use Records/Classes, Not Maps (MANDATORY)

**RULE**: For structured data (error contexts, configuration, structured logs), use typed records or classes instead of `Map<String, Object>`.

```java
// ✅ CORRECT: Strongly-typed record
public record LlmErrorContext(
        String llmProvider,
        String llmModel,
        @Nullable Integer httpStatusCode
) {}

var context = new LlmErrorContext("openai", "gpt-4", null);

// ❌ AVOID: Plain Map - typos undetected
Map<String, Object> context = Map.of("llmProvider", "openai", "llmModle", "gpt-4"); // Typo undetected!
```

**Use for**: Error contexts, configuration objects, structured log data, API models.
**Prefer records for**: Immutable value objects. **Prefer classes for**: Mutable state, JPA entities, complex domain models.

## Magic Number/String Prevention (MANDATORY)

**RULES**:
- ✅ **ALWAYS name numeric/string literals**: Create descriptive constants
- ❌ **NEVER use bare numbers/strings** like `0.09`, `"extraction"`, `1e-10`
- ❌ **NEVER use bare empty strings `""` or whitespace strings `" "`** — name them: `static final String CHAR_SEPARATOR = ""`
- ✅ **Calculate derived values** when logical relationship exists (`FINAL_RETRY = MAX_RETRIES - 1`)

**NOTE**: Test code has different rules — see Test Constants and Derive Expected Values in `@common-standards.md`.

```java
// ✅ CORRECT: Named constants — including empty and whitespace strings
private static final double MIN_PROGRESS_VALUE = 0.0;
private static final double MAX_PROGRESS_VALUE = 1.0;
private static final double EXTRACTION_WEIGHT = 0.09;
private static final String CHAR_SEPARATOR = "";
private static final String WORD_SEPARATOR = " ";
private static final int DEFAULT_TIMEOUT_SECONDS = 5;
private static final int EXTENDED_TIMEOUT_SECONDS = DEFAULT_TIMEOUT_SECONDS * 3;

// ❌ WRONG: Magic numbers and strings
if (value < 0.0 || value > 1.0) { throw new IllegalArgumentException("out of range"); }
return new StringBuilder(value).reverse().toString(); // bare operation without named context
```

### Enums: Prefer Over String/Integer Constants

**RULE**: When a set of related constants represents a fixed set of values, use an `enum` instead of `String` or `int` constants. Never write string literals twice.

```java
// ✅ CORRECT: Enum for fixed set of values
public enum Direction {
    NORTH, EAST, SOUTH, WEST
}

Direction dir = Direction.NORTH;

// ❌ WRONG: String constants duplicated
public static final String DIRECTION_NORTH = "north";
public static final String DIRECTION_EAST = "east";
// ...and then also checking: if (dir.equals("north")) — error prone
```

## Import Organization (MANDATORY)

**RULES**:
- ✅ **ALL imports at top**: First thing in file after the package declaration
- ✅ **Group in order**: (1) Static imports, (2) `java.*` / `javax.*`, (3) Third-party, (4) Project-internal
- ✅ **No wildcard imports**: Always import specific classes, never `import java.util.*`
- ✅ **No line-wrapping**: Import statements are not line-wrapped
- ❌ **NEVER import inside methods**: No imports inside methods or conditionals
- ❌ **No unused imports**: Remove all unused imports

```java
// ✅ CORRECT: All imports at top, properly organized

// Static imports
import static org.assertj.core.api.Assertions.assertThat;

// Java standard library
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

// Third-party libraries
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// Project-internal
import com.example.common.models.Document;
import com.example.oes.models.DocumentObligationExtraction;

// Initialize logger once at class level
private static final Logger logger = LoggerFactory.getLogger(MyClass.class);

// ❌ WRONG: Wildcard and inline imports
import java.util.*;  // Wildcard import — use specific classes
```
