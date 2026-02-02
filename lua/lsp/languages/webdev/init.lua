---@module 'lsp.languages.webdev.init'

local M = {}

function M.enable_all()
  local langs = { "astro", "htmx", "tailwind" }
  for _, name in ipairs(langs) do
    local ok, mod = pcall(require, "lsp.languages.webdev." .. name)
    if ok and type(mod.enable) == "function" then
      pcall(mod.enable)
    end
  end
end

return M
