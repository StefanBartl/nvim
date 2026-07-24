# Wiring replacer.nvim's progress indicator into your statusline

Personal integration notes for your `wkdnvchad` config — not part of any repo
docs, just for you. Covers: your lazy.nvim spec, and adding a `replacer`
component to your NvChad-based statusline theme(s) using the same pattern as
your existing `neotest_module`.

---

## 1. Lazy.nvim spec

You need `lib.nvim` as a dependency (it's what actually implements the
progress indicator; replacer.nvim only consumes it) plus `progress_style =
"statusline"`:

```lua
{
  "StefanBartl/replacer.nvim",
  cmd = { "Replace", "Replacer" }, -- you only had "Replace" — Replacer is the alias, add it too if you use it
  dependencies = {
    "ibhagwan/fzf-lua",
    "StefanBartl/lib.nvim", -- new: enables the progress indicator, no other effect
  },
  config = function()
    require("replacer").setup({
      engine = "telescope",
      default_scope = "%",
      progress_style = "statusline",
    })
  end,
},
```

Since you already keep `lib.nvim` on your machine at `E:\repos\lib.nvim` and
presumably reference it locally elsewhere in this config (you use
`require("lib.lua.lazy")` and `require("lib.nvim.notify")` throughout your
statusline modules already), lazy.nvim will just resolve
`"StefanBartl/lib.nvim"` the normal way (or point it at your local checkout
with `dir = "E:/repos/lib.nvim"` if you develop it locally and want changes to
apply without a git push/pull round-trip).

---

## 2. A `replacer_progress` statusline module

**Important naming note:** your `wkdnvchad.config.statusline.*` themes already
use the key `"progress"` for cursor row/col position (see `base.lua`,
`custom_light.lua`, `lspbased.lua`). Do **not** reuse that name — call the new
one `"replacer_progress"` to avoid clobbering it.

This follows the exact same shape as your `neotest_module` (a function
returning a highlighted string, `""` when there's nothing to show):

```lua
-- lua/wkdnvchad/ui/statusline/modules/replacer_progress/init.lua
---@module 'wkdnvchad.ui.statusline.modules.replacer_progress'

return function()
  local ok, sl = pcall(require, "lib.nvim.progress.styles.statusline")
  if not ok then return "" end

  local active = sl.active() -- string[], oldest first, shared across all lib.nvim.progress users
  if #active == 0 then return "" end

  -- Same highlight convention as neotest_module: blue while running.
  return " %#St_LspProgress#󰥩 " .. active[1] .. " "
end
```

Only `active[1]` is shown (the oldest still-running operation) to keep the
statusline from growing unbounded if something ever stacks up multiple
searches; drop the `[1]` and `table.concat(active, " | ")` instead if you'd
rather see all of them.

---

## 3. Wire it into `custom.lua` (and any other theme you use)

In `lua/wkdnvchad/config/statusline/custom.lua`, add it to both `modules` and
`order`:

```lua
local replacer_progress = lazy.require("wkdnvchad.ui.statusline.modules.replacer_progress")

return {
  base46 = require("wkdnvchad.config.base46"),
  ui = {
    statusline = {
      theme = "minimal",
      separator_style = "round",

      order = {
        "mode",
        "git",
        "%=",
        "breadcrumbs",
        "%=",
        "diagnostics",
        "lsp",
        "replacer_progress", -- new
        "cursor",
      },

      modules = {
        -- ...your existing mode/git/breadcrumbs/diagnostics/lsp/cursor entries...

        replacer_progress = function()
          return replacer_progress()
        end,
      },
    },
  },
}
```

(`lazy.require` returns the module table on first access, and since
`replacer_progress/init.lua` above returns a bare function rather than a
table, `replacer_progress` in `custom.lua` already *is* that callable function
— you can register `modules.replacer_progress = replacer_progress` directly
without the wrapper closure, exactly like your other `lazy.require`d modules
such as `hl_module`/`lsp_module` are used directly in `custom.lua` today.)

If you also use `custom_light.lua`, `custom_minimal.lua`, `lspbased.lua`, or
`base.lua` (they all use the same `order` + `modules` shape, per the grep
below), repeat the same two additions there:

```
lua/wkdnvchad/config/statusline/base.lua
lua/wkdnvchad/config/statusline/custom.lua
lua/wkdnvchad/config/statusline/custom_light.lua
lua/wkdnvchad/config/statusline/custom_minimal.lua
lua/wkdnvchad/config/statusline/lspbased.lua
```

---

## 4. What you'll actually see

- Nothing, for any search that finishes in under ~150ms (delay-guard in
  `lib.nvim.progress`) — no flicker on small/fast searches.
- ` 󰥩 [replacer] 42 match(es) found… (3/9) ` while a bigger `cwd` search is
  running, updating live.
- It disappears again as soon as the search finishes or is cancelled — no
  manual cleanup needed, `active()` empties itself.
- Live updates happen even if you never move the cursor: the `"statusline"`
  style calls `:redrawstatus` on every change internally, so you don't need
  any extra autocmd/timer on your side for this to refresh while idle.

## 5. If you'd rather not touch your statusline at all

`progress_style = "float"` is a zero-config alternative: a small
non-focus-stealing corner window that also lets you cancel a long search by
focusing it and pressing `<Esc>` (with an English "Yes/No" confirm — no
accidental cancels from any other window, the keymap is buffer-local to that
window). Worth trying before committing to the statusline wiring above if you
just want something that works out of the box.
