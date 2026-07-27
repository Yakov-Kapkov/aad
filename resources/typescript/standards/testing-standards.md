# Testing Standards

## Table of Contents

- [Import Organization](#import-organization)
- [No Environment Variable Dependencies](#no-environment-variable-dependencies)
- [Async Testing](#async-testing)
- [Test Data Creation](#test-data-creation)
- [Test Setup / Fixtures](#test-setup--fixtures)
- [Per-Test Overrides: Local `const` vs Outer `let`](#per-test-overrides-local-const-vs-outer-let)
- [Test Parameterization](#test-parameterization)
- [Mocking Best Practices](#mocking-best-practices)

## Import Organization (MANDATORY)

**RULE**: Use absolute imports for production code, relative imports for test utilities.

```typescript
// ✅ CORRECT
import { describe, it, expect, vi } from 'vitest';
import { FlowStorage } from '@/flow-storage/flow-storage';  // Production - absolute
import { createTestFlow } from './common-flows';  // Test utility - relative

// ❌ WRONG
import { createTestFlow } from '@/tests/unit/common-flows';  // Should be relative
import { FlowStorage } from '../../../src/flow-storage';     // Should be absolute
```

## No Environment Variable Dependencies (MANDATORY)

**RULE**: Unit tests MUST NOT fail because of missing environment variables. If the code under test reads `process.env`, the test MUST provide values via `vi.stubEnv()` or a `beforeEach` block.

```typescript
// ✅ CORRECT: stubbed env — runs anywhere
beforeEach(() => {
  vi.stubEnv('API_URL', 'https://test-api');
  vi.stubEnv('REGION', 'us');
});
afterEach(() => vi.unstubAllEnvs());

it('should use configured region', () => {
  // Arrange
  const client = new ServiceClient();

  // Act
  const endpoint = client.endpoint;

  // Assert
  expect(endpoint).toContain('us');
});

// ❌ WRONG: undefined when env var is missing
it('should use configured region', () => {
  const client = new ServiceClient();  // crashes without $env:REGION
});
```

**Scope:** Unit tests only. Integration tests may use real env vars (CI secrets, `.env` files).

## Async Testing (MANDATORY)

**RULE**: Use `async`/`await` for async tests. Un-awaited calls cause false passes.

```typescript
// ✅ CORRECT
it('should process document asynchronously', async (): Promise<void> => {
  const mockClient = {
    process: vi.fn().mockResolvedValue({ status: 'success' }),
  };
  const result = await processDocumentAsync(mockClient, 'test.pdf');
  expect(result.status).toBe('success');
});

// ❌ WRONG: Missing async/await
it('should process document', () => {
  const result = processDocumentAsync(mockClient, 'test.pdf');  // Missing await!
});
```

**Requirements**: `async` + `Promise<void>`, `await` every async call, `mockResolvedValue()` / `mockRejectedValue()` for async mocks.

## Test Data Creation (MANDATORY)

**RULE**: When creating test data that simulates database rows or API responses, use `null` for nullable fields, NOT `undefined`.

**Why**: Database `NULL` values serialize to JSON `null`.

```typescript
// ✅ CORRECT: Test data simulating database/API response
const mockDatabaseRow: FileRow = {
  DOC_ID: 'doc-001',
  PARENT: null,           // Database NULL maps to null
};

// ❌ WRONG: Using undefined for database/API simulation
const unrealisticRow: FileRow = {
  DOC_ID: 'doc-001',
  PARENT: undefined,      // Databases, APIs don't return undefined
};
```

**When to use `null` in test data:**
- Simulating database rows with nullable columns
- Mocking API responses with optional fields
- Any test data representing deserialized JSON

**When `undefined` is acceptable:**
- Optional parameters in function calls: `processData(doc, undefined)`
- Missing object properties in pure TypeScript objects

## Test Setup / Fixtures (MANDATORY)

**RULE**: Extract repeated setup code into fixtures or helper functions immediately.

```typescript
// ✅ CORRECT: Setup utilities eliminate duplication
function createSampleDocuments(count: number = 3): Document[] {
  return Array.from({ length: count }, (_, i) => createDocument(`doc_${i}`));
}

describe('DocumentProcessing', () => {
  let sampleDocuments: Document[];

  beforeEach((): void => {
    sampleDocuments = createSampleDocuments();
  });

  it('should process single document', (): void => {
    const result = process(sampleDocuments[0]);
    expect(result.success).toBe(true);
  });

  it('should process batch', (): void => {
    const results = processBatch(sampleDocuments);
    expect(results).toHaveLength(3);
  });
});

// ❌ WRONG: Duplicated setup
it('test1', () => {
  const docs = [createDocument('doc_0'), createDocument('doc_1')];  // Duplicated
});
it('test2', () => {
  const docs = [createDocument('doc_0'), createDocument('doc_1')];  // Duplicated
});
```

## Per-Test Overrides: Local `const` vs Outer `let`

**RULE**: Do not reassign outer `let` variables in a test. Declare a local `const` for any input that differs from the shared setup.

```typescript
// ✅ preferred — self-contained, clearly shows test input
it('should call next for valid page and pageSize', async () => {
  const req: Partial<express.Request> = { query: { page: '2', pageSize: '50' } };
  await handler(req as express.Request, res as express.Response, next);
});

// ❌ avoid — mutates shared state, forces reader to cross-reference beforeEach
it('should call next for valid page and pageSize', async () => {
  req = { query: { page: '2', pageSize: '50' } };
  await handler(req as express.Request, res as express.Response, next);
});
```

## Test Parameterization

**RULE**: Use parameterization (`it.each` or `describe.each`) when same Act/Assert logic, different Arrange data.

```typescript
// ✅ CORRECT: Parameterized
it.each([
  { status: FlowStatus.INITIALIZED, expected: 'initial' },
  { status: FlowStatus.RESUMING, expected: 'resumed' },
])('should handle $status correctly', ({ status, expected }): void => {
  const flow = createFlow(status);
  const result = flow.process();
  expect(result.value).toBe(expected);
});

// ❌ WRONG: Duplicate methods
it('test_initialized', () => { ... });  // 30 lines
it('test_resuming', () => { ... });     // 30 nearly identical lines
```

**When to parameterize**: Same logic, different inputs | Boundary conditions
**When NOT to**: Different test logic | Single scenario

## Mocking Best Practices

| Scenario | Approach | Auto-restores? |
|---|---|---|
| Mock a method on a shared instance | `vi.spyOn` (+ `mockRestore`) | Yes |
| Different behavior per instance | Object literal or `Object.defineProperty` | No (fresh objects per test) |
| Module-level function or class | `vi.mock("@/module")` | Yes (hoisted) |

### Shared mock — `vi.spyOn`

```typescript
const spy = vi.spyOn(context, 'completeStep').mockResolvedValue(undefined);
await context.process();
expect(spy).toHaveBeenCalledWith('extraction');
spy.mockRestore();
```

### Per-instance mock — object literal or `Object.defineProperty`

Use when different instances need different behavior.

```typescript
// ✅ Object literal
const step0 = createMockStep({ checkStatus: vi.fn().mockResolvedValue({}) });
const step1 = createMockStep({ checkStatus: vi.fn().mockRejectedValue(new Error('timeout')) });

// ✅ Object.defineProperty — bypass readonly / frozen prototypes
Object.defineProperty(step, 'checkStatus', {
  value: vi.fn().mockResolvedValue({}),
  writable: true,
  configurable: true,
});

// ❌ WRONG: Direct assignment on a class instance — TypeScript error
context.completeStep = vi.fn();
```

### Module mock — `vi.mock`

```typescript
vi.mock('@/services/llm-client', () => ({
  LlmClient: vi.fn().mockImplementation(() => ({
    analyze: vi.fn().mockResolvedValue({ result: 'success' }),
  })),
}));
```
