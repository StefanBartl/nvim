---@module 'lsp.languages.webdev'

local M = {}

function M.enable_all()
local langs = { "astro", "htmx", "tailwind", "typescript", "html" }

  for _, name in ipairs(langs) do
    local ok, mod = pcall(require, "lsp.languages.webdev." .. name)
    if ok and type(mod.enable) == "function" then
      pcall(mod.enable)
    end
  end

  vim.filetype.add({
    extension = {
      wasm = "wasm",
      wat = "wasm",
      astro = 'astro',
    },
  })
end

return M
