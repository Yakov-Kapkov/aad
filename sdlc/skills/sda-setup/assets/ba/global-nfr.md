# Global NFRs

System-wide quality guardrails. Each has a stable id so a story can reference it
without restating. Edit this file directly; do not author global NFRs inside a story.

**How they apply**
- **Always in force (compliance).** Every change must comply with *all* global NFRs —
  none may be violated, whatever the change is about.
- **Verified where relevant.** A story verifies only the global NFRs its scenarios /
  changed surface can affect (BA references those by id; QA turns them into checks).
  Untouched NFRs stay in force but are not re-tested for that change; QA regression
  re-verifies the NFRs of any behaviour the change touches.

### GNFR-AUTH — Authentication boundary
{Every protected route enforces auth; unauthenticated → 401.}

### GNFR-PERF — Baseline latency
{p95 response under {limit} for standard endpoints.}

### GNFR-SEC — Input safety
{All external input validated; no injection surface.}

### GNFR-COMPLIANCE — Data handling
{PII handling / retention / audit rules.}
