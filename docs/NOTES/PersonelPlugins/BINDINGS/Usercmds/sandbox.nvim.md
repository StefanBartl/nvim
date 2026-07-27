# sandbox.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-19, restructured 2026-07-21). Originally three separate verbs
(`:Container`/`:Image`/`:Wsl`) replacing 25 independent flat commands
(`Container*` ×10, `Container*Buffer`/`Image*Buffer` ×7, `Image*` ×4,
`Wsl*` ×4) — breaking change, no compat aliases. Biggest command-count win
of the whole migration series.

On 2026-07-21 the repo itself was renamed `nvim-containers` → `sandbox.nvim`
(internal module namespace `lua/containers/` → `lua/sandbox/`, every
`require("containers...")` → `require("sandbox...")`), and the three
verbs were unified into a single `:Sandbox` verb (short alias `:Sbx`,
identical route tree) with sub-namespaces — `:Container`/`:Image`/`:Wsl`
were too generic and collided conceptually with unrelated plugins (e.g. an
image/png viewer claiming `:Image`). Breaking change again, no compat
aliases for the old verb names.

**2026-07-26: from 3 to 10 sub-namespaces in one day.** What started as
"add a roadmap doc" turned into implementing essentially the entire
resulting `docs/ROADMAP.md` backlog, one feature per commit pushed
straight to `main` (no PRs — explicitly requested, single-maintainer repo).
Sub-namespaces went `container`/`image`/`wsl` → `container`/`image`/
`volume`/`network`/`compose`/`engine`/`registry`/`docs`/`devcontainer`/
`wsl` (10, `wsl` still conditional on `wsl.exe`). `docs/ROADMAP.md` itself
now reads "Nothing queued right now — every item that was on this list has
shipped."

Source: `lua/sandbox/bindings/usrcmds/init.lua` (verb + custom completion
types + route tables), one handler module per sub-namespace:
`container_commands.lua` (+`container_commands_buffer.lua` for the
`--buffer` terminal variants), `image_commands.lua`, `volume_commands.lua`,
`network_commands.lua`, `compose_commands.lua`, `engine_commands.lua`,
`registry_commands.lua`, `devcontainer_commands.lua`, `wsl_commands.lua`.
Docs: `docs/BINDINGS.md` (hand-maintained, authoritative), `README.md`,
`docs/ADD_USECASE.md`, `docs/ROADMAP.md` (now empty), `doc/sandbox.txt`
(native `:help sandbox`, added same day), `docs/GENERATED_COMMANDS.md`
(mechanical dump from the live route table via `:Sandbox docs generate` —
diff it against `BINDINGS.md` to catch drift).

| Command | Args | Effect |
| --- | --- | --- |
| `:Sandbox container {sub}` | `list\|logs\|logs-follow\|exec\|exec-once\|start\|stop\|kill\|restart\|pause\|unpause\|rename\|stats\|top\|cp\|run\|remove\|prune\|inspect` | Container ops |
| `:Sandbox image {sub}` | `list\|pull\|push\|tag\|build\|save\|load\|history\|inspect\|remove\|prune` | Image ops |
| `:Sandbox volume {sub}` | `list\|create\|remove\|inspect\|prune` | Volume ops |
| `:Sandbox network {sub}` | `list\|create\|remove\|inspect\|connect\|disconnect\|prune` | Network ops |
| `:Sandbox compose {sub}` | `up\|down\|restart\|ps\|logs` | Compose project ops (scoped to the compose file auto-detected in cwd/ancestor dirs) |
| `:Sandbox engine {sub}` | `set\|get\|reset` | Runtime engine switching for the session (precedence over `.sandboxrc`/config) |
| `:Sandbox registry {sub}` | `login\|logout` | Registry auth (password via stdin, never argv) |
| `:Sandbox docs {sub}` | `generate` | Regenerate `docs/GENERATED_COMMANDS.md` |
| `:Sandbox devcontainer {sub}` | `build\|attach` | `.devcontainer/devcontainer.json` build/attach |
| `:Sandbox wsl {sub}` | `list\|start\|stop\|exec\|set-default\|set-version\|export\|import\|shutdown-all` | WSL distro ops (only if `wsl.exe` reachable) |

All of the above have a `:Sbx` alias with the identical route tree.

`start`/`stop`/`kill`/`restart`/`remove`/`prune` (container) and
`pull`/`prune` (image) accept `--buffer`/`-b` to stream raw CLI output into
a terminal buffer instead of a `vim.notify` summary, e.g. `:Sandbox
container start <id> --buffer`.

## 2026-07-26: volumes/networks/compose + buffer-local keymaps

Large follow-up push implementing the bulk of `docs/ROADMAP.md`, one
feature per commit pushed straight to `main`:

- **Volumes** (`create`/`remove`/`inspect`/`prune`/`list`) and **networks**
  (`create`/`remove`/`inspect`/`connect`/`disconnect`/`prune`/`list`) —
  previously unmodelled, now full ports (`core/ports/volume_engine.lua`,
  `core/ports/network_engine.lua`) + Docker/Podman adapters, following the
  same port→adapter→usecase→route shape as containers/images.
- **Container lifecycle rounded out**: `restart`, `pause`/`unpause`,
  `rename`, `stats`, `top`, `cp`, and an interactive `run` wizard
  (`vim.ui.input` chain for image/name/ports/volumes/env) were all added —
  previously only start/stop/kill/remove/prune/inspect existed.
- **Images**: `tag`, `build` (streams to a terminal buffer),
  `save`/`load` (tarball export/import), `history` were added alongside the
  pre-existing list/pull/remove/prune/inspect.
- **Compose support**: new `compose_engine` port (not container-scoped —
  operates on a whole project) auto-detecting
  `docker-compose.yml`/`compose.yml`/`podman-compose.yml` via `vim.fs.find`
  (same lookup `docker compose`/`podman compose` do themselves); no id/name
  arg since there's exactly one project per detected file.
- **Real bug caught mid-push**: `adapters/{docker,podman}/engine.lua` are
  top-level aggregators that hand-list which sub-aggregator fields to
  expose. They'd fallen out of sync with `containers_engine.lua`/
  `images_engine.lua` — every new container/image method added in this
  push was silently unreachable through `sandbox.get_engine()` until this
  was caught and fixed (`fix(adapters): merge sub-aggregators wholesale
  instead of hand-listing fields`). Lesson: a hand-maintained field
  whitelist between an aggregator and its sub-aggregators drifts silently;
  merging wholesale (`vim.tbl_extend`) removes the whole class of bug.
- **Buffer-local list-view keymaps** — see
  [Keymaps/sandbox.nvim.md](../Keymaps/sandbox.nvim.md) for the full table.
  This was "zero keymaps" territory before; now the container/image/
  volume/network list buffers act like a lightweight lazygit/k9s pane
  instead of read-only reports.
- **Verification method**: no Docker/Podman daemon running in the dev
  sandbox this was built in, so each feature was checked the same way the
  rest of the repo already is (no test suite existed *yet* — see below) —
  `luacheck` (0 errors gate) + `nvim --headless -u NONE` module-load smoke
  checks + manual review of the constructed CLI argv against documented
  docker/podman syntax.

## 2026-07-26 (continued): the rest of the roadmap + hardening

Same day, further commits (by the point this note was last refreshed,
`docs/ROADMAP.md` had gone from "one section left" to fully empty):

- **UI polish**: auto-refreshing list views (`refresh_interval` config +
  a `luv` timer per buffer, cleaned up via a `BufWipeout` autocmd — see
  [Autocmds/sandbox.nvim.md](../Autocmds/sandbox.nvim.md)), per-status
  highlight groups (`ui/highlights.lua`), a foldable/indented inspect view
  instead of a flat `vim.inspect` dump, live log follow (`logs -f` via
  `container logs-follow`, `q` or buffer-wipeout stops the job), and
  Visual-mode multi-select (apply one list-view keymap to every selected
  line, one confirm for the whole batch).
- **Config grew**: `default_shell`, `refresh_interval`, `list_split`,
  `list_size`, plus a per-project `.sandboxrc` engine override
  (`engine=docker`/`podman`/`nerdctl` in a repo's root) — precedence
  documented in `README.md`/`doc/sandbox.txt`.
- **Engines**: a full **nerdctl** adapter (mirrors Docker's, since nerdctl
  is Docker-CLI-compatible) and runtime **engine switching**
  (`:Sandbox engine set/get/reset`, session override > `.sandboxrc` >
  config). The **containerd research item was resolved without a separate
  adapter** — nerdctl already covers containerd's practical surface, so a
  raw `ctr`-based adapter would've been redundant; documented as a
  deliberate non-implementation rather than left open.
- **Async execution**: `util/run_argv.lua` gained a genuinely
  non-blocking path, applied to `image pull` first (previously
  `run_blocking_captured` blocked the UI thread on a slow pull).
- **WSL rounded out**: `set-default`, `set-version`, `export`/`import`,
  `shutdown-all` — previously only list/start/stop/exec existed.
- **Registry + push**: `image push` (async, mirrors `pull`) and
  `registry login`/`logout`, with the password piped over stdin
  (`--password-stdin`) rather than ever appearing as an argv element or in
  shell history — worth remembering as the reason to *not* "simplify" that
  code path later.
- **Statusline**: `require("sandbox.statusline").status()` — a cached
  (3s), failure-degrading (`""` on error) `"engine (running/total)"`
  string, wired as an optional `lualine` component with zero hard
  dependency on lualine itself.
- **DX**: `composer.document()` wired up as `:Sandbox docs generate`
  (writes `docs/GENERATED_COMMANDS.md` from the live route table), a
  `tests/` plenary.nvim suite (dependency-injected fake `run_argv`, no
  live daemon needed — same constraint noted above, now actually
  addressed with real automated coverage instead of just manual smoke
  checks), and `.github/workflows/ci.yml` running luacheck + the test
  suite (needed a follow-up fix pinning luacheck's Lua to 5.1, and one
  more clearing residual lint warnings before it went green).
- **Optional integrations**: a `telescope.nvim` extension
  (`:Telescope sandbox containers|images|wsl`) and **devcontainer support**
  (`:Sandbox devcontainer build/attach` — detects
  `.devcontainer/devcontainer.json`, JSONC comments/trailing commas
  stripped before parsing; single-container and `dockerComposeFile` shapes
  only, no features/lifecycle-commands/remoteUser yet). Neither is a hard
  dependency — telescope only loads if present, devcontainer support reuses
  the existing container/compose ports rather than adding a new engine.
- **Refactor**: destructive-confirm prompts and the remaining
  `vim.ui.input` call sites were migrated to `lib.nvim.ui.kit`, replacing
  ad-hoc `vim.ui.select`/`vim.ui.input` usage with the shared kit already
  used elsewhere in the `lib.nvim` ecosystem.
- **`doc/sandbox.txt` added** (this repo had *no* vimdoc at all before) —
  full `:help sandbox` reference covering setup, every config option, all
  ten sub-namespaces, keymaps, statusline, and `:checkhealth`. Verified
  with `:helptags doc` (no errors); `doc/tags` itself stays untracked
  (already in `.gitignore`).
- **One more doc bug caught**: both `docs/BINDINGS.md` and the fresh
  `doc/sandbox.txt` still said "no autocmds" — no longer true once the
  auto-refresh timer cleanup and log-follow job cleanup autocmds (both
  buffer-local, one-shot `BufWipeout`, no global augroup) were added
  earlier the same day. Fixed in both places rather than left drifting.

## Notes

- **`--buffer` flag replaces 7 duplicate `*Buffer` commands** (explicit
  design decision, confirmed with the user before implementing given the
  scale of the change): `:ContainerStartBuffer <id>` → `:Sandbox container
  start <id> --buffer` / `-b`. The two variants previously differed only in
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
  `require("sandbox.bindings.usrcmds").setup()` — the new handler
  modules no longer self-register on require, so an explicit `.setup()`
  call is needed (matching the `setup()`-gated pattern used by every other
  migrated repo, rather than sandbox.nvim's previous load-order-implicit
  one).
- **`wsl` sub-namespace registration is conditional in Lua, not
  structural**: the original guard (`if not engine_utils.is_executable
  ("wsl") then return end` at the top of `wsl_commands.lua`) meant the
  whole file no-opped on non-Windows systems. Since that file no longer
  self-registers, the check moved to a `wsl_commands.available()`
  function, called by `bindings/usrcmds/init.lua` right before the `wsl`
  routes are appended to the shared route table — same effective behavior
  (no `wsl` subcommands exist where `wsl.exe` isn't reachable), relocated
  to the call site.
- **2026-07-21 rename fallout**: a bulk `sed` rename of `containers.` →
  `sandbox.` across the repo initially also mangled a few things it
  shouldn't have — nested subdirectories literally named `containers`
  (`adapters/<engine>/containers/`, `core/usecases/containers/`, which are
  a meaningful domain split from `images/`/`wsl/`, not part of the
  plugin-name branding) and a couple of local variables ending in
  `..._containers` (e.g. `list_containers.list_containers`). Caught via
  `luacheck` (`accessing undefined variable`) and fixed; not caught by
  `luacheck` were the require-path mid-segments that don't trip a static
  lint (a bad string literal just fails at runtime), so those needed an
  explicit second grep pass. Lesson: a literal-string bulk rename across a
  codebase needs word-boundary anchoring or a manual scope check when a
  domain word (`containers`) doubles as a plugin-name segment.
- **CI and vimdoc gap, closed**: earlier notes here said "No CI, no
  vimdoc (`doc/`) exists for this repo." Both landed as part of the
  2026-07-26 push (`.github/workflows/ci.yml` + `tests/` plenary suite;
  `doc/sandbox.txt`) — no longer an open gap as of this refresh.
