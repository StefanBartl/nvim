# sandbox.nvim — Keymaps Cheatsheet

**No global keymaps** — everything is still exposed via `:Sandbox`/`:Sbx`
user commands (see [Usercmds/sandbox.nvim.md](../Usercmds/sandbox.nvim.md)),
nothing to map via which-key at the global level.

**As of 2026-07-26 this is no longer "zero keymaps" overall**, though: the
read-only list-view scratch buffers (`container list`, `image list`,
`volume list`, `network list`) now carry **buffer-local** keymaps so you can
act on the entry under the cursor instead of re-typing a command with its
id/name — a lazygit/k9s-style TUI layer on top of the previously
inspect-only buffers. Source: `lua/sandbox/ui/list_actions.lua` (shared
`vim.keymap.set(..., { buffer = bufnr })` wiring, plus the Visual-mode
multi-select dispatch and the `BufWipeout` cleanup for the
`refresh_interval` timer) wired into `ui/list_view.lua`,
`ui/image_list_view_{docker,podman}.lua`, `ui/volume_list_view.lua`,
`ui/network_list_view.lua`.

Press `?` inside any list buffer for a live reminder; `q` closes it.

## Container list (`sandbox.nvim://container-list`)

| Key | Action | Key | Action |
|---|---|---|---|
| `<CR>` / `i` | inspect | `n` | rename (prompts) |
| `s` | start | `D` | remove (confirm) |
| `x` | stop | `l` | logs |
| `X` | kill | `L` | logs (follow, `logs -f`; `q` in that buffer stops it) |
| `r` | restart | `e` | exec (shell) |
| `p` | pause | `t` | top |
| `P` | unpause | `T` | stats |
| | | `R` | refresh list |

The `[status]` prefix on each line is highlighted by container state —
`SandboxStatusRunning` (green) / `SandboxStatusStopped` (red) /
`SandboxStatusPaused` (yellow) / `SandboxStatusOther` (comment-colored),
each linked to a `Diagnostic{Ok,Error,Warn}`/`Comment` group so it follows
the active colorscheme. Source: `lua/sandbox/ui/highlights.lua`.

## Image list (`sandbox.nvim://image-list` / `sandbox.nvim://images`)

| Key | Action |
|---|---|
| `<CR>` / `i` | inspect |
| `h` | history |
| `t` | tag (prompts for target) |
| `D` | remove (confirm) |
| `R` | refresh list |

## Volume list (`sandbox.nvim://volume-list`) / Network list (`sandbox.nvim://network-list`)

| Key | Action |
|---|---|
| `<CR>` / `i` | inspect |
| `D` | remove (confirm) |
| `R` | refresh list |

## Multi-select (all list views above)

Select several lines in any Visual mode (`V`, `v`, `j`/`k` to extend, ...),
then press the same key you'd use on one line to apply it to every
selected entry — `s`/`x`/`X`/`D` in the container list, `D` elsewhere. A
destructive bulk action (`D`, `X`) confirms once for the whole batch
instead of once per item (still gated by `confirm_destructive`, same as a
single-item action).

## Inspect view (`sandbox.nvim://inspect/<id>`)

Opened by any `inspect` action above. Renders the engine's JSON metadata
as a folded, indented `vim.inspect`-style Lua table (`foldmethod=indent`,
`foldlevel=1` — starts collapsed one level in) rather than a flat dump;
`za`/`zo`/`zc` toggle sections, `q` closes the buffer.

Cross-reference: `docs/BINDINGS.md` "## Keymaps" section and
`doc/sandbox.txt` (native `:help sandbox`, added 2026-07-26) carry the
same tables — kept in sync with this file.

## `E` and `f` in every list view (2026-08-24)

Both wired centrally in `list_actions.set_keymaps`, so every list buffer
gets them; both appear in the `?` overlay.

| lhs | action | desc |
| --- | --- | --- |
| `E` | Cycle docker → podman → nerdctl for the session, then re-render | "sandbox: cycle container engine" |
| `f` | Filter the list (only where the view supplies a `filter` callback) | "sandbox: filter this list" |

`f` is **not** `/`: Vim's search finds a line and leaves the rest on screen.
`f` narrows the buffer and matches across every *field* of an entry — for a
container that is name, id, status and image — so `f redis` finds the
container running that image even though the image is not in the rendered
line. Empty query restores everything; filtering starts from the unfiltered
set, so a second filter widens instead of compounding.

`E` re-renders because a list belongs to the engine that produced it —
leaving stale rows after a switch would be worse than not offering the key.

**Bulk confirmations now name their items** (capped at ten). "Remove 5
containers?" left open the one question a bulk confirmation must answer,
given a Visual selection is easy to get a line wrong and the action is
irreversible.

The count audit's "no count, use Visual multi-select" verdict is unchanged —
neither key takes one.
