---@module 'lsp.servers.marksman'
--- LSP setup for the Marksman Markdown language server with scoped diagnostic filtering.

---@class MarksmanServer
local M = {}

M.cfg = {
  suppress_missing_doc_links = true,
  missing_doc_links_pattern = "^Link to non%-existent document",
  root_dir_fallbacks = { ".marksman.toml", ".git" },
  filetypes = { "markdown" }, -- keep MDX only if needed by your project
}

--- Build a robust root_dir resolver for Marksman.
--- Uses .marksman.toml or .git to ensure multi-file mode (so links get resolved across the workspace).
---@return fun(fname:string):string
local function make_root_dir_resolver()
  local ok, util = pcall(require, "lspconfig.util")
  if not ok then
    -- Defensive fallback: return directory of the file
    return function(fname)
      local dir = vim.fs.dirname(fname)
      return dir or vim.loop.cwd()
    end
  end
  return function(fname)
    -- Try preferred markers first
    local detector = util.root_pattern(unpack(M.cfg.root_dir_fallbacks))
    local root = detector and detector(fname) or nil
    if root then return root end
    -- Optional: add project-specific fallbacks here (example names)
    root = util.root_pattern("Notes", "docs")(fname)
    return root or util.path.dirname(fname)
  end
end

--- Return a per-client publishDiagnostics handler that filters selected Marksman messages.
---@return fun(err,lspresult,ctx,config)
local function make_marksman_diagnostics_handler()
  local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

  --- Wrap the default handler, filtering only when the client is Marksman and the message matches.
  ---@param err any
  ---@param result table|nil
  ---@param ctx table
  ---@param config table|nil
  return function(err, result, ctx, config)
    -- Fast path if nothing to do
    if not result or not result.diagnostics or not ctx or not ctx.client_id then
      return default_handler(err, result, ctx, config)
    end

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client or client.name ~= "marksman" then
      return default_handler(err, result, ctx, config)
    end

    -- Apply filter only if enabled
    local diags = result.diagnostics
    if M.cfg.suppress_missing_doc_links and type(diags) == "table" then
      local filtered = {} ---@type table[]
      local patt = M.cfg.missing_doc_links_pattern or ""
      for _, d in ipairs(diags) do
        -- Defensive: keep any diagnostic that doesn't match the pattern
        local msg = (type(d) == "table" and type(d.message) == "string") and d.message or ""
        if not (patt ~= "" and msg:match(patt)) then
          filtered[#filtered + 1] = d
        end
      end
      -- Only replace diagnostics if something changed
      if #filtered ~= #diags then
        -- Deep-copy result to avoid mutating shared tables from the client
        local new_result = vim.tbl_deep_extend("force", {}, result, { diagnostics = filtered })
        return default_handler(err, new_result, ctx, config)
      end
    end

    return default_handler(err, result, ctx, config)
  end
end

---@param shared {capabilities: table, on_attach: fun(client,bufnr), on_init: fun(client,init_result):boolean}
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  lspconfig.marksman.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    filetypes = M.cfg.filetypes, -- keep this minimal; MDX only if you actually need it
    root_dir = make_root_dir_resolver(),
    settings = {
      -- NOTE: Marksman’s own config primarily lives in .marksman.toml at project root.
      -- This 'settings' table is left in place for future extensions; Marksman currently
      -- doesn't expose a server-side toggle to disable the broken-link check.
    },
    handlers = {
      -- Filter only for this client, leaving other servers untouched.
      ["textDocument/publishDiagnostics"] = make_marksman_diagnostics_handler(),
    },
  })
end

return M
