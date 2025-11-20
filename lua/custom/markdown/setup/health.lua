---@module 'custom.markdown.setup.health'

local M = {}

local has_api10 = (vim.health and vim.health.report_start ~= nil)

local function Hstart(msg)
  if has_api10 then
    vim.health.report_start(msg)
  else
    vim.health.start(msg)
  end
end
local function Hok(msg)
  if has_api10 then
    vim.health.report_ok(msg)
  else
    vim.health.ok(msg)
  end
end
local function Hwarn(msg)
  if has_api10 then
    vim.health.report_warn(msg)
  else
    vim.health.warn(msg)
  end
end

function M.check()
  Hstart("custom.markdown healthcheck")

  local ok_cfg, _ = pcall(require, "custom.markdown.config")
  if not ok_cfg then
    Hwarn("config module missing")
    return
  end
  Hok("config module loaded")

  local mods = {
    "custom.markdown.core.fold",
    "custom.markdown.core.fold_prev",
    "custom.markdown.core.fold_levels",
    "custom.markdown.core.headings",
    "custom.markdown.core.wrap",
    "custom.markdown.core.selection",
    "custom.markdown.core.toc",
    "custom.markdown.setup.autocmds",
    "custom.markdown.setup.keymaps",
    "custom.markdown.setup.usercmds",
  }

  for _, m in ipairs(mods) do
    local ok = pcall(require, m)
    if ok then
      Hok("module ok: " .. m)
    else
      Hwarn("module failed: " .. m)
    end
  end
end

return M
