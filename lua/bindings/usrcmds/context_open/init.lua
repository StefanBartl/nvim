---@module 'bindings.usrcmds.context_open'
--- `M-o` / `M-O` / `:ContextOpen` -- one dispatcher unifying "open the thing
--- under the cursor" across gopath.nvim (gF), markdown.nvim (TableView),
--- images.nvim, pdfport.nvim and open.nvim, instead of a different keymap
--- per plugin. See README.md for the full design and an extension guide.
---
--- `M.open()`  (M-o, bare `:ContextOpen`): resolve every provider
--- (`context_open.providers`) against the cursor position. Zero matches ->
--- search the rest of the current line instead (`context_open.scan`). Zero
--- candidates either way -> notify. One -> run it directly. More than one ->
--- `lib.nvim.ui.kit.select` ("Open with…"), the same ambiguity-picker
--- pattern open.nvim's own `open.picker` uses.
---
--- `M.list()`  (M-O, `:ContextOpen list`): every openable target in the
--- whole buffer (`context_open.scan.buffer_targets`), picked from one list;
--- selecting an entry jumps the cursor to it and runs its action.

local composer = require("lib.nvim.bindings.usercmd.composer")
local providers = require("bindings.usrcmds.context_open.providers")
local scan = require("bindings.usrcmds.context_open.scan")

local M = {}

---@return table notify handle
local function notify()
  return require("lib.nvim.notify").create("[context_open]")
end

---Show `candidates` and act on the choice: run the sole candidate directly,
---prompt when there is more than one, notify `empty_msg` when there are none.
---@internal
---@param candidates ContextOpen.Candidate[]
---@param empty_msg string
local function resolve_candidates(candidates, empty_msg)
  if #candidates == 0 then
    notify().warn(empty_msg)
    return
  end
  if #candidates == 1 then
    candidates[1].run()
    return
  end
  require("lib.nvim.ui.kit").select({
    title = "Open with…",
    items = candidates,
    respect_override = true,
    format_item = function(c)
      return c.label
    end,
    on_select = function(c)
      if c then
        c.run()
      end
    end,
  })
end

---Open whatever is under the cursor. The `M-o` / bare `:ContextOpen` action.
---@return nil
function M.open()
  local ok_ctx, context = pcall(function()
    require("bindings.usrcmds.context_open.util").ensure_loaded("open.nvim")
    return require("open.context")
  end)
  if not ok_ctx then
    notify().error("open.nvim unavailable")
    return
  end

  local signals = context.gather()
  local candidates = providers.collect(signals)

  if #candidates > 0 then
    resolve_candidates(candidates, "Nothing to open here")
    return
  end

  -- Nothing directly under the cursor: fall back to scanning the rest of
  -- the line for something openable.
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  resolve_candidates(scan.line_targets(lnum), "Nothing to open on this line")
end

---List every openable target in the buffer. The `M-O` / `:ContextOpen list` action.
---@return nil
function M.list()
  local candidates = scan.buffer_targets()
  if #candidates == 0 then
    notify().warn("No openable targets found in this buffer")
    return
  end

  require("lib.nvim.ui.kit").select({
    title = ("Open — buffer targets (%d)"):format(#candidates),
    items = candidates,
    respect_override = true,
    format_item = function(c)
      return c.label
    end,
    on_select = function(c)
      if not c then
        return
      end
      if c.lnum then
        pcall(vim.api.nvim_win_set_cursor, 0, { c.lnum, c.col or 0 })
      end
      c.run()
    end,
  })
end

---@return nil
function M.enable()
  composer.verb("ContextOpen", {
    desc = "Open whatever is under the cursor (gopath/markdown/images/pdfport/open.nvim, unified)",
    default = function()
      M.open()
    end,
    routes = {
      {
        path = { "list" },
        desc = "List every openable target in the buffer",
        run = function()
          M.list()
        end,
      },
    },
  })
end

return M
