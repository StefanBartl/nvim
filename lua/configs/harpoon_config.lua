-- If available activate Telescope-Extension
pcall(function()
  require("telescope").load_extension("harpoon")
end)

---@description
--- On VimEnter, defer 50ms and then auto-add a specific file to Harpoon slot list.
--- Skips operation if Harpoon or required function is unavailable.
--- Intended to auto-persist a frequently accessed config file (e.g., mappings.lua).
---@event VimEnter
---@defer 50ms
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      local ok, harpoon_mark = pcall(require, "harpoon.mark")
      if not ok or not harpoon_mark or type(harpoon_mark.get_mark) ~= "function" then
        --vim.notify("Harpoon.mark ist noch nicht bereit", vim.log.levels.WARN)
        return
      end

      local file = vim.fn.expand("~/.config/nvim/lua/mappings.lua")

      for i = 1, harpoon_mark.get_length() do
        if harpoon_mark.get_mark(i) == file then
          return
        end
      end

      harpoon_mark.add_file(file)
    end, 50) -- wait 50 ms to make sure Harpoon is initialized
  end,
})
