-- Real Neovim, real hover.nvim, the real config's updatetime.
vim.opt.rtp:append("E:/repos/hover.nvim")
vim.opt.rtp:append("E:/repos/lib.nvim")
vim.opt.rtp:append(vim.env.PROBE_DIR)

vim.opt.updatetime = 200 -- what lua/options.lua sets in the config being modelled
vim.opt.swapfile = false

-- Prose with no path shape in it, so `target_under_cursor` declines and the
-- position pipeline is what gets asked -- which is the thing being counted.
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].buftype = ""
vim.bo[buf].filetype = "text"
local lines = {}
for i = 1, 40 do
  lines[i] = ("line %d with some ordinary prose and nothing that looks like a target"):format(i)
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

require("position_probe").install()
require("hover").enable() -- defaults: trigger CursorHold, delay_ms 250
require("hover").attach(buf)
