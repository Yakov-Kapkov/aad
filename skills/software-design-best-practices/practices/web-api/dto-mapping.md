# DTOs & Mapping

## Rule

Every layer boundary must use its own data transfer objects. Internal
domain entities must never cross a layer boundary, including as nested
fields — every object inside a DTO must itself be a DTO.

## Application

- ✅ DO: define separate DTOs for request (input) and response
  (output) — they serve different purposes and evolve independently.
- ✅ DO: map between entity and DTO at the layer boundary
  (controller ↔ service, service ↔ repository).
- ✅ DO: use explicit mapping (manual or via mapping library) rather
  than implicit serialization that leaks internal fields.
- ✅ DO: keep DTOs flat and anemic — no business logic, no
  dependencies on domain or infrastructure layers.
- ✅ DO: ensure all nested objects within a DTO are also DTOs, not
  domain entities or persistence-layer objects.
- ❌ DON'T: serialize domain entities directly as API responses.
- ❌ DON'T: use the same DTO for multiple unrelated operations.
- ❌ DON'T: embed a domain entity or database document as a field of
  a DTO (e.g. `MyDTO { "instance": DbEntity, ... }`).
- ❌ DON'T: embed persistence concerns (lazy-loading proxies, change
  tracking) in objects that cross layer boundaries.
