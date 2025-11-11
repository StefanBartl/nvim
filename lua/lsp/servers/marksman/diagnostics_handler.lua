---@module 'lsp.servers.marksman.diagnostics_handler'
--- Marksman diagnostics filter factory.

local cfg = require("lsp.servers.marksman.config")

--- Wrap default diagnostics to filter specific Marksman messages only.
--- @return fun(err:any,result:table|nil,ctx:table,config:table|nil)
return function()
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
    if cfg.suppress_missing_doc_links and type(diags) == "table" then
      local patt = cfg.missing_doc_links_pattern or ""
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
