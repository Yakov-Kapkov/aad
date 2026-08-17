# AGENTS.md — standards-compliance

Rules for creating and editing the standards files in `standards/`.

## Folder structure

```
standards/
├── common-standards.md              ← language-agnostic rules
└── {language}/
    ├── coding-standards.md          ← production-code rules
    ├── testing-standards.md         ← test-code rules
    └── code-style.md                ← formatting and documentation
```

## Rules

### 1. Cross-language sync

Any change to a file under `standards/{language}/` must be mirrored in
the same file for **every** other language folder:

- **Adding a section** → add it to every language, with language-appropriate code examples.
- **Removing a section** → remove it from every language.
- **Changing rule text** → apply the same text change to every language.

Only code examples differ between languages; rule text is identical.

### 2. Common standards

Language-agnostic rules live in `standards/common-standards.md` — not
duplicated per language. Examples: SOLID, AAA structure, behavioral
testing, unit test scope, derive-from-mocks.

Moving a rule to common: remove it from every `standards/{language}/`
file and add it once in `standards/common-standards.md`.

### 3. File format

Each standards file follows this structure:

```
# {Title}

## Table of Contents
- [Section 1](#section-1)
- ...

## Section 1
...
```

No checklists at the end — the Table of Contents serves as the summary.

### 4. Section order by file type

**`coding-standards.md`**
1. Core Principles (SOLID, etc. — only if not in common-standards.md)
2. Type Safety / Data Models
3. Magic Number/String Prevention
4. Import Organization
5. Error Handling (only if not in common-standards.md)
6. Comments and Documentation (only if not in common-standards.md)

**`testing-standards.md`**
1. Import Organization
2. No Environment Variable Dependencies
3. Unit Test Scope (only if not in common-standards.md)
4. Async Testing
5. Test Data Creation
6. Test Setup / Fixtures
7. Test Structure (AAA — only if not in common-standards.md)
8. Test Parameterization
9. Test Constants (only if not in common-standards.md)
10. Mocking Best Practices
11. Derive Expected Values (only if not in common-standards.md)

**`code-style.md`**
1. String Formatting
2. File-Level Documentation (language-specific — rules may differ)
3. API Documentation Standards
4. Clean Code Practices (only if not in common-standards.md)
5. Anti-Patterns (only if not in common-standards.md)

Sections marked "only if not in common-standards.md" must live in
exactly one place. If the rule is in common, omit the section from
the language file entirely.

Sections marked "language-specific" may have different rule text
across languages where the underlying convention genuinely differs
(e.g. Python module docstrings vs TypeScript's no-file-header policy).

### 5. Conciseness

- One ✅ example + one ❌ example per rule. No more.
- Bullet points over paragraphs.
- No redundant prose explaining what is already shown in the example.
- If a rule can be stated in one sentence, do not use two.
- No "Why" paragraphs unless the reason is genuinely non-obvious.
  A rule that restates its own rationale wastes tokens.
- No "Applies to" lines when the scope is already clear from context
  (e.g., a rule in `common-standards.md` applies to all languages).

### 6. New languages

Adding a language:
1. Create `standards/{language}/` with the applicable files:
   - `coding-standards.md` (required)
   - `code-style.md` (required)
   - `testing-standards.md` (only if the language has its own test patterns)
2. Follow the section order above.
3. Reuse rule text verbatim from an existing language — change only
   code examples.
4. Update the `standards/README.md` structure tree.

### 7. Boundaries

- ✅ Always: sync across languages, follow section order, keep concise
- ⚠️ Ask first: moving a rule to/from `common-standards.md`, adding a
  new standards file, adding a new language folder
- 🚫 Never: duplicate language-agnostic rules per language, add
  checklists, add preambles
