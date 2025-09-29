---@module 'lsp.languages'

local M = {}

function M.enable_all()
local langs = { "markdown", "shell", "typescript" } -- add "lua", "go",...
  for _, name in ipairs(langs) do
    local ok, mod = pcall(require, "lsp.languages." .. name)
    if ok and type(mod.enable) == "function" then pcall(mod.enable) end
  end
end

return M
