---@module 'custom.markdown.codeblock_formatter.formatters'
--- Formatter registry and availability checks.
--- Exposes `default_formatters` and helper `is_tool_available(lang, fmt_cfg)`.
local M = {}

local fn = vim.fn

local default_formatters = {
  lua = {
    ext = ".lua",
    check_executable = function()
      return fn.executable("stylua") == 1
    end,
    build_cmd = function(tmp)
      return "stylua", { tmp }, true
    end,
  },
  javascript = {
    ext = ".js",
    check_executable = function()
      return fn.executable("prettier") == 1
    end,
    build_cmd = function(tmp)
      return "prettier", { "--write", tmp }, true
    end,
  },
  typescript = {
    ext = ".ts",
    check_executable = function()
      return fn.executable("prettier") == 1
    end,
    build_cmd = function(tmp)
      return "prettier", { "--write", tmp }, true
    end,
  },
  python = {
    ext = ".py",
    check_executable = function()
      return fn.executable("black") == 1
    end,
    build_cmd = function(tmp)
      return "black", { tmp }, true
    end,
  },
  go = {
    ext = ".go",
    check_executable = function()
      return fn.executable("gofmt") == 1
    end,
    build_cmd = function(tmp)
      return "gofmt", { "-w", tmp }, true
    end,
  },
  c = {
    ext = ".c",
    check_executable = function()
      return fn.executable("clang-format") == 1
    end,
    build_cmd = function(tmp)
      return "clang-format", { "-i", tmp }, true
    end,
  },
  cpp = {
    ext = ".cpp",
    check_executable = function()
      return fn.executable("clang-format") == 1
    end,
    build_cmd = function(tmp)
      return "clang-format", { "-i", tmp }, true
    end,
  },
}

--- Check tool availability. Prefer mason-registry if present, otherwise fall back to executable().
--- this function is best-effort and logs nothing by itself.
function M.is_tool_available(_, fmt_cfg)
  if not fmt_cfg or not fmt_cfg.check_executable then
    return false
  end
  -- try mason-registry if available (best-effort)
  local ok, mason_registry = pcall(require, "mason-registry")
  if ok and mason_registry then
    -- if the check_executable already returns true, accept it
    if fmt_cfg.check_executable() then
      return true
    end
    -- otherwise fallback to the check_executable result
    return fmt_cfg.check_executable()
  end
  -- no mason-registry: use provided check
  return fmt_cfg.check_executable()
end

M.default_formatters = default_formatters

return M
