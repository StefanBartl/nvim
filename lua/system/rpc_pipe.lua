---@module 'system.rpc_pipe'
-- Start a predictable named-pipe RPC server on Windows and export NVIM_LISTEN_ADDRESS.
-- Usage: require("system.rpc").setup({ debug = true })

local M = {}

--- Try to start a Windows named-pipe RPC server and export NVIM_LISTEN_ADDRESS.
-- @param opts table|nil
--   opts.debug = true -> emit vim.notify debug/warn messages
function M.setup(opts)
  opts = opts or {}
  local debug = opts.debug or false

  -- Only attempt the Windows named-pipe behavior on Windows-like OS
  local is_windows = package.config:sub(1,1) == "\\"  -- simple platform check
  if not is_windows then
    if debug then vim.notify("[system.rpc] skipping: not Windows", vim.log.levels.DEBUG) end
    return
  end

  local uname = os.getenv("USERNAME") or "user"
  local pipe = ([[\\.\pipe\nvim-%s]]):format(uname)

  local function dbg(msg)
    if debug then vim.notify("[system.rpc] " .. msg, vim.log.levels.DEBUG) end
  end
  local function warn(msg)
    if debug then vim.notify("[system.rpc] " .. msg, vim.log.levels.WARN) end
  end

  pcall(function()
    -- ensure serverstart() exists
    if vim.fn.exists("*serverstart") == 1 then
      dbg("attempting serverstart for pipe: " .. pipe)
      local ok = vim.fn.serverstart(pipe)
      -- serverstart returns 0 on error; success returns the address (string)
      if ok == 0 then
        -- intentionally silent in normal mode; warn only in debug mode
        warn("serverstart returned 0 (could not start pipe). Falling back silently.")
      else
        dbg("serverstart succeeded; address: " .. tostring(ok))
      end
    else
      warn("serverstart() not available in this build of Neovim")
    end
  end)

  -- Export the env var for child processes (and for tools reading NVIM_LISTEN_ADDRESS)
  vim.env.NVIM_LISTEN_ADDRESS = pipe
  dbg("exported NVIM_LISTEN_ADDRESS=" .. pipe)
end

return M
