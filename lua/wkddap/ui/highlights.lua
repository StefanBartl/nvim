local config = require("wkddap.config")

--FIX: MUSS DAS?

local M = {}

function M.setup()
  for name, hl in pairs(config.highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

return M
