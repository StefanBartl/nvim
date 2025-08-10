---@module 'mappings.custom'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>fs", function()
    local ok, mod = pcall(require, "usrcmds.system_find"); if ok then mod.system_find() end
  end, { desc = "[Custom] Systemwide filesearch" })

  map("n", "<leader>cd", "<cmd>CompressDir<CR>", { desc = "[Custom] Compress & copy current dir to ~/temp" })
  map("n", "<leader>cp", function()
    vim.fn.setreg("+", vim.fn.expand("%:p"))
    print("Copied path to clipboard")
  end, { desc = "[General] Copy file path" })
end

return M
