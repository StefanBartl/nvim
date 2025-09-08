---@module 'myoptions.Highlight_Cfg.cword_occurrences'
--- Highlight all occurrences of <cword> in the buffer except the one under the cursor.
--- Now supports an underline-based rendering mode (underline/undercurl/underdouble/underdotted/underdashed).
--- Ranges (leadingchar/word/tailchar/firstN) are preserved; only rendering changes.
---
--- Public API:
---   require('myoptions.Highlight_Cfg.cword_occurrences').enable()
---   require('myoptions.Highlight_Cfg.cword_occurrences').refresh()

local M = {}

local C = require("myoptions.config") ---@module 'myoptions.config'
local cfg = C.cfg and C.cfg.highlight or {}

-- Dedicated namespace and autocmd group
local NS  = vim.api.nvim_create_namespace("myopt_CwordOccur")
local AUG = vim.api.nvim_create_augroup("myopt_CwordOccur", { clear = true })

-- Internal render-style cache (created highlight groups)
local HLCACHE = {} ---@type table<string, boolean>

-- Debounce timer
---@type uv.uv_timer_t|nil
local timer = nil

-- Light cache to avoid unnecessary recomputation
---@type CwordInternalCache
local cache = { last_word = nil, last_tick = nil, last_srow = nil, last_erow = nil }

--- Shorthand to access effective feature config.
---@return table
local function CC()
  return (C.cfg and C.cfg.highlight and C.cfg.highlight.cword_occurrences) or {}
end

--- Large-file guard based on global or local limits.
---@return boolean
local function is_large_file_guard()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return false end
  local uv = vim.uv or vim.loop
  local ok, st = pcall(uv.fs_stat, name)
  if not ok or not st or not st.size then return false end
  local kb = math.floor((st.size or 0) / 1024)
  local local_lim = CC().large_file_kb
  local global_lim = cfg.large_file_kb or 5000
  local lim = type(local_lim) == "number" and local_lim or global_lim
  return kb > lim
end

--- Build \<word\> regex with smart/strict case.
---@param word string
---@param smart_case boolean
---@return string
local function build_pattern(word, smart_case)
  local has_upper = word:find("%u") ~= nil
  local caseflag = (smart_case and not has_upper) and "\\c" or "\\C"
  return caseflag .. "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
end

--- Clear all ranges for current buffer.
---@return nil
local function clear_all()
  pcall(vim.api.nvim_buf_clear_namespace, 0, NS, 0, -1)
end

--- Apply an underline-like style table according to render mode.
--- Returns a valid attr table for nvim_set_hl. Unknown styles gracefully fall back to 'underline'.
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
    style.sp = sp -- special (underline/curl color if supported by UI)
  end
  return style
end

--- Ensure (and cache) the actual highlight groups used for placement, depending on render mode.
--- For render="highlight" we reuse configured groups (hl/hl_lead).
--- For underline-modes we synthesize ephemeral groups (and keep them stable per mode).
---@return string, string  -- word_group, lead_group
local function ensure_groups()
  local render = CC().render or "highlight"

  if render == "highlight" then
    local g_word = CC().hl or "CwordOccur"
    local g_lead = CC().hl_lead or g_word
    return g_word, g_lead
  end

  -- Underline-* styles: generate deterministic names and create once
  local base = "CwordOccur__U_" .. tostring(render)
  local g_word = base .. "_WORD"
  local g_lead = base .. "_LEAD"
  local sp = CC().underline_color

  if not HLCACHE[g_word] then
    local ok = pcall(vim.api.nvim_set_hl, 0, g_word, ul_style_for(render, sp))
    if not ok then
      -- Fallback to plain underline on older UIs
      pcall(vim.api.nvim_set_hl, 0, g_word, ul_style_for("underline", sp))
    end
    HLCACHE[g_word] = true
  end
  if not HLCACHE[g_lead] then
    local ok = pcall(vim.api.nvim_set_hl, 0, g_lead, ul_style_for(render, sp))
    if not ok then
      pcall(vim.api.nvim_set_hl, 0, g_lead, ul_style_for("underline", sp))
    end
    HLCACHE[g_lead] = true
  end

  return g_word, g_lead
end

--- Low-level range add using extmarks.
---@param l0 integer
---@param c0 integer
---@param c1 integer
---@param is_lead boolean
---@return nil
local function add_range(l0, c0, c1, is_lead)
  if c1 <= c0 then return end
  local pr = CC().priority or 9
  local g_word, g_lead = ensure_groups()
  local hl = is_lead and g_lead or g_word

  vim.api.nvim_buf_set_extmark(0, NS, l0, c0, {
    end_row  = l0,
    end_col  = c1,
    hl_group = hl,
    priority = pr,
    hl_eol   = false,
    strict   = false,
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
  local firstN  = CC().firstN or 2

  local cur = vim.api.nvim_win_get_cursor(0)
  local cur_l0 = (cur[1] - 1)
  local cur_cbyte = cur[2]

  for l0 = srow, erow do
    local line = vim.api.nvim_buf_get_lines(0, l0, l0 + 1, false)[1] or ""
    local start = 0
    while true do
      local _, s, e = unpack(vim.fn.matchstrpos(line, pat, start))
      if s == -1 then break end

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

  if not CC().enabled then return end
  if is_large_file_guard() then return end

  if not CC().in_insert then
    local m = vim.fn.mode(1)
    if m:find("i") then return end
  end

  local word = vim.fn.expand("<cword>")
  if type(word) ~= "string" or #word < (CC().min_len or 2) then return end

  local srow, erow = scan_window()
  local tick = vim.api.nvim_buf_get_changedtick(0)
  cache.last_word, cache.last_tick, cache.last_srow, cache.last_erow = word, tick, srow, erow

  local pat = build_pattern(word, CC().smart_case ~= false)
  place_occurrences(pat, srow, erow)
end

--- Debounced repaint entry.
---@return nil
local function update_debounced()
  local ms = CC().debounce_ms or 40
  if ms <= 0 then
    update_now()
    return
  end
  local uv = vim.uv or vim.loop
  if not timer then
    timer = uv.new_timer()
  end
  timer:stop()
  timer:start(ms, 0, function()
    timer:stop()
    vim.schedule(update_now)
  end)
end

---@return nil
function M.refresh()
  update_now()
end

---@return nil
function M.enable()
  vim.api.nvim_clear_autocmds({ group = AUG })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on movement",
  })
  vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on movement (insert)",
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinScrolled" }, {
    group = AUG,
    callback = update_now,
    desc = "Cword occurrences: update on view/window changes",
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = AUG,
    callback = update_debounced,
    desc = "Cword occurrences: update on edits",
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = AUG,
    callback = clear_all,
    desc = "Cword occurrences: clear when leaving",
  })
  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = AUG,
    callback = function()
      if not CC().in_insert then clear_all() end
    end,
    desc = "Cword occurrences: clear on insert (if configured)",
  })

  update_now()
end

return M
