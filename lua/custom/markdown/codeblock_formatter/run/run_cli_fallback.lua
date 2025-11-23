---@module 'custom.markdown.codeblock_formatter.run.run_cli_fallback'

local helper = require("custom.markdown.codeblock_formatter.helper")
local remove_tmp = helper.remove_tmp

--- Normalize the return values of fmt_cfg.build_cmd(tmp).
--- Ensures cmd is string, args is table, writes_file is boolean.
--- Returns cmd, args, writes_file, err_string
local local_normalize_build_cmd = function(fmt_cfg, tmp)
  local ok, a, b, c = pcall(fmt_cfg.build_cmd, tmp)
  if not ok then
    return nil, nil, nil, "build_cmd raised error: " .. tostring(a)
  end
  local cmd = a
  local args = b
  local writes_file = c

  if type(cmd) ~= "string" then
    return nil, nil, nil, "build_cmd did not return command string"
  end
  if type(args) ~= "table" then
    args = {}
  end
  if type(writes_file) ~= "boolean" then
    writes_file = true
  end
  return cmd, args, writes_file, nil
end

--- Helper: call spawn_or_fallback using normalized build_cmd and ensure callback semantics.
--- Accepts fmt_cfg, tmp_path, tb (temp buffer - may be nil), block, spawn_or_fallback, cb
return function (fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
  vim.notify("cli fallback called", 2)
  local cmd, args, writes_file, merr = local_normalize_build_cmd(fmt_cfg, tmp_path)
  if not cmd then
    -- report error and return via callback
    vim.schedule(function()
      vim.notify(("md-codefmt: invalid build_cmd for %s: %s"):format(tostring(block.lang), tostring(merr)), vim.log.levels.WARN, { title = "md-codefmt" })
    end)
    if tmp_path then remove_tmp(tmp_path) end
    if tb then pcall(vim.api.nvim_buf_delete, tb, { force = true }) end
    cb("invalid_build_cmd", nil)
    return
  end

  -- call the provided spawn_or_fallback executor
  spawn_or_fallback(cmd, args, tmp_path, writes_file, function(err, out)
    if tmp_path then remove_tmp(tmp_path) end
    if tb then pcall(vim.api.nvim_buf_delete, tb, { force = true }) end
    cb(err, out)
  end)

end
