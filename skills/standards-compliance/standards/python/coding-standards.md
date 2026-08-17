# Coding Standards

## Table of Contents

- [Type Safety and Strongly-Typed Patterns](#type-safety-and-strongly-typed-patterns)
- [Magic Number/String Prevention](#magic-numberstring-prevention)
- [Import Organization](#import-organization)

## Type Safety and Strongly-Typed Patterns

### Data Models: Use Pydantic (MANDATORY)

**RULE**: Use Pydantic BaseModel for ALL data models, API models, and configuration objects.

**Why**: Runtime validation, type conversion, JSON serialization, environment parsing, IDE autocomplete.

```python
from pydantic import BaseModel, Field, field_validator

# ✅ CORRECT: Pydantic for API models
class DocumentRequest(BaseModel):
    document_id: str = Field(..., description="Unique identifier")
    content: str = Field(..., min_length=1)
    
    @field_validator('document_id')
    @classmethod
    def validate_id(cls, v: str) -> str:
        return v.strip()

# ❌ WRONG: Plain dict - no validation
request_data = {"document_id": "123", "conent": "text"}  # Typo undetected!
```

**Use Pydantic for**: API request/response, configuration (`BaseSettings`), LLM JSON parsing, domain models.
**Use dataclasses for**: Simple internal structures, error contexts, performance-critical paths.

### Type Annotations (MANDATORY)

**RULE**: EVERY function/method parameter and return type MUST have a type annotation. NEVER use `Any` type. Zero exceptions.

```python
# ✅ CORRECT
def process_documents(documents: list[Document], timeout: int = 30) -> ProcessingResult:
    pass

@pytest.mark.asyncio
async def test_process(sample_docs: list[Document]) -> None:
    pass

# ❌ WRONG: Missing annotations
def process_documents(documents, timeout=30):  # Missing all type hints
    pass
```

**Applies to**: All production code, test functions, fixtures, lambdas (where possible). Use `-> None` for procedures, `object` instead of `Any`.

### Use Dataclasses, Not Dictionaries (MANDATORY)

**RULE**: Use typed dataclasses for structured data (error contexts, configs, structured logs).

**Why**: Dictionary typos cause runtime failures. Dataclasses validated by mypy at dev time. IDE autocomplete works.

```python
from dataclasses import dataclass, asdict

# ✅ CORRECT
@dataclass
class LlmErrorContext:
    llm_provider: str
    llm_model: str
    http_status_code: Optional[int] = None
    
    def to_dict(self) -> dict:
        return {k: v for k, v in asdict(self).items() if v is not None}

context = LlmErrorContext(llm_provider="openai", llm_model="gpt-4")

# ❌ WRONG: Dict with string keys
context = {"llm_provider": "openai", "llm_modle": "gpt-4"}  # Typo undetected!
```

**Use for**: Error contexts, configs, structured logs  
**Don't use for**: Simple 2-3 field dicts, dynamic keys, external data (use Pydantic)

## Magic Number/String Prevention (MANDATORY)

**RULES**:
- ✅ **ALWAYS name numeric/string literals**: Create descriptive constants
- ❌ **NEVER use bare numbers/strings** like `0.09`, `"extraction"`, `1e-10`
- ❌ **NEVER use bare empty strings `''` or whitespace strings `' '`** — name them: `CHAR_SEPARATOR = ''`
- ✅ **Calculate derived values** when logical relationship exists (`FINAL_RETRY = MAX_RETRIES - 1`)

**NOTE**: Test code has different rules — see Test Constants and Derive Expected Values in `@common-standards.md`.

```python
# ✅ CORRECT: Named constants — including empty and whitespace strings
MIN_PROGRESS_VALUE = 0.0
MAX_PROGRESS_VALUE = 1.0
EXTRACTION_WEIGHT = 0.09
CHAR_SEPARATOR = ''
WORD_SEPARATOR = ' '
DEFAULT_TIMEOUT_SECONDS = 5
EXTENDED_TIMEOUT_SECONDS = DEFAULT_TIMEOUT_SECONDS * 3

# ❌ WRONG: Magic numbers and strings
if not (0.0 <= value <= 1.0):
    raise ValueError("Value must be between 0.0 and 1.0")
return ''.join(reversed(value))  # '' is a magic string
```

## Import Organization (MANDATORY)

**RULES**:
- ✅ **ALL imports at top**: First thing in file, before any other code
- ✅ **Group in order**: (1) Standard library, (2) Third-party, (3) Local
- ✅ **One import per line**: Exception — multiple items from same module OK
- ❌ **NEVER import inside functions**: No imports inside functions, methods, or conditionals
- ❌ **No conditional imports**: Exception — optional dependencies or platform-specific

```python
# ✅ CORRECT
"""Module docstring."""

# Standard library
from typing import List
from uuid import UUID

# Third-party
from pydantic import BaseModel
import structlog

# Local
from common.models import Document

logger = structlog.get_logger(__name__)  # Module-level

class Pipeline:
    async def process(self):
        try:
            logger.info("Processing")
        except Exception as e:
            logger.error(f"Error: {e}", exc_info=True)
            raise

# ❌ WRONG: Inline imports
def process_data():
    import json  # Should be at top
    import structlog  # Should be at top
```
