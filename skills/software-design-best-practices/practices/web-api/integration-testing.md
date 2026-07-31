# Integration Testing

## Rule

Every web API endpoint must have integration tests covering: (1) authentication
requirements, (2) input validation, (3) expected response status codes,
(4) response data shape and content. Write tests against the contract before
implementation (TDD).

## Application

- ✅ DO: write integration tests before implementing the endpoint — define the
  expected status codes, response body shape, and data fields first, then
  implement until tests pass.
- ✅ DO: cover all authentication scenarios: unauthenticated (401/403),
  insufficient role/permission (403), valid credentials (200).
- ✅ DO: cover input validation edge cases: missing required fields, invalid
  formats, boundary values (min/max length, numeric ranges), empty payloads.
- ✅ DO: test every documented status code the endpoint can return — success
  (2xx), client error (4xx), and server error (5xx) paths.
- ✅ DO: assert response data: verify types, required fields present,
  relationships (nested objects, arrays), and key values match the request
  or fixture.
- ✅ DO: use test fixtures or factories for setup data — never depend on
  pre-existing database state.
- ❌ DON'T: skip response data assertions because "the endpoint doesn't exist
  yet" — define the expected contract in the test first.
- ❌ DON'T: write integration tests that only check status codes without
  verifying the response body.
- ❌ DON'T: hardcode database IDs or environment-specific values in assertions.
