# bindings.usrcmds.case

> **Frozen. Not the active source.** `:Case` comes from the
> [`casedesk.nvim`](https://github.com/StefanBartl/casedesk.nvim) plugin since
> 2026-09-04; this tree is only the fallback that
> `lua/bindings/usrcmds/init.lua` can re-enable with one comment character.
> **Change nothing here** -- edits would be invisible while the plugin is
> active and would drift from it. The move is
> `docs/ROADMAP/casedesk/PLUGIN.md`; deleting this copy is its phase 7.

`:Case` — SAP-support case scaffolding ("casedesk"). Registers the `CASE`
argument type (validates and `<Tab>`-completes against the on-disk registry,
normalizing a pasted full SNOW id down to its short number) plus one
composer verb with a route per workflow step. See
`docs/ROADMAP/casedesk/CONCEPT.md` for the full concept.
