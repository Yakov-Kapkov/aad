# Coding Standards

## Table of Contents

- [Type Safety and Strongly-Typed Patterns](#type-safety-and-strongly-typed-patterns)
- [Magic Number/String Prevention](#magic-numberstring-prevention)
- [Namespace and Using Directives](#namespace-and-using-directives)

## Type Safety and Strongly-Typed Patterns

### Nullable Reference Types (MANDATORY)

**RULE**: Enable nullable reference types (`<Nullable>enable</Nullable>`) in every project. Annotate all reference types as nullable or non-nullable explicitly.

**Why**: Eliminates entire classes of `NullReferenceException` at compile time.

```csharp
// ✅ CORRECT: explicit nullability
public string Name { get; init; }          // non-nullable — must be set
public string? Description { get; init; } // nullable — may be null

public string? FindById(int id) =>
    _repository.TryGetValue(id, out var item) ? item.Name : null;

// ❌ WRONG: implicit nullability — compiler cannot help
#nullable disable
public string Name { get; set; }
public string FindById(int id) => null;
```

**Applies to**: all production code. Test projects must also have nullable enabled.

### Records for Immutable Data (MANDATORY)

**RULE**: Use `record` (or `record struct`) for data-carrying types that are immutable after construction. Use `class` only when mutation or identity semantics are required.

```csharp
// ✅ CORRECT: record for immutable DTOs
public record DocumentRequest(string DocumentId, string Content);
public record ProcessingResult(bool Success, string? ErrorMessage);

// ❌ WRONG: mutable class for a value-like object
public class DocumentRequest
{
    public string DocumentId { get; set; }
    public string Content { get; set; }
}
```

**Use records for**: API request/response, domain value objects, configuration, event payloads.
**Use classes for**: Services, repositories, entities with identity, types requiring custom equality.

### Use Language Keywords, Not BCL Types (MANDATORY)

**RULE**: Use C# language keywords for built-in types. Never use the BCL type name alias.

| Use | Avoid |
|-----|-------|
| `int` | `Int32` |
| `string` | `String` |
| `bool` | `Boolean` |
| `object` | `Object` |
| `long` | `Int64` |

```csharp
// ✅ CORRECT
int employeeId;
string name;
bool isActive;

// ❌ WRONG
Int32 employeeId;
String name;
Boolean isActive;
```

### Avoid `dynamic` (MANDATORY)

**RULE**: Never use `dynamic`. Use `object`, generics, or a specific interface/record to represent unknown types.

```csharp
// ✅ CORRECT: bounded by interface or generic
public T Deserialize<T>(string json) where T : class => ...;

// ❌ WRONG: bypasses all static type checking
dynamic result = JsonConvert.DeserializeObject(json);
```

## Magic Number/String Prevention (MANDATORY)

**RULES**:
- ✅ **ALWAYS name numeric/string literals**: Create descriptive `const` or `static readonly` fields
- ❌ **NEVER use bare numbers/strings** like `0.09`, `"active"`, `1e-10`
- ❌ **NEVER use bare empty strings `""` or whitespace `" "`** — name them: `private const string CharSeparator = "";`
- ✅ **Calculate derived values** when logical relationship exists (`FinalRetry = MaxRetries - 1`)

**NOTE**: Test code has different rules — see Test Constants and Derive Expected Values in `@common-standards.md`.

```csharp
// ✅ CORRECT: named constants
private const int MinAgeYears = 18;
private const int MaxAgeYears = 60;
private const double ExtractionWeight = 0.09;
private const string CharSeparator = "";
private const string WordSeparator = " ";
private static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(5);
private static readonly TimeSpan ExtendedTimeout = DefaultTimeout * 3;

// ❌ WRONG: magic numbers and strings
if (age < 18 || age > 60)
    throw new ArgumentOutOfRangeException(nameof(age));
return string.Join("", parts);  // "" is a magic string
```

**When to use `const`**: compile-time primitives and strings.
**When to use `static readonly`**: objects, collections, `TimeSpan`, and anything requiring runtime initialisation.

## Namespace and Using Directives

### File-Scoped Namespaces (MANDATORY)

**RULE**: Use file-scoped namespace declarations. Each source file contains exactly one namespace.

```csharp
// ✅ CORRECT
namespace MyCompany.MyProject.Services;

public class OrderService { }

// ❌ WRONG: block-scoped namespace adds unnecessary nesting
namespace MyCompany.MyProject.Services
{
    public class OrderService { }
}
```

### Using Directives Outside the Namespace (MANDATORY)

**RULE**: Place all `using` directives at the top of the file, **before** the namespace declaration.

**Why**: Directives inside a namespace are context-sensitive and can silently resolve to different namespaces when dependencies change.

```csharp
// ✅ CORRECT
using Microsoft.Extensions.Logging;
using System.Text;

namespace MyCompany.MyProject.Services;

// ❌ WRONG: using inside namespace is context-sensitive
namespace MyCompany.MyProject.Services
{
    using Microsoft.Extensions.Logging;
}
```

### Using Directive Organization (MANDATORY)

**RULE**: Group `using` directives in order: (1) `System.*`, (2) `Microsoft.*`, (3) third-party, (4) local project. Sort alphabetically within each group. Remove unused directives.

```csharp
// ✅ CORRECT
using System;
using System.Collections.Generic;
using System.Threading;

using Microsoft.Extensions.Logging;

using Newtonsoft.Json;

using MyCompany.Shared.Models;
```
