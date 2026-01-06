---@module 'usrcmds.search_all_drives'
--- Build Telescope tabs for cross-drive searches (grep + files).
--- Design:
---   • Drive/mount discovery with caching.
---   • POSIX, Windows, WSL supported.
---   • Grep-Tabs via ripgrep; Files-Tab via a robust, imported finder argv.
---   • No global side effects; UI concerns (vim.notify) only in tele_func.

local notify = require("lib.notify").create("[usrcmds.search_all_drives] ")

---@type SearchMounts
local Mounts = { cache = nil }

---@param s string|nil
---@return string
local function trim(s)
  local r = (s or ""):gsub("^%s+", "")
  r = r:gsub("%s+$", "")
  return r
end

local function is_wsl()
  if vim.env.WSLENV ~= nil then
    return true
  end
  if vim.fn.filereadable("/proc/version") == 1 then
    local l = (vim.fn.readfile("/proc/version")[1] or ""):lower()
    if l:find("microsoft", 1, true) then
      return true
    end
  end
  return false
end

local function os_name()
  local u = vim.loop.os_uname()
  return u and (u.sysname or "") or ""
end

-- Windows: return roots like "C:\", "D:\" … (keep backslashes for `dir`)
---@return string[]
local function windows_roots()
  local roots = {}

  local ps = io.popen(
    [[powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select -ExpandProperty Root"]]
  )
  if ps then
    for line in ps:lines() do
      local r = trim(line):gsub("\\+$", "\\")
      if r ~= "" and vim.fn.isdirectory(r) == 1 then
        table.insert(roots, r)
      end
    end
    ps:close()
  end

  if #roots == 0 then
    for byte = string.byte("A"), string.byte("Z") do
      local d = string.char(byte) .. ":\\"
      if vim.fn.isdirectory(d) == 1 then
        table.insert(roots, d)
      end
    end
  end

  return roots
end

-- POSIX/WSL
---@return string[]
local function posix_roots()
  local dirs = {}
  if is_wsl() then
    for letter in ("cdefghijklmnopqrstuvwxyz"):gmatch(".") do
      local p = "/mnt/" .. letter
      if vim.fn.isdirectory(p) == 1 then
        table.insert(dirs, p)
      end
    end
  else
    local handle = io.popen("df -P --output=target 2>/dev/null | tail -n +2")
    if handle then
      for line in handle:lines() do
        local p = trim(line)
        if p ~= "" and vim.fn.isdirectory(p) == 1 then
          table.insert(dirs, p)
        end
      end
      handle:close()
    end
    if #dirs == 0 then
      for _, p in ipairs({ "/", "/Volumes", "/media", "/mnt" }) do
        if vim.fn.isdirectory(p) == 1 then
          table.insert(dirs, p)
        end
      end
    end
  end
  return dirs
end

---@return string[]
function Mounts.get_all()
  if Mounts.cache then
    return Mounts.cache
  end
  local sys = os_name()
  local roots = sys:find("Windows", 1, true) and windows_roots() or posix_roots()

  local seen, uniq = {}, {}
  for _, p in ipairs(roots) do
    if not seen[p] then
      seen[p] = true
      table.insert(uniq, p)
    end
  end
  Mounts.cache = uniq
  return Mounts.cache
end

local M = {}

---@param builtin table
---@return table[]
function M.build_tabs(builtin)
  local findchooser = require("usrcmds.search_all_drives.select_find_command")

  local function all_roots()
    local dirs = Mounts.get_all()
    if #dirs == 0 then
      notify.warn("No drives/mount points found.")
      return nil
    end
    return dirs
  end

  local common_excludes = {
    "-g",
    "!.git/",
    "-g",
    "!node_modules/",
    "-g",
    "!dist/",
    ("-g"),
    "!build/",
    "-g",
    "!target/",
    "-g",
    "!vendor/",
    "-g",
    "!.cache/",
  }

  return {
    {
      name = "All Drives Files",
      tele_func = function()
        local dirs = all_roots()
        if not dirs then
          return
        end

        local ok, argv, err = findchooser.choose_find_command({
          include_hidden = true,
          follow_symlinks = true,
          exclude_vcs = true,
        })
        if not ok or not argv then
          notify.error(err or "No suitable file-lister found.")
          return
        end

        local cmd = vim.deepcopy(argv)
        for i = 1, #dirs do
          cmd[#cmd + 1] = dirs[i]
        end

        builtin.find_files({
          find_command = cmd,
          hidden = true,
          no_ignore = true,
        })
      end,
    },

    {
      name = "All Drives Grep (regex)",
      tele_func = function()
        local dirs = all_roots()
        if not dirs then
          return
        end
        if vim.fn.executable("rg") ~= 1 then
          notify.error("'ripgrep' (rg) not found in PATH. Install it to use live_grep.")
          return
        end
        builtin.live_grep({
          search_dirs = dirs,
          additional_args = function()
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-S" }, common_excludes)
          end,
        })
      end,
    },

    {
      name = "All Drives Grep (literal)",
      tele_func = function()
        local dirs = all_roots()
        if not dirs then
          return
        end
        if vim.fn.executable("rg") ~= 1 then
          notify.error("'ripgrep' (rg) not found in PATH. Install it to use live_grep.")
          return
        end
        builtin.live_grep({
          search_dirs = dirs,
          additional_args = function()
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-F", "-S" }, common_excludes)
          end,
        })
      end,
    },

    {
      name = "All Drives Grep (word)",
      tele_func = function()
        local dirs = all_roots()
        if not dirs then
          return
        end
        if vim.fn.executable("rg") ~= 1 then
          notify.error("'ripgrep' (rg) not found in PATH. Install it to use live_grep.")
          return
        end
        builtin.live_grep({
          search_dirs = dirs,
          additional_args = function()
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-w", "-S" }, common_excludes)
          end,
        })
      end,
    },
  }
end

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("AllDrives", function()
    require("usrcmds.search_all_drives.telescope").open()
  end, { desc = "[usrcmds.search_all_drives] Search files and grep across all drives" })

  vim.api.nvim_create_user_command("AllDrivesFzf", function()
    require("usrcmds.search_all_drives.fzf").open()
  end, { desc = "[usrcmds.search_all_drives] Search files and grep across all drives (fzf-lua)" })
end

return M
