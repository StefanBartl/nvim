---@module 'custom.diff'
---@brief Entry point for the custom diff subsystem.
---@description
--- Bootstraps all three components of the diff subsystem in one call:
---
---   1. diff_exit   — adds a safe `:DiffExit` / `q` mapping that tears down
---                    diffmode cleanly without leaving orphaned windows.
---   2. diff_origin — adds `:DiffOrigin` to compare the current buffer against
---                    its last-saved version (git or disk).
---   3. diff        — registers the flexible `:Diff [target=…] [source=…]
---                    [view=…] [output=…]` user command.
---
--- Usage (typically inside your plugin-loader or init.lua):
---
---   require("custom.diff").enable({
---     diff_exit   = true,
---     diff_origin = true,
---     diff        = true,   -- the new :Diff command
---   })
---
---   -- or enable everything at once:
---   require("custom.diff").enable({ enable_all = true })
---
--- Each sub-feature is opt-in. Passing `enable_all = true` is equivalent to
--- setting every flag to true. Unknown keys in opts are silently ignored.

-- ─────────────────────────────────────────────────────────────────────────────
-- Imports
-- ─────────────────────────────────────────────────────────────────────────────

local notify = require("lib.nvim.notify").create("[custom.diff]")

-- ─────────────────────────────────────────────────────────────────────────────
-- Module
-- ─────────────────────────────────────────────────────────────────────────────

---@class Custom.Diff.Module
local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────────────────────

---@type string
local AUGROUP = "custom_diff_cleanup"

---@type string[]
local VALID_VIEWS = { "vsplit", "split", "inline" }

---@type string[]
local VALID_OUTPUTS = { "buffer", "prompt", "file" }

---@type string[]
local TARGET_CHOICES = {
  "clipboard",
  "file path …",
  "buffer number …",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

---@type integer[]
local _scratch_bufs = {}

---@type boolean
local _setup_done = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — validation
-- ─────────────────────────────────────────────────────────────────────────────

---@param v string
---@param allowed string[]
---@return boolean
local function is_one_of(v, allowed)
  for i = 1, #allowed do
    if allowed[i] == v then
      return true
    end
  end
  return false
end

---@param bufnr integer
---@return boolean
local function buf_valid(bufnr)
  return type(bufnr) == "number"
    and vim.api.nvim_buf_is_valid(bufnr)
end

---@param win integer
---@return boolean
local function win_valid(win)
  return type(win) == "number"
    and vim.api.nvim_win_is_valid(win)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — argument parsing
-- ─────────────────────────────────────────────────────────────────────────────

---Parse a raw argument string of the form `key=value key=value …`.
---Unknown keys are silently ignored so that future extensions stay compatible.
---@param raw string
---@return table<string, string>
local function parse_args(raw)
  ---@type table<string, string>
  local out = {}

  for key, value in raw:gmatch("(%a+)=([^%s]+)") do
    out[key] = value
  end

  return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — content resolution
-- ─────────────────────────────────────────────────────────────────────────────

---Resolve a target/source specifier to a flat list of lines.
---@param spec string|integer  "clipboard", a file path, or a buffer number
---@param label string         "target" | "source"  (used in error messages)
---@return string[]|nil lines, string|nil err
local function resolve_lines(spec, label)
  -- ── clipboard ──────────────────────────────────────────────────────────────
  if spec == "clipboard" then
    local raw = vim.fn.getreg("+")

    if type(raw) ~= "string" or raw == "" then
      return nil, "clipboard is empty"
    end

    return vim.split(raw, "\n", { plain = true }), nil
  end

  -- ── buffer number ──────────────────────────────────────────────────────────
  local as_num = tonumber(spec)

  if as_num ~= nil then
    local bufnr = math.floor(as_num)

    if not buf_valid(bufnr) then
      return nil, string.format(
        "%s: buffer %d does not exist or is invalid",
        label, bufnr
      )
    end

    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), nil
  end

  -- ── file path ──────────────────────────────────────────────────────────────
  local path = vim.fn.expand(tostring(spec))

  if vim.fn.filereadable(path) ~= 1 then
    return nil, string.format(
      "%s: file not readable: %s",
      label, path
    )
  end

  return vim.fn.readfile(path), nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — scratch buffer
-- ─────────────────────────────────────────────────────────────────────────────

---Create a non-modifiable scratch buffer, populate it, and track it.
---@param lines string[]
---@param name  string
---@return integer bufnr
local function make_scratch(lines, name)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.bo[bufnr].buftype    = "nofile"
  vim.bo[bufnr].bufhidden  = "wipe"
  vim.bo[bufnr].swapfile   = false
  vim.bo[bufnr].modifiable = false

  _scratch_bufs[#_scratch_bufs + 1] = bufnr

  return bufnr
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — diff output modes
-- ─────────────────────────────────────────────────────────────────────────────

---Open a split, load the scratch buffer, and enable diffmode in both windows.
---@param origin_win  integer
---@param scratch_buf integer
---@param view        Custom.Diff.View
---@return nil
local function open_split_diff(origin_win, scratch_buf, view)
  if not win_valid(origin_win) then
    notify.error("origin window is no longer valid")
    return
  end

  vim.api.nvim_set_current_win(origin_win)

  local split_cmd = (view == "split") and "split" or "vsplit"

  vim.cmd(string.format("silent! %s | buffer %d", split_cmd, scratch_buf))

  local new_win = vim.api.nvim_get_current_win()

  if win_valid(new_win) then
    vim.wo[new_win].diff = true
  end

  if win_valid(origin_win) then
    vim.api.nvim_set_current_win(origin_win)
    vim.wo[origin_win].diff = true
  end

  if win_valid(new_win) then
    vim.api.nvim_set_current_win(new_win)
  end
end

---Pipe a unified diff through the more-prompt.
---@param a_lines string[]
---@param b_lines string[]
---@param a_label string
---@param b_label string
---@return nil
local function show_prompt_diff(a_lines, b_lines, a_label, b_label)
  local ok, result = pcall(vim.diff,
    table.concat(a_lines, "\n") .. "\n",
    table.concat(b_lines, "\n") .. "\n",
    { result_type = "unified", algorithm = "histogram", ctxlen = 3 }
  )

  if not ok or type(result) ~= "string" then
    notify.error("vim.diff failed: " .. tostring(result))
    return
  end

  if result == "" then
    notify.info("No differences found")
    return
  end

  vim.api.nvim_echo(
    { { string.format("--- %s\n+++ %s\n", a_label, b_label) .. result, "Normal" } },
    true,
    {}
  )
end

---Write a unified diff to a temporary file and report its path.
---@param a_lines string[]
---@param b_lines string[]
---@param a_label string
---@param b_label string
---@return nil
local function write_file_diff(a_lines, b_lines, a_label, b_label)
  local ok, result = pcall(vim.diff,
    table.concat(a_lines, "\n") .. "\n",
    table.concat(b_lines, "\n") .. "\n",
    { result_type = "unified", algorithm = "histogram", ctxlen = 3 }
  )

  if not ok or type(result) ~= "string" then
    notify.error("vim.diff failed: " .. tostring(result))
    return
  end

  local tmp = vim.fn.tempname() .. ".diff"

  vim.fn.writefile(
    vim.split(
      string.format("--- %s\n+++ %s\n", a_label, b_label) .. result,
      "\n",
      { plain = true }
    ),
    tmp
  )

  notify.info(string.format("Diff written to: %s", tmp))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers — interactive target picker
-- ─────────────────────────────────────────────────────────────────────────────

---Present a selection popup so the user can choose a target interactively.
---Calls `callback` with the resolved specifier string, or nil on cancel.
---@param callback fun(target: string|nil): nil
---@return nil
local function pick_target(callback)
  local select_fn

  local ok, hover = pcall(require, "lib.nvim.ui.hover_select")

  if ok and type(hover) == "function" then
    select_fn = hover
  else
    select_fn = vim.ui.select
  end

  select_fn(TARGET_CHOICES, { prompt = "Diff target:" }, function(choice, idx)
    if not choice then
      callback(nil)
      return
    end

    if idx == 1 then
      callback("clipboard")

    elseif idx == 2 then
      vim.ui.input({ prompt = "File path: ", completion = "file" }, function(path)
        if type(path) == "string" and path ~= "" then
          callback(path)
        else
          callback(nil)
        end
      end)

    elseif idx == 3 then
      vim.ui.input({ prompt = "Buffer number: " }, function(raw)
        local n = tonumber(raw)

        if n then
          callback(tostring(n))
        else
          notify.warn("Invalid buffer number")
          callback(nil)
        end
      end)
    end
  end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Core execution
-- ─────────────────────────────────────────────────────────────────────────────

---Run the diff with fully resolved options.
---@param opts         Custom.Diff.ResolvedOpts
---@param source_bufnr integer  Buffer snapshotted at invocation time
---@param origin_win   integer  Window snapshotted at invocation time
---@return nil
local function execute(opts, source_bufnr, origin_win)
  -- ── Resolve source ─────────────────────────────────────────────────────────
  local src_lines ---@type string[]|nil

  if opts.source == "current" then
    if not buf_valid(source_bufnr) then
      notify.error("Source buffer is no longer valid")
      return
    end

    src_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  else
    local lines, err = resolve_lines(opts.source, "source")

    if not lines then
      notify.error(err or "Could not resolve source")
      return
    end

    src_lines = lines
  end

  -- ── Resolve target ─────────────────────────────────────────────────────────
  local tgt_lines, tgt_err = resolve_lines(opts.target, "target")

  if not tgt_lines then
    notify.error(tgt_err or "Could not resolve target")
    return
  end

  -- ── Labels ────────────────────────────────────────────────────────────────
  local src_label = (opts.source == "current")
    and ("buf:" .. source_bufnr)
    or  tostring(opts.source)

  local tgt_label = tostring(opts.target)

  -- ── Dispatch ──────────────────────────────────────────────────────────────
  if opts.output == "prompt" then
    show_prompt_diff(src_lines, tgt_lines, src_label, tgt_label)
    return
  end

  if opts.output == "file" then
    write_file_diff(src_lines, tgt_lines, src_label, tgt_label)
    return
  end

  -- output == "buffer"
  if opts.view == "inline" then
    notify.warn("view=inline is reserved for a future release; falling back to view=vsplit")
  end

  local scratch = make_scratch(
    tgt_lines,
    string.format("[Diff] %s", tgt_label)
  )

  open_split_diff(origin_win, scratch, opts.view)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API — :Diff command
-- ─────────────────────────────────────────────────────────────────────────────

---Parse raw command arguments and launch the diff workflow.
---When `target` is absent an interactive picker is shown first.
---@param raw_args string  Raw <args> string delivered by nvim_create_user_command
---@return nil
function M.run(raw_args)
  -- Snapshot immediately — these values must not drift during async callbacks.
  local source_bufnr = vim.api.nvim_get_current_buf()
  local origin_win   = vim.api.nvim_get_current_win()

  local kv = parse_args(type(raw_args) == "string" and raw_args or "")

  -- ── view ──────────────────────────────────────────────────────────────────
  local view = kv.view or "vsplit"

  if not is_one_of(view, VALID_VIEWS) then
    notify.error(string.format(
      "Unknown view=%q  (valid: %s)",
      view, table.concat(VALID_VIEWS, ", ")
    ))
    return
  end

  -- ── output ────────────────────────────────────────────────────────────────
  local output = kv.output or "buffer"

  if not is_one_of(output, VALID_OUTPUTS) then
    notify.error(string.format(
      "Unknown output=%q  (valid: %s)",
      output, table.concat(VALID_OUTPUTS, ", ")
    ))
    return
  end

  -- ── assemble opts (target filled below) ──────────────────────────────────
  ---@type Custom.Diff.ResolvedOpts
  local opts = {
    target = "",
    source = kv.source or "current",
    view   = view   --[[@as Custom.Diff.View]],
    output = output --[[@as Custom.Diff.Output]],
  }

  -- ── target: interactive when omitted ─────────────────────────────────────
  if not kv.target or kv.target == "" then
    pick_target(function(chosen)
      if not chosen then
        notify.info("Diff cancelled")
        return
      end

      opts.target = chosen
      execute(opts, source_bufnr, origin_win)
    end)

    return
  end

  opts.target = kv.target
  execute(opts, source_bufnr, origin_win)
end

---Close all scratch buffers opened by this module and disable diffmode.
---@return nil
function M.clear()
  for _, bufnr in ipairs(_scratch_bufs) do
    if buf_valid(bufnr) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
          vim.wo[win].diff = false
        end
      end

      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win_valid(win) and vim.wo[win].diff then
      vim.wo[win].diff = false
    end
  end

  _scratch_bufs = {}

  notify.info("Diff cleared")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal — register the :Diff user command
-- ─────────────────────────────────────────────────────────────────────────────

---Register `:Diff` and `:DiffClear` plus the VimLeavePre cleanup autocmd.
---@return nil
local function setup_diff_cmd()
  local function usercmd(name, fn, desc)
    local ok, lib = pcall(require, "lib.nvim.usercmd")

    if ok and type(lib) == "function" then
      lib(name, fn, { desc = desc })
    else
      vim.api.nvim_create_user_command(name, function(info)
        fn(info.args)
      end, { desc = desc, nargs = "*" })
    end
  end

  usercmd(
    "Diff",
    function(raw)
      M.run(type(raw) == "table" and (raw.args or "") or tostring(raw or ""))
    end,
    "Diff two sources  :Diff [target=…] [source=…] [view=…] [output=…]"
  )

  usercmd(
    "DiffClear",
    function(_) M.clear() end,
    "Close all :Diff windows and disable diffmode"
  )

  local aug = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group    = aug,
    callback = function()
      for _, bufnr in ipairs(_scratch_bufs) do
        if buf_valid(bufnr) then
          pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        end
      end
    end,
    desc = "[custom.diff] Wipe scratch buffers on exit",
  })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API — enable
-- ─────────────────────────────────────────────────────────────────────────────

---Bootstrap the diff subsystem.
---Idempotent — repeated calls after the first are no-ops.
---
---@param opts Custom.Diff.Opts
---@return nil
function M.enable(opts)
  if _setup_done then
    return
  end

  if type(opts) ~= "table" then
    opts = {}
  end

  -- ── diff_exit ─────────────────────────────────────────────────────────────
  if opts.diff_exit == true or opts.enable_all == true then
    require("custom.diff.diff_exit").enable()
  end

  -- ── diff_origin ───────────────────────────────────────────────────────────
  if opts.diff_origin == true or opts.enable_all == true then
    require("custom.diff.diff_origin").enable()
  end

  -- ── :Diff command ─────────────────────────────────────────────────────────
  if opts.diff == true or opts.enable_all == true then
    setup_diff_cmd()
  end

  _setup_done = true
end

return M
