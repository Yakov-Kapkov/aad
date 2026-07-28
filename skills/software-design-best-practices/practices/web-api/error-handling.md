# Global Error Handling

## Rule

Handle exceptions in a single centralized middleware — not in
individual endpoints.

## Application

- ✅ DO: register a global exception-handling middleware as the
  outermost layer of the request pipeline.
- ✅ DO: map known exception types to appropriate HTTP status codes
  in one place (e.g., `NotFound → 404`, `ValidationError → 400`,
  `Unauthorized → 401`, `Forbidden → 403`).
- ✅ DO: return a consistent error response body: at minimum
  `message` (user-safe), `statusCode`, and optionally a `traceId`
  for correlation with server logs.
- ✅ DO: log the full exception (stack trace, inner exceptions) on
  the server — never send stack traces to the client.
- ✅ DO: catch unhandled exceptions and return `500 Internal Server
  Error` with a generic message.
- ❌ DON'T: wrap individual endpoint bodies in try-catch blocks that
  duplicate the middleware's behavior.
- ❌ DON'T: leak stack traces, internal file paths, or database error
  details in API responses.
- ❌ DON'T: swallow exceptions silently — always log and return an
  error response.
