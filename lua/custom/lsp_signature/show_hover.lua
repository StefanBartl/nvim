---@module 'custom.lsp_signature.show_hover'
--- Request hover from a single LSP client and display it in a floating preview.
--- This module normalizes the earlier inline `show_hover` logic into a reusable function.
--- It returns the created buffer and window when a hover was shown.
---
--- API:
---   show_hover(client, params, opts) -> buf, win
--- opts:
---   - mode (string|nil) : original vim mode (e.g. "n"), affects whether the float gets focus
---   - callback (fun(buf,win)|nil) : optional callback invoked with buf,win
---
--- The function schedules UI updates via vim.schedule to avoid callback restrictions.

local M = {}

local open_floating_preview = require("custom.lsp_signature.open_floating_preview")
local format_hover = require("custom.lsp_signature.format_hover")
local state = require("custom.lsp_signature.state")
local api = vim.api
local schedule = vim.schedule
local notify = vim.notify

--- Request hover and open floating preview when result exists.
---@param client table LSP client object
---@param params table request params (e.g. vim.lsp.util.make_position_params())
---@param opts table|nil
---@return integer|nil buf, integer|nil win
function M.show_hover(client, params, opts)
  opts = opts or {}
  local mode = opts.mode
  local callback = opts.callback

  local handler = function(_, result)
    if not result then
      -- no hover result; caller may want to know that nothing was shown
      schedule(function()
        notify("[signature_help] hover: no result", vim.log.levels.INFO)
      end)
      return
    end
    local lines = format_hover(result)
    if not lines or #lines == 0 then
      schedule(function()
        notify("[signature_help] hover: no lines to show", vim.log.levels.INFO)
      end)
      return
    end
    schedule(function()
      local buf, win = open_floating_preview(lines)
      state.set(buf, win)
      if mode == "n" and win and api.nvim_win_is_valid(win) then
        api.nvim_set_current_win(win)
      end
      if callback and buf and win then
        callback(buf, win)
      end
    end)
  end

  -- fire-and-forget, protect with pcall to avoid throwing in-case the client is gone
  pcall(client.request, client, "textDocument/hover", params, handler, vim.api.nvim_get_current_buf())
  -- we cannot synchronously return buf/win here because the request is async;
  -- the callback (if provided) will receive them when available.
  return nil, nil
end

return M
