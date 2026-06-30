---@module 'config.neotree.open_filemanager.unix_ubuntu'
--- Open current Neo-tree node in the system file manager with selection support.
--- FIXED: Uses node_utils.get_current() for consistent node retrieval

local notify = require("lib.nvim.notify").create("[config.neotree.open.filemanager.unix_ubutnu]")

local M = {}

local node_utils = require("config.neotree.utils.node")

-- Small FS helpers -------------------------------------------------------------

---@private
---@param p string
---@return string
local function to_abs_unixpath(p)
  -- Expand to absolute path and strip surrounding quotes
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  return p
end

---@private
---@param p string
---@return boolean is_dir, boolean is_file
local function stat_kind(p)
  local uv = vim.uv or vim.loop
  local st = uv.fs_stat(p)
  if not st then
    return false, false
  end
  return st.type == "directory", st.type == "file"
end

-- Linux DBus (org.freedesktop.FileManager1) -----------------------------------

---@private
---@return boolean
local function has_dbus_session()
  return (vim.fn.getenv("DBUS_SESSION_BUS_ADDRESS") or "") ~= ""
end

---@private
---@param path string -- absolute file path
---@param on_fail fun()
local function try_dbus_showitems(path, on_fail)
  -- Build a dbus-send call:
  -- org.freedesktop.FileManager1.ShowItems (array of URIs) and a startup_id (empty)
  -- file:/// escaping: use vim.fn.fnameescape only for shell, not URI; simple gsub below.
  local uri = "file://" .. path:gsub(" ", "%%20")
  local argv = {
    "dbus-send",
    "--session",
    "--dest=org.freedesktop.FileManager1",
    "--type=method_call",
    "/org/freedesktop/FileManager1",
    "org.freedesktop.FileManager1.ShowItems",
    string.format("array:string:%s", uri),
    "string:",
  }

  if vim.fn.executable("dbus-send") ~= 1 or not has_dbus_session() then
    return on_fail()
  end

  if vim.system then
    vim.system(argv, { text = true }, function(obj)
      if obj.code ~= 0 then
        on_fail()
      end
    end)
  else
    local ok = vim.fn.jobstart(argv, { detach = true })
    if ok <= 0 then
      on_fail()
    end
  end
end

-- Manager-specific fallback on Linux ------------------------------------------

---@private
---@return string[]|nil -- argv or nil
local function manager_select_cmd(path)
  -- Ordered by common desktops; pick first available.
  local candidates = {
    { "nautilus", "--select", path },
    { "nemo", "--select", path },
    { "dolphin", "--select", path },
    { "thunar", "--select", path },
    { "pcmanfm", path }, -- no --select; opens the file (may open editor); we will adjust below.
  }
  for _, cmd in ipairs(candidates) do
    if vim.fn.executable(cmd[1]) == 1 then
      -- pcmanfm has no --select; open the directory instead
      if cmd[1] == "pcmanfm" then
        local dir = vim.fn.fnamemodify(path, ":p:h")
        return { "pcmanfm", dir }
      end
      return cmd
    end
  end
  return nil
end

---@private
---@param argv string[]
---@param on_fail fun()
local function run_detached(argv, on_fail)
  if vim.system then
    vim.system(argv, { text = true }, function(obj)
      if obj.code ~= 0 then
        on_fail()
      end
    end)
  else
    local ok = vim.fn.jobstart(argv, { detach = true })
    if ok <= 0 then
      on_fail()
    end
  end
end

-- Public API -------------------------------------------------------------------

--- Open the selected node in the system file manager (Linux/macOS).
--- FIXED: Now uses node_utils.get_current() instead of state.current_node
---@param state Cfg.NeoTree.State
---@return boolean ok
function M.open(state)
  -- FIXED: Use node_utils.get_current() for consistent node retrieval
  local node = node_utils.get_current(state)
  if not node then
    notify.warn("Open in File Manager: no node under cursor")
    return false
  end

  local raw, _ = node_utils.get_path(node)
  if raw == "" then
    notify.warn("Open in File Manager: no path under cursor")
    return false
  end

  -- Pfad in absolute Unix-Form konvertieren
  local abs = to_abs_unixpath(raw)
  local _, is_file = stat_kind(abs)

  -- macOS branch: Finder reveal or open
  if vim.fn.has("mac") == 1 then
    local argv = is_file and { "open", "-R", abs } or { "open", abs }
    return run_detached(argv, function()
      notify.error("Open in Finder failed")
    end) or true
  end

  -- Linux/Unix branch
  if vim.fn.has("unix") == 1 then
    if is_file then
      -- Try DBus ShowItems (select the file in the file manager)
      local tried_manager = false
      try_dbus_showitems(abs, function()
        -- Manager-specific --select
        local sel = manager_select_cmd(abs)
        if sel then
          tried_manager = true
          run_detached(sel, function()
            notify.error("Open in File Manager failed (manager fallback)")
          end)
        end
      end)
      if tried_manager then
        return true
      end
      -- Final fallback: open containing directory via gio/xdg-open
      local dir = vim.fn.fnamemodify(abs, ":p:h")
      local argv = vim.fn.executable("gio") == 1 and { "gio", "open", dir } or { "xdg-open", dir }
      run_detached(argv, function()
        notify.error("Open in File Manager failed (dir fallback)")
      end)
      return true
    else
      -- Directory: open directly with gio/xdg-open
      local argv = vim.fn.executable("gio") == 1 and { "gio", "open", abs } or { "xdg-open", abs }
      run_detached(argv, function()
        notify.error("Open in File Manager failed")
      end)
      return true
    end
  end

  notify.warn("Open in File Manager: unsupported OS")
  return false
end

return M
