---@module 'plugins.webdev'
--- resty.nvim's lazy.nvim spec -- an HTTP client, kept out of startup.
---
--- This used to be `event = "VeryLazy"`, which made it one of the most
--- expensive things in the whole startup -- not so much by itself (243ms) as
--- by what it drags along. Loading resty sources its `plugin/resty.lua`, whose
--- `require("resty")` hits a top-level `pcall(require, "telescope")` in
--- resty/init.lua:62, and its `after/plugin/resty_http_cmp.lua`, which opens
--- with `require("cmp")`. So a VeryLazy resty pulled in telescope (74ms,
--- defeating its own `cmd = "Telescope"`) plus nvim-cmp (148ms, defeating its
--- own `event = "InsertEnter"`) plus LuaSnip (97ms) and the cmp sources --
--- roughly 600ms, for an HTTP client nobody had opened a file for.
---
--- ## Why not `ft = { "http", "resty" }`
---
--- Because it makes things worse, which is worth writing down. To get a
--- plugin's `ftdetect/` to run before the plugin itself is loaded, lazy.nvim
--- puts `ft` plugins on the runtimepath early and marks them `_.rtp_loaded`.
--- But `loader.get_start_plugins()` selects on
--- `not plugin._.loaded and (plugin._.rtp_loaded or plugin.lazy == false)` --
--- so an `rtp_loaded` plugin is pulled into the startup batch regardless of
--- `lazy = true`. Measured: with `ft`, lazy reported
--- `_.loaded = { start = "start" }` and resty loaded on every start; without
--- it, `_.loaded = nil` and it is not on the runtimepath at all.
---
--- So the filetype trigger is wired here instead. `vim.filetype.add` supplies
--- what resty's own `ftdetect/resty.lua` would have (`.http` Neovim already
--- knows natively), and the autocmd's `require` is what actually asks lazy to
--- load the plugin -- at the moment such a file is opened, not before.
--- `once` is enough: the plugin stays loaded afterwards.

return {
  {
    "lima1909/resty.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Resty",
    init = function()
      vim.filetype.add({ extension = { resty = "resty" } })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "http", "resty" },
        once = true,
        desc = "Load resty.nvim on its own filetypes (see plugins/webdev.lua)",
        callback = function()
          pcall(require, "resty")
        end,
      })
    end,
  },
}
