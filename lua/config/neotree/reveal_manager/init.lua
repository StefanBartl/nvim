---@module 'config.neotree.reveal_manager'
---@brief Centralized reveal logic for Neo-tree
local M = {}

local utils = require("config.neotree.utils")

---@type {file:string, time:number}|nil
local last_reveal = nil

---Reveal a file in Neo-tree
---@param ctx Cfg.NeoTree.RevealContext
---@return boolean success
function M.reveal(ctx)
  if not ctx or not ctx.file or ctx.file == "" then
    return false
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return false
  end

  -- Track for duplicate prevention
  last_reveal = {
    file = ctx.file,
    time = vim.loop.now(),
  }

  local ok = pcall(function()
    cmd.execute({
      action = "show",
      source = "filesystem",
      position = ctx.position or "left",
      dir = ctx.dir,
      reveal = true,
      reveal_file = ctx.file,
    })
  end)

  return ok
end

---Reveal current buffer
---@param buf integer|nil
---@param position Cfg.NeoTree.Position|nil
---@return boolean success
function M.reveal_buffer(buf, position)
  buf = buf or vim.api.nvim_get_current_buf()

  local ctx = utils.get_buffer_context(buf)
  if not ctx then
    return false
  end

  ---@cast ctx Cfg.NeoTree.RevealContext
  ctx.position = position

  -- Check if already revealed recently
  if last_reveal and last_reveal.file == ctx.file then
    local elapsed = vim.loop.now() - last_reveal.time
    if elapsed < 500 then
      return false -- Skip duplicate
    end
  end

  return M.reveal(ctx)
end

---Clear reveal cache
function M.clear()
  last_reveal = nil
end

return M
