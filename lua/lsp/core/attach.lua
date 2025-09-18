---@module 'lsp.core.attach'
--- Build on_init/on_attach handlers; no dependency on lspconfig.

local M = {}

---@param bufnr integer
---@return boolean
local function has_valid_buf(bufnr)
  if type(bufnr) ~= "number" or bufnr <= 0 then return false end
  if not vim.api.nvim_buf_is_loaded(bufnr) then return false end
  local bt = vim.bo[bufnr].buftype
  if bt ~= "" and bt ~= "acwrite" then return false end
  return true
end

---@param opts { use_workspace_diagnostics?: boolean, use_lazydev?: boolean }|nil
---@return { on_attach: fun(client,bufnr), on_init: fun(client,init_result):boolean }
function M.build(opts)
  opts = opts or {}

  local function on_init(client, _)
    local ok, nvlsp = pcall(require, "nvchad.config.lspconfig")
    if ok and type(nvlsp.on_init) == "function" then pcall(nvlsp.on_init, client) end
    return true
  end

  local function on_attach(client, bufnr)
    if not client or type(client) ~= "table" then return end
    if not has_valid_buf(bufnr) then return end
    if not client.server_capabilities then return end

    if opts.use_workspace_diagnostics then
      local ok_wd, wd = pcall(require, "workspace-diagnostics")
      if ok_wd and type(wd.populate_workspace_diagnostics) == "function" then
        pcall(wd.populate_workspace_diagnostics, client, bufnr)
      end
    end

    if opts.use_lazydev and vim.bo[bufnr].filetype == "lua" then
      pcall(require, "lazydev")
    end

    local ok, nvlsp = pcall(require, "nvchad.config.lspconfig")
    if ok and type(nvlsp.on_attach) == "function" then pcall(nvlsp.on_attach, client, bufnr) end
  end

  return { on_attach = on_attach, on_init = on_init }
end

return M
