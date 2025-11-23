---@module 'plugins.linux_only'
--- Return a Lazy plugin spec array only when running on Linux.
--- Always return a table (possibly empty) so `{ import = "plugins" }` safe bleibt.
---@type LazyPluginSpec[]
local specs = {}

local function is_linux()
  local ok, sysname = pcall(function() return vim.loop and vim.loop.os_uname and vim.loop.os_uname().sysname end)
  if ok and type(sysname) == "string" and sysname == "Linux" then
    return true
  end
  -- optional: treat WSL as linux when env var is set
  if vim.env and vim.env.INCLUDE_WSL_AS_LINUX == "1" and vim.env.WSL_DISTRO_NAME then
    return true
  end
  return false
end

if is_linux() then
  specs = {
    {
      "3rd/image.nvim",
      build = false,
      lazy = false,
      opts = {
        processor = "magick_cli",
        integrations = {
          markdown = {
            only_render_image_at_cursor = true,
            only_render_image_at_cursor_mode = "popup",
          },
        },
      },
    },
  }
end

return specs
