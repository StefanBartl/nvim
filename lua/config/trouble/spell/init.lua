---@module 'config.trouble.spell'
---@brief Spell-check diagnostics integration with Trouble / quickfix fallback.
---@description
--- Provides `:SpellChecker` / `:TroubleSpell [lang] [scope]` to run an
--- interactive spell-correction session inside the current buffer or across
--- the cwd.
---
--- Features:
---   • Language argument  – `:SpellChecker en` or `:SpellChecker de`
---   • Scope argument     – `%` (buffer, default) or `cwd` (all text files)
---   • Diagnostics via vim.diagnostic (namespace-isolated, source="spell")
---   • Trouble integration when available, otherwise falls back to quickfix
---   • ENTER / `<CR>` in the list jumps to the exact location
---   • `z=`  in normal mode opens native spell suggestions, then advances
---   • `1z=` accepts the first suggestion, refreshes, advances automatically
---   • `]s` / `[s` navigate between spell errors (configurable)
---   • Toggling off restores the original `spell` / `spelllang` window opts
---   • Corrected entries vanish from the list immediately after each fix
---   • Per-buffer state – multiple buffers can run simultaneous sessions
---
--- Architecture:
---   State  → _state  (module-local, per-buffer table)
---   Config → _cfg    (merged from DEFAULTS + user opts at setup time)
---   IO     → collect()  reads lines, calls vim.spell.check per line
---   UI     → open_list() / refresh_list() dispatch to trouble or qf
---   Cmds   → register_cmd() / register_map() wrap lib.usercmd / lib.map

-- ─────────────────────────────────────────────────────────────────────────────
-- Imports  (System → Debug → Utils → State → UI → Controller → Keymaps)
-- ─────────────────────────────────────────────────────────────────────────────

local api  = vim.api
local diag = vim.diagnostic
local fn   = vim.fn

local notify = require("lib.notify").create("[spell]")

-- ─────────────────────────────────────────────────────────────────────────────
-- Module
-- ─────────────────────────────────────────────────────────────────────────────

---@class Cfg.Spell.Module
local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Namespace
-- ─────────────────────────────────────────────────────────────────────────────

---@type integer
local NS = api.nvim_create_namespace("cfg_spell_checker")

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────

---@type Cfg.Spell.Config
local DEFAULTS = {
  severity    = diag.severity.WARN,
  source      = "spell",
  keymap      = false,
  keymap_fix  = "<leader>z=",
  keymap_fix1 = "<leader>z1",
  keymap_next = "]s",
  use_trouble = true,
  qf_title    = "SpellChecker",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

---@type Cfg.Spell.Config
local _cfg = vim.tbl_extend("force", {}, DEFAULTS)

---Per-buffer activation state.
---@type table<integer, Cfg.Spell.BufState>
local _state = {}

---@type boolean
local _setup_done = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Guards
-- ─────────────────────────────────────────────────────────────────────────────

---@param bufnr integer
---@return boolean
local function buf_valid(bufnr)
  return type(bufnr) == "number" and api.nvim_buf_is_valid(bufnr)
end

---@return boolean
local function spell_api_ok()
  return type(vim.spell) == "table"
    and type(vim.spell.check) == "function"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Collection
-- ─────────────────────────────────────────────────────────────────────────────

---Build a single vim.Diagnostic from a vim.spell.check entry.
---@param bufnr    integer
---@param lnum     integer            0-based line number
---@param entry    Cfg.Spell.Entry
---@param source   string
---@param severity vim.diagnostic.Severity
---@return vim.Diagnostic
local function make_diag(bufnr, lnum, entry, source, severity)
  local word = entry[1]
  local col  = entry[3] - 1   -- vim.spell returns 1-based byte col

  -- Clamp: col must be >= 0
  if col < 0 then col = 0 end

  return {
    bufnr    = bufnr,
    lnum     = lnum,
    col      = col,
    end_lnum = lnum,
    end_col  = col + #word,
    severity = severity,
    source   = source,
    message  = ("'%s' is not in the dictionary"):format(word),
    user_data = { word = word, error_type = entry[2] },
  }
end

---Scan a buffer and return all spell diagnostics.
---@param bufnr    integer
---@param source   string
---@param severity vim.diagnostic.Severity
---@return vim.Diagnostic[]
local function collect_buf(bufnr, source, severity)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local spell_check = vim.spell.check

  ---@type vim.Diagnostic[]
  local out = {}
  local n   = 0

  for i = 1, #lines do
    local errs = spell_check(lines[i])
    for j = 1, #errs do
      n      = n + 1
      out[n] = make_diag(bufnr, i - 1, errs[j], source, severity)
    end
  end

  return out
end

---Text-file extensions considered when scanning cwd.
---@type table<string, true>
local TEXT_EXT = {
  lua=true, md=true, txt=true, rst=true, vim=true, toml=true,
  yaml=true, yml=true, json=true, ts=true, js=true, py=true,
  sh=true, zsh=true, fish=true, c=true, cpp=true, h=true,
  go=true, rs=true, java=true, rb=true, html=true, css=true,
  tex=true, bib=true,
}

---Collect diagnostics from every text file under cwd.
---Only files already open in Neovim are scanned (avoids mass-loading).
---@param source   string
---@param severity vim.diagnostic.Severity
---@return table<integer, vim.Diagnostic[]>   bufnr → diagnostics
local function collect_cwd(source, severity)
  local cwd  = fn.getcwd()
  ---@type table<integer, vim.Diagnostic[]>
  local result = {}

  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if not buf_valid(bufnr) then goto continue end
    if api.nvim_buf_get_option(bufnr, "buftype") ~= "" then goto continue end

    local path = api.nvim_buf_get_name(bufnr)
    if path == "" then goto continue end

    -- Must be under cwd
    if path:sub(1, #cwd) ~= cwd then goto continue end

    local ext = path:match("%.([^.]+)$")
    if ext and not TEXT_EXT[ext] then goto continue end

    result[bufnr] = collect_buf(bufnr, source, severity)

    ::continue::
  end

  return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Quickfix helpers
-- ─────────────────────────────────────────────────────────────────────────────

---Convert vim.Diagnostic list to quickfix entries.
---@param diagnostics vim.Diagnostic[]
---@return table[]
local function diags_to_qf(diagnostics)
  local entries = { [#diagnostics] = false }   -- pre-size

  for i, d in ipairs(diagnostics) do
    local bufnr  = d.bufnr or 0
    local fname  = buf_valid(bufnr) and api.nvim_buf_get_name(bufnr) or ""
    entries[i] = {
      bufnr = bufnr,
      filename = fname,
      lnum  = d.lnum + 1,
      col   = d.col + 1,
      text  = d.message,
      type  = "W",
    }
  end

  return entries
end

---Populate the quickfix list from a diagnostics table.
---@param diagnostics vim.Diagnostic[]
---@param title string
local function set_qf(diagnostics, title)
  local entries = diags_to_qf(diagnostics)
  fn.setqflist(entries, "r")
  fn.setqflist({}, "a", { title = title })

  -- Add z= keymap inside the qf window if it's open
  vim.schedule(function()
    for _, winid in ipairs(api.nvim_list_wins()) do
      local buf = api.nvim_win_get_buf(winid)
      if api.nvim_buf_get_option(buf, "buftype") == "quickfix" then
        vim.keymap.set("n", "z=", function()
          -- jump to the qf entry under cursor, then open z=
          vim.cmd("cc " .. fn.line("."))
          vim.defer_fn(function()
            vim.cmd("normal! z=")
            vim.defer_fn(function()
              M.refresh()
            end, 80)
          end, 40)
        end, { buffer = buf, silent = true, desc = "[spell] Fix under cursor" })
      end
    end
  end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Trouble helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@return boolean
local function trouble_available()
  local ok, _ = pcall(require, "trouble")
  return ok
end

---Open (or focus) trouble filtered to source="spell".
local function open_trouble()
  local ok, trouble = pcall(require, "trouble")
  if not ok then return end

  trouble.open({
    mode   = "diagnostics",
    filter = { source = _cfg.source },
  })
end

---Refresh an already-open trouble window.
local function refresh_trouble()
  local ok, trouble = pcall(require, "trouble")
  if not ok then return end
  pcall(trouble.refresh)
end

---Close the trouble window.
local function close_trouble()
  local ok, trouble = pcall(require, "trouble")
  if not ok then return end
  pcall(trouble.close)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Unified list dispatch
-- ─────────────────────────────────────────────────────────────────────────────

---Open whichever list backend is configured/available.
---@param diagnostics vim.Diagnostic[]
local function open_list(diagnostics)
  if _cfg.use_trouble and trouble_available() then
    open_trouble()
  else
    set_qf(diagnostics, _cfg.qf_title)
    vim.cmd("copen")
  end
end

---Refresh whichever list is open.
---@param diagnostics vim.Diagnostic[]
local function refresh_list(diagnostics)
  if _cfg.use_trouble and trouble_available() then
    vim.schedule(refresh_trouble)
  else
    set_qf(diagnostics, _cfg.qf_title)
  end
end

---Close whichever list is open.
local function close_list()
  if _cfg.use_trouble and trouble_available() then
    close_trouble()
  else
    vim.cmd("cclose")
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Per-buffer keymaps
-- ─────────────────────────────────────────────────────────────────────────────

---@param bufnr integer
local function attach_keymaps(bufnr)
  local opts_base = { buffer = bufnr, silent = true }

  -- z= : open spell suggestions, then jump to next error
  if type(_cfg.keymap_fix) == "string" and _cfg.keymap_fix ~= "" then
    vim.keymap.set("n", _cfg.keymap_fix, function()
      M.fix_current()
    end, vim.tbl_extend("force", opts_base, {
      desc = "[spell] Correct word under cursor",
    }))
  end

  -- 1z= : accept first suggestion immediately, refresh, advance
  if type(_cfg.keymap_fix1) == "string" and _cfg.keymap_fix1 ~= "" then
    vim.keymap.set("n", _cfg.keymap_fix1, function()
      vim.cmd("normal! 1z=")
      vim.defer_fn(function()
        M.refresh()
        M.goto_next()
      end, 60)
    end, vim.tbl_extend("force", opts_base, {
      desc = "[spell] Accept first suggestion & advance",
    }))
  end

  -- ]s : jump to next spell error
  if type(_cfg.keymap_next) == "string" and _cfg.keymap_next ~= "" then
    vim.keymap.set("n", _cfg.keymap_next, function()
      M.goto_next()
    end, vim.tbl_extend("force", opts_base, {
      desc = "[spell] Next spell error",
    }))
  end
end

---@param bufnr integer
local function detach_keymaps(bufnr)
  if not buf_valid(bufnr) then return end

  local maps = { _cfg.keymap_fix, _cfg.keymap_fix1, _cfg.keymap_next }

  for _, lhs in ipairs(maps) do
    if type(lhs) == "string" and lhs ~= "" then
      pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
    end
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Language helpers
-- ─────────────────────────────────────────────────────────────────────────────

---Temporarily set spelllang to `lang` in the current window.
---Returns the previous value so it can be restored on deactivation.
---@param lang string
---@return string  previous spelllang
local function apply_lang(lang)
  local prev = vim.wo.spelllang
  vim.wo.spelllang = lang
  return prev
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

---Return a list of currently active buffer handles.
---@return integer[]
function M.active_bufs()
  local out = {}
  local n   = 0
  for bufnr in pairs(_state) do
    n      = n + 1
    out[n] = bufnr
  end
  return out
end

---Jump to the next diagnostic in the spell namespace.
---@return nil
function M.goto_next()
  diag.goto_next({ namespace = NS, float = false })
end

---Jump to the previous diagnostic in the spell namespace.
---@return nil
function M.goto_prev()
  diag.goto_prev({ namespace = NS, float = false })
end

---Open the z= suggestion menu for the word under the cursor.
---After the user picks a suggestion, refresh diagnostics and advance.
---@return nil
function M.fix_current()
  vim.cmd("normal! z=")
  vim.defer_fn(function()
    M.refresh()
    M.goto_next()
  end, 60)
end

---Re-scan the current buffer and update diagnostics + list.
---If no errors remain, deactivates the session for that buffer.
---@return nil
function M.refresh()
  local bufnr = api.nvim_get_current_buf()

  if not buf_valid(bufnr) then return end
  if not _state[bufnr] then return end   -- not an active spell session

  diag.reset(NS, bufnr)

  local diagnostics = collect_buf(bufnr, _cfg.source, _cfg.severity)
  diag.set(NS, bufnr, diagnostics)

  refresh_list(diagnostics)

  if #diagnostics == 0 then
    notify.info("No spelling errors remaining — session closed")
    _state[bufnr] = nil
    detach_keymaps(bufnr)
  end
end

---Activate a spell session.
---@param lang?  string            e.g. "en", "de", "en,de"  (default "en")
---@param scope? Cfg.Spell.Scope   "buf" or "cwd"             (default "buf")
---@return nil
function M.run(lang, scope)
  if not spell_api_ok() then
    notify.error("vim.spell.check requires Neovim >= 0.9")
    return
  end

  lang  = (type(lang)  == "string" and lang  ~= "") and lang  or "en"
  scope = (type(scope) == "string" and scope ~= "") and scope or "buf"

  local bufnr = api.nvim_get_current_buf()

  if not buf_valid(bufnr) then
    notify.warn("Current buffer is invalid")
    return
  end

  -- ── Toggle off ────────────────────────────────────────────────────────────
  if _state[bufnr] then
    M.clear()
    return
  end

  -- ── Activate ──────────────────────────────────────────────────────────────
  local spell_was_on  = vim.wo.spell
  local prev_spelllang = apply_lang(lang)

  if not spell_was_on then
    vim.wo.spell = true
    notify.info(("'spell' enabled (lang: %s)"):format(lang))
  end

  _state[bufnr] = {
    spell_was_on  = spell_was_on,
    prev_spelllang = prev_spelllang,
    lang          = lang,
  }

  -- ── Collect & publish ─────────────────────────────────────────────────────
  if scope == "cwd" then
    -- Multi-buffer scan
    local all = collect_cwd(_cfg.source, _cfg.severity)

    local total = 0
    for b, ds in pairs(all) do
      diag.reset(NS, b)
      diag.set(NS, b, ds)
      total = total + #ds
    end

    -- Flatten for qf
    local flat = {}
    local fi   = 0
    for _, ds in pairs(all) do
      for _, d in ipairs(ds) do
        fi       = fi + 1
        flat[fi] = d
      end
    end

    if total == 0 then
      notify.info("No spelling errors found in cwd")
      _state[bufnr] = nil
      vim.wo.spell = spell_was_on
      vim.wo.spelllang = prev_spelllang
      return
    end

    open_list(flat)
    notify.info(("%d spelling error(s) found across cwd"):format(total))

  else
    -- Single-buffer scan
    local diagnostics = collect_buf(bufnr, _cfg.source, _cfg.severity)

    if #diagnostics == 0 then
      notify.info("No spelling errors found")
      _state[bufnr] = nil
      vim.wo.spell = spell_was_on
      vim.wo.spelllang = prev_spelllang
      return
    end

    diag.reset(NS, bufnr)
    diag.set(NS, bufnr, diagnostics)

    attach_keymaps(bufnr)
    open_list(diagnostics)

    notify.info(("%d spelling error(s) found (lang: %s)"):format(
      #diagnostics, lang
    ))
  end
end

---Deactivate the spell session for the current buffer.
---Restores original spell/spelllang window options.
---@return nil
function M.clear()
  local bufnr = api.nvim_get_current_buf()

  if not buf_valid(bufnr) then return end

  local st = _state[bufnr]

  diag.reset(NS, bufnr)
  _state[bufnr] = nil

  detach_keymaps(bufnr)

  -- Restore window options that existed before the session
  if st then
    vim.wo.spell = st.spell_was_on
    if st.prev_spelllang then
      vim.wo.spelllang = st.prev_spelllang
    end
  end

  close_list()

  notify.info("Spell checker deactivated")
end

---@return Cfg.Spell.Config
function M.get_config()
  return vim.tbl_extend("force", {}, _cfg)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Registration helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param name string
---@param fna   function
---@param desc string
local function register_cmd(name, _fna, desc)
  local ok, usercmd = pcall(require, "lib.usercmd")

  if ok and type(usercmd) == "function" then
    usercmd(name, fn, { desc = desc })
  else
    api.nvim_create_user_command(name, fna, { desc = desc })
  end
end

---@param lhs  string
---@param rhs  function
---@param desc string
local function register_map(lhs, rhs, desc)
  local ok, libmap = pcall(require, "lib.map")

  if ok and type(libmap) == "function" then
    libmap("n", lhs, rhs, { desc = desc })
  else
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Setup
-- ─────────────────────────────────────────────────────────────────────────────

---Call once from your plugin config.  Idempotent.
---@param opts? Cfg.Spell.Opts
---@return nil
function M.setup(opts)
  if _setup_done then return end

  if type(opts) == "table" then
    _cfg = vim.tbl_extend("force", DEFAULTS, opts)
  end

  -- ── Commands ──────────────────────────────────────────────────────────────

  -- :SpellChecker [lang] [scope]
  -- :TroubleSpell [lang] [scope]      (alias)
  local function cmd_run(args)
    local parts = vim.split(args.args or "", "%s+", { trimempty = true })
    local lang  = parts[1]
    local scope = parts[2]

    -- Normalise scope arg: "%" → "buf", anything else → literal
    if scope == "%" then scope = "buf" end

    M.run(lang, scope)
  end

  local cmd_opts = {
    nargs = "*",
    complete = function(_, line, _)
      local parts = vim.split(line, "%s+", { trimempty = false })
      local n     = #parts

      -- First arg: language
      if n == 2 then
        return { "en", "de", "fr", "es", "it", "pt", "nl", "en,de" }
      end

      -- Second arg: scope
      if n == 3 then
        return { "%", "cwd" }
      end

      return {}
    end,
  }

  -- Wrap raw command handler via lib.usercmd if available, else fallback.
  local ok_uc, usercmd = pcall(require, "lib.usercmd")

  if ok_uc and type(usercmd) == "function" then
    usercmd("SpellChecker",  cmd_run, vim.tbl_extend("force", cmd_opts, {
      desc = "Toggle spell-check session  [lang] [%|cwd]",
    }))
    usercmd("TroubleSpell",  cmd_run, vim.tbl_extend("force", cmd_opts, {
      desc = "Alias for :SpellChecker",
    }))
  else
    api.nvim_create_user_command("SpellChecker", cmd_run,
      vim.tbl_extend("force", cmd_opts, {
        desc = "Toggle spell-check session  [lang] [%|cwd]",
      })
    )
    api.nvim_create_user_command("TroubleSpell", cmd_run,
      vim.tbl_extend("force", cmd_opts, {
        desc = "Alias for :SpellChecker",
      })
    )
  end

  register_cmd("SpellCheckerClear", M.clear, "Clear spell diagnostics & close list")
  register_cmd("SpellCheckerRefresh", M.refresh, "Re-scan buffer for spelling errors")

  -- ── Global keymap ─────────────────────────────────────────────────────────
  if type(_cfg.keymap) == "string" and _cfg.keymap ~= "" then
    register_map(_cfg.keymap, function() M.run() end,
      "[spell] Toggle spell session (current buf, default lang)")
  end

  -- ── Autocmd: clean up state for deleted buffers ───────────────────────────
  local ok_ag, augroup = pcall(require, "lib.augroup")

  if ok_ag and type(augroup) == "function" then
    augroup("cfg_spell_checker_gc", {
      {
        event    = "BufDelete",
        callback = function(ev)
          _state[ev.buf] = nil
        end,
        desc = "[spell] GC state for deleted buffers",
      },
    })
  else
    local ag = api.nvim_create_augroup("cfg_spell_checker_gc", { clear = true })
    api.nvim_create_autocmd("BufDelete", {
      group    = ag,
      callback = function(ev)
        _state[ev.buf] = nil
      end,
      desc = "[spell] GC state for deleted buffers",
    })
  end

  _setup_done = true
end

return M
