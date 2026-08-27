---@module 'wkdoptions.hl_config.cword_occurrences'
--- Highlight all occurrences of <cword> in the buffer except the one under the cursor.
--- Supports "highlight" and underline-family (underline/undercurl/underdouble/underdotted/underdashed).
--- Slices: leadingchar | word | tailchar | firstN

local lazy = require("lib.lua.lazy")
local C = lazy.require("wkdoptions.config") ---@module 'wkdoptions.config'
local Debounce = lazy.require("lib.nvim.debounce")
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")

local M = {}

-- Keep a typed handle to highlight-namespace config to avoid undefined-field warnings.
---@type WKDOptions.HL_CFG
local H = (C and C.cfg and C.cfg.highlight) or {}

-- Dedicated namespace and autocmd group
local NS = vim.api.nvim_create_namespace("myopt_CwordOccur")
local AUG = Autocmd.group("myopt_CwordOccur", true)

-- Internal render-style cache (created highlight groups)
local HLCACHE = {} ---@type table<string, boolean>

local buffer_is_ui_like = require("wkdoptions.hl_config.utils.skip").std_skip

-- Debounce handle (recreated in M.enable() so config changes to debounce_ms take effect)
---@type { call: fun(...:any), cancel: fun() }|nil
local debounced = nil

--- Shorthand to access effective feature config.
---@return CwordOccurrencesCfg
local function CC()
  return H.cword_occurrences or {} ---@type CwordOccurrencesCfg
end

--- Resolve the effective case mode with backward compatibility to `smart_case`.
--- If `case_mode` is unset, fall back to `smart_case` (boolean) semantics.
---@return CwordCaseMode
local function resolve_case_mode()
  local cm = CC().case_mode
  if cm == "smart" or cm == "sensitive" or cm == "insensitive" then
    return cm
  end
  -- Backward compatibility for legacy boolean `smart_case`
  local sc = CC().smart_case
  if sc == false then
    return "sensitive"
  end
  return "smart"
end

--- Large-file guard based on global or local limits.
---@return boolean
local function is_large_file_guard()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return false
  end
  local uv = vim.uv or vim.loop
  local ok, st = pcall(uv.fs_stat, name)
  if not ok or not st or not st.size then
    return false
  end
  local kb = math.floor((st.size or 0) / 1024)
  local local_lim = CC().large_file_kb
  local global_lim = H.large_file_kb or 5000
  local lim = type(local_lim) == "number" and local_lim or global_lim
  return kb > lim
end

--- Build the search pattern with configurable case and match kind.
---@param word string
---@param case_mode CwordCaseMode
---@param match_kind CwordMatchKind
---@return string
local function build_pattern(word, case_mode, match_kind)
  local caseflag ---@type string
  if case_mode == "insensitive" then
    caseflag = "\\c"
  elseif case_mode == "smart" then
    local has_upper = word:find("%u") ~= nil
    caseflag = has_upper and "\\C" or "\\c"
  else
    caseflag = "\\C"
  end

  local escaped = vim.fn.escape(word, "\\")
  local left = (match_kind == "exact") and "\\<" or ""
  local right = (match_kind == "exact") and "\\>" or ""

  return caseflag .. "\\V" .. left .. escaped .. right
end

--- Clear all ranges for current buffer.
---@return nil
local function clear_all()
  pcall(vim.api.nvim_buf_clear_namespace, 0, NS, 0, -1)
end

--- Apply an underline-like style table according to render mode.
---@param render string
---@param sp string|nil
---@return table
local function ul_style_for(render, sp)
  local style = {} ---@type table
  if render == "undercurl" then
    style.undercurl = true
  elseif render == "underdouble" then
    style.underdouble = true
  elseif render == "underdotted" then
    style.underdotted = true
  elseif render == "underdashed" then
    style.underdashed = true
  else
    style.underline = true
  end
  if sp and type(sp) == "string" and sp ~= "" then
    style.sp = sp
  end
  return style
end

--- Check if a highlight group exists (after following links).
---@param name string
---@return boolean
local function hl_exists(name)
  if type(name) ~= "string" or name == "" then
    return false
  end
  local ok, info = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and type(info) == "table" and next(info) ~= nil
end

--- Ensure (and cache) the actual highlight groups used for placement.
---@return string, string  -- word_group, lead_group
local function ensure_groups()
  local render = CC().render or "highlight"

  if render == "highlight" then
    local g_word = CC().hl or "CwordOccur"
    local g_lead = CC().hl_lead or g_word
    local a_word = CC().hl_attr or { bg = "#3a3f4a" }
    local a_lead = CC().hl_lead_attr or { bg = "#5a6070" }

    if not HLCACHE[g_word] then
      if not hl_exists(g_word) then
        pcall(vim.api.nvim_set_hl, 0, g_word, a_word)
      end
      HLCACHE[g_word] = true
    end
    if not HLCACHE[g_lead] then
      if not hl_exists(g_lead) then
        pcall(vim.api.nvim_set_hl, 0, g_lead, a_lead)
      end
      HLCACHE[g_lead] = true
    end
    return g_word, g_lead
  end

  -- Underline-* styles
  local base = "CwordOccur__U_" .. tostring(render)
  local g_word = base .. "_WORD"
  local g_lead = base .. "_LEAD"
  local sp = CC().underline_color
  local force = CC().force_plain_underline ~= false

  if not HLCACHE[g_word] then
    local ok = pcall(
      vim.api.nvim_set_hl,
      0,
      g_word,
      vim.tbl_extend("force", ul_style_for(render, sp), force and { underline = true } or {})
    )
    if not ok then
      pcall(vim.api.nvim_set_hl, 0, g_word, { underline = true })
    end
    HLCACHE[g_word] = true
  end
  if not HLCACHE[g_lead] then
    local ok = pcall(
      vim.api.nvim_set_hl,
      0,
      g_lead,
      vim.tbl_extend("force", ul_style_for(render, sp), force and { underline = true } or {})
    )
    if not ok then
      pcall(vim.api.nvim_set_hl, 0, g_lead, { underline = true })
    end
    HLCACHE[g_lead] = true
  end

  return g_word, g_lead
end

--- Low-level range add using extmarks; use 'combine' for robust overlay.
---@param l0 integer
---@param c0 integer
---@param c1 integer
---@param is_lead boolean
---@return nil
local function add_range(l0, c0, c1, is_lead)
  if c1 <= c0 then
    return
  end
  local pr = CC().priority or 9
  local g_word, g_lead = ensure_groups()
  local hl = is_lead and g_lead or g_word

  vim.api.nvim_buf_set_extmark(0, NS, l0, c0, {
    end_row = l0,
    end_col = c1,
    hl_group = hl,
    priority = pr,
    hl_eol = false,
    strict = false,
    hl_mode = "combine",
    right_gravity = false,
    end_right_gravity = true,
  })
end

--- Place all matches for pattern in [srow,erow], excluding the one under the active cursor.
---@param pat string
---@param srow integer
---@param erow integer
---@return nil
local function place_occurrences(pat, srow, erow)
  local marking = (CC().marking or "leadingchar") ---@type CwordMarking
  local firstN = CC().firstN or 2

  local cur = vim.api.nvim_win_get_cursor(0)
  local cur_l0 = (cur[1] - 1)
  local cur_cbyte = cur[2]

  for l0 = srow, erow do
    local line = vim.api.nvim_buf_get_lines(0, l0, l0 + 1, false)[1] or ""

    -- A line containing an embedded NUL byte cannot be represented as a plain
    -- Vimscript String; vim.fn.* silently converts such a Lua string into a
    -- Blob when crossing into Vimscript, and matchstrpos() then throws
    -- "E976: Using a Blob as a String" because it expects a String argument.
    -- This happens e.g. when a binary file gets loaded into a buffer (neo-tree
    -- rename_buffer() calls bufload() on the renamed path, which fires this
    -- module's BufEnter handler even for non-text buffers) — skip such lines.
    if not line:find("\0", 1, true) then
      local start = 0
      while true do
        ---@diagnostic disable-next-line: deprecated
        local ok, res = pcall(vim.fn.matchstrpos, line, pat, start)
        if not ok then break end
        local _, s, e = unpack(res)
        if s == -1 then
          break
        end

        local exclude = (l0 == cur_l0) and (s <= cur_cbyte) and (cur_cbyte < e)
        if not exclude then
          if marking == "leadingchar" then
            add_range(l0, s, s + 1, true)
          elseif marking == "tailchar" then
            add_range(l0, e - 1, e, true)
          elseif marking == "firstN" then
            local upto = math.min(s + firstN, e)
            add_range(l0, s, upto, true)
          else -- "word"
            add_range(l0, s, e, false)
          end
        end
        start = s + 1
      end
    end
  end
end

--- Determine scan window by viewport_only flag.
---@return integer, integer
local function scan_window()
  if CC().viewport_only then
    local s = math.max(1, vim.fn.line("w0")) - 1
    local e = math.max(1, vim.fn.line("w$")) - 1
    return s, e
  end
  local last = math.max(0, vim.api.nvim_buf_line_count(0) - 1)
  return 0, last
end

--- Immediate repaint (clears first).
---@return nil
local function update_now()
  clear_all()

  if buffer_is_ui_like(0) then
    return
  end
  if not CC().enabled then
    return
  end
  if vim.bo[0].binary then
    return
  end
  if is_large_file_guard() then
    return
  end

  if not CC().in_insert then
    local m = vim.fn.mode(1)
    if m:find("i") then
      return
    end
  end

  -- Safely get current word
  local ok, word = pcall(vim.fn.expand, "<cword>")
  if not ok or type(word) ~= "string" or #word < (CC().min_len or 2) then
    return
  end

  local srow, erow = scan_window()
  -- Optionally reuse cache here (removed to avoid unused-local warnings).

  local case_mode = resolve_case_mode() ---@type CwordCaseMode
  local match_kind = (CC().match_kind == "substring") and "substring" or "exact" ---@type CwordMatchKind
  local pat = build_pattern(word, case_mode, match_kind)
  place_occurrences(pat, srow, erow)
end

--- Only run `fn` if the window/buffer that scheduled it are still valid
--- (they may have closed between the triggering event and this deferred call).
---@param winid integer
---@param bufnr integer
---@param fn fun()
local function if_still_valid(winid, bufnr, fn)
  if not vim.api.nvim_win_is_valid(winid) or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  fn()
end

--- Debounced repaint entry (guards stale win/buf on fire).
---@return nil
local function update_debounced()
  local winid, bufnr = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local ms = CC().debounce_ms or 40
  if ms <= 0 or not debounced then
    update_now()
    return
  end
  debounced.call(winid, bufnr)
end

function M.refresh()
  update_now()
end

function M.enable()
  vim.api.nvim_clear_autocmds({ group = AUG })

  debounced = Debounce.new(function(winid, bufnr)
    if_still_valid(winid, bufnr, update_now)
  end, CC().debounce_ms or 40)

  Autocmd.create({ "CursorMoved" }, update_debounced, {
    group = AUG,
    desc = "Cword occurrences: update on movement",
  })
  Autocmd.create({ "CursorMovedI" }, update_debounced, {
    group = AUG,
    desc = "Cword occurrences: update on movement (insert)",
  })
  Autocmd.create({ "BufEnter", "BufWinEnter", "WinScrolled" }, update_now, {
    group = AUG,
    desc = "Cword occurrences: update on view/window changes",
  })
  Autocmd.create({ "TextChanged", "TextChangedI" }, update_debounced, {
    group = AUG,
    desc = "Cword occurrences: update on edits",
  })
  Autocmd.create({ "BufLeave", "WinLeave" }, clear_all, {
    group = AUG,
    desc = "Cword occurrences: clear when leaving",
  })
  Autocmd.create({ "InsertEnter" }, function()
    if not CC().in_insert then
      clear_all()
    end
  end, {
    group = AUG,
    desc = "Cword occurrences: clear on insert (if configured)",
  })

  update_now()
end

return M
