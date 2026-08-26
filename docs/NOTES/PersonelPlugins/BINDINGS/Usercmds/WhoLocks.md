# `:WhoLocks` — diagnose a Windows file lock

Config-internal, not a plugin's own command
([`lua/bindings/usrcmds/who_locks/`](../../../../../lua/bindings/usrcmds/who_locks/init.lua),
alongside [`:MyPlugins`](./MyPlugins.md) and [`:MyReposUpdate`](./MyReposUpdate.md)).

| Command | Effect |
| --- | --- |
| `:WhoLocks [path]` | Report who is holding `path` (default: the current buffer's file) open |
| `:WhoLocks [path] --json` | The same three findings as one `vim.json.encode`d object |

Run it right after a file operation failed with `EBUSY: resource busy or
locked` (or `EPERM`/`EACCES`). It measures rather than guesses:

1. A live `uv.fs_rename` probe, so "is it locked *right now*" is a fact.
2. The processes holding the file, via the Windows Restart Manager.
3. Neo-tree's own `fs_event` watchers covering the file's folder.

(1) and (2) live in `lib.nvim.cross.fs.lock`, shared with fileops.nvim's
`:File lockinfo` and filetree.nvim. What this command adds is (3), and that it
works on *any* path with no buffer needed — which is what makes it useful
outside a plugin: it distinguishes a foreign holder from a handle leaked
inside this very Neovim, the one case no retry can outwait.

**An open buffer is never the cause.** Neovim closes a file after reading it
and keeps only its swap file open — measured, not assumed.

`--json` exists for scripting and a possible pickers.nvim integration.
`lib.nvim.cross.fs.lock.report` only ever produces human-readable text lines,
so the json path calls `probe`/`who` directly and assembles the structured
object itself rather than routing through `report`.

`<Tab>` completes `path` (file completion) and `--json`.

## Examples

```vim
:WhoLocks                                  " the current buffer's file
:WhoLocks C:/repos/foo.nvim/lua/init.lua
:WhoLocks --json                           " structured, for scripts
```
