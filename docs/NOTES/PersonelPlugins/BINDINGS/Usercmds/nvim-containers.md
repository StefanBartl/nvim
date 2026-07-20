# nvim-containers — User Commands Cheatsheet

Three command trees, built via `lib.nvim.usercmd.composer` (migrated
2026-07-19). Replaces 25 independent flat commands (`Container*` ×10,
`Container*Buffer`/`Image*Buffer` ×7, `Image*` ×4, `Wsl*` ×4) — breaking
change, no compat aliases. Biggest command-count win of the whole migration
series.

Source: `lua/containers/bindings/usrcmds/init.lua` (verbs + custom types),
`container_commands.lua`, `container_commands_buffer.lua`, `image_commands.lua`,
`wsl_commands.lua` (exported handler functions, one file each)
Docs: `docs/BINDINGS.md`, `README.md`, `docs/ADD_USECASE.md`

| Command | Args | Effect |
| --- | --- | --- |
| `:Container {sub}` | `list\|logs\|exec\|exec-once\|start\|stop\|kill\|remove\|prune\|inspect` | Container ops |
| `:Image {sub}` | `list\|pull\|remove\|prune` | Image ops |
| `:Wsl {sub}` | `list\|start\|stop\|exec` | WSL distro ops (only registered if `wsl.exe` reachable) |

`start`/`stop`/`kill`/`remove`/`prune` (Container) and `pull`/`prune` (Image)
accept `--buffer`/`-b` to stream raw CLI output into a terminal buffer
instead of a `vim.notify` summary.

## Notes

- **`--buffer` flag replaces 7 duplicate `*Buffer` commands** (explicit
  design decision, confirmed with the user before implementing given the
  scale of the change): `:ContainerStartBuffer <id>` → `:Container start
  <id> --buffer` / `-b`. The two variants previously differed only in
  output target (terminal buffer vs `vim.notify`) with near-identical
  handler bodies (`container_commands.lua` vs
  `container_commands_buffer.lua`) — folding the distinction into a Phase 6
  flag eliminates that duplication and is what the flag feature was built
  for. `container_commands_buffer.lua` also gained a small `require_engine()`
  helper deduplicating a check that was copy-pasted 7×.
- **Dynamic ID/name completion added** (a real improvement, not just
  parity — the original commands had zero completion for container/image/
  distro identifiers, only `complete = "file"` on the two exec commands).
  Confirmed with the user before implementing, specifically because
  `list_containers()`/`list_images()`/`list_distros()` all shell out
  *synchronously* (`run_argv.run_blocking_captured`, no timeout) with no
  caching — a naive per-keystroke `<Tab>` would re-run `docker ps -a` etc.
  on every completion request. Mitigated with a 4s TTL cache
  (`cached_names()` in `bindings/usrcmds/init.lua`) per list kind.
- **Real bug found and fixed during verification**: a misconfigured/
  unreachable engine makes `get_engine()`/`list_*()` call `vim.notify(ERROR)`
  as a side effect. That's fine on a real dispatch, but firing it while
  Neovim is computing `<Tab>` candidates made `vim.fn.getcompletion()`
  surface a **hard error to the caller** even though the Lua exception
  itself was already caught by `pcall`. Fixed by temporarily silencing
  `vim.notify` for the duration of each cached fetch — completion now
  degrades to "no candidates" instead of erroring. Real dispatch (not
  completion) still notifies normally.
- **Handler refactor**: all 25 handlers moved from inline
  `nvim_create_user_command` callbacks to exported plain functions
  (`M.list`, `M.start(id)`, ...) taking simple positional args instead of
  the raw `opts` table — same pattern as mdview.nvim's action-module
  refactor earlier in this migration series. Every function body is
  otherwise byte-for-byte unchanged.
- **`plugin/` entrypoints consolidated**: the 4 separate
  `plugin/{container_commands,container_commands_buffer,image_commands,
  wsl_commands}.lua` (each a one-line `require(...)`, relying on
  top-level-code-as-registration) became one `plugin/commands.lua` calling
  `require("containers.bindings.usrcmds").setup()` — the new handler
  modules no longer self-register on require, so an explicit `.setup()`
  call is needed (matching the `setup()`-gated pattern used by every other
  migrated repo, rather than nvim-containers' previous load-order-implicit
  one).
- **`:Wsl` registration is now conditional in Lua, not structural**: the
  original guard (`if not engine_utils.is_executable("wsl") then return
  end` at the top of `wsl_commands.lua`) meant the whole file no-opped on
  non-Windows systems. Since that file no longer self-registers, the check
  moved to a `wsl_commands.available()` function, called by
  `bindings/usrcmds/init.lua` right before `composer.verb("Wsl", ...)` —
  same effective behavior (no `:Wsl` command exists where `wsl.exe` isn't
  reachable), relocated to the call site.
- **No CI, no vimdoc (`doc/`) exists for this repo** — pre-existing, not
  part of this migration's scope.
