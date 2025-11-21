---@module 'custom.markdown.codeblock_formatter.run.format_single_block'
--- Format a single fenced code block taken from a Markdown buffer.
--- Workflow:
---   1. extract block text from source buffer
---   2. write a temp file (for CLI formatters)
---   3. create an ephemeral buffer for LSP formatting attempts
---   4. try formatting via attached LSP clients (client request -> apply_text_edits)
---   5. if no LSP edits: run CLI formatter via provided `spawn_or_fallback`
---   6. cleanup and callback with (err, formatted_text) where formatted_text is a string
---
--- Exports: returns a function with signature
---   (bufnr: integer, block: table, fmt_cfg: table, spawn_or_fallback: function, cb: function) -> nil
--- Notes:
---   - `fmt_cfg.build_cmd(tmp_path)` is expected to return (cmd:string, args:table, writes_file:boolean)
---   - This module validates and normalizes build_cmd returns to avoid Lua multiple-return pitfalls.
---   - All comments in this file are in English as requested for generated code.
local helper = require("custom.markdown.codeblock_formatter.helper")
local write_temp_file = helper.write_temp_file
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
local run_cli_fallback = function(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
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

return function(bufnr, block, fmt_cfg, spawn_or_fallback, cb)
  cb = cb or function() end

  -- extract original block lines
  local orig_lines = vim.api.nvim_buf_get_lines(bufnr, block.start_row - 1, block.end_row, false)
  local orig_text = table.concat(orig_lines, "\n")

  -- write temporary file for CLI formatters
  local tmp_path, tmp_err = write_temp_file(orig_text, fmt_cfg.ext)
  if not tmp_path then
    cb("tmp_write_error:" .. tostring(tmp_err), nil)
    return
  end

  vim.schedule(function()
    vim.notify(("md-codefmt: tmp file for block -> %s"):format(tostring(tmp_path)), vim.log.levels.DEBUG, { title = "md-codefmt" })
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
  local tb = vim.api.nvim_create_buf(false, true)
  if not tb then
    -- If ephemeral buffer cannot be created, fallback immediately to CLI
    run_cli_fallback(fmt_cfg, tmp_path, nil, block, spawn_or_fallback, cb)
    return
  end

  -- populate buffer and set filetype/options
  vim.api.nvim_buf_set_lines(tb, 0, -1, false, vim.split(orig_text, "\n", { plain = true }))
  vim.api.nvim_set_option_value("filetype", ft, { buf = tb })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = tb })
  vim.api.nvim_set_option_value("modifiable", true, { buf = tb })

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
    run_cli_fallback(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
    return
  end

  -- prepare formatting params
  local tabSize = vim.api.nvim_get_option_value("shiftwidth", { buf = tb }) or vim.api.nvim_get_option_value("tabstop", { buf = tb }) or 2
  local insertSpaces = vim.api.nvim_get_option_value("expandtab", { buf = tb })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(tb),
    options = { tabSize = tabSize, insertSpaces = insertSpaces },
  }

  -- request formatting from each candidate client; apply first successful edits
  local pending = #candidates
  local applied = false

  for _, client in ipairs(candidates) do
    -- send the request directly to the specific client and pass tb as bufnr
    -- client.request(method, params, handler, bufnr)
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
          vim.notify(("md-codefmt: client error %s"):format(tostring(err)), vim.log.levels.DEBUG, { title = "md-codefmt" })
        elseif result and result ~= vim.NIL and #result > 0 then
          local ok, apperr = pcall(vim.lsp.util.apply_text_edits, result, tb, (client and (client.offset_encoding or "utf-16")) or "utf-16")
          if ok then
            applied = true
            local formatted_lines = vim.api.nvim_buf_get_lines(tb, 0, -1, false)
            local formatted_text = table.concat(formatted_lines, "\n")
            -- cleanup temp file and buffer
            remove_tmp(tmp_path)
            pcall(vim.api.nvim_buf_delete, tb, { force = true })
            cb(nil, formatted_text)
            return
          else
            vim.notify(("md-codefmt: apply_text_edits failed: %s"):format(tostring(apperr)), vim.log.levels.DEBUG, { title = "md-codefmt" })
          end
        else
          vim.notify(("md-codefmt: client returned no edits for %s"):format(tostring(block.lang)), vim.log.levels.DEBUG, { title = "md-codefmt" })
        end

        if pending == 0 and not applied then
          -- none of the LSP clients produced edits -> fallback to CLI
          run_cli_fallback(fmt_cfg, tmp_path, tb, block, spawn_or_fallback, cb)
        end
      end)
    end, tb)
  end
end
