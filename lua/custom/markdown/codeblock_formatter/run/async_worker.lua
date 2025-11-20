---@module 'custom.markdown.codeblock_formatter.run'
--- Core runner: async execution of external formatters and atomic patching.
--- This version adds an early notification that prints detected languages,
--- and separates the "apply replacements" logic into a helper to make future
--- modularization easier.
--- keep logic synchronous/async as before; this file remains
--- the main worker until further split into smaller modules.
local M = {}

local api = vim.api
local uv = vim.loop
local fn = vim.fn

local helper = require("custom.markdown.codeblock_formatter.helper")
local write_temp_file = helper.write_temp_file
local read_file = helper.read_file
local remove_tmp = helper.remove_tmp

local cfg_mod = require("custom.markdown.codeblock_formatter.config")
local fmt_mod = require("custom.markdown.codeblock_formatter.formatters")
local finder = require("custom.markdown.codeblock_formatter.find_blocks")

-- runtime config; will be populated by init
M._config = {
  formatters = fmt_mod.default_formatters,
  notify_level = vim.log.levels.INFO,
  prefer_treesitter = true,
  lang_aliases = cfg_mod.default.lang_aliases,
  supported_langs = nil,
}

local function notify(msg, level, opts)
  opts = opts or {}
  level = level or M._config.notify_level
  vim.schedule(function()
    vim.notify(msg, level, vim.tbl_extend("force", { title = "md-codefmt" }, opts))
  end)
end

local function debug_log(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.DEBUG, { title = "md-codefmt" })
  end)
end

-- synchronous fallback runner
local function sync_run(cmd, args, tmp_path, writes_file)
  local argv = { cmd }
  for _, a in ipairs(args or {}) do
    table.insert(argv, a)
  end
  local out = fn.systemlist(argv)
  local rc = vim.v.shell_error
  if rc ~= 0 then
    if writes_file and tmp_path then
      local s = read_file(tmp_path)
      if s then
        return rc, s
      end
    end
    return rc, table.concat(out, "\n")
  end
  if writes_file and tmp_path then
    local s = read_file(tmp_path)
    return rc, s
  end
  return rc, table.concat(out, "\n")
end

-- spawn with fallback (keeps behavior from previous file)
local function spawn_or_fallback(cmd, args, tmp_path, writes_file, cb)
  cb = cb or function() end
  local ok, spawn_err = pcall(function()
    if writes_file then
      local stderr_pipe = uv.new_pipe(false)
      local stderr_chunks = {}
      local handle_ok, handle_err = pcall(function()
        uv.spawn(cmd, { args = args, stdio = { nil, nil, stderr_pipe } }, function(code, _)
          ---@diagnostic disable-next-line lib.uv
          if
            stderr_pipe
            and not pcall(function()
              ---@diagnostic disable-next-line lib.uv
              return stderr_pipe:is_closing()
            end)
          then
            ---@diagnostic disable-next-line lib.uv
            pcall(function()
              ---@diagnostic disable-next-line lib.uv
              stderr_pipe:close()
            end)
          end
          if code ~= 0 then
            local err_text = table.concat(stderr_chunks, "")
            if tmp_path then
              local s = read_file(tmp_path)
              if s then
                cb("exit_code_" .. tostring(code), s)
                return
              end
            end
            cb("exit_code_" .. tostring(code) .. ":" .. err_text, nil)
            return
          end
          if tmp_path then
            local s, rerr = read_file(tmp_path)
            if not s then
              cb("read_tmp_failed:" .. tostring(rerr), nil)
              return
            end
            cb(nil, s)
            return
          end
          cb(nil, nil)
        end)
        ---@diagnostic disable-next-line lib.uv
        stderr_pipe:read_start(function(err, chunk)
          if err then
            return
          end
          if chunk then
            table.insert(stderr_chunks, chunk)
          end
        end)
      end)
      if not handle_ok then
        error(handle_err)
      end
      return
    else
      local stdout_pipe = uv.new_pipe(false)
      local stderr_pipe = uv.new_pipe(false)
      local stdout_chunks = {}
      local stderr_chunks = {}
      local handle_ok, handle_err = pcall(function()
        uv.spawn(cmd, { args = args, stdio = { nil, stdout_pipe, stderr_pipe } }, function(code, _)
          ---@diagnostic disable-next-line lib.uv
          if
            stdout_pipe
            and not pcall(function()
              ---@diagnostic disable-next-line lib.uv
              return stdout_pipe:is_closing()
            end)
          then
            pcall(function()
              ---@diagnostic disable-next-line lib.uv
              stdout_pipe:close()
            end)
          end
          ---@diagnostic disable-next-line lib.uv
          if
            stderr_pipe
            and not pcall(function()
              ---@diagnostic disable-next-line lib.uv
              return stderr_pipe:is_closing()
            end)
          then
            pcall(function()
              ---@diagnostic disable-next-line lib.uv
              stderr_pipe:close()
            end)
          end
          if code ~= 0 then
            local err_text = table.concat(stderr_chunks, "")
            cb("exit_code_" .. tostring(code) .. ":" .. err_text, nil)
            return
          end
          local out_text = table.concat(stdout_chunks, "")
          if out_text ~= "" then
            cb(nil, out_text)
            return
          end
          if tmp_path then
            local s, _ = read_file(tmp_path)
            if s then
              cb(nil, s)
              return
            end
          end
          cb("no_output", nil)
        end)
        ---@diagnostic disable-next-line lib.uv
        stdout_pipe:read_start(function(err, chunk)
          if err then
            return
          end
          if chunk then
            table.insert(stdout_chunks, chunk)
          end
        end)
        ---@diagnostic disable-next-line lib.uv
        stderr_pipe:read_start(function(err, chunk)
          if err then
            return
          end
          if chunk then
            table.insert(stderr_chunks, chunk)
          end
        end)
      end)
      if not handle_ok then
        error(handle_err)
      end
      return
    end
  end)
  if not ok then
    local rc, out = sync_run(cmd, args or {}, tmp_path, writes_file)
    if rc ~= 0 then
      cb("sync_failed_code_" .. tostring(rc) .. ":" .. tostring(spawn_err), out)
    else
      cb(nil, out)
    end
  end
end

-- Create a temporary buffer with filetype derived from `lang`,
-- populate it with `text`, attempt formatting via any attached LSP client that supports
-- "textDocument/formatting". If LSP formatting succeeded, call cb(nil, formatted_text).
-- Otherwise, fall back to calling spawn_or_fallback(cmd,args,tmp,writes_file,cb).
-- try_lsp_then_spawn: attempt LSP-based formatting first, otherwise fall back to CLI.
-- create an ephemeral buffer, set filetype (with a few common aliases),
-- insert text, query LSP clients that advertise the filetype, request formatting from
-- each client (client.request), apply the first successful edits, return formatted text
-- via cb(err, formatted_text). If no client provides edits, fall back to spawn_or_fallback.
local function try_lsp_then_spawn(lang, text, tmp_path, _, spawn_cmd, spawn_args, writes_file, cb)
  cb = cb or function() end

  -- small filetype aliasing for common fences (adjust or move to global config)
  local ft_alias = {
    ts = "typescript",
    tsx = "typescript",
    js = "javascript",
    jsx = "javascript",
    py = "python",
    lua = "lua",
    c = "c",
    cpp = "cpp",
    cs = "csharp",
    go = "go",
  }
  local ft = ft_alias[lang] or lang

  -- create ephemeral buffer (unlisted, scratch)
  local tb = vim.api.nvim_create_buf(false, true)
  if not tb then
    spawn_or_fallback(spawn_cmd, spawn_args or {}, tmp_path, writes_file, cb)
    return
  end

  -- set filetype and populate buffer with the code text
  vim.api.nvim_set_option_value("filetype", ft, { buf = tb })
  local lines = {}
  for ln in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, ln)
  end
  vim.api.nvim_buf_set_lines(tb, 0, -1, false, lines)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = tb })
  vim.api.nvim_set_option_value("modifiable", true, { buf = tb })

  local function discover_formatting_clients_for_buffer(tb2, lang2)
    local checked = {}
    local supporting_clients = {}

    for _, client in ipairs(vim.lsp.get_clients()) do
      local ok, supports = pcall(function()
        -- call method on client; provide tb so servers can be file-aware
        if client.supports_method then
          return client:supports_method("textDocument/formatting", tb2)
        end
        -- fallback: try server_capabilities if present
        local caps = client.server_capabilities or {}
        return caps.documentFormattingProvider == true
      end)
      local name = client.name or tostring(client.id or "<unknown>")
      table.insert(checked, string.format("%s:supports=%s", name, tostring(supports)))
      if ok and supports then
        table.insert(supporting_clients, client)
      end
    end

    -- debug: list checked clients and their support result
    vim.schedule(function()
      if #checked == 0 then
        vim.notify(
          ("md-codefmt: no active LSP clients to check for lang=%s"):format(tostring(lang2)),
          vim.log.levels.DEBUG,
          { title = "md-codefmt" }
        )
      else
        vim.notify(
          ("md-codefmt: checked LSP clients: %s"):format(table.concat(checked, ", ")),
          vim.log.levels.DEBUG,
          { title = "md-codefmt" }
        )
      end
    end)

    return supporting_clients
  end

  -- Usage: replace previous 'candidates' or 'clients_for_filetype' invocation with:
  local candidates = discover_formatting_clients_for_buffer(tb, ft)
  if #candidates == 0 then
    vim.schedule(function()
      vim.notify(
        "md-codefmt: no LSP clients that support formatting for buffer (falling back to CLI)",
        vim.log.levels.DEBUG,
        { title = "md-codefmt" }
      )
    end)
    pcall(vim.api.nvim_buf_delete, tb, { force = true })
    spawn_or_fallback(spawn_cmd, spawn_args or {}, tmp_path, writes_file, cb)
    return
  end

  -- prepare formatting params (textDocument + required options)
  local tabSize = vim.api.nvim_get_option_value("shiftwidth", { buf = tb })
    or vim.api.nvim_get_option_value("tabstop", { buf = tb })
    or 2
  local insertSpaces = vim.api.nvim_get_option_value("expandtab", { buf = tb })
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(tb),
    options = { tabSize = tabSize, insertSpaces = insertSpaces },
  }

  -- send formatting request to each candidate client; use first that returns edits
  local pending = #candidates
  local applied = false

  for _, client in ipairs(candidates) do
    -- client.request(method, params, handler, bufnr) -- attach bufnr so server can be file-aware
    client.request("textDocument/formatting", params, function(err, result, _)
      vim.schedule(function()
        pending = pending - 1

        if applied then
          -- another client already applied edits; ignore
          if pending == 0 and not applied then
            -- should not happen; fallback defensively
            pcall(vim.api.nvim_buf_delete, tb, { force = true })
            spawn_or_fallback(spawn_cmd, spawn_args or {}, tmp_path, writes_file, cb)
          end
          return
        end

        if err then
          vim.schedule(function()
            vim.notify(
              ("md-codefmt: client '%s' formatting error: %s"):format(client.name or tostring(client.id), tostring(err)),
              vim.log.levels.DEBUG,
              { title = "md-codefmt" }
            )
          end)
        elseif result and result ~= vim.NIL and #result > 0 then
          -- try to apply edits returned by this client
          local ok, apperr = pcall(
            vim.lsp.util.apply_text_edits,
            result,
            tb,
            client and (client.offset_encoding or "utf-16") or "utf-16"
          )
          if ok then
            applied = true
            -- read formatted buffer and return via callback
            local formatted_lines = vim.api.nvim_buf_get_lines(tb, 0, -1, false)
            local formatted_text = table.concat(formatted_lines, "\n")
            pcall(vim.api.nvim_buf_delete, tb, { force = true })
            vim.schedule(function()
              vim.notify(
                ("md-codefmt: LSP formatting succeeded for %s (client=%s)"):format(
                  tostring(lang),
                  client.name or tostring(client.id)
                ),
                vim.log.levels.DEBUG,
                { title = "md-codefmt" }
              )
            end)
            cb(nil, formatted_text)
            return
          else
            vim.schedule(function()
              vim.notify(
                ("md-codefmt: apply_text_edits failed for client %s: %s"):format(
                  client.name or tostring(client.id),
                  tostring(apperr)
                ),
                vim.log.levels.DEBUG,
                { title = "md-codefmt" }
              )
            end)
          end
        else
          vim.schedule(function()
            vim.notify(
              ("md-codefmt: client %s returned no edits for %s"):format(
                client.name or tostring(client.id),
                tostring(lang)
              ),
              vim.log.levels.DEBUG,
              { title = "md-codefmt" }
            )
          end)
        end

        -- if this was the last client and none applied, fallback
        if pending == 0 and not applied then
          pcall(vim.api.nvim_buf_delete, tb, { force = true })
          vim.schedule(function()
            vim.notify(
              ("md-codefmt: no LSP edits from any client for %s, falling back to CLI"):format(tostring(lang)),
              vim.log.levels.DEBUG,
              { title = "md-codefmt" }
            )
          end)
          spawn_or_fallback(spawn_cmd, spawn_args or {}, tmp_path, writes_file, cb)
        end
      end)
    end, tb)
  end
end

-- helper: apply replacements atomically and keep single undo step
local function apply_replacements_atomic(bufnr, orig_lines, replacements)
  -- replacements: list of { start_row, end_row, lines = {...} }, 1-based inclusive
  table.sort(replacements, function(a, b)
    return a.start_row < b.start_row
  end)
  local final_lines = {}
  local cur = 1
  for _, r in ipairs(replacements) do
    while cur < r.start_row do
      table.insert(final_lines, orig_lines[cur])
      cur = cur + 1
    end
    for _, ln in ipairs(r.lines) do
      table.insert(final_lines, ln)
    end
    cur = r.end_row + 1
  end
  while cur <= #orig_lines do
    table.insert(final_lines, orig_lines[cur])
    cur = cur + 1
  end
  api.nvim_buf_set_lines(bufnr, 0, -1, false, final_lines)
end

-- Main formatting driver
function M.format_blocks_async(bufnr, sline, eline, opts)
  bufnr = bufnr or api.nvim_get_current_buf()
  sline = sline or 1
  eline = eline or api.nvim_buf_line_count(bufnr)
  opts = opts or {}

  -- prepare supported set and aliases
  local supported = {}
  for k, _ in pairs(M._config.formatters or {}) do
    supported[k] = true
  end
  local aliases = M._config.lang_aliases or {}

  local blocks = finder.find_blocks_in_range(
    bufnr,
    sline,
    eline,
    supported,
    aliases,
    { prefer_treesitter = M._config.prefer_treesitter }
  )
  if not blocks or #blocks == 0 then
    notify("No supported fenced codeblocks in range.", M._config.notify_level)
    if opts.on_exit then
      opts.on_exit(true, { changed = false })
    end
    return
  end

  notify(string.format("Found %d supported fenced block(s).", #blocks), M._config.notify_level)

  -- list found languages (debug visibility)
  for _, v in ipairs(blocks) do
    notify(
      string.format("found block lang=%s start=%d end=%d", tostring(v.lang), v.start_row, v.end_row),
      M._config.notify_level
    )
  end

  -- pre-check tools
  local missing = {}
  for _, b in ipairs(blocks) do
    local fmt_cfg = (M._config.formatters or {})[b.lang]
    if not fmt_cfg then
      missing[b.lang] = "no_config"
    else
      if not fmt_mod.is_tool_available(b.lang, fmt_cfg) then
        missing[b.lang] = "not_available"
      end
    end
  end
  if next(missing) then
    local parts = {}
    for k, v in pairs(missing) do
      table.insert(parts, k .. ":" .. v)
    end
    notify("Missing/unavailable tools: " .. table.concat(parts, ", "), vim.log.levels.WARN)
  end

  local orig_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local pending = #blocks
  local replacements = {}
  local errors = {}

  for _, block in ipairs(blocks) do
    local lang = block.lang
    local fmt_cfg = (M._config.formatters or {})[lang]
    if not fmt_cfg then
      table.insert(errors, { block = block, err = "missing_formatter_config" })
      pending = pending - 1
      goto continue_block
    end

    if not fmt_mod.is_tool_available(lang, fmt_cfg) then
      table.insert(errors, { block = block, err = "tool_not_available:" .. lang })
      pending = pending - 1
      goto continue_block
    end

    local block_lines = api.nvim_buf_get_lines(bufnr, block.start_row - 1, block.end_row, false)
    local original_text = table.concat(block_lines, "\n")
    local tmp, werr = write_temp_file(original_text, fmt_cfg.ext)
    if not tmp then
      table.insert(errors, { block = block, err = "tmp_write_error:" .. tostring(werr) })
      pending = pending - 1
      goto continue_block
    end

    local cmd, args, writes_file = fmt_cfg.build_cmd(tmp)
    writes_file = (writes_file == nil) and true or writes_file
    args = args or {}

    -- spawn_or_fallback(cmd, args, tmp, writes_file, function(err, formatted)
    try_lsp_then_spawn(block.lang, original_text, tmp, fmt_cfg.ext, cmd, args, writes_file, function(err, formatted)
      vim.schedule(function()
        if err or not formatted then
          table.insert(errors, { block = block, err = tostring(err) })
          debug_log(
            string.format(
              "Formatter error for lang=%s at %d..%d : %s",
              block.lang,
              block.start_row,
              block.end_row,
              tostring(err)
            )
          )
        else
          if formatted:sub(-1) == "\n" then
            formatted = formatted:sub(1, -2)
          end
          local new_lines = {}
          for ln in formatted:gmatch("([^\n]*)\n?") do
            table.insert(new_lines, ln)
          end
          local same = true
          if #new_lines ~= #block_lines then
            same = false
          else
            for i = 1, #new_lines do
              if new_lines[i] ~= block_lines[i] then
                same = false
                break
              end
            end
          end
          if not same then
            table.insert(replacements, { start_row = block.start_row, end_row = block.end_row, lines = new_lines })
            debug_log(
              string.format(
                "Queued replacement for %s block %d..%d (orig=%d -> new=%d)",
                block.lang,
                block.start_row,
                block.end_row,
                #block_lines,
                #new_lines
              )
            )
          else
            debug_log(string.format("No change for %s block %d..%d", block.lang, block.start_row, block.end_row))
          end
        end
        remove_tmp(tmp)
        pending = pending - 1
        if pending == 0 then
          if #replacements == 0 then
            notify("No changes after formatting.", M._config.notify_level)
            if opts.on_exit then
              opts.on_exit(true, { changed = false, errors = errors })
            end
            return
          end
          apply_replacements_atomic(bufnr, orig_lines, replacements)
          notify(string.format("Formatted %d codeblock(s).", #replacements), M._config.notify_level)
          if #errors > 0 then
            notify(string.format("Some blocks had errors: %d (check messages)", #errors), vim.log.levels.WARN)
            for _, e in ipairs(errors) do
              debug_log(
                ("Error block %d..%d lang=%s : %s"):format(
                  e.block.start_row or 0,
                  e.block.end_row or 0,
                  e.block.lang or "?",
                  tostring(e.err)
                )
              )
            end
          end
          if opts.on_exit then
            opts.on_exit(true, { changed = true, replacements = replacements, errors = errors })
          end
        end
      end)
    end)

    ::continue_block::
  end
end

function M.format_buffer_async()
  local bufnr = api.nvim_get_current_buf()
  M.format_blocks_async(bufnr, 1, api.nvim_buf_line_count(bufnr))
end

function M.format_range_async(sline, eline)
  local bufnr = api.nvim_get_current_buf()
  if not sline or not eline then
    local mode = fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
      sline = fn.line("'<")
      eline = fn.line("'>")
    else
      sline = fn.line(".")
      eline = sline
    end
  end
  M.format_blocks_async(bufnr, sline, eline)
end

return M
