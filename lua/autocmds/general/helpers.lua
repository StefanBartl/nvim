---@module 'autocmds.general.helpers'

local M = {}

-- Internal: create an augroup with `clear=true` to keep things idempotent.
---@param name string
---@return integer
function M.augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Internal: detect whether we are inside Kitty (Linux/macOS).
-- The presence of KITTY_LISTEN_ON or TERM="xterm-kitty" is a strong signal.
---@return boolean
function M.in_kitty()
  local env = vim.env
  return (env.KITTY_LISTEN_ON and #env.KITTY_LISTEN_ON > 0) or (env.TERM == "xterm-kitty")
end

-- Internal: run a Kitty remote control command safely and silently.
---@param padding integer
---@param margin integer
function M.kitty_set_spacing(padding, margin)
  -- The `kitty @` RC client is part of Kitty installs; only run if we are in Kitty.
  if not M.in_kitty() then
    return
  end
  -- `silent !kitty @ set-spacing padding=<n> margin=<n>` will adjust spacing for the current OS window.
  -- Using `vim.cmd` to avoid job control complexity; it’s synchronous but negligible here.
  local cmd = string.format(":silent !kitty @ set-spacing padding=%d margin=%d", padding, margin)
  pcall(function()
    vim.cmd(cmd)
  end)
end

return M
