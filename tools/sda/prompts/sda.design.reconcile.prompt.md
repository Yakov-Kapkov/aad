---
description: Reconcile design docs with reality — find and fix inconsistencies across the AI readme, global + per-layer docs, and decision docs
agent: sda-design
---

Start in system mode. Discover the repo's layers via sda-code-explore, then
update and create the design documentation (AI readme, global `docs/`, each
layer's `docs/`, decision docs) so it matches the current state of the
repository.

Apply the doc-tree rules: global `docs/` (architecture, vocabulary, index,
diagrams) + one `docs/` per layer (index, vocabulary, decisions), thin readmes
(no implementation detail), and per-topic-folder decision numbering starting
at 1 (one decision per file).
