# Authentication

## Rule

Enforce authentication and authorization as a pipeline concern — a
single gate that runs before every protected endpoint, not inline
checks duplicated across handlers.

## Application

- ✅ DO: register auth as middleware (Express, Fastify, Koa) or as a
  wrapper function (Azure Functions, Lambda) that gates all protected
  routes.
- ✅ DO: separate authentication (who you are) from authorization
  (what you're allowed to do). Auth middleware verifies identity;
  role/permission checks happen in a second layer.
- ✅ DO: return standard HTTP status codes: `401 Unauthorized` when
  credentials are missing or invalid, `403 Forbidden` when the
  authenticated identity lacks the required permission.
- ✅ DO: keep the auth layer framework-agnostic — it should depend
  only on the request object and a token verifier, not on routing or
  business logic.
- ✅ DO: fail closed: if the auth layer is absent or misconfigured,
  reject all requests rather than allowing unauthenticated access.
- ❌ DON'T: embed token validation, role checks, or API key lookups
  in individual endpoint handlers.
- ❌ DON'T: distinguish between missing and invalid credentials in
  error messages sent to the client — both return a generic
  "Unauthorized" to avoid leaking information.
- ❌ DON'T: skip auth for "internal" or "admin-only" endpoints —
  every endpoint behind a gateway needs auth.
