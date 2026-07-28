# Entity Exposure

## Rule

Do not return raw database entities to callers outside the data access
layer. Always map to DTOs before crossing the layer boundary.

## Application

- ✅ DO: map database entities to plain DTOs at the repository or
  data-access boundary before returning to the service layer.
- ✅ DO: keep entities internal to the data access layer — no other
  layer should import or reference entity types.
- ✅ DO: use projections (query-level mapping) when possible — it
  combines column selection and DTO mapping in one database round-trip.
- ❌ DON'T: return entity objects from repositories to services or
  controllers.
- ❌ DON'T: serialize entities directly in API responses — this
  exposes internal schema details and risks accidental data leaks.
- ❌ DON'T: rely on serialization settings (e.g., `JsonIgnore`) to
  hide entity fields — that masks the design problem instead of
  fixing the layer violation.
