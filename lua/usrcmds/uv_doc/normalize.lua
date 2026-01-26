---@module 'uv_doc.normalize'
---@brief Symbol name normalization and prefix handling

local M = {}

local strings = require("lib.strings")

--- Prefix expansion map for common categories
---@type table<string, string>
local PREFIX_MAP = {
  loop = "uv_loop_",
  fs = "uv_fs_",
  fs_event = "uv_fs_event_",
  fs_poll = "uv_fs_poll_",
  tcp = "uv_tcp_",
  udp = "uv_udp_",
  pipe = "uv_pipe_",
  tty = "uv_tty_",
  signal = "uv_signal_",
  timer = "uv_timer_",
  poll = "uv_poll_",
  work = "uv_work_",
  dl = "uv_dl",
  process = "uv_",
  stream = "uv_stream_",
}

--- Normalizes input to canonical "uv_*" form
---@param name string
---@nodiscard
---@return string
function M.to_uv(name)
  if type(name) ~= "string" then
    return "uv_invalid"
  end

  local n = name
  n = strings.replace_plain(n, "vim.uv.", "")
  n = strings.replace_plain(n, "vim.loop.", "")
  n = strings.replace_plain(n, ":", "_")

  -- Common shorthands
  if n == "cwd" then
    return "uv_cwd"
  end
  if n == "chdir" then
    return "uv_chdir"
  end

  -- Constructor pattern: new_<type> → uv_<type>_init
  local constructor = n:match("^new_(%w+)$")
  if constructor then
    return "uv_" .. constructor .. "_init"
  end

  -- Ensure uv_ prefix
  if not strings.starts_with(n, "uv_") then
    n = "uv_" .. n
  end

  return n
end

--- Gets prefix for category query
---@param query string
---@nodiscard
---@return string|nil
function M.get_prefix(query)
  return PREFIX_MAP[query]
end

return M
