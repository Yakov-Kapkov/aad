# Testing Standards

## Table of Contents

- [Import Organization](#import-organization)
- [No Environment Variable Dependencies](#no-environment-variable-dependencies)
- [Async Testing](#async-testing)
- [Test Data Creation](#test-data-creation)
- [Test Setup / Fixtures](#test-setup--fixtures)
- [Per-Test Overrides: Local Variable vs Instance Field](#per-test-overrides-local-variable-vs-instance-field)
- [Test Parameterization](#test-parameterization)
- [Mocking Best Practices](#mocking-best-practices)

## Import Organization

See **coding-standards.md § Import Organization**. The same rules
apply to test files. Key points: all imports at file top after
package declaration, no inline imports inside test methods, no
wildcard imports.

## No Environment Variable Dependencies (MANDATORY)

**RULE**: Unit tests MUST NOT fail because of missing environment variables. If the code under test reads `System.getenv()` / `System.getProperty()`, the test MUST provide values via a test setup or a mocking approach.

```java
// ✅ CORRECT: Environment variables stubbed — runs anywhere
@ExtendWith(SystemStubsExtension.class)
class ServiceClientTest {

    @SystemStub
    private EnvironmentVariables environment =
            new EnvironmentVariables("API_URL", "https://test-api", "REGION", "us");

    @Test
    void shouldUseConfiguredRegion() {
        // Arrange
        var client = new ServiceClient();

        // Act
        String endpoint = client.getEndpoint();

        // Assert
        assertThat(endpoint).contains("us");
    }
}

// ❌ WRONG: Fails when env var is missing
@Test
void shouldUseConfiguredRegion() {
    var client = new ServiceClient(); // crashes without REGION env var
}
```

**Scope:** Unit tests only. Integration tests may use real env vars (CI secrets, `.env` files).

## Async Testing (MANDATORY)

**RULE**: Use proper async test patterns for async code. Non-awaited futures cause false passes.

```java
// ✅ CORRECT: Properly await async results
@Test
void shouldProcessDocumentAsynchronously() throws Exception {
    // Arrange
    var mockClient = mock(DocumentClient.class);
    when(mockClient.process(any())).thenReturn(
            CompletableFuture.completedFuture(new Result("success")));

    // Act
    Result result = processDocumentAsync(mockClient, "test.pdf").get();

    // Assert
    assertThat(result.status()).isEqualTo("success");
}

// ❌ WRONG: Missing .get() — future not awaited
@Test
void shouldProcessDocument() {
    CompletableFuture<Result> result = processDocumentAsync(mockClient, "test.pdf"); // Not awaited!
}
```

**Requirements**: Always call `.get()`, `.join()`, or use `assertTimeout` for `CompletableFuture`. Use `@Timeout` annotation to prevent hanging tests.

## Test Data Creation (MANDATORY)

**RULE**: When creating test data that simulates database rows or API responses, use `null` for nullable fields, NOT missing keys or `Optional.empty()`.

**Why**: Database `NULL` values serialize to JSON `null`.

```java
// ✅ CORRECT: Test data simulating database/API response
var mockDatabaseRow = new FileRow("doc-001", null); // Database NULL maps to null

// ❌ WRONG: Using Optional.empty() for database/API simulation
var unrealisticRow = new FileRow("doc-001", Optional.empty()); // Databases don't return Optional
```

**When to use `null` in test data:**
- Simulating database rows with nullable columns
- Mocking API responses with optional fields
- Any test data representing deserialized JSON

**When `Optional.empty()` is acceptable:**
- Return values from methods that return `Optional<T>`
- Testing Optional-based APIs directly

## Test Setup / Fixtures (MANDATORY)

**RULE**: Extract repeated setup code into `@BeforeEach` methods or helper functions immediately.

```java
// ✅ CORRECT: Setup utilities eliminate duplication
class DocumentProcessingTest {

    private List<Document> sampleDocuments;

    @BeforeEach
    void setUp() {
        sampleDocuments = createSampleDocuments(3);
    }

    @Test
    void shouldProcessSingleDocument() {
        // Act
        Result result = process(sampleDocuments.get(0));

        // Assert
        assertThat(result.isSuccess()).isTrue();
    }

    @Test
    void shouldProcessBatch() {
        // Act
        List<Result> results = processBatch(sampleDocuments);

        // Assert
        assertThat(results).hasSize(3);
    }

    private static List<Document> createSampleDocuments(int count) {
        return IntStream.range(0, count)
                .mapToObj(i -> createDocument("doc_" + i))
                .toList();
    }
}

// ❌ WRONG: Duplicated setup
@Test
void test1() {
    var docs = List.of(createDocument("doc_0"), createDocument("doc_1")); // Duplicated
}
@Test
void test2() {
    var docs = List.of(createDocument("doc_0"), createDocument("doc_1")); // Duplicated
}
```

## Per-Test Overrides: Local Variable vs Instance Field

**RULE**: Do not reassign or mutate instance fields in a test. Declare a local variable for any input that differs from the shared setup.

```java
// ✅ preferred — self-contained, clearly shows test input
@Test
void shouldCallNextForValidPageAndPageSize() {
    var req = new MockHttpServletRequest();
    req.addParameter("page", "2");
    req.addParameter("pageSize", "50");
    handler.handle(req, response, chain);
}

// ❌ avoid — mutates shared state, forces reader to cross-reference @BeforeEach
@Test
void shouldCallNextForValidPageAndPageSize() {
    request.addParameter("page", "2");
    request.addParameter("pageSize", "50");
    handler.handle(request, response, chain);
}
```

## Test Parameterization

**RULE**: Use parameterization (`@ParameterizedTest` with `@MethodSource` or `@CsvSource`) when same Act/Assert logic, different Arrange data.

```java
// ✅ CORRECT: Parameterized
@ParameterizedTest
@CsvSource({
        "INITIALIZED, initial",
        "RESUMING, resumed"
})
void shouldHandleStatusCorrectly(FlowStatus status, String expected) {
    // Arrange
    var flow = createFlow(status);

    // Act
    Result result = flow.process();

    // Assert
    assertThat(result.getValue()).isEqualTo(expected);
}

// ❌ WRONG: Duplicate methods
@Test void testInitialized() { /* 30 lines */ }
@Test void testResuming() { /* 30 nearly identical lines */ }
```

**When to parameterize**: Same logic, different inputs | Boundary conditions
**When NOT to**: Different test logic | Single scenario

## Mocking Best Practices

| Scenario | Approach | Auto-restores? |
|---|---|---|
| Mock a dependency | `@Mock` + `@ExtendWith(MockitoExtension.class)` | Yes |
| Spy on a real object | `@Spy` or `Mockito.spy()` | Yes |
| Static method | `Mockito.mockStatic()` in try-with-resources | Yes (on close) |
| Constructor mock | `Mockito.mockConstruction()` in try-with-resources | Yes (on close) |

### Dependency mock — `@Mock` + `@InjectMocks`

```java
@ExtendWith(MockitoExtension.class)
class PipelineTest {

    @Mock
    private DocumentDownloader downloader;

    @InjectMocks
    private Pipeline pipeline;

    @Test
    void shouldProcessDocument() {
        // Arrange
        when(downloader.download("doc-1")).thenReturn(sampleDoc);

        // Act
        Result result = pipeline.process("doc-1");

        // Assert
        verify(downloader).download("doc-1");
        assertThat(result.isSuccess()).isTrue();
    }
}
```

### Static method mock — `mockStatic`

Use when mocking static utility methods. Always use try-with-resources.

```java
@Test
void shouldUseCurrentTime() {
    Instant fixedInstant = Instant.parse("2024-01-01T00:00:00Z");

    try (var mockedInstant = mockStatic(Instant.class)) {
        mockedInstant.when(Instant::now).thenReturn(fixedInstant);

        var result = service.createTimestamp();

        assertThat(result).isEqualTo(fixedInstant);
    }
    // Static mock is automatically restored here
}
```

### Per-instance behavior — separate mocks

Use when different instances need different behavior.

```java
// ✅ Separate mocks with distinct behaviors
var successStep = mock(ProcessingStep.class);
when(successStep.checkStatus()).thenReturn(new Context());

var failureStep = mock(ProcessingStep.class);
when(failureStep.checkStatus()).thenThrow(new TimeoutException("timeout"));
```