# Testing Standards

## Table of Contents

- [Test Project and File Naming (MANDATORY)](#test-project-and-file-naming-mandatory)
- [No Environment Variable Dependencies](#no-environment-variable-dependencies)
- [Async Testing](#async-testing)
- [Test Data Creation](#test-data-creation)
- [Test Setup / Fixtures](#test-setup--fixtures)
- [Per-Test Overrides: Local Variable vs Shared Field](#per-test-overrides-local-variable-vs-shared-field)
- [Test Parameterization](#test-parameterization)
- [Mocking Best Practices](#mocking-best-practices)

## Test Project and File Naming (MANDATORY)

**RULES**:
- Test project: `{ProductionProject}.Tests.csproj`
- Test class: `{ClassUnderTest}Tests` in a file named `{ClassUnderTest}Tests.cs`
- Test method: `{Method}_When{Condition}_Should{ExpectedResult}`
- Mirror the production namespace: `MyCompany.Feature` → `MyCompany.Feature.Tests`

```csharp
// ✅ CORRECT
namespace MyCompany.Orders.Tests;

public class OrderServiceTests
{
    [Fact]
    public async Task ProcessOrder_WhenInventoryAvailable_ShouldReturnSuccess() { }

    [Fact]
    public void ProcessOrder_WhenItemOutOfStock_ShouldThrowInvalidOperationException() { }
}

// ❌ WRONG: unclear naming
public class Tests
{
    [Fact]
    public void Test1() { }
}
```

## No Environment Variable Dependencies (MANDATORY)

**RULE**: Unit tests MUST NOT fail because of missing environment variables. If the code under test reads `Environment.GetEnvironmentVariable` or `IConfiguration`, the test MUST supply values via a test double or in-memory configuration.

```csharp
// ✅ CORRECT: in-memory configuration — runs anywhere
private static IConfiguration BuildConfig(Dictionary<string, string?> values) =>
    new ConfigurationBuilder().AddInMemoryCollection(values).Build();

[Fact]
public void Client_WhenRegionConfigured_ShouldUseRegionInEndpoint()
{
    // Arrange
    IConfiguration config = BuildConfig(new() { ["Region"] = "us-east" });
    var client = new ServiceClient(config);

    // Act
    string endpoint = client.Endpoint;

    // Assert
    Assert.Contains("us-east", endpoint);
}

// ❌ WRONG: fails when $env:Region is absent
[Fact]
public void Client_ShouldUseRegionInEndpoint()
{
    var client = new ServiceClient();  // reads Environment.GetEnvironmentVariable internally
}
```

**Scope:** Unit tests only. Integration tests may use real environment configuration (CI secrets, `appsettings.Test.json`).

## Async Testing (MANDATORY)

**RULE**: Async tests MUST return `Task`, never `void`. Un-awaited calls cause false passes.

```csharp
// ✅ CORRECT
[Fact]
public async Task ProcessDocument_WhenValid_ShouldReturnSuccess()
{
    // Arrange
    var mockClient = new Mock<IDocumentClient>();
    mockClient.Setup(c => c.FetchAsync(It.IsAny<string>(), default))
              .ReturnsAsync(new DocumentResponse("content"));

    // Act
    var result = await _service.ProcessDocumentAsync("doc-1");

    // Assert
    Assert.True(result.Success);
}

// ❌ WRONG: async void — exceptions are unobserved, test may pass silently
[Fact]
public async void ProcessDocument_WhenValid_ShouldReturnSuccess()
{
    var result = _service.ProcessDocumentAsync("doc-1");  // Missing await!
}
```

**Requirements**: `async Task` return type, `await` every async call, `ReturnsAsync` / `ThrowsAsync` for async mocks (Moq).

## Test Data Creation (MANDATORY)

**RULE**: When creating test data that simulates database rows or API responses, use `null` for nullable fields — never omit them.

**Why**: Database `NULL` values map to C# `null`. Omitting a field creates an object different from what the real system would return.

```csharp
// ✅ CORRECT: null for nullable fields
var row = new OrderRow
{
    OrderId = "order-001",
    ParentOrderId = null,   // DB NULL maps to null
    Status = "Pending",
};

// ❌ WRONG: relying on default initialisation to omit nullable columns
var row = new OrderRow { OrderId = "order-001", Status = "Pending" };
// ParentOrderId missing — default is null here by accident, not intent
```

## Test Setup / Fixtures (MANDATORY)

**RULE**: Extract repeated setup into the constructor (xUnit), `[SetUp]` (NUnit), or `TestInitialize` (MSTest). Share expensive fixtures via `IClassFixture<T>` (xUnit).

```csharp
// ✅ CORRECT: shared setup in constructor
public class OrderServiceTests
{
    private readonly OrderService _sut;
    private readonly Mock<IOrderRepository> _repository;

    public OrderServiceTests()
    {
        _repository = new Mock<IOrderRepository>();
        _sut = new OrderService(_repository.Object);
    }

    [Fact]
    public async Task GetOrder_WhenExists_ShouldReturnOrder() { ... }

    [Fact]
    public async Task GetOrder_WhenMissing_ShouldReturnNull() { ... }
}

// ❌ WRONG: duplicated setup in every test
[Fact]
public async Task Test1()
{
    var repo = new Mock<IOrderRepository>();
    var sut = new OrderService(repo.Object);  // Duplicated
    ...
}
```

## Per-Test Overrides: Local Variable vs Shared Field (MANDATORY)

**RULE**: Do not mutate shared fields inside a test. Declare a local variable for any input that differs from the shared constructor setup.

```csharp
// ✅ CORRECT: local variable — self-contained, clearly shows test input
[Fact]
public async Task ProcessOrder_WhenPageSizeIsLarge_ShouldReturnAllItems()
{
    var query = new OrderQuery(Page: 2, PageSize: 100);
    var result = await _sut.GetOrdersAsync(query);
    Assert.Equal(100, result.PageSize);
}

// ❌ WRONG: mutates shared field — forces reader to cross-reference setup
[Fact]
public async Task ProcessOrder_WhenPageSizeIsLarge_ShouldReturnAllItems()
{
    _query.PageSize = 100;  // side-effects shared state
    var result = await _sut.GetOrdersAsync(_query);
}
```

## Test Parameterization

**RULE**: Use `[Theory]` with `[InlineData]`, `[MemberData]`, or `[ClassData]` when the same Act/Assert logic runs with different Arrange data.

```csharp
// ✅ CORRECT: parameterized
[Theory]
[InlineData(OrderStatus.Pending,   "pending")]
[InlineData(OrderStatus.Confirmed, "confirmed")]
[InlineData(OrderStatus.Cancelled, "cancelled")]
public void MapStatus_ShouldReturnExpectedLabel(OrderStatus status, string expected)
{
    var result = OrderMapper.MapStatus(status);
    Assert.Equal(expected, result);
}

// ❌ WRONG: duplicate methods
[Fact] public void MapStatus_Pending_ShouldReturnPending() { ... }   // 20 lines
[Fact] public void MapStatus_Confirmed_ShouldReturnConfirmed() { ... }  // 20 nearly identical lines
```

**When to parameterize**: Same logic, different inputs | Boundary conditions.
**When NOT to**: Different test logic | Single scenario.

## Mocking Best Practices

| Scenario | Approach | Auto-restores? |
|---|---|---|
| Mock a dependency injected via constructor | `Mock<T>` (Moq) passed via constructor | Per-test instance |
| Verify a method was called | `mock.Verify(...)` after Act | Manual |
| Throw from a mock | `mock.Setup(...).ThrowsAsync(new ...)` | Per-test instance |
| Mock static/extension methods | `Mock<T>` is insufficient — restructure to inject an interface | N/A |

### Constructor injection mock — Moq

```csharp
// ✅ CORRECT
var mockRepo = new Mock<IOrderRepository>();
mockRepo.Setup(r => r.GetByIdAsync("order-1", default))
        .ReturnsAsync(new Order("order-1", "Pending"));

var sut = new OrderService(mockRepo.Object);
var result = await sut.GetOrderAsync("order-1");

mockRepo.Verify(r => r.GetByIdAsync("order-1", default), Times.Once);
```

### Avoid mocking what you don't own

```csharp
// ❌ WRONG: mocking a BCL type — brittle, signals wrong abstraction
var mockList = new Mock<IList<string>>();

// ✅ CORRECT: use a real in-memory object
var list = new List<string> { "a", "b" };
```
