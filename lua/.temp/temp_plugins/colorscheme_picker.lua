---@module 'commands.colorscheme_nvchad'
--- User commands and pickers to change and persist NvChad colorschemes.
--- Features:
---   * :ColorschemePick           -> Auto picker (Telescope preferred, else fzf-lua)
---   * :ColorschemeTelescope      -> Telescope-based picker with live preview
---   * :ColorschemeFzf            -> fzf-lua-based picker
---   * :ColorschemeSet {name}     -> Directly set & persist theme without picker
--- Persistence:
---   Rewrites ui.theme in chadrc.lua. Robust path lookup:
---     1) vim.g.colorscheme_persist_path (if set)
---     2) stdpath("config")/lua/chadrc.lua
---     3) stdpath("config")/lua/custom/chadrc.lua
---     4) runtimepath scan for lua/chadrc.lua or lua/custom/chadrc.lua
--- Runtime apply:
---   Uses NvChad Base46 if available; falls back to :colorscheme.

---@class CSNvChad
---@field _desc string
local M = {}
-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Safe require: returns module or nil.
---@param mod string
---@return any|nil
local function srequire(mod)
  local ok, m = pcall(require, mod)
  if ok then return m end
  return nil
end

--- Detect available colorschemes via Vim completion.
---@return string[]
local function list_colorschemes()
  ---@type string[]
  local names = vim.fn.getcompletion("", "color")
  table.sort(names)
  return names
end

--- Apply a theme at runtime using NvChad Base46 if present; otherwise use :colorscheme.
---@param theme string
---@return boolean applied
local function apply_runtime(theme)
  local base46 = srequire("base46")  -- NvChad theming module
  if base46 and type(base46.load_theme) == "function" then
    local ok = pcall(base46.load_theme, theme)
    if ok then
      -- Keep :colorscheme in sync for plugins that query `vim.g.colors_name`
      pcall(vim.cmd.colorscheme, theme)
      return true
    end
  end
  local ok = pcall(vim.cmd.colorscheme, theme)
  return ok
end

--- Test whether a file exists and is a regular file.
---@param p string
---@return boolean
local function is_file(p)
  local uv = vim.uv or vim.loop
  if uv and uv.fs_stat then
    local st = uv.fs_stat(p)
    return st and st.type == "file" or false
  end
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

--- Try to locate chadrc.lua in common NvChad layouts.
---@return string|nil
local function find_chadrc_path()
  -- 0) explicit override
  if type(vim.g.colorscheme_persist_path) == "string" and vim.g.colorscheme_persist_path ~= "" then
    if is_file(vim.g.colorscheme_persist_path) then
      return vim.g.colorscheme_persist_path
    end
  end

  -- 1) standard user config
  local cfg = vim.fn.stdpath("config")
  local c1 = cfg .. "/lua/chadrc.lua"
  if is_file(c1) then return c1 end

  -- 2) older/custom layout
  local c2 = cfg .. "/lua/custom/chadrc.lua"
  if is_file(c2) then return c2 end

  -- 3) scan runtimepath for both variants
  for _, rtp in ipairs(vim.api.nvim_list_runtime_paths()) do
    local p1 = rtp .. "/lua/chadrc.lua"
    if is_file(p1) then return p1 end
    local p2 = rtp .. "/lua/custom/chadrc.lua"
    if is_file(p2) then return p2 end
  end

  -- 4) fallback: nvim_get_runtime_file (broad search)
  local hits = vim.api.nvim_get_runtime_file("chadrc.lua", true)
  for _, h in ipairs(hits) do
    if h:find("/lua/") and is_file(h) then
      return h
    end
  end
  local hits2 = vim.api.nvim_get_runtime_file("lua/chadrc.lua", true)
  for _, h in ipairs(hits2) do
    if is_file(h) then
      return h
    end
  end

  return nil
end

--- Write text atomically: create a .bak once, then overwrite target.
---@param path string
---@param content string
---@return boolean,string|nil
local function write_file_atomic(path, content)
  local uv = vim.uv or vim.loop
  local bak = path .. ".bak"
  if uv and uv.fs_access and uv.fs_copyfile then
    if uv.fs_access(path, "R") then
      pcall(uv.fs_copyfile, path, bak)
    end
  else
    local rf = io.open(path, "rb")
    if rf then
      local old = rf:read("*a"); rf:close()
      pcall(function()
        local wf = io.open(bak, "wb"); if wf then wf:write(old); wf:close() end
      end)
    end
  end

  local wf = io.open(path, "wb")
  if not wf then
    return false, "could not open file for writing"
  end
  wf:write(content)
  wf:close()
  return true, nil
end


--- Comment- and string-aware theme persistence for NvChad (base46).
--- Only touches real code (never commented-out lines or block comments).
--- Supports:
---   A) M.base46 = { ..., theme = "...", ... }  -> replace theme
---      or inject theme if missing inside the table
---   B) M.base46.theme = "..."                  -> replace theme
---   C) If a base46 table exists but has no theme key, inject it before "}"
---   D) If no base46 table exists at all, append a minimal block

---@param file string
---@param theme string
---@return boolean, string|nil
local function persist_theme_in_file(file, theme)
  -- Read file
  local f = io.open(file, "rb")
  if not f then
    return false, "could not open chadrc.lua for reading"
  end
  local s = f:read("*a"); f:close()

  -- -----------------------------------------------------------------------
  -- Helpers to detect comments/strings and skip matches inside them
  -- -----------------------------------------------------------------------

  ---@class Range
  ---@field s integer
  ---@field e integer

  --- Collect ranges for:
  ---   * line comments:        -- ... \n
  ---   * long block comments:  --[=*[ ... ]=*]
  ---   * quoted strings:       "..." or '...' (handles simple escapes)
  ---   * long bracket strings: [=*[ ... ]=*]
  --- Matches in these ranges are ignored.
  ---@param txt string
  ---@return Range[]
  local function collect_ignored_ranges(txt)
    local ranges = {} ---@type Range[]
    local i, n = 1, #txt

    local function add_range(a, b)
      ranges[#ranges + 1] = { s = a, e = b }
    end

    local function read_long_bracket(idx)
      -- expects txt:sub(idx, idx) == '['
      local j = idx + 1
      while j <= n and txt:sub(j, j) == '=' do j = j + 1 end
      if j <= n and txt:sub(j, j) == '[' then
        local eq = j - (idx + 1)
        local close = ']' .. string.rep('=', eq) .. ']'
        local k = txt:find(close, j + 1, true)
        if k then
          return idx, k + #close - 1
        end
      end
      return nil, nil
    end

    while i <= n do
      local ch = txt:sub(i, i)
      local ch2 = (i < n) and txt:sub(i, i + 1) or ""

      -- line/block comments
      if ch2 == "--" then
        -- long block comment?
        if i + 2 <= n and txt:sub(i + 2, i + 2) == '[' then
          local a, b = read_long_bracket(i + 2)
          if a and b then
            -- include the leading "--"
            add_range(i, b)
            i = b + 1
          else
            -- plain line comment
            local nl = txt:find("\n", i + 2, true) or (n + 1)
            add_range(i, nl - 1)
            i = nl
          end
        else
          -- plain line comment
          local nl = txt:find("\n", i + 2, true) or (n + 1)
          add_range(i, nl - 1)
          i = nl
        end

      -- quoted strings
      elseif ch == '"' or ch == "'" then
        local q = ch
        local j = i + 1
        while j <= n do
          local c = txt:sub(j, j)
          if c == "\\" then
            j = j + 2
          elseif c == q then
            add_range(i, j)
            j = j + 1
            break
          else
            j = j + 1
          end
        end
        i = j

      -- long bracket string
      elseif ch == '[' then
        local a, b = read_long_bracket(i)
        if a and b then
          add_range(a, b)
          i = b + 1
        else
          i = i + 1
        end

      else
        i = i + 1
      end
    end

    table.sort(ranges, function(x, y) return x.s < y.s end)
    return ranges
  end

  --- Check if index lies in any ignored range
  ---@param ranges Range[]
  ---@param idx integer
  ---@return boolean
  local function in_ignored(ranges, idx)
    -- binary search would be nicer; linear is fine for small files
    for _, r in ipairs(ranges) do
      if idx >= r.s and idx <= r.e then return true end
    end
    return false
  end

  local ignored = collect_ignored_ranges(s)
  local function not_ignored_at(pos) return not in_ignored(ignored, pos) end

  local replaced = false

  -- -----------------------------------------------------------------------
  -- A) Replace / inject inside:  M.base46 = { ... }
  -- -----------------------------------------------------------------------
  do
    local init = 1
    while true do
      -- restrict to "M.base46 = %b{}" to avoid unrelated tables named base46
      local a, b = s:find("M%s*%.%s*base46%s*=%s*%b{}", init)
      if not a then break end
      if not_ignored_at(a) then
        local block = s:sub(a, b)
        -- Replace existing theme key
        local changed, count = block:gsub(
          "%f[%w_]theme%s*=%s*(['\"]).-(['\"])",
          function(q1, _q2) return "theme = " .. q1 .. theme .. q1 end,
          1
        )
        if count > 0 then
          s = s:sub(1, a - 1) .. changed .. s:sub(b + 1)
          replaced = true
          break
        end
        -- Inject theme if missing: after opening "{"
        local injected = block:gsub("{%s*", '{ theme = "' .. theme .. '", ', 1)
        if injected ~= block then
          s = s:sub(1, a - 1) .. injected .. s:sub(b + 1)
          replaced = true
          break
        end
      end
      init = b + 1
    end
  end

  -- -----------------------------------------------------------------------
  -- B) Replace direct assignment:  M.base46.theme = "..."
  -- -----------------------------------------------------------------------
  if not replaced then
    local init = 1
    while true do
      -- capture the LHS prefix and the opening quote of RHS
      local a, b, prefix, q = s:find("([%.%w_]-base46%s*%.%s*theme%s*=%s*)(['\"])", init)
      if not a then break end
      if not_ignored_at(a) then
        -- find the closing quote for the old value
        local j = b + 1
        while j <= #s do
          local c = s:sub(j, j)
          if c == "\\" then
            j = j + 2
          elseif c == q then
            -- replace full assignment value
            s = s:sub(1, a - 1) .. prefix .. q .. theme .. q .. s:sub(j + 1)
            replaced = true
            break
          else
            j = j + 1
          end
        end
        if replaced then break end
      end
      init = b + 1
    end
  end

  -- -----------------------------------------------------------------------
  -- C) If a base46 table exists but has no theme, inject before closing "}"
  -- -----------------------------------------------------------------------
  if not replaced then
    local init = 1
    while true do
      local a, b = s:find("M%s*%.%s*base46%s*=%s*%b{}", init)
      if not a then break end
      if not_ignored_at(a) then
        local block = s:sub(a, b)
        if not block:match("%f[%w_]theme%s*=") then
          -- inject right before the final "}"
          local injected = block:gsub("%s*}%s*$", ',\n  theme = "' .. theme .. '"\n}', 1)
          if injected ~= block then
            s = s:sub(1, a - 1) .. injected .. s:sub(b + 1)
            replaced = true
            break
          end
        end
      end
      init = b + 1
    end
  end

  -- -----------------------------------------------------------------------
  -- D) No base46 at all -> append minimal block
  -- -----------------------------------------------------------------------
  if not replaced then
    s = s
      .. "\n\n"
      .. "-- persisted by colorscheme picker\n"
      .. "M = M or {}\n"
      .. "M.base46 = M.base46 or {}\n"
      .. ('M.base46.theme = "%s"\n'):format(theme)
    replaced = true
  end

  -- Write back if changed
  if replaced then
    local ok, err = write_file_atomic(file, s)
    if not ok then
      return false, err or "failed to write chadrc.lua"
    end
    return true, nil
  else
    return false, "no changes applied to chadrc.lua"
  end
end



--- Persist theme by locating chadrc.lua and rewriting ui.theme.
---@param theme string
---@return boolean ok
local function persist_theme(theme)
  local path = find_chadrc_path()
  if not path then
    vim.notify("[colorscheme] Could not locate chadrc.lua. Set vim.g.colorscheme_persist_path explicitly.", vim.log.levels.ERROR)
    return false
  end
  local ok, err = persist_theme_in_file(path, theme)
  if not ok then
    vim.notify("[colorscheme] Persist failed: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Apply + persist with notifications.
---@param theme string
local function apply_and_persist(theme)
  theme = vim.trim(theme or "")
  if theme == "" then
    vim.notify("[colorscheme] Empty theme name", vim.log.levels.WARN)
    return
  end
  local applied = apply_runtime(theme)
  if not applied then
    vim.notify("[colorscheme] Failed to apply theme at runtime: " .. theme, vim.log.levels.ERROR)
    return
  end
  if persist_theme(theme) then
    vim.notify("[colorscheme] Applied and persisted theme: " .. theme, vim.log.levels.INFO)
  end
end

-- ---------------------------------------------------------------------------
-- Pickers
-- ---------------------------------------------------------------------------

--- Telescope-based picker with live preview and confirm-to-persist.
local function telescope_picker()
  local builtin = srequire("telescope.builtin")
  local actions = srequire("telescope.actions")
  local action_state = srequire("telescope.actions.state")
  if not (builtin and actions and action_state) then
    vim.notify("[colorscheme] telescope components not available", vim.log.levels.ERROR)
    return
  end

  builtin.colorschemes = builtin.colorschemes or builtin.colorscheme

  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = (entry and (entry.value or entry.text or entry[1])) or nil
        if name then
          apply_and_persist(name)
        else
          vim.notify("[colorscheme] Could not read selected entry", vim.log.levels.ERROR)
        end
      end)
      return true
    end,
  })
end

--- fzf-lua-based picker with confirm-to-persist and optional preview on <C-p>.
local function fzf_picker()
  local fzf = srequire("fzf-lua")
  if not fzf then
    vim.notify("[colorscheme] fzf-lua not found", vim.log.levels.WARN)
    return
  end
  local entries = list_colorschemes()
  fzf.fzf_exec(entries, {
    prompt = "NvChad Colorschemes> ",
    actions = {
      ["default"] = function(selected)
        local theme = (type(selected) == "table") and selected[1] or selected
        if theme then
          apply_and_persist(theme)
        end
      end,
      ["ctrl-p"] = function(selected)
        local theme = (type(selected) == "table") and selected[1] or selected
        if theme then
          pcall(apply_runtime, theme)
        end
      end,
    },
  })
end

--- Auto picker: prefer Telescope, else fzf-lua.
local function auto_picker()
  if srequire("telescope.builtin") then
    telescope_picker()
    return
  end
  if srequire("fzf-lua") then
    fzf_picker()
    return
  end
  vim.notify("[colorscheme] No picker found (install telescope.nvim or fzf-lua)", vim.log.levels.WARN)
end

-- ---------------------------------------------------------------------------
-- User Commands
-- ---------------------------------------------------------------------------

vim.api.nvim_create_user_command("ColorschemePick", function()
  auto_picker()
end, { desc = "Pick colorscheme (auto picker, persists in chadrc.lua)" })

vim.api.nvim_create_user_command("ColorschemeTelescope", function()
  telescope_picker()
end, { desc = "Pick colorscheme via Telescope (persists on confirm)" })

vim.api.nvim_create_user_command("ColorschemeFzf", function()
  fzf_picker()
end, { desc = "Pick colorscheme via fzf-lua (persists on confirm)" })

vim.api.nvim_create_user_command("ColorschemeSet", function(opts)
  ---@type string
  local theme = opts.args or ""
  apply_and_persist(theme)
end, {
  nargs = 1,
  complete = function(_, _, _)
    return list_colorschemes()
  end,
  desc = "Set & persist colorscheme directly",
})










--- Additions to your commands.colorscheme_nvchad module
--- Focus: accurately detect Base46 themes vs general Vim colorschemes
--- and provide pickers/commands that only persist if Base46 supports a name.

-- ============
-- Discovery
-- ============

--- Find all Base46 theme names by scanning runtime:
---  * plugin themes: lua/base46/themes/*.lua
---  * user themes:   lua/themes/*.lua   (as per Base46 docs)
---@return string[] list, table<string,true> set
local function list_base46_themes()
  local list ---@type string[]
  local set  ---@type table<string, true>
  list, set = {}, {}

  local function add(name)
    if name and name ~= "" and not set[name] then
      set[name] = true
      table.insert(list, name)
    end
  end

  -- Plugin-provided themes
  for _, p in ipairs(vim.api.nvim_get_runtime_file("lua/base46/themes/*.lua", true)) do
    local n = p:match("[/\\]themes[/\\]([%w%-%_]+)%.lua$")
    add(n)
  end
  -- User local themes
  for _, p in ipairs(vim.api.nvim_get_runtime_file("lua/themes/*.lua", true)) do
    local n = p:match("[/\\]themes[/\\]([%w%-%_]+)%.lua$")
    add(n)
  end

  table.sort(list)
  return list, set
end

--- List all Vim-level colorschemes (what Telescope/fzf-lua see by default)
---@return string[]
local function list_vim_colorschemes()
  ---@type string[]
  local names = vim.fn.getcompletion("", "color")
  table.sort(names)
  return names
end

--- Compute sets and differences
---@return {b46:string[], b46set:table<string,true>, vimcs:string[], vimset:table<string,true>, vim_only:string[], b46_only:string[]}
local function get_theme_sets()
  local b46, b46set = list_base46_themes()
  local vimcs = list_vim_colorschemes()
  local vimset = {}
  for _, n in ipairs(vimcs) do vimset[n] = true end

  local vim_only, b46_only = {}, {}
  for _, n in ipairs(vimcs) do
    if not b46set[n] then table.insert(vim_only, n) end
  end
  for _, n in ipairs(b46) do
    if not vimset[n] then table.insert(b46_only, n) end
  end

  return { b46 = b46, b46set = b46set, vimcs = vimcs, vimset = vimset, vim_only = vim_only, b46_only = b46_only }
end

--- Predicate: is this a Base46-supported theme?
---@param name string
---@return boolean
local function is_base46(name)
  local _, set = list_base46_themes()
  return set[name] == true
end

-- ============
-- Pickers
-- ============

--- Base46-only picker via Telescope (no live preview to keep it simple & robust)
local function telescope_picker_base46()
  local pickers = require("telescope.pickers")
  local finders  = require("telescope.finders")
  local conf     = require("telescope.config").values
  local actions  = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local sets = get_theme_sets()
  local entries = sets.b46
  if #entries == 0 then
    vim.notify("[colorscheme] No Base46 themes found in runtime", vim.log.levels.ERROR)
    return
  end

  pickers.new({}, {
    prompt_title = "Base46 Themes (persistable)",
    finder = finders.new_table(entries),
    sorter = conf.generic_sorter({}),
    previewer = nil, -- omit custom live preview to avoid private API hacks
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = entry and (entry[1] or entry.value or entry.text)
        if name then
          apply_and_persist(name)
        end
      end)
      return true
    end
  }):find()
end

--- Base46-only picker via fzf-lua (optional manual preview on <C-p>)
local function fzf_picker_base46()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[colorscheme] fzf-lua not found", vim.log.levels.WARN)
    return
  end
  local sets = get_theme_sets()
  local entries = sets.b46
  if #entries == 0 then
    vim.notify("[colorscheme] No Base46 themes found in runtime", vim.log.levels.ERROR)
    return
  end

  fzf.fzf_exec(entries, {
    prompt = "Base46 Themes> ",
    actions = {
      ["default"] = function(selected)
        local name = type(selected) == "table" and selected[1] or selected
        if name then apply_and_persist(name) end
      end,
      ["ctrl-p"] = function(selected)
        local name = type(selected) == "table" and selected[1] or selected
        if name then pcall(apply_runtime, name) end
      end,
    },
  })
end

--- Auto Base46 picker: prefer Telescope if present, else fzf-lua
local function pick_base46()
  if pcall(require, "telescope.pickers") then
    telescope_picker_base46(); return
  end
  if pcall(require, "fzf-lua") then
    fzf_picker_base46(); return
  end
  vim.notify("[colorscheme] Install telescope.nvim or fzf-lua for Base46 picker", vim.log.levels.WARN)
end

--- “All colorschemes” picker as before (Telescope builtin), but persist only if Base46 supports the chosen name.
--- Otherwise: apply transiently and warn.
local function telescope_picker_all_with_guard()
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = entry and (entry.value or entry.text or entry[1])
        if not name then return end
        if is_base46(name) then
          apply_and_persist(name)
        else
          -- apply only; do not persist
          local ok = apply_runtime(name)
          if ok then
            vim.notify(("[colorscheme] Applied non-Base46 theme '%s' (not persisted)"):format(name), vim.log.levels.WARN)
          else
            vim.notify(("[colorscheme] Failed to apply '%s'"):format(name), vim.log.levels.ERROR)
          end
        end
      end)
      return true
    end,
  })
end

-- ============
-- User Commands
-- ============

--- List Base46 vs Vim colorschemes and their differences in a scratch buffer
vim.api.nvim_create_user_command("ColorschemeList", function()
  local sets = get_theme_sets()

  local lines = {} ---@type string[]
  local function add(title, arr)
    table.insert(lines, title .. " (" .. tostring(#arr) .. ")")
    for _, n in ipairs(arr) do table.insert(lines, "  " .. n) end
    table.insert(lines, "")
  end

  add("Base46 themes", sets.b46)
  add("Vim colorschemes", sets.vimcs)
  add("Vim-only (not in Base46; preview ok, no persistence)", sets.vim_only)
  add("Base46-only (not a Vim colorscheme; persist ok, preview via Base46 apply)", sets.b46_only)

  -- open scratch
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype  = "markdown"
  vim.api.nvim_set_current_buf(buf)
end, { desc = "List Base46 vs Vim colorschemes and their differences" })

--- Base46-only picker (persistable)
vim.api.nvim_create_user_command("ColorschemePickBase46", function()
  pick_base46()
end, { desc = "Pick Base46 theme (persisted)" })

--- All colorschemes picker, with Base46-guard on persistence
vim.api.nvim_create_user_command("ColorschemePickAll", function()
  if not pcall(require, "telescope.builtin") then
    vim.notify("[colorscheme] Telescope not available for ColorschemePickAll", vim.log.levels.ERROR)
    return
  end
  telescope_picker_all_with_guard()
end, { desc = "Pick any colorscheme (persist only if Base46 supports it)" })





return M
