---@module 'debugging.tools.buffer_inspector'
-- Inspect buffer options and state for debugging

local api = vim.api
local M = {}

---@param bufnr? integer
function M.inspect(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then
    print("[buffer_inspector] Invalid buffer")
    return
  end

  local opts = {
    number = vim.api.nvim_buf_get_option(bufnr, "number"),
    modifiable = vim.api.nvim_buf_get_option(bufnr, "modifiable"),
    readonly = vim.api.nvim_buf_get_option(bufnr, "readonly"),
    buftype = vim.api.nvim_buf_get_option(bufnr, "buftype"),
    filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
    hidden = vim.api.nvim_buf_get_option(bufnr, "hidden"),
  }

  print(string.format("[buffer_inspector] Buffer %d state:", bufnr))
  for k, v in pairs(opts) do
    print(string.format("  %s = %s", k, tostring(v)))
  end
end

---@param bufnr? integer
function M.enable(bufnr)
  api.nvim_create_user_command(
    "DebugToolsInspectBuffer",
    function(args)
      local target_buf = args.args ~= "" and tonumber(args.args) or bufnr
      M.inspect(target_buf)
    end,
    { nargs = "?", desc = "[debugging.tools.buffer_inspector] Inspect buffer state" }
  )
end

return M

