---@module 'lsp.languages'

local M = {}

function M.enable_all()
  local langs = { "markdown", "shell",  "lua", "go", "java", "dart" } -- add "lua", "go",...
  for _, name in ipairs(langs) do
    local ok, mod = pcall(require, "lsp.languages." .. name)
    if ok and type(mod.enable) == "function" then
      pcall(mod.enable)
    end
  end

  -- Web Development Languages separat laden
  local ok_webdev, webdev = pcall(require, "lsp.languages.webdev")
  if ok_webdev and type(webdev.enable_all) == "function" then
    pcall(webdev.enable_all)
  end
end

return M
