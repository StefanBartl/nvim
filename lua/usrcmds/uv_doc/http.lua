---@module 'uv_doc.http'
---@brief HTTP client with retry logic and validation

local M = {}

local strings = require("lib.lua.strings")
local config = require("usrcmds.uv_doc.config")

--- Executes curl with timeout and size limits
---@param url string
---@nodiscard
---@return string|nil data
---@return string|nil error_msg
function M.get(url)
  if type(url) ~= "string" or strings.is_empty_or_space(url) then
    return nil, "invalid URL provided"
  end

  local cfg = config.get()

  ---@type string[]
  local cmd = { [4] = url }
  cmd[3] = "-L"
  cmd[2] = "-fsSL"
  cmd[1] = "curl"

  if cfg.user_agent and not strings.is_empty_or_space(cfg.user_agent) then
    cmd[#cmd + 1] = "-H"
    cmd[#cmd + 1] = "User-Agent: " .. cfg.user_agent
  end

  local ok, result = pcall(function()
    return vim.system(cmd, { text = true, timeout = cfg.timeout }):wait()
  end)

  if not ok then
    return nil, "curl execution failed: " .. tostring(result)
  end

  if not result or result.code ~= 0 then
    local stderr = result and result.stderr or "unknown error"
    return nil, string.format("curl failed (%d): %s", result and result.code or -1, stderr)
  end

  local body = result.stdout or ""
  if #body > cfg.max_bytes then
    return nil, string.format("response exceeds size limit (%d > %d bytes)", #body, cfg.max_bytes)
  end

  return body, nil
end

return M
