# Code Style and Documentation

## Table of Contents

- [Naming Conventions](#naming-conventions)
- [Layout and Formatting](#layout-and-formatting)
- [String Formatting](#string-formatting)
- [File-Level Documentation](#file-level-documentation)
- [API Documentation Standards](#api-documentation-standards)

## Naming Conventions (MANDATORY)

| Symbol | Convention | Example |
|--------|-----------|---------|
| Class, record, struct, enum | PascalCase | `OrderService`, `OrderStatus` |
| Interface | `I` + PascalCase | `IOrderService` |
| Public method, property, event | PascalCase | `GetOrderAsync`, `OrderId` |
| Local variable, parameter | camelCase | `orderId`, `isActive` |
| Private field | _camelCase | `_orderRepository` |
| Constant (`const` / `static readonly`) | PascalCase | `MaxRetryCount`, `DefaultTimeout` |
| Enum member | PascalCase | `OrderStatus.Confirmed` |
| Generic type parameter | `T` or `T` + descriptor | `T`, `TResult`, `TKey` |

```csharp
// ✅ CORRECT
public class OrderService
{
    private readonly IOrderRepository _orderRepository;
    private const int MaxRetryCount = 3;

    public async Task<Order?> GetOrderAsync(string orderId) { }
}

// ❌ WRONG: missing underscore on field, wrong casing elsewhere
public class orderService
{
    private readonly IOrderRepository orderRepository;  // missing underscore prefix
    private const int MAX_RETRY_COUNT = 3;              // PascalCase, not UPPER_SNAKE

    public async Task<Order?> getOrderAsync(string OrderId) { }
}
```

**Note**: Do not use underscores in identifiers except:
- Private instance fields (`_camelCase`)
- Test method names (`Method_WhenCondition_ShouldResult`)

## Layout and Formatting (MANDATORY)

- **Indent**: 4 spaces. No tabs.
- **Braces**: Allman style — opening brace on its own line, aligned with the enclosing keyword.
- **One statement per line.** One declaration per line.
- **Blank line** between method/property definitions.
- **Line length**: aim for ≤120 characters; break before binary operators when wrapping.
- **Parentheses**: use to make sub-expression grouping explicit in complex conditionals.

```csharp
// ✅ CORRECT: Allman braces, 4-space indent
public class OrderProcessor
{
    public void Process(Order order)
    {
        if ((order.Status == OrderStatus.Pending) && (order.Total > 0))
        {
            Submit(order);
        }
    }
}

// ❌ WRONG: K&R style, mixed indent, missing blank lines
public class OrderProcessor {
  public void Process(Order order) {
    if (order.Status == OrderStatus.Pending && order.Total > 0) { Submit(order); } } }
```

### `var` Usage

Use `var` only when the type is **obvious** from the right-hand side of the assignment.

```csharp
// ✅ CORRECT: type is obvious (new keyword, cast, literal)
var order = new Order("order-1");
var items = new List<OrderItem>();

// ✅ CORRECT: explicit type when not obvious
OrderSummary summary = GetSummary(orderId);
int count = Convert.ToInt32(Console.ReadLine());

// ❌ WRONG: type is not apparent from expression
var result = ProcessOrder(order);
```

**Test code exception**: `var` is acceptable for local assertion variables in tests when the variable is immediately used in an `Assert` call and the method name makes the type evident (e.g., `var result = await sut.GetOrderAsync(...)`). All other test variables follow the same rule.

### `using` Statement for Disposable Types (MANDATORY)

Use the declaration form of `using` for `IDisposable` resources. Prefer the brace-free form (C# 8+).

```csharp
// ✅ CORRECT: brace-free using declaration
using var connection = new SqlConnection(connectionString);
using var reader = command.ExecuteReader();

// ❌ WRONG: try/finally with manual Dispose
SqlConnection connection = new SqlConnection(connectionString);
try
{
    // use connection
}
finally
{
    connection?.Dispose();
}
```

### Short-Circuit Operators (MANDATORY)

Use `&&` and `||` (short-circuit) instead of `&` and `|` for boolean expressions.

```csharp
// ✅ CORRECT: short-circuits — avoids NullReferenceException
if ((order != null) && (order.Total > 0)) { }

// ❌ WRONG: & evaluates both sides regardless
if ((order != null) & (order.Total > 0)) { }
```

## String Formatting (MANDATORY)

**RULE**: Wrap variable values in single quotes in error, log, and user-facing messages.

**Why**: Makes variable boundaries visible, especially for IDs, file paths, and values with spaces.

```csharp
// ✅ CORRECT
throw new InvalidOperationException($"Order '{orderId}' not found.");
throw new ArgumentException($"File '{filePath}' does not exist.");
logger.LogError("Failed to process order. orderId={OrderId}", orderId);  // Structured logging — no extra quotes in value

// ❌ WRONG
throw new InvalidOperationException($"Order {orderId} not found.");
logger.LogError("Failed to process order. orderId='{OrderId}'", orderId);  // Don't add quotes in structured log values
```

## File-Level Documentation

**Do not add file-level block comments.** Documentation comments apply to types and members — not to files. Each C# source file should contain exactly one top-level type; the type's XML doc serves as the file's documentation.

## API Documentation Standards (MANDATORY)

**All public types, methods, and properties must have XML documentation comments.**

Every XML doc must include:
1. `<summary>` — one-sentence description
2. `<remarks>` — fuller explanation of behaviour or design intent (mandatory for types; use for methods when the summary alone is insufficient)

Additional tags as applicable: `<param>`, `<returns>`, `<exception>`, `<example>`.

**Document the symbol itself** — describe what *this* type/method does, not where it is called from.

```csharp
// ✅ CORRECT
/// <summary>Factory and cache for <see cref="SnowflakeService"/> instances.</summary>
/// <remarks>
/// Maintains a dictionary keyed by <see cref="SnowflakeType"/>. On first call for a
/// given type, creates the service from the matching config provider and caches it.
/// Subsequent calls return the cached instance.
/// </remarks>
public class SnowflakeServiceProvider { }

/// <summary>Extracts obligations from a document by ID.</summary>
/// <remarks>
/// Validates the document ID, retrieves content from storage, runs the extraction
/// pipeline, and returns a structured result.
/// </remarks>
/// <param name="documentId">Unique identifier for the document.</param>
/// <param name="content">Raw document content to process.</param>
/// <param name="options">Optional processing configuration.</param>
/// <returns>Processing result with extracted obligations.</returns>
/// <exception cref="DocumentNotFoundException">Thrown when the document does not exist.</exception>
public async Task<ProcessingResult> ProcessDocumentAsync(
    string documentId,
    string content,
    ProcessingOptions? options = null) { }

// ❌ WRONG: restates the method name, no useful information
/// <summary>Processes the document.</summary>
public async Task<ProcessingResult> ProcessDocumentAsync(...) { }
```

### Comment Style

- Use `//` for single-line inline explanations. Begin with an uppercase letter and end with a period.
- Avoid `/* */` block comments — use XML docs for public API and `//` for inline notes.
- Place comments on a separate line above the code they describe; not at the end of a line.

```csharp
// ✅ CORRECT: explains non-obvious reason
// ConfigureAwait(false) prevents deadlock in synchronization-context-bound callers.
var result = await _service.FetchAsync(id).ConfigureAwait(false);

// ❌ WRONG: restates the code
// Fetch the result from service.
var result = await _service.FetchAsync(id);
```
