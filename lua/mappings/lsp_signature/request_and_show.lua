---@module 'mappings.lsp_signature.request_and_show'
--- Requests signatureHelp from LSP; falls back to hover.
--- Calls the optional callback with bufnr, winid for toggle support.

local api = vim.api
local util = vim.lsp.util
local schedule = vim.schedule
local cmd = vim.cmd

local format_signature_help = require("mappings.lsp_signature.format_signature_help")
local format_hover = require("mappings.lsp_signature.format_hover")
local open_floating_preview = require("mappings.lsp_signature.open_floating_preview")

-- Request signatureHelp; fallback to hover; optional callback(bufnr, winid)
---@param bufnr integer
---@param callback fun(bufnr:integer, winid:integer)?
return function(bufnr, callback)
  bufnr = bufnr or api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if not clients or vim.tbl_isempty(clients) then
    pcall(vim.lsp.buf.signature_help)
    return
  end

  local params = util.make_position_params(0, "utf-8")

  local function ensure_insert_mode_if_needed()
    local mode = vim.fn.mode()
    if mode ~= "i" and mode ~= "ic" and mode ~= "R" then
      pcall(function() cmd("startinsert!") end)
    end
  end

  local function handle_hover(c)
    local hover_handler = function(err, result)
      if err or not result then return end
      local lines = format_hover(result)
      if lines then
        schedule(function()
          local bufnr2, winid = open_floating_preview(lines)
					if not bufnr2 or not winid then return end
          ensure_insert_mode_if_needed()
          if callback then callback(bufnr2, winid) end
        end)
      end
    end
    pcall(c.request, c, "textDocument/hover", params, hover_handler, bufnr)
  end

  for _, client in pairs(clients) do
    if client.server_capabilities and client.server_capabilities.signatureHelpProvider then
      local handler = function(err, result)
        if err or not result then
          schedule(function()
            handle_hover(client)
          end)
          return
        end

        local lines = format_signature_help(result)
        if lines and not vim.tbl_isempty(lines) then
          schedule(function()
            local bufnr3, winid = open_floating_preview(lines)
						if not bufnr3 or not winid then return end
            ensure_insert_mode_if_needed()
            if callback then callback(bufnr3, winid) end
          end)
          return
        end

        schedule(function()
          handle_hover(client)
        end)
      end
      pcall(client.request, client, "textDocument/signatureHelp", params, handler, bufnr)
      return
    end
  end

  -- No client advertises signatureHelp → fallback to hover
  handle_hover(clients[1])
end
