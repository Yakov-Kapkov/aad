# Testing Standards

## Table of Contents

- [Import Organization](#import-organization)
- [No Environment Variable Dependencies](#no-environment-variable-dependencies)
- [Async Testing](#async-testing)
- [Test Data Creation](#test-data-creation)
- [Test Setup / Fixtures](#test-setup--fixtures)
- [Per-Test Overrides: Local Variable vs Shared Fixture](#per-test-overrides-local-variable-vs-shared-fixture)
- [Test Parameterization](#test-parameterization)
- [Mocking Best Practices](#mocking-best-practices)

## Import Organization (MANDATORY)

**RULE**: Use absolute imports for production code, relative imports for test utilities.

```python
# ✅ CORRECT
from skills_sdk.flow_storage import InMemoryStorage  # Production - absolute
from .common_flows import InputModel  # Test utility - relative

# ❌ WRONG
from tests.unit.common_flows import InputModel  # Should be relative
from ...skills_sdk.flow_storage import InMemoryStorage  # Should be absolute
```

## No Environment Variable Dependencies (MANDATORY)

**RULE**: Unit tests MUST NOT fail because of missing environment variables. If the code under test reads `os.environ` / `os.getenv()`, the test MUST provide values via `monkeypatch.setenv()` or a `conftest.py` fixture.

```python
# ✅ CORRECT: fixture provides env — runs anywhere
@pytest.fixture
def _env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("API_URL", "https://test-api")
    monkeypatch.setenv("REGION", "us")

def test_client_uses_region(self, _env: None) -> None:
    # Arrange
    client = ServiceClient()

    # Act
    result = client.endpoint

    # Assert
    assert "us" in result

# ❌ WRONG: KeyError when env var is missing
def test_client_uses_region(self) -> None:
    client = ServiceClient()  # crashes without $env:REGION
```

**Scope:** Unit tests only. Integration tests may use real env vars (CI secrets, `.env` files).

## Async Testing (MANDATORY)

**RULE**: Use `async`/`await` for async tests. Un-awaited calls cause false passes.

```python
# ✅ CORRECT
@pytest.mark.asyncio
async def test_async_processing() -> None:
    mock_client = AsyncMock()
    result = await process_async(mock_client, "test.pdf")
    assert result.success

# ❌ WRONG: Missing async
def test_async_processing() -> None:
    result = process_async(mock_client)  # Missing await!
```

**Requirements**: Use `@pytest.mark.asyncio`, `async def`, `await`, `AsyncMock` (not `Mock`)

## Test Data Creation (MANDATORY)

**RULE**: When creating test data that simulates database rows or API responses, use `None` for nullable fields, NOT missing keys.

**Why**: Database `NULL` values serialize to JSON `null`.

```python
# ✅ CORRECT: Test data simulating database/API response
mock_database_row = {
    "DOC_ID": "doc-001",
    "PARENT": None,           # Database NULL maps to None
}

# ❌ WRONG: Omitting the key entirely
mock_database_row = {
    "DOC_ID": "doc-001",
    # PARENT missing — databases don't omit columns
}
```

**When to use `None` in test data:**
- Simulating database rows with nullable columns
- Mocking API responses with optional fields
- Any test data representing deserialized JSON

## Test Setup / Fixtures (MANDATORY)

**RULE**: Extract repeated setup code into fixtures or helper functions immediately.

```python
# ✅ CORRECT: Fixture eliminates duplication
@pytest.fixture
def sample_documents() -> list[Document]:
    return [create_document(f"doc_{i}") for i in range(3)]

def test_single(sample_documents: list[Document]) -> None:
    result = process(sample_documents[0])
    assert result.success

def test_batch(sample_documents: list[Document]) -> None:
    results = process_batch(sample_documents)
    assert len(results) == 3

# ❌ WRONG: Duplicated setup
def test_single() -> None:
    sample_documents = [create_document(f"doc_{i}") for i in range(3)]  # Duplicated
    result = process(sample_documents[0])

def test_batch() -> None:
    sample_documents = [create_document(f"doc_{i}") for i in range(3)]  # Duplicated
```

## Per-Test Overrides: Local Variable vs Shared Fixture

**RULE**: Do not reassign or mutate shared fixture values in a test. Declare a local variable for any input that differs from the shared setup.

```python
# ✅ preferred — self-contained, clearly shows test input
def test_valid_page_and_page_size() -> None:
    params = {"page": "2", "page_size": "50"}
    result = handler(params, response, next_fn)

# ❌ avoid — mutates shared state, forces reader to cross-reference fixture
def test_valid_page_and_page_size(params: dict[str, str]) -> None:
    params["page"] = "2"
    params["page_size"] = "50"
    result = handler(params, response, next_fn)
```

## Test Parameterization

**RULE**: Use parameterization (`@pytest.mark.parametrize`) when same Act/Assert logic, different Arrange data.

```python
# ✅ CORRECT: Parameterized
@pytest.mark.parametrize("status,expected", [
    (FlowStatus.INITIALIZED, "initial"),
    (FlowStatus.RESUMING, "resumed"),
], ids=["initialized", "resuming"])
def test_flow_behavior(status, expected):
    # Single test covers multiple scenarios

# ❌ WRONG: Duplicate methods
def test_initialized_flow(): ...  # 30 lines
def test_resuming_flow(): ...     # 30 nearly identical lines
```

**When to parameterize**: Same logic, different inputs | Boundary conditions
**When NOT to**: Different test logic | Single scenario

## Mocking Best Practices

| Scenario | Approach | Auto-restores? |
|---|---|---|
| All instances share one mock | `patch.object` (context manager or decorator) | Yes |
| Different behavior per instance | `object.__setattr__` on each instance | No (fresh objects per test) |
| Module-level function or constant | `@patch("module.name")` | Yes |

### Shared mock — `patch.object`

```python
with patch.object(downloader, 'download_document',
                  new_callable=AsyncMock, return_value=sample_doc) as mock_dl:
    result = await pipeline.process()
    mock_dl.assert_called_once()
```

### Per-instance mock — `object.__setattr__`

Use when different instances need different behavior. Bypasses
Pydantic / ORM `__setattr__` overrides.

```python
object.__setattr__(step0, "check_status", AsyncMock(return_value=Context()))
object.__setattr__(step1, "check_status", AsyncMock(
    side_effect=lambda **kw: setattr(step1, "progress", 0.25) or Context()
))

# ❌ WRONG: Plain assignment on a Pydantic model — may raise
step1.check_status = AsyncMock()
```