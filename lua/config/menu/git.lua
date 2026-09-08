---@module 'config.menu.git'
--- The Git section of the right-click menu, as our own item list.
---
--- It used to be nvzone/menu's `menus.gitsigns`, pulled in by name
--- (`items = "gitsigns"`). That made a data file of a third-party plugin part
--- of this config's menu, so the section would have vanished the moment
--- nvzone/menu was uninstalled -- exactly what the move to
--- `lib.nvim.contextmenu`'s kit renderer is meant to make possible. The
--- entries are the same ones, minus `undo_stage_hunk` (deprecated in
--- gitsigns.nvim in favour of `stage_hunk` toggling on a staged hunk).
---
--- Every entry is gated on gitsigns.nvim actually being loaded, so the whole
--- section disappears rather than offering commands that would error.

local contextmenu = require("lib.nvim.contextmenu")
local icons = require("config.menu.icons")

--- `table.unpack` does not exist in this Neovim: it ships LuaJIT without the
--- 5.2 compatibility layer, so the name is Lua 5.1's global `unpack`. Every
--- entry below went through `table.unpack` and therefore errored the moment
--- it was picked -- silently, because the failure was inside the callback the
--- menu runs, not on the path that builds it.
local unpack_args = table.unpack or unpack

local M = {}

--- Whether gitsigns.nvim is available to act on.
---@return boolean
local function has_gitsigns()
  return package.loaded["gitsigns"] ~= nil or vim.fn.exists(":Gitsigns") == 2
end

--- Run one gitsigns action by name, resolved at call time so this file never
--- forces the plugin to load.
---@param name string
---@param ... any
---@return fun()
local function gs(name, ...)
  local args = { ... }
  return function()
    local ok, gitsigns = pcall(require, "gitsigns")
    if not ok or type(gitsigns[name]) ~= "function" then
      require("lib.nvim.notify")
        .create("[config.menu.git]")
        .warn(("gitsigns.%s is not available"):format(name))
      return
    end
    gitsigns[name](unpack_args(args))
  end
end

--- The Git entries for the current buffer, or an empty list when
--- gitsigns.nvim isn't there.
---@return Lib.ContextMenu.Item[]
function M.items()
  local out = {}
  if not has_gitsigns() then
    return out
  end

  -- Named sections here too: the Git fly-out is long enough that "which of
  -- these act on a hunk" is a question the frame can answer for free.
  contextmenu.group(
    out,
    contextmenu.heading("Hunks"),
    contextmenu.entry(true, "Stage Hunk", gs("stage_hunk"), "sh", { icon = icons.git_stage }),
    contextmenu.entry(true, "Reset Hunk", gs("reset_hunk"), "rh", { icon = icons.git_reset }),
    contextmenu.entry(
      true,
      "Stage Buffer",
      gs("stage_buffer"),
      "sb",
      { icon = icons.git_stage_buffer }
    ),
    contextmenu.entry(
      true,
      "Reset Buffer",
      gs("reset_buffer"),
      "rb",
      { icon = icons.git_reset_buffer }
    ),
    contextmenu.entry(true, "Preview Hunk", gs("preview_hunk"), "hp", { icon = icons.git_preview })
  )

  contextmenu.group(
    out,
    contextmenu.heading("Blame"),
    contextmenu.entry(true, "Blame Line", function()
      local ok, gitsigns = pcall(require, "gitsigns")
      if ok then
        gitsigns.blame_line({ full = true })
      end
    end, "b", { icon = icons.git_blame }),
    contextmenu.entry(
      true,
      "Toggle Current Line Blame",
      gs("toggle_current_line_blame"),
      "tb",
      { icon = icons.git_toggle }
    )
  )

  contextmenu.group(
    out,
    contextmenu.heading("Diff"),
    contextmenu.entry(true, "Diff This", gs("diffthis"), "dt", { icon = icons.git_diff }),
    contextmenu.entry(
      true,
      "Diff Last Commit",
      gs("diffthis", "~"),
      "dc",
      { icon = icons.git_history }
    ),
    contextmenu.entry(
      true,
      "Toggle Deleted",
      gs("toggle_deleted"),
      "td",
      { icon = icons.git_toggle }
    )
  )

  return out
end

return M
