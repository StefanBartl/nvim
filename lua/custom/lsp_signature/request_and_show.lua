---@module 'custom.lsp_signature.request_and_show'
--- Requests signatureHelp; fallback auf hover, mit persistentem Popup und Parameter-Highlighting
local api = vim.api
local schedule = vim.schedule
local open_floating_preview = require("custom.lsp_signature.open_floating_preview")
local format_signature_help = require("custom.lsp_signature.format_signature_help")
local format_hover = require("custom.lsp_signature.format_hover")

-- Highlight-Gruppen für Parameter
local param_highlight_groups = {
  "LspSignatureParam1",
  "LspSignatureParam2",
  "LspSignatureParam3",
  "LspSignatureParam4",
}
for i, grp in ipairs(param_highlight_groups) do
  vim.cmd(string.format("highlight %s guifg=#%06x gui=bold", grp, 0xff8800 + (i-1)*0x003300))
end
vim.cmd("highlight LspSignatureActiveParam guifg=#ffffff guibg=#005f87 gui=bold")

-- Toggle-Popup
local current_popup = {buf = nil, win = nil}
local ns_id = api.nvim_create_namespace("LspSignatureParams")

---@param bufnr integer|nil?
---@param callback fun(bufnr:integer, winid:integer)?
return function(bufnr, callback)
  bufnr = bufnr or api.nvim_get_current_buf()

  -- Wenn Popup schon offen ist, schließen und beenden
  if current_popup.win and api.nvim_win_is_valid(current_popup.win) then
    pcall(api.nvim_win_close, current_popup.win, true)
    current_popup.buf = nil
    current_popup.win = nil
    return
  end

  local clients = vim.lsp.get_clients({bufnr=bufnr})
  if not clients or vim.tbl_isempty(clients) then return end

  local params = vim.lsp.util.make_position_params(0, "utf-8")
  local mode = vim.fn.mode()

  local function show_hover(c)
    local handler = function(_, result)
      if not result then return end
      local lines = format_hover(result)
      if lines then
        schedule(function()
          local buf, win = open_floating_preview(lines)
          current_popup.buf = buf
          current_popup.win = win
          if mode == "n" and win and api.nvim_win_is_valid(win) then
            api.nvim_set_current_win(win)
          end
          if callback and buf ~= nil and win ~= nil then callback(buf, win) end
        end)
      end
    end
    pcall(c.request, c, "textDocument/hover", params, handler, bufnr)
  end

  for _, client in pairs(clients) do
    if client.server_capabilities.signatureHelpProvider then
      local handler = function(_, result)
        if not result then
          schedule(function() show_hover(client) end)
          return
        end

        local lines = format_signature_help(result)
        if not lines then
          schedule(function() show_hover(client) end)
          return
        end

        schedule(function()
          local buf, win = open_floating_preview(lines)
          current_popup.buf = buf
          current_popup.win = win

          -- Parameter-Highlighting
          local sig = result.signatures[result.activeSignature and result.activeSignature+1 or 1]
          if sig and sig.parameters then
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
                local group = (i == (sig.activeParameter or 0)+1) and "LspSignatureActiveParam"
                             or param_highlight_groups[(i-1) % #param_highlight_groups + 1]
                vim.hl.range(buf, ns_id, group,
                             {0, start_col-1}, {0, end_col},
                             {inclusive=false})
              end
            end
          end

          -- Fokus im Normalmodus direkt auf Popup
          if mode == "n" and win and api.nvim_win_is_valid(win) then
            api.nvim_set_current_win(win)
          end
          if callback and buf ~= nil and win ~= nil then callback(buf, win) end
        end)
      end

      pcall(client.request, client, "textDocument/signatureHelp", params, handler, bufnr)
      return
    end
  end

  -- Kein SignatureHelp -> Hover-Fallback
  show_hover(clients[1])
end
