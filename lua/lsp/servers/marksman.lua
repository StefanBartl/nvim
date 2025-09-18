---@module 'lsp.servers.marksman'
--- Marksman (Markdown) via native LSP config/enable with scoped diagnostics filter.
--- This version makes `root_dir` compatible with both legacy lspconfig-style
--- callers (fname: string) and the new native `vim.lsp` pipeline
--- (bufnr: integer, cb?: fun(root:string)), preventing "file: expected string, got number".
---
--- It also keeps a narrow diagnostics filter to suppress "missing doc link" noise.

---@class MarksmanServer
local M = {}

---@class MarksmanCfg
---@field suppress_missing_doc_links boolean
---@field missing_doc_links_pattern string
---@field root_dir_fallbacks string[]      -- project root markers
---@field filetypes string[]               -- LSP filetypes
M.cfg = {
  suppress_missing_doc_links = true,
  missing_doc_links_pattern = "^Link to non%-existent document",
  root_dir_fallbacks = { ".marksman.toml", ".git", "mkdocs.yml" },
  filetypes = { "markdown", "markdown.mdx" },
}

-- Resolve the current working directory via libuv, compatible across NVIM versions.
---@return string
local function _cwd()
  -- Prefer vim.uv on newer Neovim; fall back to vim.loop for older builds.
  local uv = vim.uv or vim.loop
  return uv and uv.cwd() or vim.fn.getcwd()
end

--------------------------------------------------------------------------------
-- Polymorphic root_dir resolver
--------------------------------------------------------------------------------

--- Build a resolver that accepts either:
---   1) (fname: string) → string              -- legacy lspconfig usage
---   2) (bufnr: integer, cb?: fun(root)) → s  -- native vim.lsp usage (async-capable)
---
--- In both cases it returns the root as a string and, if a callback is supplied,
--- calls it with the resolved root (required by the new `vim.lsp` enable flow).
---
--- @return fun(arg:(string|integer), cb?:fun(root:string)):string
local function make_root_dir_resolver()
  ---@param arg string|integer                 -- filename or bufnr
  ---@param cb fun(root:string)|nil            -- optional async callback
  ---@return string                            -- resolved root
  return function(arg, cb)
    -- Normalize to absolute file name
    ---@type string
    local fname
    if type(arg) == "number" then
      -- New API passes a buffer number
      fname = vim.api.nvim_buf_get_name(arg) or ""
    else
      -- Legacy API passes a filename path
      fname = tostring(arg or "")
    end
    if fname == "" then
      -- Fall back to CWD if no name is available (e.g., new unsaved buffer)
      fname = _cwd()
    end

    -- Compute directory component safely
    local dir = vim.fs.dirname(fname)
    if not dir or dir == "" then
      dir = _cwd()
    end

    -- Resolve project root using markers; fall back to the containing dir
    ---@type string
    local root = vim.fs.root(dir, M.cfg.root_dir_fallbacks) or dir

    -- Support async contract of the new vim.lsp pipeline
    if cb ~= nil then
      cb(root)
    end
    return root
  end
end

--------------------------------------------------------------------------------
-- Diagnostics filter (Marksman-specific)
--------------------------------------------------------------------------------

--- Wrap default diagnostics to filter specific Marksman messages only.
--- @return fun(err:any,result:table|nil,ctx:table,config:table|nil)
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
      ---@type table[]
      local filtered = {}
      for i = 1, #diags do
        ---@type table
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

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

--- Setup Marksman via native `vim.lsp.config()/enable()`.
--- @param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
--- @param opts { enable?: boolean }|nil
--- @return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  -- Only proceed if the native config API is available (Neovim 0.11+)
  if type(vim.lsp.config) == "table" then
    vim.lsp.config("marksman", {
      cmd = { "marksman", "server" },
      filetypes = M.cfg.filetypes,
      -- Important: the resolver must accept (bufnr, cb) in the new pipeline.
      root_dir = make_root_dir_resolver(),
      capabilities = shared.capabilities,
      on_attach = shared.on_attach,
      on_init = shared.on_init,
      handlers = {
        ["textDocument/publishDiagnostics"] = make_marksman_diagnostics_handler(),
      },
      -- Marksman benefits from multi-file workspaces for link resolution
      single_file_support = false,
    })

    if opts.enable ~= false then
      -- Enable now; attaches on FileType/BufReadPost per native pipeline
      pcall(vim.lsp.enable, "marksman")
    end
  end
end

return M
