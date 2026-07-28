# Input Validation

## Rule

Validate all input at the boundary — before it reaches business logic.

## Application

- ✅ DO: validate in the API layer (controller/endpoint), before any
  processing.
- ✅ DO: use declarative validation (annotations, attributes, schemas)
  on DTOs rather than imperative checks scattered in business logic.
- ✅ DO: return structured error responses listing all validation
  failures — not just the first one.
- ✅ DO: sanitize strings: trim whitespace, enforce length limits,
  reject or escape control characters.
- ✅ DO: validate numeric ranges and enum membership explicitly.
- ❌ DON'T: rely on client-side validation alone. Server-side
  validation is mandatory.
- ❌ DON'T: pass raw user input directly to database queries, file
  system operations, or external command execution.
- ❌ DON'T: embed user input in error messages sent to the client
  (risk of reflection attacks).
