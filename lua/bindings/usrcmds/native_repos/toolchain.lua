---@module 'bindings.usrcmds.native_repos.toolchain'
---@brief The tools the native apps build with, checked and (where no administrator rights are needed) installed.
---@description
--- Each app names its tools in `plugins.personal.core.natives` (`needs`). A tool has a check (is it usable here)
--- and either an install command that runs for the current user (rustup through winget, tauri-cli through cargo,
--- the MinGW-w64 packages through MSYS2's pacman) or only a hint, when installing needs an administrator
--- (Node.js, CMake, the MSVC build tools, MSYS2 itself). The list is in dependency order: rust before tauri-cli.
--- Windows only, like the build scripts; the table of what is expected where is docs/NOTES/builds/toolchain.md.

local M = {}

local uv = vim.uv or vim.loop

---@return string
function M.msys2_root()
  local root = vim.env.MSYS2_ROOT
  if not root or root == "" then
    root = "C:/msys64"
  end
  return (root:gsub("\\", "/"):gsub("/+$", ""))
end

---@param path string
---@return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

---Runs a short probe; a program that cannot start or hangs (30 s) counts as a failure, never as an error.
---@param argv string[]
---@return boolean ok, string stdout
local function runs(argv)
  local ok, res = pcall(function()
    return vim.system(argv, { text = true }):wait(30000)
  end)
  if not ok or res.code ~= 0 then
    return false, ""
  end
  return true, res.stdout or ""
end

---Whether `dir` is an entry of $PATH (Windows: case and slashes do not count).
---@param dir string
---@return boolean
local function on_path(dir)
  local function norm(p)
    return (p:gsub("/", "\\"):gsub("\\+$", ""):lower())
  end
  local want = norm(dir)
  for entry in (vim.env.PATH or ""):gmatch("[^;]+") do
    if norm(entry) == want then
      return true
    end
  end
  return false
end

---@return string
local function vswhere()
  local base = vim.env["ProgramFiles(x86)"] or "C:/Program Files (x86)"
  return base .. "/Microsoft Visual Studio/Installer/vswhere.exe"
end

-- MinGW-w64 of MSYS2: what ai-desktop's scripts/setup.ps1 checks for (g++, make, objdump, OpenSSL)
local mingw_files = {
  "mingw64/bin/g++.exe",
  "mingw64/bin/mingw32-make.exe",
  "mingw64/bin/objdump.exe",
  "mingw64/include/openssl/ssl.h",
  "mingw64/lib/libssl.dll.a",
}

---@class NativeRepos.Tool
---@field id string
---@field desc string
---@field check fun(): boolean
---@field install? fun(): string[]|nil argv that installs it for the current user (nil: not possible here)
---@field requires? string[] Tools its install needs (skipped while one of them is missing)
---@field path? fun(): string Folder to put in front of PATH after the install (new tools are not on it yet)
---@field hint string What to do by hand

---@type NativeRepos.Tool[]
M.list = {
  {
    id = "rust",
    desc = "Rust (rustup, cargo)",
    check = function()
      return vim.fn.executable("cargo") == 1
    end,
    install = function()
      return {
        "winget",
        "install",
        "-e",
        "--id",
        "Rustlang.Rustup",
        "--scope",
        "user",
        "--accept-source-agreements",
        "--accept-package-agreements",
      }
    end,
    path = function()
      return (vim.env.USERPROFILE or vim.env.HOME or "") .. "/.cargo/bin"
    end,
    hint = "winget install -e --id Rustlang.Rustup --scope user (or https://rustup.rs)",
  },
  {
    id = "msvc",
    desc = "MSVC build tools (the linker of Rust's msvc target)",
    check = function()
      local exe = vswhere()
      if not exists(exe) then
        return false
      end
      local ok, out = runs({
        exe,
        "-products",
        "*",
        "-requires",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-property",
        "installationPath",
      })
      return ok and vim.trim(out) ~= ""
    end,
    hint = "Visual Studio Build Tools with 'Desktop development with C++' (needs an administrator): "
      .. "winget install -e --id Microsoft.VisualStudio.2022.BuildTools",
  },
  {
    id = "node",
    desc = "Node.js with npm (pnpm comes through npx when it is missing)",
    check = function()
      return vim.fn.executable("npm") == 1
    end,
    hint = "winget install -e --id OpenJS.NodeJS.LTS (needs an administrator)",
  },
  {
    id = "tauri-cli",
    desc = "Tauri CLI 2 (cargo tauri)",
    check = function()
      return vim.fn.executable("cargo") == 1 and (runs({ "cargo", "tauri", "--version" }))
    end,
    requires = { "rust" },
    install = function()
      return { "cargo", "install", "tauri-cli", "--version", "^2", "--locked" }
    end,
    hint = "cargo install tauri-cli --version ^2 --locked",
  },
  {
    id = "cmake",
    desc = "CMake >= 3.20",
    check = function()
      return vim.fn.executable("cmake") == 1
        or exists((vim.env.ProgramFiles or "C:/Program Files") .. "/CMake/bin/cmake.exe")
    end,
    hint = "winget install -e --id Kitware.CMake (needs an administrator)",
  },
  {
    id = "mingw64",
    desc = "MinGW-w64 of MSYS2 with OpenSSL (g++, mingw32-make, objdump, OpenSSL)",
    check = function()
      local root = M.msys2_root()
      for _, file in ipairs(mingw_files) do
        if not exists(root .. "/" .. file) then
          return false
        end
      end
      return true
    end,
    install = function()
      local pacman = M.msys2_root() .. "/usr/bin/pacman.exe"
      if not exists(pacman) then
        return nil
      end
      return {
        pacman,
        "-S",
        "--needed",
        "--noconfirm",
        "mingw-w64-x86_64-gcc",
        "mingw-w64-x86_64-make",
        "mingw-w64-x86_64-openssl",
      }
    end,
    hint = "MSYS2 in $MSYS2_ROOT (default C:/msys64, https://www.msys2.org), then "
      .. "pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-openssl "
      .. "(a 404: pacman -Syu in an MSYS2 shell first)",
  },
}

---@param tools? NativeRepos.Tool[] Default `M.list`
---@return table<string, NativeRepos.Tool>
local function by_id(tools)
  local out = {}
  for _, tool in ipairs(tools or M.list) do
    out[tool.id] = tool
  end
  return out
end

---@param id string
---@return NativeRepos.Tool|nil
function M.get(id)
  return by_id()[id]
end

---The tools a set of apps needs, once each, in the order of `M.list`.
---@param natives Plugins.Personal.Native[]
---@return string[]
function M.needed(natives)
  local wanted = {}
  for _, native in ipairs(natives) do
    for _, id in ipairs(native.needs or {}) do
      wanted[id] = true
    end
  end
  local out = {}
  for _, tool in ipairs(M.list) do
    if wanted[tool.id] then
      out[#out + 1] = tool.id
    end
  end
  return out
end

---What an ensure run does with the missing tools: install the ones with a command, name the others.
---@param ids string[] Missing tool ids
---@param tools? NativeRepos.Tool[] Default `M.list`
---@return string[] install, string[] hints
function M.plan(ids, tools)
  local known = by_id(tools)
  local install, hints = {}, {}
  for _, id in ipairs(ids) do
    local tool = known[id]
    if tool and tool.install and tool.install() then
      install[#install + 1] = id
    else
      hints[#hints + 1] = ("%s: %s"):format(id, tool and tool.hint or "unknown tool")
    end
  end
  return install, hints
end

---The by-hand line of every tool in `ids`, also of one that has an install command (it ran and did not help).
---@param ids string[]
---@param tools? NativeRepos.Tool[] Default `M.list`
---@return string[]
function M.hints(ids, tools)
  local known = by_id(tools)
  return vim.tbl_map(function(id)
    return ("%s: %s"):format(id, known[id] and known[id].hint or "unknown tool")
  end, ids)
end

---The apps whose tools are all there, and a line for each one that is held back.
---@param natives Plugins.Personal.Native[]
---@param missing table<string, boolean>
---@return Plugins.Personal.Native[] ready, string[] held
function M.split(natives, missing)
  local ready, held = {}, {}
  for _, native in ipairs(natives) do
    local lacks = vim.tbl_filter(function(id)
      return missing[id]
    end, native.needs or {})
    if #lacks == 0 then
      ready[#ready + 1] = native
    else
      held[#held + 1] = ("%s: missing %s (:MyNative deps)"):format(
        native.name,
        table.concat(lacks, ", ")
      )
    end
  end
  return ready, held
end

---A check that throws counts as "missing": a broken probe must not stop the run that called it.
---@param ids string[]
---@param tools? NativeRepos.Tool[] Default `M.list`
---@return table<string, boolean> missing
function M.check(ids, tools)
  local known = by_id(tools)
  local missing = {}
  for _, id in ipairs(ids) do
    local tool = known[id]
    local ok, there = false, false
    if tool then
      ok, there = pcall(tool.check)
    end
    if not ok or not there then
      missing[id] = true
    end
  end
  return missing
end

---Checks the tools and installs the missing ones that can be installed, one after the other. Output lines go
---to `items` (quickfix entries). `on_done` gets what is still missing and the by-hand line of each of those.
---@param ids string[]
---@param items table[]
---@param on_done fun(missing: table<string, boolean>, hints: string[])
---@param tools? NativeRepos.Tool[] Default `M.list`
function M.ensure(ids, items, on_done, tools)
  local known = by_id(tools)
  local missing = M.check(ids, tools)
  local todo = vim.tbl_filter(function(id)
    return missing[id]
  end, ids)
  local install = M.plan(todo, tools)
  local index = 0
  local function step()
    index = index + 1
    local id = install[index]
    if not id then
      -- only what was missing is checked again (the probes start programs); an install that did not help
      -- keeps its by-hand line
      local still = M.check(todo, tools)
      on_done(
        still,
        M.hints(
          vim.tbl_filter(function(t)
            return still[t]
          end, todo),
          tools
        )
      )
      return
    end
    local tool = known[id]
    local blocked = vim.tbl_filter(function(dep)
      return M.check({ dep }, tools)[dep] == true
    end, tool.requires or {})
    if #blocked > 0 then
      items[#items + 1] =
        { text = ("== tool %s: skipped, %s is missing"):format(id, table.concat(blocked, ", ")) }
      step()
      return
    end
    local argv = tool.install() --[[@as string[] ]]
    items[#items + 1] = { text = ("== tool %s: %s"):format(id, table.concat(argv, " ")) }
    local started = pcall(vim.system, argv, { text = true }, function(res)
      vim.schedule(function()
        items[#items + 1] =
          { text = ("== tool %s: %s"):format(id, res.code == 0 and "ok" or "FAILED") }
        -- winget and cargo draw progress with a bare CR: every frame would be its own line
        for _, line in
          ipairs(vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true }))
        do
          line = vim.trim(line:match("([^\r]*)\r*$") or line)
          if line ~= "" then
            items[#items + 1] = { text = line }
          end
        end
        if res.code == 0 and tool.path then
          local dir = tool.path():gsub("/", "\\")
          if exists(dir) and not on_path(dir) then
            vim.env.PATH = dir .. ";" .. (vim.env.PATH or "")
          end
        end
        step()
      end)
    end)
    if not started then
      items[#items + 1] = { text = ("== tool %s: cannot start %s"):format(id, argv[1]) }
      step()
    end
  end
  step()
end

M._on_path = on_path

return M
