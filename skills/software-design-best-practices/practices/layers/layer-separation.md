# Layer Separation

## Rule

Give each architectural layer an unambiguous name, store its files in
a dedicated layer-specific folder, and enforce that code in one layer
only depends on the layer directly below it.

## Application

- ✅ DO: define layers with standard, unambiguous names:
  `Presentation` (or `Web`, `Api`), `Application` (or `Services`),
  `Domain` (or `Core`), `Infrastructure` (or `Data`).
- ✅ DO: create a top-level folder per layer. Put every file in
  exactly one layer folder — no file belongs to two layers.
- ✅ DO: enforce a strict dependency direction:
  `Presentation → Application → Domain ← Infrastructure`.
- ✅ DO: define interfaces/abstractions in the inner layer
  (Domain/Core) and implement them in the outer layer
  (Infrastructure).
- ❌ DON'T: use vague layer names like `Common`, `Utils`, `Helpers`
  — these become dumping grounds.
- ❌ DON'T: let the Presentation layer import from Infrastructure
  directly.
- ❌ DON'T: place a file that mixes two concerns (e.g., a controller
  that executes SQL) in either layer — refactor it first.
