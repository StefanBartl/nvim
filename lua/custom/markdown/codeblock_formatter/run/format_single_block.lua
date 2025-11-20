---@module 'custom.markdown.codeblock_formatter.run.format_single_block'
-- Format a single code block (block = { start_row, end_row, lang, ... }).
-- Steps:
--  1. extract block text from original buffer,
--  2. write temp file for CLI fallback and create ephemeral buffer for LSP approach,
--  3. try LSP formatting per-client (send request to relevant clients with bufnr),
--  4. if any client returns edits apply them to ephemeral buffer and return formatted text,
--  5. otherwise run CLI formatter (spawn_or_fallback) on temp file and return its output,
--  6. cleanup tmp/buffer and call callback(cb_err, formatted_text_or_nil).

local helper = require("custom.markdown.codeblock_formatter.helper")
local write_temp_file = helper.write_temp_file
local remove_tmp = helper.remove_tmp

return function (bufnr, block, fmt_cfg, spawn_or_fallback, cb)
  cb = cb or function() end
  -- extract original block lines
  local orig_lines = vim.api.nvim_buf_get_lines(bufnr, block.start_row - 1, block.end_row, false)
  local orig_text = table.concat(orig_lines, "\n")

  -- create tmp file (for CLI fallback) and notify path for debugging
  local tmp_path, tmp_err = write_temp_file(orig_text, fmt_cfg.ext)
  if not tmp_path then
    cb("tmp_write_error:" .. tostring(tmp_err), nil)
    return
  end
  vim.schedule(function() vim.notify("md-codefmt: tmp file for block -> " .. tmp_path, vim.log.levels.DEBUG, { title = "md-codefmt" }) end)

  -- create ephemeral buffer for LSP formatting
  local ft_alias = { ts = "typescript", tsx = "typescript", js = "javascript", jsx = "javascript", py = "python", lua = "lua" }
  local ft = ft_alias[block.lang] or block.lang
  local tb = vim.api.nvim_create_buf(false, true)
  if not tb then
    -- no temp buffer -> fallback immediately to CLI
    spawn_or_fallback(fmt_cfg.build_cmd(tmp_path))
    -- note: spawn_or_fallback in your code expects (cmd,args,tmp,writes_file,cb); adapt if needed
    spawn_or_fallback(fmt_cfg.build_cmd(tmp_path), tmp_path, fmt_cfg.ext, function(err, out)
      remove_tmp(tmp_path)
      cb(err, out)
    end)
    return
  end

  -- populate buffer and set filetype/options
  vim.api.nvim_buf_set_lines(tb, 0, -1, false, vim.split(orig_text, "\n", { plain = true }))
  vim.api.nvim_set_option_value("filetype", ft, { buf = tb })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = tb })
  vim.api.nvim_set_option_value("modifiable", true, { buf = tb })

  -- discover active LSP clients and ask each whether it supports formatting for this buffer
  local active_clients = vim.lsp.get_clients()
  local candidates = {}
  for _, client in ipairs(active_clients) do
    local ok, supports = pcall(function()
      if client.supports_method then
        return client:supports_method("textDocument/formatting", tb)
      end
      local caps = client.server_capabilities or {}
      return caps.documentFormattingProvider == true
    end)
    if ok and supports then table.insert(candidates, client) end
  end

  if #candidates == 0 then
    -- no LSP formatter -> fallback to CLI
    spawn_or_fallback(fmt_cfg.build_cmd(tmp_path), tmp_path, fmt_cfg.ext, function(err, out)
      remove_tmp(tmp_path)
      pcall(vim.api.nvim_buf_delete, tb, { force = true })
      cb(err, out)
    end)
    return
  end

  -- prepare formatting params
  local tabSize = vim.api.nvim_get_option_value("shiftwidth", { buf = tb }) or vim.api.nvim_get_option_value("tabstop", { buf = tb }) or 2
  local insertSpaces = vim.api.nvim_get_option_value("expandtab", { buf = tb })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(tb),
    options = { tabSize = tabSize, insertSpaces = insertSpaces },
  }

  -- request formatting from each client; use the first that returns edits
  local pending = #candidates
  local applied = false

  for _, client in ipairs(candidates) do
    -- send the request directly to the specific client and pass tb as bufnr
    client.request("textDocument/formatting", params, function(err, result)
      vim.schedule(function()
        pending = pending - 1
        if applied then
          if pending == 0 and not applied then
            -- defensive fallback if none applied
            spawn_or_fallback(fmt_cfg.build_cmd(tmp_path), tmp_path, fmt_cfg.ext, function(err2, out2)
              remove_tmp(tmp_path); pcall(vim.api.nvim_buf_delete, tb, { force = true }); cb(err2, out2)
            end)
          end
          return
        end

        if err then
          vim.notify(("md-codefmt: client error %s"):format(tostring(err)), vim.log.levels.DEBUG, { title = "md-codefmt" })
        elseif result and result ~= vim.NIL and #result > 0 then
          local ok, apperr = pcall(vim.lsp.util.apply_text_edits, result, tb, client and (client.offset_encoding or "utf-16") or "utf-16")
          if ok then
            applied = true
            local formatted_lines = vim.api.nvim_buf_get_lines(tb, 0, -1, false)
            local formatted_text = table.concat(formatted_lines, "\n")
            remove_tmp(tmp_path)
            pcall(vim.api.nvim_buf_delete, tb, { force = true })
            cb(nil, formatted_text)
            return
          else
            vim.notify(("md-codefmt: apply_text_edits failed: %s"):format(tostring(apperr)), vim.log.levels.DEBUG, { title = "md-codefmt" })
          end
        else
          vim.notify(("md-codefmt: client returned no edits for %s"):format(block.lang), vim.log.levels.DEBUG, { title = "md-codefmt" })
        end

        if pending == 0 and not applied then
          -- fallback to CLI after all clients returned
          spawn_or_fallback(fmt_cfg.build_cmd(tmp_path), tmp_path, fmt_cfg.ext, function(err2, out2)
            remove_tmp(tmp_path)
            pcall(vim.api.nvim_buf_delete, tb, { force = true })
            cb(err2, out2)
          end)
        end
      end)
    end, tb) -- pass tb as bufnr so server can be file-aware
  end
end
