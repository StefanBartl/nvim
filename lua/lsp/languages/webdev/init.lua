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

  -- WASM/WAT Filetype Detection
  vim.filetype.add({
    extension = {
      wasm = "wasm",
      wat = "wasm",
    },
  })
end

return M
