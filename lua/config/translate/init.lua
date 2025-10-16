---@module 'translate.init'
---Orchestrates translate.nvim modules

-- load dependencies if not if not already done
-- require("translate").setup({
--     default = { command = "deepl_pro" },
--     preset = { output = { replace = true } },
-- })

require("config.translate.replace")
require("config.translate.usercommands")
require("config.translate.keymaps")
