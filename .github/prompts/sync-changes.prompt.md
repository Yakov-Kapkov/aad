---
description: Pull dev-suite artifacts edited in an installed .copilot folder back into this repo, then verify the pulled changes against the repo's tests and quality rules.
---

# Sync changes

## 1. Pull

Read `.sync/source_path.txt` (gitignored), trim it, then run from the repo root:

```powershell
cd scripts/powershell
.\pull-dev-suite.ps1 -SourceBase "<source path>"
```

- Missing or non-directory path: ask the user. Never guess.
- No extra flags — `-IncludeModels`, `-Prune`, `-WhatIf` are the user's call; name them in the report when they apply.
- Blocked by execution policy: rerun as `powershell -NoProfile -ExecutionPolicy Bypass -File .\pull-dev-suite.ps1 -SourceBase "<source path>"`.
- `0 added, 0 updated, 0 pruned`: report in sync (plus the model-only count) and stop.

## 2. Make it land

The repo already holds the rules and the tests — apply them, do not restate them: run tests, check the repo's quality rules, and fix any issues. Report the results.