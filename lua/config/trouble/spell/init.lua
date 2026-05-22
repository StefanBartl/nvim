---@module 'config.trouble.spell'
---@brief Spell-check diagnostics integration for trouble.nvim.
---@description
--- Features:
---
---   • Scans the current buffer using vim.spell.check()
---   • Publishes all spelling errors as diagnostics
---   • Opens trouble.nvim filtered to source="spell"
---   • ENTER inside trouble jumps to the exact location
---   • z= opens native spell suggestions
---   • 1z= accepts the first suggestion
---   • Diagnostics automatically refresh after correction
---   • Corrected entries disappear immediately
---   • Cursor automatically jumps to the next spell error
---
--- Designed for:
---
---   spell session → correct → continue → finish

-- ─────────────────────────────────────────────────────────────────────────────
-- Imports
-- ─────────────────────────────────────────────────────────────────────────────

local notify = require("lib.notify").create("[config.trouble.spell]")

-- ─────────────────────────────────────────────────────────────────────────────
-- Module
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.Module
local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Namespace
-- ─────────────────────────────────────────────────────────────────────────────

---@type integer
local NS = vim.api.nvim_create_namespace("cfg_spell_trouble")

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

---@type table<integer, true>
local _active = {}

---@type boolean
local _setup_done = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────

---@type Cfg.Spell.Config
local DEFAULTS = {
  severity    = vim.diagnostic.severity.WARN,
  source      = "spell",

  keymap      = false,
  keymap_fix  = "<leader>z=",
  keymap_fix1 = "<leader>z1",
}

---@type Cfg.Spell.Config
local _cfg = vim.tbl_extend("force", {}, DEFAULTS)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param bufnr integer
---@return boolean
local function buf_valid(bufnr)
  return type(bufnr) == "number"
    and vim.api.nvim_buf_is_valid(bufnr)
end

---@return boolean
local function spell_api_ok()
  return type(vim.spell) == "table"
    and type(vim.spell.check) == "function"
end

---@param bufnr integer
---@param lnum integer
---@param entry Cfg.Spell.Entry
---@param source string
---@param severity vim.diagnostic.Severity
---@return vim.Diagnostic
local function make_diag(bufnr, lnum, entry, source, severity)
  local word = entry[1]
  local col  = entry[3]

  return {
    bufnr    = bufnr,
    lnum     = lnum,
    col      = col,
    end_lnum = lnum,
    end_col  = col + #word,

    severity = severity,
    source   = source,
    message  = word,
  }
end

---@param bufnr integer
---@param source string
---@param severity vim.diagnostic.Severity
---@return vim.Diagnostic[]
local function collect(bufnr, source, severity)
  local lines       = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local spell_check = vim.spell.check

  ---@type vim.Diagnostic[]
  local out = {}

  local n = 0

  for i = 1, #lines do
    local errs = spell_check(lines[i])

    for j = 1, #errs do
      n      = n + 1
      out[n] = make_diag(bufnr, i - 1, errs[j], source, severity)
    end
  end

  return out
end

---@return nil
local function open_trouble()
  local ok, trouble = pcall(require, "trouble")

  if not ok then
    notify.error("trouble.nvim is unavailable")
    return
  end

  trouble.open({
    mode = "diagnostics",

    filter = {
      source = _cfg.source,
    },
  })
end

---@return nil
local function refresh_trouble()
  local ok, trouble = pcall(require, "trouble")

  if not ok then
    return
  end

  pcall(trouble.refresh)
end

---@param bufnr integer
---@return nil
local function attach_keymaps(bufnr)
  -- Interactive spell correction.
  if type(_cfg.keymap_fix) == "string" and _cfg.keymap_fix ~= "" then
    vim.keymap.set("n", _cfg.keymap_fix, function()
      M.fix_current()
    end, {
      buffer = bufnr,
      silent = true,
      desc   = "[spell] Correct current spelling issue",
    })
  end

  -- Accept first suggestion immediately.
  if type(_cfg.keymap_fix1) == "string" and _cfg.keymap_fix1 ~= "" then
    vim.keymap.set("n", _cfg.keymap_fix1, function()
      vim.cmd("normal! 1z=")

      vim.defer_fn(function()
        M.refresh()
        M.goto_next()
      end, 50)
    end, {
      buffer = bufnr,
      silent = true,
      desc   = "[spell] Accept first correction suggestion",
    })
  end
end

---@param bufnr integer
---@return nil
local function detach_keymaps(bufnr)
  if not buf_valid(bufnr) then
    return
  end

  if type(_cfg.keymap_fix) == "string" then
    pcall(vim.keymap.del, "n", _cfg.keymap_fix, { buffer = bufnr })
  end

  if type(_cfg.keymap_fix1) == "string" then
    pcall(vim.keymap.del, "n", _cfg.keymap_fix1, { buffer = bufnr })
  end
end

---@param name string
---@param fn function
---@param desc string
---@return nil
local function register_cmd(name, fn, desc)
  local ok, usercmd = pcall(require, "lib.usercmd")

  if ok and type(usercmd) == "function" then
    usercmd(name, fn, {
      desc = desc,
    })
  else
    vim.api.nvim_create_user_command(name, fn, {
      desc = desc,
    })
  end
end

---@param lhs string
---@param fn function
---@param desc string
---@return nil
local function register_map(lhs, fn, desc)
  local ok, libmap = pcall(require, "lib.map")

  if ok and type(libmap) == "function" then
    libmap("n", lhs, fn, {
      desc = desc,
    })
  else
    vim.keymap.set("n", lhs, fn, {
      desc = desc,
    })
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

---@return nil
function M.refresh()
  local bufnr = vim.api.nvim_get_current_buf()

  if not buf_valid(bufnr) then
    return
  end

  vim.diagnostic.reset(NS, bufnr)

  local diagnostics = collect(
    bufnr,
    _cfg.source,
    _cfg.severity
  )

  vim.diagnostic.set(NS, bufnr, diagnostics)

  vim.schedule(function()
    refresh_trouble()
  end)

  if #diagnostics == 0 then
    notify.info("No spelling errors remaining")

    _active[bufnr] = nil

    return
  end
end

---@return nil
function M.goto_next()
  vim.diagnostic.goto_next({
    namespace = NS,
    float     = false,
  })
end

---@return nil
function M.fix_current()
  vim.cmd("normal! z=")

  vim.defer_fn(function()
    M.refresh()
    M.goto_next()
  end, 50)
end

---@return nil
function M.run()
  if not spell_api_ok() then
    notify.error("vim.spell.check requires Neovim >= 0.9")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if not buf_valid(bufnr) then
    notify.warn("Invalid buffer")
    return
  end

  -- Toggle off
  if _active[bufnr] then
    M.clear()
    return
  end

  if not vim.wo.spell then
    vim.wo.spell = true

    notify.info("'spell' enabled for current window")
  end

  local diagnostics = collect(
    bufnr,
    _cfg.source,
    _cfg.severity
  )

  if #diagnostics == 0 then
    notify.info("No spelling errors found")
    return
  end

  vim.diagnostic.set(NS, bufnr, diagnostics)

  _active[bufnr] = true

  attach_keymaps(bufnr)

  open_trouble()

  notify.info(string.format(
    "%d spelling error(s) found",
    #diagnostics
  ))
end

---@return nil
function M.clear()
  local bufnr = vim.api.nvim_get_current_buf()

  if not buf_valid(bufnr) then
    return
  end

  vim.diagnostic.reset(NS, bufnr)

  _active[bufnr] = nil

  detach_keymaps(bufnr)

  local ok, trouble = pcall(require, "trouble")

  if ok then
    pcall(trouble.close)
  end

  notify.info("Spell checker deactivated")
end

---@return Cfg.Spell.Config
function M.get_config()
  return vim.tbl_extend("force", {}, _cfg)
end

---@param opts? Cfg.Spell.Opts
---@return nil
function M.setup(opts)
  if _setup_done then
    return
  end

  if type(opts) == "table" then
    _cfg = vim.tbl_extend("force", DEFAULTS, opts)
  end

  register_cmd(
    "SpellChecker",
    M.run,
    "Toggle spell diagnostics session"
  )

  register_cmd(
    "TroubleSpell",
    M.run,
    "Alias for :SpellChecker"
  )

  register_cmd(
    "TroubleSpellClear",
    M.clear,
    "Clear spell diagnostics"
  )

  if type(_cfg.keymap) == "string" and _cfg.keymap ~= "" then
    register_map(
      _cfg.keymap,
      M.run,
      "[spell] Toggle spell session"
    )
  end

  vim.api.nvim_create_autocmd("BufDelete", {
    group = vim.api.nvim_create_augroup(
      "cfg_spell_trouble_gc",
      { clear = true }
    ),

    callback = function(ev)
      _active[ev.buf] = nil
    end,

    desc = "[spell] Cleanup deleted buffers",
  })

  _setup_done = true
end

return M
