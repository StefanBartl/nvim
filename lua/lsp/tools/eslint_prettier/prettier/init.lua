---@module 'lsp.tools.eslint_prettier.prettier'
local fn = vim.fn
local M = { prettier_bin = nil }

local function resolve_executable(name)
  if fn.executable(name) == 1 then
    return name
  end
  local mason_bin = fn.stdpath("data") .. "/mason/bin"
  local suffix = ""
  if vim.uv.os_uname().sysname:match("Windows") or fn.has("win32") == 1 then
    suffix = ".cmd"
  end
  local candidate = mason_bin .. "/" .. name .. suffix
  if fn.executable(candidate) == 1 then
    return candidate
  end
  candidate = mason_bin .. "/" .. name
  if fn.executable(candidate) == 1 then
    return candidate
  end
  return nil
end

function M.get_prettier_bin()
  if M.prettier_bin then
    return M.prettier_bin
  end
  M.prettier_bin = resolve_executable("prettier")
  return M.prettier_bin
end

function M.set_prettier_bin(path)
  M.prettier_bin = path
end

return M
