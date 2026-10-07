# bindings.usrcmds

Entry point that wires up submodule user commands (`bindings_explorer`,
`context_open`, `telemetry_nvim_config`, `autocmd_docs`, `bindings_audit`, `cdx`, `clipboard`) and
registers a few standalone ones directly,
e.g. `:CopyLocation` (copies the current file's absolute path + cursor
position to the clipboard).

## `:Clipboard [path] {target}` / `:Clipboard {snippet}`

Copies the path of a well-known directory of this config to the clipboard
(module `clipboard/`). No keymap on purpose.

| Command | Copies |
|---|---|
| `:Clipboard path reports` | `<config>/docs/ROADMAP/reports` |
| `:Clipboard path handovers` | `<config>/docs/ROADMAP/handovers` |

`path` is optional (`:Clipboard reports` works too); it is the first
sub-command so other things to copy can get their own word later. Targets are
data (`require("bindings.usrcmds.clipboard").TARGETS`, directory relative to
the config dir or absolute, `$ENV` expanded); `enable({ targets = { notes =
"docs/NOTES" }, form = "env" })` adds some / switches the written form to
`$NVIM_CONFIG_DIR/...` (via gopath.nvim's `shorten_path` when installed).

Snippets are fixed texts copied verbatim (module data `SNIPPETS`, extendable via
`enable({ snippets = { ["words"] = { text = ..., desc = ... } } })`):

| Command | Copies |
|---|---|
| `:Clipboard remove citeX` | `:%s/\[cite: \d\+\]//g` (strips `[cite: 12]` markers) |

