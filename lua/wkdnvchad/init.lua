---@module 'wkdnvchad'
--- Entry point: `M.setup(opts)` turns on wkdnvchad's own submodules
--- (mappings, ...) selectively per `opts.all`/`opts.<name>` flag rather
--- than loading everything unconditionally.

local M = {}

---@param opts WkdNvC.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.all or opts.mappings then
    require("wkdnvchad.mappings").setup({ all = true })
  end

  if opts.all or opts.usrcmd then
    require("wkdnvchad.usrcmd").setup()
  end
end

return M
