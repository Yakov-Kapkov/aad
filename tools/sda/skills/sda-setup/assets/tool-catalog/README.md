# Tool Catalog

Language-specific `tool-catalog.md` files ship with this skill. The
sda-setup script copies the matching catalog into `.sda/resources/{language}/`
at setup time; `sda-setup` (Step 7) and `sda-tool-installer` read it from there.

**`Hook command` convention:** a row's `Hook command` is that tool's canonical
non-interactive invocation, written in its quietest form — the silence flag it
carries is appended to every command generated for the tool. Leave the flag out
when the tool has none; never invent one.

A code formatter's `Hook command` is its **in-place** form — formatting rewrites
files, so the read-only variant (`--check`, `--verify-no-changes`) is a
static-analysis command, not a format command.

**Source of truth:** these files are the source. Edit them here.