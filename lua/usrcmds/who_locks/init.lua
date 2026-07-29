---@module 'usrcmds.who_locks'
---@brief Diagnose a Windows file lock (EBUSY/EPERM/EACCES) on any path.
---@description
--- Registers `:WhoLocks [path]`. Run it right after a file op failed with
--- `EBUSY: resource busy or locked` — it measures rather than guesses:
---
---   1. A live `uv.fs_rename` probe, so "is it locked *now*" is fact.
---   2. The processes holding the file, via the Windows Restart Manager.
---   3. Neo-tree's own `fs_event` watchers covering the file's folder.
---
--- (1) and (2) live in `lib.nvim.cross.fs.lock`, shared with fileops.nvim's
--- `:File lockinfo` and filetree.nvim. What this command adds is (3) and the fact
--- that it works on *any* path, with no buffer needed — which is what makes
--- it useful outside a plugin: it distinguishes a foreign holder from a
--- handle leaked inside this very Neovim, the one case no retry can outwait.
---
--- An open buffer is never the cause: Neovim closes a file after reading it
--- and keeps only its swap file open.

local notify = require("lib.nvim.notify").create("[usrcmds.who_locks]")
local usercmd = require("lib.nvim.usercmd")

local M = {}

local fn = vim.fn

---Reach neo-tree's watcher registry. The table is a module local, so it is
---only observable as an upvalue of the accessor neo-tree exposes.
---@return table<string, any>|nil
local function neotree_watchers()
  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok or type(fs_watch.show_watched) ~= "function" then return nil end
  for i = 1, math.huge do
    local name, value = debug.getupvalue(fs_watch.show_watched, i)
    if not name then break end
    if name == "watchers" and type(value) == "table" then return value end
  end
  return nil
end

---Which neo-tree watchers cover this file's folder — the local suspect the
---Restart Manager would only ever report as "nvim".
---@param path string
---@return string[]
local function watcher_lines(path)
  if not package.loaded["neo-tree"] then
    return { "  neo-tree not loaded — cannot be the holder in this session" }
  end
  local watchers = neotree_watchers()
  if not watchers then
    return { "  neo-tree loaded, but its watcher table is not reachable (internals changed?)" }
  end

  local dir = fn.fnamemodify(path, ":p:h"):gsub("\\", "/"):lower()
  local lines, total, matching = {}, 0, 0
  for watched, w in pairs(watchers) do
    total = total + 1
    local norm = tostring(watched):gsub("\\", "/"):lower():gsub("/$", "")
    if norm == dir then
      matching = matching + 1
      lines[#lines + 1] = ("  WATCHES THIS FOLDER: %s (references=%s, active=%s, handle=%s)")
        :format(watched, tostring(w and w.references), tostring(w and w.active),
          (w and w.handle) and "open" or "nil")
    end
  end
  table.insert(lines, 1, ("  %d watched folder(s) total, %d covering this file's folder")
    :format(total, matching))
  return lines
end

---Register :WhoLocks.
function M.enable()
  usercmd.create("WhoLocks", function(args)
    local path = args.args ~= "" and fn.fnamemodify(fn.expand(args.args), ":p")
      or fn.expand("%:p")
    if path == "" then
      notify.warn("no file: pass a path or run this from a buffer with a file name")
      return
    end

    local ok_lock, lock = pcall(require, "lib.nvim.cross.fs.lock")
    if not ok_lock then
      notify.error("lib.nvim.cross.fs.lock unavailable — update lib.nvim")
      return
    end

    local bufnr = fn.bufnr(path)
    lock.report(path, function(lines)
      table.insert(lines, 2, "cwd:    " .. fn.getcwd())
      table.insert(lines, 3, "buffer: " .. (bufnr ~= -1
        and ("#%d, modified=%s"):format(bufnr, tostring(vim.bo[bufnr].modified))
        or "not open in any buffer"))
      lines[#lines + 1] = ""
      lines[#lines + 1] = "neo-tree fs_event watchers:"
      vim.list_extend(lines, watcher_lines(path))

      local text = table.concat(lines, "\n")
      notify.info(text)
      -- Also to :messages, so the block survives the notification timeout
      -- and can be yanked out for a bug report.
      print(text)
    end)
  end, {
    desc = "[usrcmds.who_locks] Diagnose who is holding a file open (Windows EBUSY/EPERM)",
    nargs = "?",
    complete = "file",
  })
end

return M
