---@module 'utils.search_all_drives'
---@version 1.2

---@class SearchMounts
---@field cache string[]|nil
local Mounts = { cache = nil }

---@param s string|nil
---@return string
local function trim(s)
  -- gsub returns (new_string, count); the assignment keeps only the first value.
  local r = (s or ""):gsub("^%s+", "")
  r = r:gsub("%s+$", "")
  return r
end


local function is_wsl()
  if vim.env.WSLENV ~= nil then return true end
  if vim.fn.filereadable("/proc/version") == 1 then
    local l = (vim.fn.readfile("/proc/version")[1] or ""):lower()
    if l:find("microsoft", 1, true) then return true end
  end
  return false
end

local function os_name()
  local u = vim.loop.os_uname()
  return u and (u.sysname or "") or ""
end

-- Windows: gib Wurzeln als "C:\", "D:\" … zurück (Backslashes beibehalten!)
---@return string[]
local function windows_roots()
  local roots = {}

  local ps = io.popen([[powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select -ExpandProperty Root"]])
  if ps then
    for line in ps:lines() do
      local r = trim(line):gsub("\\+$", "\\")
      if r ~= "" and vim.fn.isdirectory(r) == 1 then
        table.insert(roots, r) -- wichtig: Backslashes behalten für 'dir'
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

-- POSIX/WSL wie gehabt
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
  if Mounts.cache then return Mounts.cache end
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

-- Wähle ein robustes find_command:
-- - Windows: nutze 'cmd.exe /c dir /s /b /a:-d' (liefert Dateien zeilenweise)
-- - Sonst: fd bevorzugen, sonst rg --files
---@return string[]|nil
local function choose_find_command()
  local sys = os_name()
  if sys:find("Windows", 1, true) then
    return { "cmd.exe", "/c", "dir", "/s", "/b", "/a:-d" }
  end
  if vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git" }
  end
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--files", "--hidden", "--no-ignore-vcs", "--color", "never" }
  end
  return nil
end



-- In utils/search_all_drives.lua ergänzen/ändern
---@param builtin table
---@return table[]
function M.build_tabs(builtin)
  local function all_roots()
    local dirs = Mounts.get_all()
    if #dirs == 0 then
      vim.notify("No drives/mount points found.", vim.log.levels.WARN)
      return nil
    end
    return dirs
  end

  local common_excludes = {
    "-g", "!.git/",
    "-g", "!node_modules/",
    "-g", "!dist/",
    "-g", "!build/",
    "-g", "!target/",
    "-g", "!vendor/",
    "-g", "!.cache/",
  }

  return {

    -- Regex (wie bisher)
    {
      name = "All Drives Grep (regex)",
      tele_func = function()
        local dirs = all_roots(); if not dirs then return end
        if vim.fn.executable("rg") ~= 1 then
          vim.notify("'ripgrep' (rg) not found in PATH. Install it to use live_grep.", vim.log.levels.ERROR)
          return
        end
        builtin.live_grep({
          search_dirs     = dirs,
          additional_args = function()
            -- Regex + smart-case + hidden + no-ignore + Excludes
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-S" }, common_excludes)
          end,
        })
      end,
    },

    -- Literal-Matches (kein Regex): ideal für einfache Begriffe wie 'install'
    {
      name = "All Drives Grep (literal)",
      tele_func = function()
        local dirs = all_roots(); if not dirs then return end
        if vim.fn.executable("rg") ~= 1 then
          vim.notify("'ripgrep' (rg) not found in PATH. Install it to use live_grep.", vim.log.levels.ERROR)
          return
        end
        builtin.live_grep({
          search_dirs     = dirs,
          additional_args = function()
            -- -F = fixed strings, -S = smart-case
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-F", "-S" }, common_excludes)
          end,
        })
      end,
    },

    -- Ganze Wörter (z. B. nur 'install' als Wort, nicht 'reinstalling')
    {
      name = "All Drives Grep (word)",
      tele_func = function()
        local dirs = all_roots(); if not dirs then return end
        if vim.fn.executable("rg") ~= 1 then
          vim.notify("'ripgrep' (rg) not found in PATH. Install it to use live_grep.", vim.log.levels.ERROR)
          return
        end
        builtin.live_grep({
          search_dirs     = dirs,
          additional_args = function()
            -- -w = word, -S = smart-case
            return vim.list_extend({ "--hidden", "--no-ignore-vcs", "-w", "-S" }, common_excludes)
          end,
        })
      end,
    },
  }
end

return M

