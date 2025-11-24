---@module 'custom.lsp_signature.request_and_show'
--- Request signatureHelp for the current position and show it in a floating preview.
--- Modularized: parameter highlight setup and hover logic were extracted into separate modules.
--- Additional behavior:
---  - notifies user when no signature is shown in branches that previously returned silently.
---  - uses the highlights module to initialize highlight groups and obtain namespace id.

local api = vim.api
local schedule = vim.schedule
local open_floating_preview = require("custom.lsp_signature.open_floating_preview")
local format_signature_help = require("custom.lsp_signature.format_signature_help")
local state = require("custom.lsp_signature.state")

local param_hl = require("custom.lsp_signature.highlights.parameters")
local hover_helper = require("custom.lsp_signature.show_hover")

local notify = vim.notify

-- ensure highlight groups exist and get namespace id
-- default color options can be overridden by passing a table to param_hl.setup()
local ns_id = param_hl.setup() -- returns namespace id for hl.range usage

--- Show or toggle popup for current buffer.
---@param bufnr integer|nil?
---@param callback fun(bufnr:integer, winid:integer)?
return function(bufnr, callback)
  bufnr = bufnr or api.nvim_get_current_buf()

  -- If popup already tracked and valid -> close it and notify user
  if state.current.win and api.nvim_win_is_valid(state.current.win) then
    state.close()
    notify("[signature_help] signature popup closed", vim.log.levels.INFO)
    return
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if not clients or vim.tbl_isempty(clients) then
    notify("[signature_help] no LSP client attached to buffer", vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_position_params(0, "utf-8")
  local mode = vim.fn.mode()

  -- helper to show hover using the modular helper
  local function show_hover(client)
    -- call modular hover helper; it will notify if hover empty
    hover_helper.show_hover(client, params, { mode = mode, callback = callback })
  end

  -- iterate clients and prefer those that provide signatureHelp
  for _, client in pairs(clients) do
    if client.server_capabilities and client.server_capabilities.signatureHelpProvider then
      -- signature request handler
      local handler = function(_, result)
        if not result then
          -- no signature result; notify and fall back to hover
          schedule(function()
            notify("[signature_help] signatureHelp: no result, showing hover instead", vim.log.levels.INFO)
            show_hover(client)
          end)
          return
        end

        local lines = format_signature_help(result)
        if not lines or #lines == 0 then
          schedule(function()
            notify("[signature_help] signatureHelp produced no displayable lines, showing hover instead", vim.log.levels.INFO)
            show_hover(client)
          end)
          return
        end

        schedule(function()
          local buf, win = open_floating_preview(lines)
          state.set(buf, win)

          -- Parameter highlighting (all params + active)
          local sig = result.signatures[result.activeSignature and result.activeSignature + 1 or 1]
          if sig and sig.parameters then
            -- fetch group names and ns from highlights module
            local groups = param_hl.group_names()
            local _ns = ns_id or param_hl.setup() -- ensure ns present

            for i, param in ipairs(sig.parameters) do
              local start_col, end_col
              if type(param.label) == "table" and #param.label == 2 then
                -- LSP provides numeric range: [start, end] in bytes/characters
                -- Convert to 1-based columns used by vim.hl.range: start_col = start+1, end_col = end
                start_col = param.label[1] + 1
                end_col = param.label[2]
              elseif type(param.label) == "string" then
                -- fallback: search textual label inside signature label
                local s, e = string.find(sig.label, vim.pesc(param.label), 1, true)
                start_col = s
                end_col = e
              end

              if start_col and end_col and buf then
                local group = (i == (sig.activeParameter or 0) + 1) and "LspSignatureActiveParam"
                  or groups[(i - 1) % #groups + 1]
                -- highlight the range in the floating buffer using the namespace id
                -- `vim.hl.range` expects 0-based row/col positions as {row, col}
                pcall(vim.hl.range, buf, _ns, group, { 0, start_col - 1 }, { 0, end_col }, { inclusive = false })
              end
            end
          end

          if mode == "n" and win and api.nvim_win_is_valid(win) then
            api.nvim_set_current_win(win)
          end
          if callback and buf and win then
            callback(buf, win)
          end
        end)
      end

      -- request signatureHelp; wrap in pcall to avoid throwing if client disappears
      pcall(client.request, client, "textDocument/signatureHelp", params, handler, bufnr)
      return
    end
  end

  -- Fallback: none of the clients provide signatureHelp -> notify and show hover from first client
  notify("[signature_help] no client provides signatureHelp, falling back to hover", vim.log.levels.INFO)
  show_hover(clients[1])
end
