-- debugged version

---@module 'nvchad.lsp.signature'
---Provides safe and buffer-local LSP signature help autocommands.

local M = {}
local api = vim.api

---@param triggerChars string[]
---@return boolean
local function check_triggeredChars(triggerChars)
  local cur_line = api.nvim_get_current_line()
  local pos = api.nvim_win_get_cursor(0)[2] + 1

  local prev_char = cur_line:sub(pos - 1, pos - 1)
  local cur_char = cur_line:sub(pos, pos)

  for _, char in ipairs(triggerChars) do
    if cur_char == char or prev_char == char then
      return true
    end
  end

  return false
end

---@param client vim.lsp.Client
---@param bufnr integer
function M.setup(client, bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local provider = client.server_capabilities.signatureHelpProvider
  local triggerChars = provider and provider.triggerCharacters or {}

  local group_name = "LspSignature_" .. bufnr
  local group = api.nvim_create_augroup(group_name, { clear = true })

  api.nvim_create_autocmd("TextChangedI", {
    group = group,
    buffer = bufnr,
    callback = function()
      if not api.nvim_buf_is_valid(bufnr) then
        return
      end

      if check_triggeredChars(triggerChars) then
        vim.lsp.buf.signature_help {
          focus = false,
          silent = true,
          max_height = 7,
          border = "single",
        }
      end
    end,
  })

  api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function()
      api.nvim_clear_autocmds {
        group = group_name,
        buffer = bufnr,
      }
    end,
  })
end

return M

