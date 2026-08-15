# bindings.usrcmds

Entry point that wires up submodule user commands (`case`, `bindings_explorer`,
`context_open`, `telemetry_nvim_config`, `update_repos`, `who_locks`) and
registers a few standalone ones directly, e.g. `:CopyLocation` (copies the
current file's absolute path + cursor position to the clipboard).
