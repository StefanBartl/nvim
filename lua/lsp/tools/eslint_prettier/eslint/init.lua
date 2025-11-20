---@module 'lsp.tools.eslint_prettier.eslint'
--- eslint utilities and bin resolution
local fn = vim.fn

local M = {
  eslint_bin = nil, -- resolved executable (string)
}

--- Try to resolve executable by name, then mason bin folder, add .cmd on Windows.
---@param name string
---@return string|nil
local function resolve_executable(name)
  -- check direct in PATH
  if fn.executable(name) == 1 then
    return name
  end

  -- mason bin path: stdpath('data') .. '/mason/bin'
  local mason_bin = fn.stdpath("data") .. "/mason/bin"
  local platform_suffix = ""
  if vim.loop.os_uname().sysname:match("Windows") or vim.fn.has("win32") == 1 then
    platform_suffix = ".cmd"
  end

  local candidate = mason_bin .. "/" .. name .. platform_suffix
  if fn.executable(candidate) == 1 then
    return candidate
  end

  -- fallback try without suffix
  candidate = mason_bin .. "/" .. name
  if fn.executable(candidate) == 1 then
    return candidate
  end

  return nil
end

function M.get_eslint_bin()
  if M.eslint_bin then
    return M.eslint_bin
  end
  M.eslint_bin = resolve_executable("eslint_d")
  return M.eslint_bin
end

function M.set_eslint_bin(path)
  M.eslint_bin = path
end

return M
