# Coding Standards

## Table of Contents

- [Type Safety and Strongly-Typed Patterns](#type-safety-and-strongly-typed-patterns)
- [Magic Number/String Prevention](#magic-numberstring-prevention)
- [Import Organization](#import-organization)

## Type Safety and Strongly-Typed Patterns

### Data Models: Use Zod or TypeScript Interfaces (MANDATORY)

**RULE**: For ALL data models, API models, and configuration objects, use Zod schemas for runtime validation or TypeScript interfaces for compile-time checking.

**Note on null vs undefined**: For database/API models, use `| null` for nullable fields rather than optional properties (`?`). Database `NULL` and API `null` map to TypeScript `null`, not `undefined`. See `@testing-standards.md` for test data guidance.

```typescript
import { z } from 'zod';

// ✅ CORRECT: Zod for API models with runtime validation
const DocumentResponseSchema = z.object({
  documentId: z.string(),
  status: z.string(),
  result: z.record(z.unknown()).nullable(),
});
type DocumentResponse = z.infer<typeof DocumentResponseSchema>;
const response = DocumentResponseSchema.parse(JSON.parse(jsonString));

// ❌ WRONG: Plain object - no validation, typos undetected
const requestData = { documentId: "123", conent: "text" };  // Typo undetected!
```

**When to use Zod**: API request/response, parsing external data, configuration with env vars, complex domain models requiring runtime validation.
**When to use interfaces**: Internal data structures, simple DTOs, type definitions without runtime validation.

### Type Annotations (MANDATORY)

**RULE**: EVERY function/method parameter and return type MUST have a type annotation. NEVER use `any` type. Zero exceptions.

```typescript
// ✅ CORRECT: All parameters and return types annotated
function processDocuments(
  documents: Document[],
  context: ProcessingContext,
  timeout: number = 30
): ProcessingResult {
  // Implementation
}

// ❌ WRONG: Missing type annotations
function processDocuments(documents, context, timeout = 30) {  // Missing all types
  // Implementation
}
```

**Applies to**: All production code, test functions, arrow functions. Use `: void` for procedures, `unknown` instead of `any`.

### Prefer Specific Types Over `undefined` (MANDATORY)

**RULE**: Do not use `undefined` in types when a more specific alternative exists.

| Instead of | Use |
|---|---|
| `return undefined` when nothing is found | Return type with `\| null` (explicit absence) or throw |
| Optional parameter `param?: T` | Default value `param: T = defaultValue` when a sensible default exists |
| `T \| undefined` in a return type | `T \| null` for intentional absence (matches DB/API semantics) |
| `undefined` as an initial value | `null` as the explicit "not yet set" value |

```typescript
// ✅ CORRECT: null signals intentional absence
function findUser(id: string): User | null {
  const row = db.query(id);
  return row ?? null;
}

// ❌ AVOID: undefined as return value
function findUser(id: string): User | undefined {
  return db.query(id);  // undefined leaks from implementation detail
}
```

**Exceptions**: Object properties using `?` syntax, destructured values from external APIs, Map/Array `.get()` / `.find()` results.

### Use Interfaces/Types, Not Plain Objects (MANDATORY)

**RULE**: For structured data (error contexts, configuration, structured logs), use typed interfaces or types instead of plain objects.

```typescript
// ✅ CORRECT: Strongly-typed interface
interface LlmErrorContext {
  llmProvider: string;
  llmModel: string;
  httpStatusCode?: number;
}

const context: LlmErrorContext = createErrorContext('openai', 'gpt-4');

// ❌ AVOID: Plain object - typos undetected
const context = { llmProvider: "openai", llmModle: "gpt-4" };  // Typo undetected!
```

**Use for**: Error contexts, configuration objects, structured log data, API models.
**Prefer interfaces over types for**: Object shapes. **Prefer types for**: Unions, intersections, mapped types.

## Magic Number/String Prevention (MANDATORY)

**RULES**:
- ✅ **ALWAYS name numeric/string literals**: Create descriptive constants
- ❌ **NEVER use bare numbers/strings** like `0.09`, `"extraction"`, `1e-10`
- ❌ **NEVER use bare empty strings `''` or whitespace strings `' '`** — name them: `const CHAR_SEPARATOR = ''`
- ✅ **Calculate derived values** when logical relationship exists (`FINAL_RETRY = MAX_RETRIES - 1`)

**NOTE**: Test code has different rules — see Test Constants and Derive Expected Values in `@common-standards.md`.

```typescript
// ✅ CORRECT: Named constants — including empty and whitespace strings
const MIN_PROGRESS_VALUE = 0.0;
const MAX_PROGRESS_VALUE = 1.0;
const EXTRACTION_WEIGHT = 0.09;
const CHAR_SEPARATOR = '';
const WORD_SEPARATOR = ' ';
const DEFAULT_TIMEOUT_SECONDS = 5;
const EXTENDED_TIMEOUT_SECONDS = DEFAULT_TIMEOUT_SECONDS * 3;

// ❌ WRONG: Magic numbers and strings
if (value < 0.0 || value > 1.0) { throw new Error("out of range"); }
return value.split('').reverse().join('');   // '' is a magic string
```

### Union Types: Derive From Constants

**RULE**: When a union type corresponds to named string/number constants, group them into a single `as const` object and derive the type. Never write string literals twice.

```typescript
// ✅ CORRECT: const object + derived type
export const DIRECTIONS = {
  NORTH: 'north',
  EAST:  'east',
  SOUTH: 'south',
  WEST:  'west',
} as const;

export type Direction = (typeof DIRECTIONS)[keyof typeof DIRECTIONS];
const dir: Direction = DIRECTIONS.NORTH;

// ❌ WRONG: string literals duplicated in both object and type
export type Direction = 'north' | 'east' | 'south' | 'west';
export const DIRECTIONS = { NORTH: 'north', ... } as const;
```

## Import Organization (MANDATORY)

**RULES**:
- ✅ **ALL imports at the top**: First thing in file, before any other code
- ✅ **Group in order**: (1) External libraries, (2) Internal modules, (3) Types
- ✅ **One import per line**: Exception — multiple items from same module OK
- ❌ **NEVER import inside functions**: No imports inside functions, methods, or conditionals
- ❌ **No conditional imports**: Exception — dynamic imports for code splitting

```typescript
// ✅ CORRECT: All imports at top, properly organized

// External library imports
import { z } from 'zod';
import structlog from 'structlog';

// Internal module imports
import { Document } from '@/common/models';
import { DocumentObligationExtraction } from '@/oes-skill/models';

// Type imports
import type { ProcessingContext, ProcessingResult } from '@/types';

// Initialize logger once at module level
const logger = structlog.getLogger();

// ❌ WRONG: Inline imports
function processData(): void {
  const structlog = require('structlog');  // Should be at top of file
}
```
