---@module 'bindings.mappings.noice'
---Noice-specific key mappings that are only active in buffers with filetype "noice*".

local M = {}

local Autocmd = require("lib.nvim.autocmd")

---@return nil
function M.setup()
  local map = vim.g.__map_helper
  local ok1, noice = pcall(require, "noice")
  local ok2, noice_lsp = pcall(require, "noice.lsp")

  -- Create an augroup for Noice mappings
  local grp = vim.api.nvim_create_augroup("NoiceBufferMaps", { clear = true })

  -- Autocmd to set mappings only for buffers with filetype starting with "noice"
  Autocmd.create("FileType", function(ev)
    local bufnr = ev.buf

    -- Scroll forward
    map({ "n", "i", "s" }, "<A-j>", function()
      if not ok2 or not noice_lsp.scroll(4) then
        return "<c-f>"
      end
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

    map({ "n", "i", "s" }, "<A-Down>", function()
      if not ok2 or not noice_lsp.scroll(4) then
        return "<c-f>"
      end
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

    -- Scroll backward
    map({ "n", "i", "s" }, "<A-k>", function()
      if not ok2 or not noice_lsp.scroll(-4) then
        return "<c-b>"
      end
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

    map({ "n", "i", "s" }, "<A-Up>", function()
      if not ok2 or not noice_lsp.scroll(-4) then
        return "<c-b>"
      end
    end, { buffer = bufnr, silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

    -- Dismiss UI
    map({ "n", "i" }, "<A-x>", function()
      if ok1 then
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
