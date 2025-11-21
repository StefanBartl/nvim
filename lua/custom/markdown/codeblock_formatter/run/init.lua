---@module 'custom.markdown.codeblock_formatter.run'
--- Runner glue that uses the extracted `format_single_block` module to format
--- each fenced codeblock independently (LSP-first, CLI-fallback).
--- Responsibilities:
---  - collect blocks with the finder module
---  - for each block call format_single_block(bufnr, block, fmt_cfg, cb)
---  - gather async results, produce replacements only when formatted text differs
---  - apply all replacements atomically (single undo step)
---  - robust logging / notify so man beim Debuggen sieht, was passiert
--- this module assumes `custom.markdown.codeblock_formatter.run.format_single_block`
--- exposes a function with signature:
---   format_single_block(bufnr, block, fmt_cfg, callback)
--- where callback(err, formatted_text_or_nil).
local M = {}

local fn = vim.fn
local api = vim.api

local cfg_mod = require("custom.markdown.codeblock_formatter.config")
local fmt_mod = require("custom.markdown.codeblock_formatter.formatters")
local finder = require("custom.markdown.codeblock_formatter.find_blocks")
local format_single_block = require("custom.markdown.codeblock_formatter.run.format_single_block")

-- runtime config (can be overridden by init module)
M._config = {
  formatters = fmt_mod.default_formatters,
  notify_level = vim.log.levels.INFO,
  prefer_treesitter = true,
  lang_aliases = cfg_mod.default.lang_aliases,
  supported_langs = nil,
}

local function notify(msg, level)
  level = level or M._config.notify_level
  vim.schedule(function()
    vim.notify(msg, level, { title = "md-codefmt" })
  end)
end

local function debug(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.DEBUG, { title = "md-codefmt" })
  end)
end

-- small spawn_or_fallback helper: try uv.spawn if available, otherwise sync systemlist.
-- English comments: This is a pragmatic fallback used when format_single_block needs to
-- run a CLI formatter; it accepts (cmd, args, tmp_path, writes_file, cb).
local function spawn_or_fallback(cmd, args, tmp_path, writes_file, cb)
  cb = cb or function() end
  args = args or {}

  -- try uv.spawn with minimal pipes if available
  local ok, uv = pcall(function()
    return vim.loop
  end)
  if ok and uv then
    local stderr = uv.new_pipe(false)
    local err_chunks = {}
    local handle_ok = pcall(function()
      uv.spawn(cmd, { args = args, stdio = { nil, nil, stderr } }, function(code, _)
        ---@diagnostic disable-next-line lib.uv
        if
          stderr
          and not pcall(function()
            ---@diagnostic disable-next-line li.uv
            return stderr:is_closing()
          end)
        then
          pcall(function()
            ---@diagnostic disable-next-line li.uv
            stderr:close()
          end)
        end
        if code ~= 0 then
          local err_text = table.concat(err_chunks, "")
          -- try read tmp if possible
          if writes_file and tmp_path then
            local f, _ = io.open(tmp_path, "rb")
            if f then
              local content = f:read("*a")
              f:close()
              cb("exit_code_" .. tostring(code) .. ":" .. err_text, content)
              return
            end
          end
          cb("exit_code_" .. tostring(code) .. ":" .. err_text, nil)
          return
        end
        -- success: if writes_file read tmp, otherwise nothing useful
        if writes_file and tmp_path then
          local f = io.open(tmp_path, "rb")
          if f then
            local content = f:read("*a")
            f:close()
            cb(nil, content)
            return
          end
        end
        cb(nil, nil)
      end)
      ---@diagnostic disable-next-line lib.uv
      stderr:read_start(function(err, chunk)
        if err then
          return
        end
        if chunk then
          table.insert(err_chunks, chunk)
        end
      end)
    end)
    if not handle_ok then
      -- fall through to sync below
    else
      return
    end
  end

  -- synchronous fallback using vim.fn.systemlist
  local argv = { cmd }
  for _, a in ipairs(args) do
    table.insert(argv, a)
  end
  local out = vim.fn.systemlist(argv)
  local rc = vim.v.shell_error
  if rc ~= 0 then
    -- try read tmp if writes_file
    if writes_file and tmp_path then
      local f = io.open(tmp_path, "rb")
      if f then
        local content = f:read("*a")
        f:close()
        cb("sync_exit_" .. tostring(rc), content)
        return
      end
    end
    cb("sync_exit_" .. tostring(rc), table.concat(out, "\n"))
    return
  end
  if writes_file and tmp_path then
    local f = io.open(tmp_path, "rb")
    if f then
      local content = f:read("*a")
      f:close()
      cb(nil, content)
      return
    end
  end
  cb(nil, table.concat(out, "\n"))
end

-- apply replacements atomically (single set_lines -> single undo)
local function apply_replacements_atomic(bufnr, orig_lines, replacements)
  table.sort(replacements, function(a, b)
    return a.start_row < b.start_row
  end)
  local final = {}
  local cur = 1
  for _, r in ipairs(replacements) do
    while cur < r.start_row do
      table.insert(final, orig_lines[cur])
      cur = cur + 1
    end
    for _, ln in ipairs(r.lines) do
      table.insert(final, ln)
    end
    cur = r.end_row + 1
  end
  while cur <= #orig_lines do
    table.insert(final, orig_lines[cur])
    cur = cur + 1
  end
  api.nvim_buf_set_lines(bufnr, 0, -1, false, final)
end

--- Format all supported fenced codeblocks in a buffer (async orchestration).
--- bufnr: buffer to operate on
--- sline/eline: optional 1-based search range
function M.format_blocks_async(bufnr, sline, eline, opts)
  bufnr = bufnr or api.nvim_get_current_buf()
  sline = sline or 1
  eline = eline or api.nvim_buf_line_count(bufnr)
  opts = opts or {}

  -- prepare supported languages set and aliases
  local supported = {}
  for k, _ in pairs(M._config.formatters or {}) do
    supported[k] = true
  end
  local aliases = M._config.lang_aliases or {}

  -- find blocks in range
  local blocks = finder.find_blocks_in_range(
    bufnr,
    sline,
    eline,
    supported,
    aliases,
    { prefer_treesitter = M._config.prefer_treesitter }
  )
  if not blocks or #blocks == 0 then
    notify("No supported fenced codeblocks in range.")
    if opts.on_exit then
      opts.on_exit(true, { changed = false })
    end
    return
  end

  notify(string.format("Found %d supported fenced block(s).", #blocks))
  for _, b in ipairs(blocks) do
    debug(string.format("found block lang=%s start=%d end=%d", tostring(b.lang), b.start_row, b.end_row))
  end

  -- prepare orchestration containers
  local orig_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local pending = #blocks
  local replacements = {}
  local errors = {}

  -- iterate blocks and call the single-block formatter
  for _, block in ipairs(blocks) do
    local fmt_cfg = (M._config.formatters or {})[block.lang]
    if not fmt_cfg then
      table.insert(errors, { block = block, err = "no_formatter_config" })
      pending = pending - 1
      goto continue_block
    end

    -- call the modular function; callback will be invoked async
    format_single_block(bufnr, block, fmt_cfg, spawn_or_fallback, function(err, formatted_text)
      -- schedule work on main loop
      vim.schedule(function()
        if err then
          table.insert(errors, { block = block, err = tostring(err) })
          debug(
            string.format(
              "format_single_block error for %s %d..%d : %s",
              block.lang,
              block.start_row,
              block.end_row,
              tostring(err)
            )
          )
        elseif not formatted_text then
          -- no output: treat as non-changed; still log
          debug(
            string.format(
              "format_single_block returned no formatted output for %s %d..%d",
              block.lang,
              block.start_row,
              block.end_row
            )
          )
        else
          -- normalize trailing newline removal (we store lines without final empty)
          if formatted_text:sub(-1) == "\n" then
            formatted_text = formatted_text:sub(1, -2)
          end
          local new_lines = {}
          for ln in formatted_text:gmatch("([^\n]*)\n?") do
            table.insert(new_lines, ln)
          end

          -- fetch original block lines for comparison (use original snapshot to avoid race)
          local orig_block_lines = {}
          for i = block.start_row, block.end_row do
            table.insert(orig_block_lines, orig_lines[i])
          end

          local same = true
          if #new_lines ~= #orig_block_lines then
            same = false
          else
            for i = 1, #new_lines do
              if new_lines[i] ~= orig_block_lines[i] then
                same = false
                break
              end
            end
          end

          if not same then
            table.insert(replacements, { start_row = block.start_row, end_row = block.end_row, lines = new_lines })
            debug(
              string.format(
                "Queued replacement for %s block %d..%d (orig=%d -> new=%d)",
                block.lang,
                block.start_row,
                block.end_row,
                #orig_block_lines,
                #new_lines
              )
            )
          else
            debug(
              string.format(
                "No change for %s block %d..%d (formatter output identical)",
                block.lang,
                block.start_row,
                block.end_row
              )
            )
          end
        end

        pending = pending - 1
        if pending == 0 then
          -- all blocks processed -> apply replacements (if any)
          if #replacements == 0 then
            notify("No changes after formatting.")
            if opts.on_exit then
              opts.on_exit(true, { changed = false, errors = errors })
            end
            return
          end

          -- apply atomically
          apply_replacements_atomic(bufnr, orig_lines, replacements)
          notify(string.format("Formatted %d codeblock(s).", #replacements))
          if #errors > 0 then
            notify(string.format("Some blocks had errors: %d (check messages)", #errors), vim.log.levels.WARN)
            for _, e in ipairs(errors) do
              debug(
                string.format(
                  "Error block %d..%d lang=%s : %s",
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
    end) -- end format_single_block callback

    ::continue_block::
  end -- for blocks
end

--- Convenience command handlers
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
