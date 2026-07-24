---@module 'config.harpoon.persist_paths'
--- Seeds a curated set of absolute file paths into Harpoon's PINS_KEY bucket
--- ONCE, the very first time this config is used on a machine (tracked via a
--- marker file under stdpath("state")). After that, the bucket is fully
--- user-owned: reordering/deleting entries in the Harpoon UI persists across
--- restarts like any other Harpoon list, and nothing here auto-re-adds
--- deleted entries on its own. Two commands give explicit, on-demand control:
---   :HarpoonPersistPaths     - top up: add any target_specs path that is
---                               currently missing, appended at the end.
---                               Everything else in the list is left alone.
---   :HarpoonSetDefaultPaths  - hard reset: clear the bucket and rebuild it
---                               from target_specs, in that exact order.
---
--- Depends on:
---   - utils.harpoon_sanitize (sanitize + dedup, no full replace)
---   - plenary (only for robust absolute path fallback)
---   - harpoon v2 API (prefers :list():add(); falls back gracefully)

local notify = require("lib.nvim.notify").create("[config.harpoon.persist_paths]")
local usercmd = require("lib.nvim.usercmd")

local M = {}

local normkey = require("lib.nvim.fs.normkey")
local uv = vim.uv or vim.loop
local ok_path, Path = pcall(require, "plenary.path")
local sani = require("config.harpoon.utils.sanitize")
local Autocmd = require("lib.nvim.autocmd")

--------------------------------------------------------------------------------
-- Path normalization
--------------------------------------------------------------------------------

---Return a canonical absolute path (resolve symlinks if possible).
---@param p string
---@return string
local function canon(p)
  if type(p) ~= "string" or p == "" then
    return ""
  end
  if uv and uv.fs_realpath then
    local rp = uv.fs_realpath(p)
    if type(rp) == "string" and rp ~= "" then
      return rp
    end
  end
  if ok_path then
    return Path:new(p):absolute()
  end
  -- Fallback: normalize relative → absolute-ish
  return vim.fs.normalize(p)
end

---Check if path is an existing regular file.
---@param p string
---@return boolean
local function is_file(p)
  local st = uv and uv.fs_stat and uv.fs_stat(p) or nil
  return (st and st.type == "file") and true or false
end

--------------------------------------------------------------------------------
-- Target spec → absolute paths
--------------------------------------------------------------------------------

---@type string[][]
M.target_specs = {}

--- Runtime-added default paths (:HarpoonPin), persisted as a plain JSON array
--- of absolute path strings. Kept OUT of the git-tracked config on purpose:
--- these are machine-local additions. The committed defaults live in
--- target_specs (misc.lua); user pins layer on top of them, and both together
--- are what :HarpoonSetDefaultPaths rebuilds from.
local USER_PINS_FILE = vim.fs.joinpath(vim.fn.stdpath("state"), "harpoon_user_pins.json")

---@return string[]
local function load_user_pins()
  local st = uv.fs_stat(USER_PINS_FILE)
  if not st or st.type ~= "file" then
    return {}
  end
  local fd = uv.fs_open(USER_PINS_FILE, "r", 420)
  if not fd then
    return {}
  end
  local data = uv.fs_read(fd, st.size, 0) or ""
  uv.fs_close(fd)
  if data == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, data)
  if not ok or type(decoded) ~= "table" then
    notify.warn("[harpoon] user pins file is corrupt, ignoring: " .. USER_PINS_FILE)
    return {}
  end
  local out = {} ---@type string[]
  for _, v in ipairs(decoded) do
    if type(v) == "string" and v ~= "" then
      out[#out + 1] = v
    end
  end
  return out
end

---@param pins string[]
---@return boolean ok
local function save_user_pins(pins)
  local dir = vim.fn.stdpath("state")
  if uv.fs_stat(dir) == nil then
    vim.fn.mkdir(dir, "p")
  end
  local fd = uv.fs_open(USER_PINS_FILE, "w", 420)
  if not fd then
    notify.error("[harpoon] could not write user pins file: " .. USER_PINS_FILE)
    return false
  end
  uv.fs_write(fd, vim.json.encode(pins), 0)
  uv.fs_close(fd)
  return true
end

---@param sym string
---@return string
local function expand_var(sym)
  if sym == "$REPOS_DIR" then
    return vim.env.REPOS_DIR or ""
  elseif sym == "$HOME" then
    return (uv.os_homedir and uv.os_homedir()) or vim.fn.expand("~")
  elseif sym == "$NVIM_HOME" then
    return vim.fn.stdpath("config")
  end
  return sym
end

---@param segs string[]
---@return string
local function join_spec(segs)
  local parts = {} ---@type string[]
  -- Pre-allocate to avoid reallocations for known length
  parts[#parts + 1] = expand_var(segs[1] or "")
  for i = 2, #segs do
    parts[#parts + 1] = segs[i]
  end
  ---@diagnostic disable-next-line: deprecated
  local unpack = table.unpack or unpack
  return vim.fs.joinpath(unpack(parts))
end

--- All default paths, absolute and deduped: the committed target_specs first
--- (in order), then the machine-local :HarpoonPin additions. Order defines the
--- sequence :HarpoonSetDefaultPaths rebuilds the bucket in.
---@return string[]
local function resolve_targets()
  local out = {} ---@type string[]
  local seen = {} ---@type table<string, boolean>

  local function push(p)
    if p == "" then
      return
    end
    local k = normkey(p)
    if not seen[k] then
      seen[k] = true
      out[#out + 1] = p
    end
  end

  for i = 1, #M.target_specs do
    push(canon(join_spec(M.target_specs[i])))
  end
  for _, p in ipairs(load_user_pins()) do
    push(canon(p))
  end
  return out
end

--- Normalized-key set of every default path (static + user pins). Used by the
--- quick-menu pin marker (config.harpoon.pin_marks) to flag protected lines.
---@return table<string, boolean>
function M.pinned_set()
  local set = {} ---@type table<string, boolean>
  for _, p in ipairs(resolve_targets()) do
    set[normkey(p, { realpath = true })] = true
  end
  return set
end

--------------------------------------------------------------------------------
-- Fixed project key
--------------------------------------------------------------------------------

--- Harpoon2's default `settings.key()` returns the raw, ambient `vim.loop.cwd()`
--- (not git-root-aware), so it drifts with `:cd`, cwd_sync, session restore etc.
--- These pins are meant to be available regardless of which project is active,
--- so the whole harpoon list lives under ONE fixed key instead of whatever
--- project happens to be ambient (which previously scattered lists across a
--- per-cwd bucket each). bindings/mappings/harpoon.lua wires harpoon's
--- `settings.key` to exactly this value, so the normal `<C-e>` UI and this
--- module operate on the same single global bucket.
---@type string
M.PINS_KEY = vim.fn.stdpath("config")
local PINS_KEY = M.PINS_KEY

--- Marker for "have we ever seeded this bucket". Deliberately NOT "is the
--- bucket currently empty" -- the user emptying it on purpose (select-all +
--- dd in the quick menu) must stay empty across restarts, not get silently
--- repopulated. Use :HarpoonSetDefaultPaths to restore defaults on demand.
local INIT_MARKER = vim.fs.joinpath(vim.fn.stdpath("state"), "harpoon_persist_paths.initialized")

--------------------------------------------------------------------------------
-- PINS_KEY access
--------------------------------------------------------------------------------

---Run `fn(harpoon, list)` with harpoon's project key temporarily pinned to
---PINS_KEY, regardless of the ambient project cwd. Harpoon2 resolves
---`settings.key()` again on every ADD/REMOVE-triggered autosave (see
---`sync_on_change` in harpoon/init.lua), so the override must stay in place
---for the whole call, not just the `harpoon:list()` lookup.
---@param fn fun(harpoon: table, list: Cfg.Harpoon.List): boolean
---@return boolean ok, boolean|string result_or_err
local function with_pins_key(fn)
  local ok_hp, harpoon = pcall(require, "harpoon")
  if not ok_hp then
    return false, "harpoon not available"
  end

  local settings = harpoon.config and harpoon.config.settings
  local orig_key = settings and settings.key
  if type(orig_key) ~= "function" then
    return false, "harpoon.config.settings.key missing"
  end

  settings.key = function()
    return PINS_KEY
  end

  local ok_run, result = pcall(function()
    local list = harpoon:list()
    if type(list) ~= "table" then
      return false
    end
    ---@cast list Cfg.Harpoon.List
    return fn(harpoon, list)
  end)

  settings.key = orig_key

  if not ok_run then
    return false, tostring(result)
  end
  return true, result
end

--------------------------------------------------------------------------------
-- Injection
--------------------------------------------------------------------------------

---Persist the current PINS_KEY bucket to disk. MUST be called while the key
---override is active (inside a with_pins_key callback), because harpoon:sync()
---resolves settings.key() again to decide which bucket to write. Does not rely
---on harpoon's save_on_change extension, which is only wired once
---bindings/mappings/harpoon.lua has run its harpoon:setup() (UIReady) — this
---module can fire earlier (VimEnter, first-run seed) or standalone in tests.
---@param harpoon table
---@param list table
local function save_bucket(harpoon, list)
  if type(harpoon.save) == "function" then
    pcall(harpoon.save, harpoon)
  elseif type(list.save) == "function" then
    pcall(list.save, list)
  end
end

---Add an item to the harpoon list using v2 API when available.
---@param list table
---@param path string
local function add_with_context(list, path)
  local item = { value = canon(path), context = { row = 1, col = 0 } }
  if type(list.add) == "function" then
    pcall(function()
      list:add(item)
    end)
  elseif type(list.append) == "function" then
    pcall(function()
      list:append(item)
    end)
  else
    -- Last resort (pure table)
    list.items = list.items or {}
    table.insert(list.items, item)
  end
end

---Top up the PINS_KEY bucket: add any target_specs path that is currently
---missing (existing entries, order and any extra user-added entries are left
---untouched), appended at the end in target_specs order.
---@return boolean changed
function M.inject_now()
  local ok, result = with_pins_key(function(harpoon, list)
    -- Ensure list shape and remove legacy duplicates
    sani.sanitize_items_in_place(list)

    local have = {} ---@type table<string, boolean>
    if type(list.items) == "table" then
      for i = 1, #list.items do
        local it = list.items[i]
        local v = (type(it) == "table") and it.value or it
        if type(v) == "string" then
          have[normkey(v)] = true
        end
      end
    end

    local targets = resolve_targets()
    local added = false
    for i = 1, #targets do
      local p = targets[i]
      if p ~= "" and is_file(p) then
        local k = normkey(p, { realpath = true })
        if not have[k] then
          add_with_context(list, p)
          have[k] = true
          added = true
        end
      end
    end

    -- Final dedup in case of races or overlaps
    local removed = (sani.dedup_in_place_safe(list) or 0) > 0

    local changed = added or removed
    if changed then
      save_bucket(harpoon, list)
    end
    return changed
  end)

  if not ok then
    notify.error("[harpoon] persistpaths: inject_now failed: " .. tostring(result))
    return false
  end
  return result
end

---Hard reset: clear the PINS_KEY bucket and rebuild it from target_specs, in
---that exact order. Anything the user added beyond target_specs is lost --
---this is the explicit "give me the defaults back" command.
---@return boolean ok
function M.set_defaults()
  local ok, result = with_pins_key(function(harpoon, list)
    for i = #list.items, 1, -1 do
      if list.items[i] ~= nil then
        list:remove_at(i)
      end
    end

    local targets = resolve_targets()
    for i = 1, #targets do
      local p = targets[i]
      if p ~= "" and is_file(p) then
        add_with_context(list, p)
      end
    end

    save_bucket(harpoon, list)
    return true
  end)

  if not ok then
    notify.error("[harpoon] persistpaths: set_defaults failed: " .. tostring(result))
    return false
  end
  return true
end

--------------------------------------------------------------------------------
-- Pin / unpin (runtime-added defaults)
--------------------------------------------------------------------------------

---Resolve a user-supplied path arg (may be "" → current buffer) to a canonical
---absolute path, or nil if it is not an existing file.
---@param path string|nil
---@return string|nil abs, string|nil err
local function resolve_pin_arg(path)
  if type(path) ~= "string" or path == "" then
    path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      return nil, "no file path given and current buffer has no name"
    end
  end
  local abs = canon(vim.fs.normalize(vim.fn.fnamemodify(path, ":p")))
  if not is_file(abs) then
    return nil, "not an existing file: " .. abs
  end
  return abs, nil
end

---Add a path to the machine-local default pins (persisted) and inject it into
---the live list now. Defaults to the current buffer when path is nil/empty.
---@param path string|nil
---@return boolean ok
function M.pin(path)
  local abs, err = resolve_pin_arg(path)
  if not abs then
    notify.warn("[harpoon] pin: " .. tostring(err))
    return false
  end

  local pins = load_user_pins()
  local key = normkey(abs, { realpath = true })
  local already = false
  for _, p in ipairs(pins) do
    if normkey(canon(p), { realpath = true }) == key then
      already = true
      break
    end
  end

  if not already then
    pins[#pins + 1] = abs
    if not save_user_pins(pins) then
      return false
    end
  end

  -- Make it show up immediately (appended if missing). inject_now also tops up
  -- any other missing default, which is the intended "defaults present" state.
  M.inject_now()
  notify.info(string.format("[harpoon] %s: %s", already and "already pinned" or "pinned", abs))
  return true
end

---Remove a path from the machine-local default pins. Leaves the entry in the
---live list (it just stops being a protected default); delete it in the quick
---menu if you also want it gone. Defaults to the current buffer.
---@param path string|nil
---@return boolean ok
function M.unpin(path)
  local abs, err = resolve_pin_arg(path)
  if not abs then
    -- Allow unpinning a path that no longer exists on disk: fall back to the
    -- raw argument so a stale pin can still be cleared.
    abs = (type(path) == "string" and path ~= "") and canon(vim.fs.normalize(vim.fn.fnamemodify(path, ":p")))
      or nil
    if not abs then
      notify.warn("[harpoon] unpin: " .. tostring(err))
      return false
    end
  end

  local key = normkey(abs, { realpath = true })
  local pins = load_user_pins()
  local kept = {} ---@type string[]
  local removed = false
  for _, p in ipairs(pins) do
    if normkey(canon(p), { realpath = true }) == key then
      removed = true
    else
      kept[#kept + 1] = p
    end
  end

  if not removed then
    notify.info("[harpoon] not a user pin (nothing to unpin): " .. abs)
    return false
  end

  if not save_user_pins(kept) then
    return false
  end
  notify.info("[harpoon] unpinned: " .. abs)
  return true
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---True the very first time this runs on a machine; false on every later start,
---no matter what the user has since done to the PINS_KEY bucket's contents.
---@return boolean
local function is_first_run()
  return uv.fs_stat(INIT_MARKER) == nil
end

---@return nil
local function mark_initialized()
  local dir = vim.fn.stdpath("state")
  if uv.fs_stat(dir) == nil then
    vim.fn.mkdir(dir, "p")
  end
  local fd = uv.fs_open(INIT_MARKER, "w", 420) -- 0644
  if fd then
    uv.fs_close(fd)
  end
end

---@param opts Cfg.Harpoon.PersistPathsOpts|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  if opts.target_specs and type(opts.target_specs) == "table" then
    M.target_specs = opts.target_specs
  end

  -- Seed the defaults exactly once ever (first use on this machine). Every
  -- later start leaves the bucket exactly as the user last left it -- use
  -- the two commands below to top up or hard-reset on demand.
  if is_first_run() then
    local grp = Autocmd.group("HarpoonPersistPaths", true)
    Autocmd.create("VimEnter", function()
      vim.schedule(function()
        M.inject_now()
        mark_initialized()
      end)
    end, {
      group = grp,
      once = true,
    })
  end

  usercmd.create("HarpoonPersistPaths", function()
    local changed = M.inject_now()
    notify.info(string.format("[harpoon] persistpaths: %s", changed and "changed" or "no change"))
  end, { desc = "Add any missing default Harpoon paths (appended, existing entries untouched)" })

  usercmd.create("HarpoonSetDefaultPaths", function()
    if M.set_defaults() then
      notify.info("[harpoon] persistpaths: reset to defaults")
    end
  end, { desc = "Reset the Harpoon default-paths bucket to exactly target_specs" })

  usercmd.create("HarpoonPin", function(cmd)
    M.pin(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = "file",
    desc = "Pin a file as a persistent Harpoon default (defaults to current buffer)",
  })

  usercmd.create("HarpoonUnpin", function(cmd)
    M.unpin(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    complete = "file",
    desc = "Remove a file from the persistent Harpoon defaults (defaults to current buffer)",
  })
end

return M
