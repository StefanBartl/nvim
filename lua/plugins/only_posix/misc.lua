-- plugins.platform.posix.lua
---@type LazyPluginSpec[]
return {
  {
    "3rd/image.nvim",
    cond = function()
      local os = (vim.uv or vim.loop).os_uname().sysname
      local has_magick = vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1
      return os ~= "Windows_NT" and has_magick
    end,
    opts = { processor = "magick_cli" },
  },
}
