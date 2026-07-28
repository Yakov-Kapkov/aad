# Shared Resources

## Rule

Extract code used by multiple layers or modules into dedicated shared
folders, scoped by the layer they belong to.

## Application

- ✅ DO: create shared folders scoped by layer:
  `Presentation/Shared/` for shared UI components and view helpers;
  `Domain/Shared/` for shared value objects and domain primitives;
  `Infrastructure/Shared/` for shared data access utilities.
- ✅ DO: extract cross-cutting concerns (logging, configuration,
  dependency injection) into a dedicated `Infrastructure/CrossCutting/`
  or similar folder — these are infrastructure concerns.
- ✅ DO: move a utility to the shared folder when it is used by at
  least two files in the same layer.
- ❌ DON'T: create a single root-level `Shared/` or `Common/` folder
  that every layer imports — this defeats layer separation.
- ❌ DON'T: put domain logic in infrastructure shared folders, or
  UI logic in domain shared folders.
- ❌ DON'T: extract a utility to shared preemptively — wait until it
  is actually used by multiple consumers.
