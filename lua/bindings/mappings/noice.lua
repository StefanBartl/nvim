---@module 'bindings.mappings.noice'
---Noice-specific key mappings that are only active in buffers with filetype "noice*".

local M = {}

local Autocmd = require("lib.nvim.bindings.autocmd")

---@return nil
function M.setup()
  local map = vim.g.__map_helper

  -- noice is required inside the callbacks, not here. Requiring at setup() time
  -- force-loaded the plugin on every startup despite its lazy spec, purely to
  -- define keymaps that can only ever fire inside a noice buffer — by which
  -- point noice is loaded by definition.
  ---@return table|nil
  local function noice_lsp()
    local ok, mod = pcall(require, "noice.lsp")
    return ok and mod or nil
  end

  --- Scroll the noice LSP float, or fall back to the plain scroll key.
  ---@param delta integer
  ---@return string|nil
  local function scroll(delta)
    local mod = noice_lsp()
    if not mod or not mod.scroll(delta) then
      return delta > 0 and "<c-f>" or "<c-b>"
    end
  end

  -- Create an augroup for Noice mappings
  local grp = Autocmd.group("NoiceBufferMaps", true)

  -- Autocmd to set mappings only for buffers with filetype starting with "noice"
  Autocmd.create("FileType", function(ev)
    local bufnr = ev.buf

    -- Scroll forward
    map({ "n", "i", "s" }, "<A-j>", function()
      return scroll(4)
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

    map({ "n", "i", "s" }, "<A-Down>", function()
      return scroll(4)
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

    -- Scroll backward
    map({ "n", "i", "s" }, "<A-k>", function()
      return scroll(-4)
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

    map({ "n", "i", "s" }, "<A-Up>", function()
      return scroll(-4)
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

    -- Dismiss UI
    map({ "n", "i" }, "<A-x>", function()
      local ok, noice = pcall(require, "noice")
      if ok then
        noice.cmd("dismiss")
      end
    end, { buffer = bufnr, desc = "[Noice] Dismiss UI" })
  end, {
    group = grp,
    pattern = "noice*",
    desc = "Set Noice buffer-local keymaps",
  })
end

return M
