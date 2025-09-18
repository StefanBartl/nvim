---@module 'lsp.servers.marksman'
--- Marksman (Markdown) via native LSP config/enable with scoped diagnostics filter.

---@class MarksmanServer
local M = {}

M.cfg = {
  suppress_missing_doc_links = true,
  missing_doc_links_pattern = "^Link to non%-existent document",
  root_dir_fallbacks = { ".marksman.toml", ".git" },
  filetypes = { "markdown" },
}

--- Root resolver using vim.fs (no lspconfig.util dependency).
---@return fun(fname:string):string|nil
local function make_root_dir_resolver()
  return function(fname)
    local dir = vim.fs.dirname(fname)
    if not dir or dir == "" then return vim.uv.cwd() end
    local root = vim.fs.root(dir, M.cfg.root_dir_fallbacks)
    return root or dir
  end
end

--- Wrap default diagnostics to filter specific Marksman messages only.
---@return fun(err:any,result:table|nil,ctx:table,config:table|nil)
local function make_marksman_diagnostics_handler()
  local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
  return function(err, result, ctx, config)
    if not result or not result.diagnostics or not ctx or not ctx.client_id then
      return default_handler(err, result, ctx, config)
    end
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client or client.name ~= "marksman" then
      return default_handler(err, result, ctx, config)
    end
    local diags = result.diagnostics
    if M.cfg.suppress_missing_doc_links and type(diags) == "table" then
      local patt = M.cfg.missing_doc_links_pattern or ""
      local filtered = {}
      for i = 1, #diags do
        local d = diags[i]
        local msg = (type(d) == "table" and type(d.message) == "string") and d.message or ""
        if not (patt ~= "" and msg:match(patt)) then
          filtered[#filtered + 1] = d
        end
      end
      if #filtered ~= #diags then
        local new_result = vim.tbl_deep_extend("force", {}, result, { diagnostics = filtered })
        return default_handler(err, new_result, ctx, config)
      end
    end
    return default_handler(err, result, ctx, config)
  end
end

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) == "table" then
    vim.lsp.config("marksman", {
      cmd = { "marksman", "server" },
      filetypes = M.cfg.filetypes,
      -- Use function for parity; alternatively: root_markers = M.cfg.root_dir_fallbacks
      root_dir = make_root_dir_resolver(),
      capabilities = shared.capabilities,
      on_attach = shared.on_attach,
      on_init = shared.on_init,
      handlers = {
        ["textDocument/publishDiagnostics"] = make_marksman_diagnostics_handler(),
      },
      single_file_support = false, -- encourage multi-file workspace for link resolution
    })
    if opts.enable ~= false then pcall(vim.lsp.enable, "marksman") end
  end
end

return M
