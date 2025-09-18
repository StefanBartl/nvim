-- config/harpoon/health.lua
---@module 'config.harpoon.health'
local M = {}

local health = vim.health

function M.check()
  local ok_hp = pcall(require, "harpoon")
  if not ok_hp then
    health.error("harpoon not found (ThePrimeagen/harpoon, branch=harpoon2)")
  else
    health.ok("harpoon loaded")
  end

  local ok_plenary = pcall(require, "plenary.path")
  if not ok_plenary then health.warn("plenary not found (optional)") else vim.health.ok("plenary ok") end

  local ok_fzf = pcall(require, "fzf-lua")
  if ok_fzf then health.ok("fzf-lua found (optional)") else vim.health.warn("fzf-lua missing (optional)") end
  local ok_tel = pcall(require, "telescope")
  if ok_tel then health.ok("telescope found (optional)") else vim.health.warn("telescope missing (optional)") end

  -- Simple write test for harpoon storage (best-effort)
  local ok, harpoon = pcall(require, "harpoon")
  if ok then
    local list = harpoon:list()
    if type(list) == "table" and type(list.items) == "table" then
      health.ok(("harpoon list ok (%d items)"):format(#list.items))
    else
      health.error("harpoon:list() returned unexpected shape")
    end
  end
end

return M

