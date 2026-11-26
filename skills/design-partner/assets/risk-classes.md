# Risk classes

The list a flow is attacked against. Every class is a test, an explicit
`Out`/`Deferred`, or a question — never a silence.

- idempotency and duplicate delivery
- concurrency: two writers, or a write racing a background correction
- an entity that is missing, deleted, or incomplete
- unsupported input on a **write**, not only on a read
- partial failure: half the operation lands
- authorization on the write path
- a migration or a shape change — what gates the release, and the way back
- the losing edge of a protective rule: the case where it is wrong, or where it
  stops protecting
- a new user-facing string the interface must carry
