# Loading States

## Rule

Show a shared loading indicator for every async data fetch — never
leave the UI in an ambiguous blank or stale state.

## Application

- ✅ DO: use a single, shared loading indicator component (spinner,
  skeleton, progress bar) for all async operations.
- ✅ DO: show the indicator immediately when a fetch begins — not
  after a delay.
- ✅ DO: hide the indicator when the fetch completes (success or
  error).
- ✅ DO: for list/detail patterns, show the loading indicator in
  the content area that will be replaced — not as a full-page
  overlay unless the entire page depends on the fetch.
- ✅ DO: handle the error state explicitly — show an error message
  with a retry action, not a stuck spinner.
- ❌ DON'T: create per-page or per-component loading spinners that
  differ in appearance or behavior.
- ❌ DON'T: leave stale data visible during a refresh fetch — show
  the loading indicator over or in place of the stale content.
- ❌ DON'T: show a loading indicator for operations that complete in
  under 100 ms — the flash is distracting.
