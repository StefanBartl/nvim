---@module 'config.neotree.trash'
--- Neo-tree integration: move selected file/folder to system Trash and refresh neo-tree view.
--- Provides send_to_trash(path) and neotree_send_node_to_trash(state) exported functions.

local M = {}

local uv = vim.loop

--- Escape shell argument in a platform-appropriate way.
---@param path string
---@return string
local function escape_shell_arg(path)
  -- English comment: escape path for shell commands. For Windows we use single-quoted PowerShell arg,
  -- for POSIX we escape single quotes using the standard trick.
  if uv.os_uname().sysname == "Windows_NT" then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

--- Send given file/directory path to system Trash using available backend.
--- Tries gio, trash, trash-put, kioclient5, macOS osascript, Windows PowerShell, then local ~/.local/share/Trash/files fallback.
---@param path string
---@return boolean, string
local function send_to_trash(path)
  -- English comment: detect platform and available trash utility, then invoke it.
  -- This implementation uses a single exit point (ok, msg) to avoid unreachable-code diagnostics.
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
      if vim.v.shell_error == 0 then
        ok, msg = true, out
      else
        ok, msg = false, out
      end
    elseif has_exe("trash") then
      local out = vim.fn.system({ "trash", path })
      if vim.v.shell_error == 0 then
        ok, msg = true, out
      else
        ok, msg = false, out
      end
    elseif has_exe("trash-put") then
      local out = vim.fn.system({ "trash-put", path })
      if vim.v.shell_error == 0 then
        ok, msg = true, out
      else
        ok, msg = false, out
      end
    elseif has_exe("kioclient5") then
      local out = vim.fn.system({ "kioclient5", "move", path, "trash:/" })
      if vim.v.shell_error == 0 then
        ok, msg = true, out
      else
        ok, msg = false, out
      end
    elseif sys == "Darwin" and has_exe("osascript") then
      local applescript = string.format('tell application "Finder" to delete POSIX file %s', esc)
      local out = vim.fn.system({ "osascript", "-e", applescript })
      if vim.v.shell_error == 0 then
        ok, msg = true, out
      else
        ok, msg = false, out
      end
    else
      -- Fallback: move to ~/.local/share/Trash/files (best-effort)
      local home = uv.os_homedir()
      local trashdir = home .. "/.local/share/Trash/files"
      if not uv.fs_stat(trashdir) then
        local okc, errc = pcall(function() vim.fn.mkdir(trashdir, "p") end)
        if not okc then
          ok, msg = false, "failed to create trash dir: " .. tostring(errc)
        end
      end
      if ok == false and msg:match("^failed to create") then
        -- keep the error from mkdir
      else
        local dest = trashdir .. "/" .. vim.fn.fnamemodify(path, ":t")
        local ok_mv, err_mv = os.rename(path, dest)
        if ok_mv then
          ok, msg = true, "moved to " .. dest
        else
          ok, msg = false, tostring(err_mv)
        end
      end
    end
  else
    -- Windows: use PowerShell + Microsoft.VisualBasic.FileIO to send to Recycle Bin
    local ps_script = string.format(
      "Add-Type -AssemblyName Microsoft.VisualBasic; " ..
      "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(%s,'OnlyErrorDialogs','SendToRecycleBin')",
      esc
    )
    local stat = uv.fs_stat(path)
    if stat and stat.type == "directory" then
      ps_script = string.format(
        "Add-Type -AssemblyName Microsoft.VisualBasic; " ..
        "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(%s,'OnlyErrorDialogs','SendToRecycleBin')",
        esc
      )
    end
    local out = vim.fn.system({ "powershell", "-NoProfile", "-Command", ps_script })
    if vim.v.shell_error == 0 then
      ok, msg = true, out
    else
      ok, msg = false, out
    end
  end

  return ok, msg
end

--- Neo-tree mapping callback: move selected node to Trash and refresh the Neo-tree view.
--- Uses the neo-tree commands refresh API: require("neo-tree.sources.filesystem.commands").refresh(state)
---@param state table
---@return nil
local function neotree_send_node_to_trash(state)
  -- English comment: node retrieval for neo-tree state object
  local node = state.tree and state.tree:get_node() or nil
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
    -- Correct refresh call: obtain the proper state object for the filesystem source
    -- and call the commands.refresh(state) provided by neo-tree.
    local manager = require("neo-tree.sources.manager")
    local fs_state = manager.get_state(state.name) or manager.get_state("filesystem")
    if fs_state then
      -- call the filesystem commands refresh function
      local fs_commands = require("neo-tree.sources.filesystem.commands")
      if type(fs_commands.refresh) == "function" then
        fs_commands.refresh(fs_state)
      else
        -- fallback: try manager-level refresh if present
        if type(manager.refresh) == "function" then
          manager.refresh("filesystem")
        end
      end
    end
  else
    vim.notify("Failed to move to Trash: " .. tostring(msg), vim.log.levels.ERROR)
  end
end

-- Export functions. Make sure 'return' is at the very end so no unreachable-code diagnostics occur.
M.send_to_trash = send_to_trash
M.neotree_send_node_to_trash = neotree_send_node_to_trash

---@package
---@return NeoTreeTrash
return M
