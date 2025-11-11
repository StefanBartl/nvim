---@module 'lsp.usercmds'
---

local nvim_create_user_command = vim.api.nvim_create_user_command
local lsp = vim.lsp

local M = {}

local desc_tag = "[lsp] "

local function _active_servers()
  local ok, reg = pcall(require, "lsp.core.registry")
  if not ok or type(reg) ~= "table" then
    return {}
  end
  return { "lua_ls", "ts_ls", "gopls", "marksman" }
end

local function _buf_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

---@return nil
function M.attach()
  pcall(nvim_create_user_command, "LspStartHere", function()
    for _, name in ipairs(_active_servers()) do
      pcall(lsp.enable, name) -- (neu) native API
    end
  end, { desc = desc_tag .. "Start/attach configured LSP servers for current buffer (vim.lsp)" })

  pcall(nvim_create_user_command, "LspStopHere", function()
    local ids = {}
    for _, c in ipairs(_buf_clients(0)) do
      ids[#ids + 1] = c.id
    end
    if #ids > 0 then
      lsp.stop_client(ids, true)
    end
  end, { desc = desc_tag .. "Stop LSP clients attached to current buffer" })

  pcall(nvim_create_user_command, "LspRestartHere", function()
    local ids = {}
    for _, c in ipairs(_buf_clients(0)) do
      ids[#ids + 1] = c.id
    end
    if #ids > 0 then
      lsp.stop_client(ids, true)
    end
    vim.defer_fn(function()
      for _, name in ipairs(_active_servers()) do
        pcall(vim.lsp.enable, name)
      end
    end, 50)
  end, { desc = desc_tag .. "Restart LSP for current buffer (vim.lsp)" })
end

return M
