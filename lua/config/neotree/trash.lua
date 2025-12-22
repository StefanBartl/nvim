---@module 'config.neotree.trash'
--- Neo-tree integration: move selected file/folder to system Trash and refresh neo-tree view.
--- Provides send_to_trash(path) and neotree_send_node_to_trash(state) exported functions.

local M = {}

local uv = vim.loop

--- Escape shell argument in a platform-appropriate way.
---@param path string
---@return string
local function escape_shell_arg(path)
  if uv.os_uname().sysname == "Windows_NT" then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

--- Send given file/directory path to system Trash using available backend.
---@param path string
---@return boolean, string
local function send_to_trash(path)
  local sys = uv.os_uname().sysname
  local esc = escape_shell_arg(path)

  local function has_exe(name)
    return vim.fn.executable(name) == 1
  end

  local ok = false
  local msg = "no supported trash command found"

  if sys ~= "Windows_NT" then
    if has_exe("gio") then
      local out = vim.fn.system({ "gio", "trash", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("trash") then
      local out = vim.fn.system({ "trash", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("trash-put") then
      local out = vim.fn.system({ "trash-put", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("kioclient5") then
      local out = vim.fn.system({ "kioclient5", "move", path, "trash:/" })
      ok, msg = vim.v.shell_error == 0, out
    elseif sys == "Darwin" and has_exe("osascript") then
      local applescript = string.format('tell application "Finder" to delete POSIX file %s', esc)
      local out = vim.fn.system({ "osascript", "-e", applescript })
      ok, msg = vim.v.shell_error == 0, out
    else
      local home = uv.os_homedir()
      local trashdir = home .. "/.local/share/Trash/files"
      if not uv.fs_stat(trashdir) then
        local okc, errc = pcall(vim.fn.mkdir, trashdir, "p")
        if not okc then
          return false, "failed to create trash dir: " .. tostring(errc)
        end
      end
      local dest = trashdir .. "/" .. vim.fn.fnamemodify(path, ":t")
      local ok_mv, err_mv = os.rename(path, dest)
      ok, msg = ok_mv, ok_mv and ("moved to " .. dest) or tostring(err_mv)
    end
  else
    local ps_script = string.format(
      "Add-Type -AssemblyName Microsoft.VisualBasic; "
        .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(%s,'OnlyErrorDialogs','SendToRecycleBin')",
      esc
    )
    local stat = uv.fs_stat(path)
    if stat and stat.type == "directory" then
      ps_script = string.format(
        "Add-Type -AssemblyName Microsoft.VisualBasic; "
          .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(%s,'OnlyErrorDialogs','SendToRecycleBin')",
        esc
      )
    end
    local out = vim.fn.system({ "powershell", "-NoProfile", "-Command", ps_script })
    ok, msg = vim.v.shell_error == 0, out
  end

  return ok, msg
end

--- Neo-tree mapping callback: move selected node to Trash and refresh the Neo-tree view.
---@param state table
---@return nil
local function neotree_send_node_to_trash(state)
  local node = state.tree and state.tree:get_node()
  if not node then
    vim.notify("No node under cursor", vim.log.levels.WARN)
    return
  end

  local path = node.path or node.uri or node:get_id()
  if not path then
    vim.notify("Node has no path", vim.log.levels.ERROR)
    return
  end

  local prompt = string.format("Move to Trash: %s ? (y/N) ", path)
  local ans = vim.fn.input(prompt)
  if not (ans == "y" or ans == "Y") then
    vim.notify("Cancelled", vim.log.levels.INFO)
    return
  end

  local ok, msg = send_to_trash(path)

  if ok then
    vim.notify("Moved to Trash: " .. path, vim.log.levels.INFO)

    -- safe refresh
    local manager = require("neo-tree.sources.manager")
    local success, fs_state = pcall(manager.get_state, state.name)

    -- ensure fs_state is always a valid table of type neotree.State
    if not success or type(fs_state) ~= "table" then
      local ok2, fs_state2 = pcall(manager.get_state, "filesystem")
      if ok2 and type(fs_state2) == "table" then
        fs_state = fs_state2
      else
        -- fallback: minimaler, leerer State, damit Typ passt
        ---@diagnostic disable-next-line: missing-fields
        fs_state = { tree = { refresh = function() end }, name = "filesystem" }
      end
    end

    -- if not success or type(fs_state) ~= "table" then
    --   local ok2, fs_state2 = pcall(manager.get_state, "filesystem")
    --   fs_state = ok2 and type(fs_state2) == "table" and fs_state2 or nil
    -- end
    --
    -- if fs_state then
    --   local fs_commands = require("neo-tree.sources.filesystem.commands")
    --   if type(fs_commands.refresh) == "function" then
    --     pcall(fs_commands.refresh, fs_state)
    --   else
    --     pcall(manager.refresh, "filesystem")
    --   end
    -- end

    else
    vim.notify("Failed to move to Trash: " .. tostring(msg), vim.log.levels.ERROR)
  end
end

M.send_to_trash = send_to_trash
M.neotree_send_node_to_trash = neotree_send_node_to_trash

---@package
---@return NeoTreeTrash
return M
