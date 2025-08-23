---@module 'commands.colorscheme_nvchad'
--- User commands and pickers to change and persist NvChad colorschemes.
--- Linux/macOS only; no Windows-specific branches.
--- Features:
---   * :ColorschemePick            -> Auto picker (Telescope preferred, else fzf-lua) with persistence
---   * :ColorschemeTelescope       -> Telescope-based picker with live preview (persist on confirm)
---   * :ColorschemeFzf             -> fzf-lua-based picker (persist on confirm; <C-p> for preview)
---   * :ColorschemeSet {name}      -> Directly apply & persist a theme without a picker
---   * :ColorschemeList            -> Scratch buffer listing Base46 vs Vim colorschemes
---   * :ColorschemePickBase46      -> Picker for Base46-only themes (always persistable)
---   * :ColorschemePickAll         -> Telescope picker for all Vim colorschemes; persists only if Base46 supports the selection
--- Persistence details:
---   Rewrites Base46 theme in chadrc.lua with comment/string aware editing.
---   Robust lookup order:
---     1) vim.g.colorscheme_persist_path (explicit)
---     2) stdpath("config")/lua/chadrc.lua
---     3) stdpath("config")/lua/custom/chadrc.lua
---     4) scan runtimepath for either of the above
--- Runtime application order:
---   Prefer NvChad Base46 `load_theme` (if available), then `:colorscheme`.

---@class CSNvChad
---@field _desc string

---@class CSNvChadAPI
---@field apply_runtime fun(theme: string): boolean
---@field persist fun(theme: string): boolean
---@field apply_and_persist fun(theme: string)
---@field list_colorschemes fun(): string[]
---@field list_base46_themes fun(): string[], table<string, true>
---@field is_base46 fun(name: string): boolean

local M = {}

-- ===========================================================================
-- Small utilities
-- ===========================================================================

--- Safe require which returns the module or nil.
---@param mod string
---@return any|nil
local function srequire(mod)
  local ok, m = pcall(require, mod)
  if ok then return m end
  return nil
end

--- Detect available Vim colorschemes via completion.
---@return string[]
local function list_colorschemes()
  ---@type string[]
  local names = vim.fn.getcompletion("", "color")
  table.sort(names)
  return names
end
M.list_colorschemes = list_colorschemes

--- Apply a theme at runtime using Base46 if present; fallback to :colorscheme.
---@param theme string
---@return boolean applied
local function apply_runtime(theme)
  -- Prefer Base46 (NvChad) when available
  local base46 = srequire("base46")
  if base46 and type(base46.load_theme) == "function" then
    local ok = pcall(base46.load_theme, theme)
    if ok then
      -- Keep :colorscheme in sync for plugins that read vim.g.colors_name
      pcall(vim.cmd.colorscheme, theme)
      return true
    end
  end
  -- Fallback to plain colorscheme
  local ok = pcall(vim.cmd.colorscheme, theme)
  return ok
end
M.apply_runtime = apply_runtime

--- Check if path refers to an existing regular file.
---@param p string
---@return boolean
local function is_file(p)
  local uv = vim.uv or vim.loop
  if uv and uv.fs_stat then
    local st = uv.fs_stat(p)
    return (st and st.type == "file") or false
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

  -- 4) broad search
  for _, h in ipairs(vim.api.nvim_get_runtime_file("chadrc.lua", true)) do
    if h:find("/lua/") and is_file(h) then return h end
  end
  for _, h in ipairs(vim.api.nvim_get_runtime_file("lua/chadrc.lua", true)) do
    if is_file(h) then return h end
  end

  return nil
end

--- Write a file atomically (best-effort), keeping a .bak once.
---@param path string
---@param content string
---@return boolean ok, string|nil err
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
        local wf = io.open(bak, "wb")
        if wf then wf:write(old); wf:close() end
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

-- ===========================================================================
-- Comment/string aware persistence into chadrc.lua
-- ===========================================================================

-- Avoid name clashes with LuaLS-internal Range types.
---@class Base46Span
---@field s integer  -- start index (1-based)
---@field e integer  -- end index (inclusive)

--- Compute ignored spans (comments/strings) in a Lua source string.
--- Matches inside these spans must be ignored by the persistence logic.
---@param txt string
---@return Base46Span[]
local function collect_ignored_spans(txt)
  local ranges = {} ---@type Base46Span[]
  local i, n = 1, #txt

  ---@param a integer
  ---@param b integer
  local function add_span(a, b)
    ranges[#ranges + 1] = { s = a, e = b }
  end

  --- Read a long-bracket sequence starting at idx (txt[idx] == '[').
  --- Returns the span [a,b] or nil if not a valid long bracket.
  ---@param idx integer
  ---@return integer|nil a, integer|nil b
  local function read_long_bracket(idx)
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
      -- block comment?
      if i + 2 <= n and txt:sub(i + 2, i + 2) == '[' then
        local a, b = read_long_bracket(i + 2)
        if a and b then
          add_span(i, b)  -- include the leading "--"
          i = b + 1
        else
          local nl = txt:find("\n", i + 2, true) or (n + 1)
          add_span(i, nl - 1)
          i = nl
        end
      else
        local nl = txt:find("\n", i + 2, true) or (n + 1)
        add_span(i, nl - 1)
        i = nl
      end

    -- quoted short strings
    elseif ch == '"' or ch == "'" then
      local q = ch
      local j = i + 1
      while j <= n do
        local c = txt:sub(j, j)
        if c == "\\" then
          j = j + 2
        elseif c == q then
          add_span(i, j)
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
        add_span(a, b)
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

--- Check if an index lies inside any ignored span.
---@param spans Base46Span[]
---@param idx integer
---@return boolean
local function in_ignored(spans, idx)
  -- Linear scan is fine for small files.
  for _, r in ipairs(spans) do
    if idx >= r.s and idx <= r.e then return true end
  end
  return false
end

--- Replace/inject Base46 theme assignments in a chadrc.lua file content.
--- Strategies:
---   A) Replace in `M.base46 = { ... theme = "..." ... }`
---      or inject missing `theme = "<name>"` inside the table.
---   B) Replace in direct `M.base46.theme = "..."`.
---   C) If a base46 table exists but has no `theme`, inject before closing `}`.
---   D) If no base46 at all, append a minimal block.
---@param file string
---@param theme string
---@return boolean ok, string|nil err
local function persist_theme_in_file(file, theme)
  local f = io.open(file, "rb")
  if not f then
    return false, "could not open chadrc.lua for reading"
  end
  local s = f:read("*a"); f:close()

  local ignored = collect_ignored_spans(s)
  local function not_ignored_at(pos) return not in_ignored(ignored, pos) end

  local replaced = false

  -- A) Replace/inject inside `M.base46 = %b{}`
  do
    local init = 1
    while true do
      local a, b = s:find("M%s*%.%s*base46%s*=%s*%b{}", init)
      if not a then break end
      if not_ignored_at(a) then
        local block = s:sub(a, b)
        -- Replace existing theme key (capture only opening quote; closing is matched)
        local changed, count = block:gsub(
          "%f[%w_]theme%s*=%s*(['\"]).-['\"]",
          function(q1) return "theme = " .. q1 .. theme .. q1 end,
          1
        )
        if count > 0 then
          s = s:sub(1, a - 1) .. changed .. s:sub(b + 1)
          replaced = true
          break
        end
        -- Inject theme if missing: right after opening "{"
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

  -- B) Replace in direct assignment: `M.base46.theme = "..."` (outside A)
  if not replaced then
    local init = 1
    while true do
      local a, b, prefix, q = s:find("([%.%w_]-base46%s*%.%s*theme%s*=%s*)(['\"])", init)
      if not a then break end
      if not_ignored_at(a) then
        local j = b + 1
        while j <= #s do
          local c = s:sub(j, j)
          if c == "\\" then
            j = j + 2
          elseif c == q then
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

  -- C) If base46 table exists but without theme, inject before final "}"
  if not replaced then
    local init = 1
    while true do
      local a, b = s:find("M%s*%.%s*base46%s*=%s*%b{}", init)
      if not a then break end
      if not_ignored_at(a) then
        local block = s:sub(a, b)
        if not block:match("%f[%w_]theme%s*=") then
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

  -- D) No base46 at all -> append minimal block
  if not replaced then
    s = s
      .. "\n\n"
      .. "-- persisted by colorscheme picker\n"
      .. "M = M or {}\n"
      .. "M.base46 = M.base46 or {}\n"
      .. ('M.base46.theme = "%s"\n'):format(theme)
    replaced = true
  end

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

--- Persist theme by locating chadrc.lua and rewriting Base46 theme.
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
M.persist = persist_theme

--- Apply + persist with notifications.
---@param theme string
function M.apply_and_persist(theme)
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

-- ===========================================================================
-- Pickers (Telescope / fzf-lua)
-- ===========================================================================

--- Telescope-based picker with live preview; persists on confirm.
local function telescope_picker()
  local builtin = srequire("telescope.builtin")
  local actions = srequire("telescope.actions")
  local action_state = srequire("telescope.actions.state")
  if not (builtin and actions and action_state) then
    vim.notify("[colorscheme] telescope components not available", vim.log.levels.ERROR)
    return
  end

  -- Compatibility shim for older Telescope versions
  builtin.colorschemes = builtin.colorschemes or builtin.colorscheme

  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = (entry and (entry.value or entry.text or entry[1])) or nil
        if name then
          M.apply_and_persist(name)
        else
          vim.notify("[colorscheme] Could not read selected entry", vim.log.levels.ERROR)
        end
      end)
      return true
    end,
  })
end

--- fzf-lua picker; persists on <CR>, preview (apply-only) on <C-p>.
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
        if theme then M.apply_and_persist(theme) end
      end,
      ["ctrl-p"] = function(selected)
        local theme = (type(selected) == "table") and selected[1] or selected
        if theme then pcall(apply_runtime, theme) end
      end,
    },
  })
end

--- Auto picker: prefer Telescope, else fzf-lua.
local function auto_picker()
  if srequire("telescope.builtin") then
    telescope_picker(); return
  end
  if srequire("fzf-lua") then
    fzf_picker(); return
  end
  vim.notify("[colorscheme] No picker found (install telescope.nvim or fzf-lua)", vim.log.levels.WARN)
end

-- ===========================================================================
-- Base46 theme discovery and guarded pickers
-- ===========================================================================

--- Find all Base46 theme names by scanning runtime:
---  * plugin themes: lua/base46/themes/*.lua
---  * user themes:   lua/themes/*.lua
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
M.list_base46_themes = list_base46_themes

--- Predicate: does Base46 support this theme?
---@param name string
---@return boolean
local function is_base46(name)
  local _, set = list_base46_themes()
  return set[name] == true
end
M.is_base46 = is_base46

--- Telescope picker for Base46-only themes (always persistable).
local function telescope_picker_base46()
  local pickers  = srequire("telescope.pickers")
  local finders  = srequire("telescope.finders")
  local confmod  = srequire("telescope.config")
  local actions  = srequire("telescope.actions")
  local action_state = srequire("telescope.actions.state")

  if not (pickers and finders and confmod and actions and action_state) then
    vim.notify("[colorscheme] telescope components not available", vim.log.levels.ERROR)
    return
  end

  local b46 = list_base46_themes
  local entries = b46

  pickers.new({}, {
    prompt_title = "Base46 Themes (persistable)",
    finder = finders.new_table(entries),
    sorter = confmod.values.generic_sorter({}),
    previewer = nil,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = entry and (entry[1] or entry.value or entry.text)
        if name then M.apply_and_persist(name) end
      end)
      return true
    end
  }):find()
end

--- fzf-lua picker for Base46-only themes; preview on <C-p>.
local function fzf_picker_base46()
  local fzf = srequire("fzf-lua")
  if not fzf then
    vim.notify("[colorscheme] fzf-lua not found", vim.log.levels.WARN)
    return
  end
  local b46, _ = list_base46_themes()
  if #b46 == 0 then
    vim.notify("[colorscheme] No Base46 themes found in runtime", vim.log.levels.ERROR)
    return
  end

  fzf.fzf_exec(b46, {
    prompt = "Base46 Themes> ",
    actions = {
      ["default"] = function(selected)
        local name = type(selected) == "table" and selected[1] or selected
        if name then M.apply_and_persist(name) end
      end,
      ["ctrl-p"] = function(selected)
        local name = type(selected) == "table" and selected[1] or selected
        if name then pcall(apply_runtime, name) end
      end,
    },
  })
end

--- Auto Base46 picker: prefer Telescope, else fzf-lua.
local function pick_base46()
  if srequire("telescope.pickers") then
    telescope_picker_base46(); return
  end
  if srequire("fzf-lua") then
    fzf_picker_base46(); return
  end
  vim.notify("[colorscheme] Install telescope.nvim or fzf-lua for Base46 picker", vim.log.levels.WARN)
end

--- Telescope picker for all Vim colorschemes,
--- but persist only if Base46 supports the selected name.
local function telescope_picker_all_with_guard()
  local builtin = srequire("telescope.builtin")
  local actions = srequire("telescope.actions")
  local action_state = srequire("telescope.actions.state")
  if not (builtin and actions and action_state) then
    vim.notify("[colorscheme] telescope components not available", vim.log.levels.ERROR)
    return
  end

  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local name = entry and (entry.value or entry.text or entry[1])
        if not name then return end
        if is_base46(name) then
          M.apply_and_persist(name)
        else
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

-- ===========================================================================
-- User Commands
-- ===========================================================================

vim.api.nvim_create_user_command("ColorschemePick", function()
  auto_picker()
end, { desc = "Pick colorscheme (auto picker, persists in chadrc.lua)" })

vim.api.nvim_create_user_command("ColorschemeTelescope", function()
  telescope_picker()
end, { desc = "Pick colorscheme via Telescope (persist on confirm)" })

vim.api.nvim_create_user_command("ColorschemeFzf", function()
  fzf_picker()
end, { desc = "Pick colorscheme via fzf-lua (persist on confirm)" })

vim.api.nvim_create_user_command("ColorschemeSet", function(opts)
  ---@type string
  local theme = opts.args or ""
  M.apply_and_persist(theme)
end, {
  nargs = 1,
  complete = function()
    return list_colorschemes()
  end,
  desc = "Set & persist colorscheme directly",
})

vim.api.nvim_create_user_command("ColorschemeList", function()
  local b46, b46set = list_base46_themes()
  local vimcs = list_colorschemes()
  local vimset = {}
  for _, n in ipairs(vimcs) do vimset[n] = true end

  local vim_only, b46_only = {}, {}
  for _, n in ipairs(vimcs) do if not b46set[n] then table.insert(vim_only, n) end end
  for _, n in ipairs(b46)  do if not vimset[n] then table.insert(b46_only, n) end end

  local lines = {} ---@type string[]
  local function add(title, arr)
    table.insert(lines, title .. " (" .. tostring(#arr) .. ")")
    for _, n in ipairs(arr) do table.insert(lines, "  " .. n) end
    table.insert(lines, "")
  end

  add("Base46 themes", b46)
  add("Vim colorschemes", vimcs)
  add("Vim-only (not in Base46; preview ok, no persistence)", vim_only)
  add("Base46-only (not a Vim colorscheme; persist ok, preview via Base46 apply)", b46_only)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].filetype   = "markdown"
  vim.api.nvim_set_current_buf(buf)
end, { desc = "List Base46 vs Vim colorschemes and their differences" })

vim.api.nvim_create_user_command("ColorschemePickBase46", function()
  pick_base46()
end, { desc = "Pick Base46 theme (persisted)" })

vim.api.nvim_create_user_command("ColorschemePickAll", function()
  if not srequire("telescope.builtin") then
    vim.notify("[colorscheme] Telescope not available for ColorschemePickAll", vim.log.levels.ERROR)
    return
  end
  telescope_picker_all_with_guard()
end, { desc = "Pick any colorscheme (persist only if Base46 supports it)" })

return M ---@cast M CSNvChadAPI
