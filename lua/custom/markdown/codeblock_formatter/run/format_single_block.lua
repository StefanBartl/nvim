---@module 'custom.markdown.codeblock_formatter.run.format_single_block'
--- Format a single fenced code block taken from a Markdown buffer.
--- Workflow:
---   1. extract block text from source buffer
---   2. strip possible fence lines (defensive)
---   3. write a temp file (for CLI formatters)
---   4. create an ephemeral buffer for LSP formatting attempts
---   5. try formatting via attached LSP clients (client request -> apply_text_edits)
---   6. if no LSP edits: run CLI formatter via provided `run_cli_fallback`
---   7. cleanup and callback with (err, formatted_text)
local run_cli_fallback = require("custom.markdown.codeblock_formatter.run.run_cli_fallback")
local helper = require("custom.markdown.codeblock_formatter.helper")
local write_temp_file = helper.write_temp_file
local remove_tmp = helper.remove_tmp
local strip_fences = helper.strip_fences
local notify = vim.notify
local api = vim.api

return function(bufnr, block, fmt_cfg, spawn_or_fallback, cb)
  cb = cb or function() end

  -- extract original block lines (1-based indices provided by finder)
  local orig_lines = api.nvim_buf_get_lines(bufnr, block.start_row - 1, block.end_row, false)

  -- defensive: strip fence lines if finder accidentally included them
  orig_lines = strip_fences(orig_lines)

  -- build text for formatting
  local orig_text = table.concat(orig_lines, "\n")

  -- debug dump of the extracted text (keep concise)
  notify("md-codefmt: extracted block preview (" .. tostring(block.lang) .. "):", vim.log.levels.DEBUG)
  if #orig_lines > 0 then
    local preview = table.concat({ orig_lines[1], (orig_lines[2] or ""), (orig_lines[3] or ""), "", "", "EOB:", (orig_lines[#orig_lines - 1] or ""), (orig_lines[#orig_lines] or "") }, "\n")
    notify(preview, vim.log.levels.DEBUG)
  end

  -- write temporary file for CLI formatters
  local tmp_path, tmp_err = write_temp_file(orig_text, fmt_cfg.ext)
  if not tmp_path then
    cb("tmp_write_error:" .. tostring(tmp_err), nil)
    return
  end

  vim.schedule(function()
    notify(("md-codefmt: tmp file for block -> %s"):format(tostring(tmp_path)), vim.log.levels.DEBUG, { title = "md-codefmt" })
  end)

  -- ephemeral buffer creation + filetype mapping
  local ft_alias = {
    ts = "typescript",
    tsx = "typescript",
    js = "javascript",
    jsx = "javascript",
    py = "python",
    lua = "lua",
  }
  local ft = ft_alias[block.lang] or block.lang
  local tb = api.nvim_create_buf(false, true)
  if not tb then
    -- If ephemeral buffer cannot be created, fallback immediately to CLI
    notify("[md-codefmt] ephemeral buffer cannot be created, fallback to CLI", vim.log.levels.WARN)
    run_cli_fallback(fmt_cfg, tmp_path, nil, block, spawn_or_fallback, cb)
    return
  end

  -- populate buffer using stripped lines and set filetype/options
  api.nvim_buf_set_lines(tb, 0, -1, false, orig_lines)
  api.nvim_set_option_value("filetype", ft, { buf = tb })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = tb })
  api.nvim_set_option_value("modifiable", true, { buf = tb })

  -- discover active LSP clients and query support for formatting for this buffer
  local active_clients = vim.lsp.get_clients()
  local candidates = {}
  for _, client in ipairs(active_clients) do
    local ok, supports = pcall(function()
      if client.supports_method then
        -- ask client directly whether it supports formatting for this specific buffer
        return client:supports_method("textDocument/formatting", tb)
      end
      local caps = client.server_capabilities or {}
      return caps.documentFormattingProvider == true
    end)
    if ok and supports then
      table.insert(candidates, client)
    end
  end

  if #candidates == 0 then
    -- no LSP formatter available -> CLI fallback
    notify("[md-codefmt] no LSP formatter available -> CLI fallback", vim.log.levels.DEBUG)
    run_cli_fallback(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
    return
  end

  -- prepare formatting params
  local tabSize = api.nvim_get_option_value("shiftwidth", { buf = tb }) or api.nvim_get_option_value("tabstop", { buf = tb }) or 2
  local insertSpaces = api.nvim_get_option_value("expandtab", { buf = tb })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(tb),
    options = { tabSize = tabSize, insertSpaces = insertSpaces },
  }

  -- request formatting from each candidate client; apply first successful edits
  local pending = #candidates
  local applied = false

  for _, client in ipairs(candidates) do
    -- send the request directly to the specific client and pass tb as bufnr
    client.request("textDocument/formatting", params, function(err, result)
      vim.schedule(function()
        pending = pending - 1

        if applied then
          -- another client already applied edits
          if pending == 0 and not applied then
            -- defensive: fall back to CLI
            run_cli_fallback(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
          end
          return
        end

        if err then
          notify(("md-codefmt: client error %s"):format(tostring(err)), vim.log.levels.DEBUG, { title = "md-codefmt" })
        elseif result and result ~= vim.NIL and #result > 0 then
          local ok, apperr = pcall(vim.lsp.util.apply_text_edits, result, tb, (client and (client.offset_encoding or "utf-16")) or "utf-16")
          if ok then
            applied = true
            local formatted_lines = api.nvim_buf_get_lines(tb, 0, -1, false)
            local formatted_text = table.concat(formatted_lines, "\n")
            -- cleanup temp file and buffer
            remove_tmp(tmp_path)
            pcall(api.nvim_buf_delete, tb, { force = true })
            cb(nil, formatted_text)
        return
          else
            notify(("md-codefmt: apply_text_edits failed: %s"):format(tostring(apperr)), vim.log.levels.DEBUG, { title = "md-codefmt" })
          end
        else
          notify(("md-codefmt: client returned no edits for %s"):format(tostring(block.lang)), vim.log.levels.DEBUG, { title = "md-codefmt" })
        end

        if pending == 0 and not applied then
          -- none of the LSP clients produced edits -> fallback to CLI
          notify("[md-codefmt] none of the LSP clients produced edits -> fallback to CLI", vim.log.levels.DEBUG)
          run_cli_fallback(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
        end
      end)
    end, tb)
  end
end
