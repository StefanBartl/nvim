---@module 'lib.buf_win_tab.resize_guarded'
--- Provides a helper to create window-resize mappings that are disabled
--- for specific buffer filetypes or buffer names. Useful for terminals,
--- floating windows, or plugin-specific buffers like lazygit.

--[[ Usage:
-- local resize_guarded = require("lib.buf_win_tab.resize_guarded")
-- local exclude_filetypes = { "terminal" }
-- local exclude_names = { ".*lazygit.*" }
--
-- vim.keymap.set({ "n", "t" }, "<S-h>", resize_guarded.create("vertical resize -5", exclude_filetypes, exclude_names), { desc = "[Window] Resize narrower" })
-- vim.keymap.set({ "n", "t" }, "<S-l>", resize_guarded.create("vertical resize +5", exclude_filetypes, exclude_names), { desc = "[Window] Resize wider" })
-- vim.keymap.set({ "n", "t" }, "<S-k>", resize_guarded.create("resize +5", exclude_filetypes, exclude_names), { desc = "[Window] Resize taller" })
-- vim.keymap.set({ "n", "t" }, "<S-j>", resize_guarded.create("resize -5", exclude_filetypes, exclude_names), { desc = "[Window] Resize shorter" })
--
-- * `exclude_filetypes`: checks against `vim.bo[buf].filetype`.
-- * `exclude_names`: checks against `vim.api.nvim_buf_get_name(buf)` using a Lua pattern. -- * The module generates a clean, reusable function for all mappings.
--]]


local api = vim.api

---@param cmd string Command to execute for resizing, e.g., "vertical resize -5"
---@param exclude_filetypes? string[] List of buffer filetypes to ignore (optional)
---@param exclude_names? string[] List of buffer name patterns (Lua patterns) to ignore (optional)
---@return fun(): nil Function suitable for mapping in `vim.keymap.set`
local function create(cmd, exclude_filetypes, exclude_names)
  exclude_filetypes = exclude_filetypes or {}
  exclude_names = exclude_names or {}

  return function()
    local buf = api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype or ""
    local name = api.nvim_buf_get_name(buf) or ""

    -- Skip if the buffer's filetype is in the excluded list
    for _, v in ipairs(exclude_filetypes) do
      if ft == v then
        return
      end
    end

    -- Skip if the buffer's name matches any excluded pattern
    for _, pat in ipairs(exclude_names) do
      if name:match(pat) then
        return
      end
    end

    -- Execute the resize command
    vim.cmd(cmd)
  end
end

return {
  create = create,
}
