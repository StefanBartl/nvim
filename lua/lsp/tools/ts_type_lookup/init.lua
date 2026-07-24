---@module 'lsp.tools.ts_type_lookup'

local M = {}

function M.setup()
  require("lsp.tools.ts_type_lookup.cmds").attach()
  require("lsp.tools.ts_type_lookup.ts_telescope_picker").attach()
  require("lsp.tools.ts_type_lookup.noice_integration")
end

return M
