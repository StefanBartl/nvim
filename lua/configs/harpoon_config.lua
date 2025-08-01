-- Load Telescope extension 'harpoon' if available
pcall(function()
  require("telescope").load_extension("harpoon")
end)

-- Determine OS-specific root directory
local is_win = vim.fn.has("win32") == 1
local root = is_win and "E:\\" or vim.fn.expand("~/")

-- Define relevant paths to be added to Harpoon
local mappings_file = vim.fn.expand("~/.config/nvim/lua/mappings.lua")
local builtin_file = vim.fn.expand(root .. "/MyGithub/Notes/CLI-Notes/CLI-Builtin.md")
local tools_file = vim.fn.expand(root .. "/MyGithub/Notes/CLI-Notes/CLI-Tools.md")

-- Autocmd: On VimEnter, defer Harpoon integration
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local utils_ok, utils = pcall(require, "harpoon.utils")
    if not utils_ok then return end

    local paths = {
      utils.normalize_path(mappings_file),
      utils.normalize_path(builtin_file),
      utils.normalize_path(tools_file),
    }

    local attempts = 0
    local stopped = false
    local timer = vim.loop.new_timer()

    ---@param path string
    ---@param mark any
    ---@return boolean
    local function file_already_marked(path, mark)
      for i = 1, mark.get_length() do
        if mark.get_marked_file_name(i) == path then
          return true
        end
      end
      return false
    end

    timer:start(50, 50, vim.schedule_wrap(function()
      if stopped then return end
      attempts = attempts + 1

      local ok, mark = pcall(require, "harpoon.mark")
      if not ok or not mark or type(mark.add_file) ~= "function" then
        if attempts > 20 then
          stopped = true
          if not timer:is_closing() then
            timer:stop()
            timer:close()
          end
        end
        return
      end

      stopped = true
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end

      for _, path in ipairs(paths) do
        if not file_already_marked(path, mark) then
          pcall(mark.add_file, path)
        end
      end
    end))
  end,
})
