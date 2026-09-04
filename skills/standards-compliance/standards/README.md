# Coding Standards — Index

**Purpose**: AI assistant instructions for maintaining code quality and consistency. Standards are split by language; shared workflow rules live in `common-standards.md`.

These files are bundled with the **standards-compliance** skill. Toolchain specs
(`tool-discovery.md`, `tool-catalog.md`) ship with the **sda-setup** skill instead.

---

## Structure

```
standards/
├── common-standards.md              ← language-agnostic rules
├── csharp/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── code-style.md
├── java/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── code-style.md
├── python/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── code-style.md
├── postgresql/
│   ├── coding-standards.md
│   └── code-style.md
└── typescript/
    ├── coding-standards.md
    ├── testing-standards.md
    └── code-style.md
```

---

## Quick Navigation

| File | Purpose | When to Use |
|------|---------|-------------|
| **[common-standards.md](common-standards.md)** | Language-agnostic rules (SOLID, AAA, behavioral testing, constant reuse) | Loaded for all languages automatically |
| **coding-standards.md** | Core technical rules for production code | Writing production code: types, constants, imports |
| **testing-standards.md** | How to write quality tests | Writing any test code: structure, AAA, mocking |
| **code-style.md** | Formatting and documentation rules | Formatting code, writing comments/docs |

## Decision Tree: Which File Do I Need?

```
What are you doing?
│
│
├─ Writing production code?
│  ├─ Need types, constants, imports? → coding-standards.md (for your language)
│  └─ Need formatting, comments, docs? → code-style.md (for your language)
│
├─ Writing tests?
│  └─ Need test structure, setup, mocking? → testing-standards.md (for your language)
│
└─ Doing code review?
   └─ Check checklists in all relevant files
```

## File Summaries

### coding-standards.md

**C#** (`csharp/`):
- Nullable reference types (MANDATORY, `<Nullable>enable</Nullable>`)
- Records for immutable data vs classes
- Language keywords over BCL types (`int` not `Int32`)
- Avoid `dynamic`
- Interface `I` prefix
- Magic number/string prevention (`const` / `static readonly`)
- Namespace and using directive organization (file-scoped, outside namespace)

**Java** (`java/`):
- Type annotations (MANDATORY, NEVER use raw types or `Object`)
- Records/classes with Bean Validation vs plain Maps
- Optional for nullable returns
- Enums over string/integer constants
- Magic number/string prevention
- Import organization (no wildcards, grouped by origin)

**TypeScript** (`typescript/`):
- SOLID principles
- Type annotations (MANDATORY, NEVER use `any`)
- Interfaces/Types vs plain objects
- Derived/projection types (`Pick`/`Omit` from a base interface)
- Zod schemas for runtime validation
- Magic number/string prevention
- Import organization (ES6 modules)

**PostgreSQL** (`postgresql/`):
- Data types (TIMESTAMPTZ, NUMERIC, UUID, TEXT over VARCHAR)
- Naming conventions (snake_case, prefixed constraints/indexes)
- Constraints and validation (NOT NULL, CHECK, FK)
- Index design (CONCURRENTLY, partial, covering)
- Migration structure (forward-only, versioned)
- Schema organization

**Python** (`python/`):
- SOLID principles
- Type annotations (MANDATORY for all parameters)
- Pydantic models / dataclasses vs dictionaries
- Magic number/string prevention
- Import organization (PEP 8)

### testing-standards.md

**C#** (`csharp/`):
- Test/file naming (`{Class}Tests`, `Method_WhenCondition_ShouldResult`)
- No environment variable dependencies (in-memory `IConfiguration`)
- Async tests return `Task` (never `async void`)
- Test parameterization (`[Theory]` + `[InlineData]` / `[MemberData]`)
- Mocking best practices (Moq constructor injection)

**Java** (`java/`):
- `@BeforeEach` setup and helper functions
- Test parameterization (`@ParameterizedTest`, `@CsvSource`, `@MethodSource`)
- Mocking best practices (Mockito `@Mock`, `@InjectMocks`, `mockStatic`)

**TypeScript** (`typescript/`):
- Test setup functions and utilities
- Test parameterization (`it.each` / `describe.each`)
- Mocking best practices (`vi.spyOn`, `vi.mock`)

**Python** (`python/`):
- Fixture usage (eliminate duplication)
- Test parameterization (`@pytest.mark.parametrize`)
- Mocking best practices (`patch.object`)

PostgreSQL has no `testing-standards.md` — database testing is covered by the application language's testing standards.

### code-style.md

**C#** (`csharp/`):
- Naming conventions (PascalCase types/methods, camelCase locals — no underscores, no `_` prefix)
- Layout and formatting (Allman braces, 4-space indent, `var` rules, `using` for disposable)
- String formatting (quote variables in messages)
- No file-level block comments (type XML doc serves as file doc)
- XML doc standards (`<summary>`, `<remarks>`, `<param>`, `<returns>`, `<exception>`)

**Java** (`java/`):
- String formatting (quote variables)
- No file-level block comments (class Javadoc serves as file doc)
- Javadoc standards (Summary + description + `@param` / `@return` / `@throws`)

**TypeScript** (`typescript/`):
- String formatting (quote variables)
- Clean code practices
- Comments (explain "why", not "what")
- TSDoc standards (Title + @summary + @description)
- Anti-patterns to avoid (orphaned constants, etc.)

**PostgreSQL** (`postgresql/`):
- SQL formatting (uppercase keywords, one column per line, aligned JOINs)
- Migration file documentation (purpose, business reason, locking notes)
- Object documentation (`COMMENT ON` for tables, nullable columns, indexes)

**Python** (`python/`):
- String formatting (quote variables)
- Clean code practices
- Module docstring (MANDATORY: max 5 lines at top of every file)
- Docstring standards (Summary, Args, Returns, Raises)
- Comments (explain "why", not "what")
- Anti-patterns to avoid (orphaned constants, etc.)

---

## For Human Developers

**Quick reference**: Bookmark this README and use the decision tree above.

**Code review**: Use checklists from each relevant file.

**Disputes**: Cite specific file + section in PR discussions.

## Framework-Specific Notes

**Java**: Examples use JUnit 5 and Mockito. Ensure a static analysis tool (Checkstyle, SpotBugs, or Error Prone) is configured. Use records for immutable value objects.

**TypeScript**: Examples use Jest/Vitest syntax but principles apply to Mocha or other frameworks. Ensure `strict: true` in `tsconfig.json`. ESLint should enforce these standards where possible.

**Python**: Examples use pytest. Ensure mypy strict mode is enabled.
