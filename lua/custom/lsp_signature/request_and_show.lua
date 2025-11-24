---@module 'custom.lsp_signature.request_and_show'
--- Request signatureHelp for the current position and show it in a floating preview.
--- When signatureHelp is not available or produces no displayable lines, this module
--- falls back to querying hover across all clients (via the modular show_hover helper).
--- If hover across clients also produces nothing within a short timeout, it then calls
--- the fallback providers module to attempt other LSP methods (typeDefinition/implementation/references).
---
--- Behavior is best-effort and asynchronous. The module uses a small deferred check to avoid
--- launching fallback providers when hover already produced a floating preview.
local api = vim.api
local schedule = vim.schedule
local open_floating_preview = require("custom.lsp_signature.open_floating_preview")
local format_signature_help = require("custom.lsp_signature.format_signature_help")
local state = require("custom.lsp_signature.state")

local param_hl = require("custom.lsp_signature.highlights.parameters")
local hover_helper = require("custom.lsp_signature.show_hover")
local fallback_providers = require("custom.lsp_signature.fallback_providers")

local notify = vim.notify

-- ensure highlight groups exist and get namespace id
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

  -- helper to show hover across clients using the modular helper
  local function show_hover_across_clients()
    -- show_hover returns true when at least one request was scheduled
    local did_schedule = hover_helper.show_hover(clients, params, { mode = mode, callback = callback })

    -- schedule a short deferred check: if no floating preview appeared, call fallback providers
    vim.defer_fn(function()
      if state.current.win and api.nvim_win_is_valid(state.current.win) then
        -- a hover or signature preview was opened; nothing to do
        return
      end
      -- nothing opened yet -> try fallback providers (typeDefinition, implementation, references)
      fallback_providers.try_providers(clients, params, { mode = mode, callback = callback })
    end, 300) -- 300ms delay to allow hover responses to arrive
    return did_schedule
  end

  -- iterate clients and prefer those that provide signatureHelp
  for _, client in pairs(clients) do
    if client.server_capabilities and client.server_capabilities.signatureHelpProvider then
      -- signature request handler
      local handler = function(_, result)
        if not result then
          -- no signature result; notify and fall back to hover across clients
          schedule(function()
            notify("[signature_help] signatureHelp: no result, trying hover across clients", vim.log.levels.INFO)
            show_hover_across_clients()
          end)
          return
        end

        local lines = format_signature_help(result)
        if not lines or #lines == 0 then
          schedule(function()
            notify(
              "[signature_help] signatureHelp produced no displayable lines, trying hover across clients",
              vim.log.levels.INFO
            )
            show_hover_across_clients()
          end)
          return
        end

        schedule(function()
          local buf, win = open_floating_preview(lines)
          state.set(buf, win)

          -- Parameter highlighting (all params + active)
          local sig = result.signatures[result.activeSignature and result.activeSignature + 1 or 1]
          if sig and sig.parameters then
            local groups = param_hl.group_names()
            local _ns = ns_id or param_hl.setup()

            for i, param in ipairs(sig.parameters) do
              local start_col, end_col
              if type(param.label) == "table" and #param.label == 2 then
                start_col = param.label[1] + 1
                end_col = param.label[2]
              elseif type(param.label) == "string" then
                local s, e = string.find(sig.label, vim.pesc(param.label), 1, true)
                start_col = s
                end_col = e
              end

              if start_col and end_col and buf then
                local group = (i == (sig.activeParameter or 0) + 1) and "LspSignatureActiveParam"
                  or groups[(i - 1) % #groups + 1]
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

  -- Fallback: none of the clients provide signatureHelp -> notify and try hover across clients
  notify("[signature_help] no client provides signatureHelp, trying hover across clients", vim.log.levels.INFO)
  show_hover_across_clients()
end
