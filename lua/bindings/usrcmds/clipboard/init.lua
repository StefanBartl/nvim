---@module 'bindings.usrcmds.clipboard'
---@brief `:Clipboard [path] {target}` / `:Clipboard {snippet}` -- copy a well-known directory path or a ready-made Ex command to the clipboard.
---@description
--- The report and handover folders under `docs/ROADMAP/` are pasted into
--- Claude Code prompts, shells and file dialogs all day, so this saves the
--- detour through a file manager:
---
---   :Clipboard path reports      <config>/docs/ROADMAP/reports
---   :Clipboard path handovers    <config>/docs/ROADMAP/handovers
---
--- `path` is the first sub-command of `:Clipboard`: further things to copy
--- (a file's content, a link, ...) get their own word next to it later, which
--- is why the directory targets sit one level down. `path` itself is
--- optional -- `:Clipboard reports` is the same as `:Clipboard path reports`.
---
--- Snippets are the second kind of target: a fixed text (usually an Ex command that is
--- tedious to type) that is copied verbatim, no path involved:
---
---   :Clipboard remove citeX      :%s/\[cite: \d\+\]//g   (strips "[cite: 12]" markers)
---
--- They live in `M.SNIPPETS` (words -> text), extendable through `enable({ snippets = ... })`.
---
--- Deliberately no keymap (`<leader>cf` / `cg` belong to casedesk.nvim).
---
--- The path is copied as an absolute path with forward slashes -- directly
--- usable in a shell, an explorer address bar and Neovim alike. With
--- `form = "env"` it is folded into `$NVIM_CONFIG_DIR/...` (or whatever root
--- gopath.nvim's `shorten_path` knows) when the directory lies under one; a
--- directory under no known root stays absolute.
---
--- Targets are plain data (`M.TARGETS`, name -> directory relative to
--- `stdpath("config")`, or absolute, `$ENV` allowed): `enable({ targets = {
--- notes = "docs/NOTES" } })` adds more `:Clipboard` arguments without touching
--- this file. The copy goes through `lib.nvim.cross.copy_to_clipboard`
--- (Windows, macOS, Linux X11/Wayland, WSL).

local composer = require("lib.nvim.bindings.usercmd.composer")
local copy_to_clipboard = require("lib.nvim.cross.copy_to_clipboard")
local expand_path = require("lib.nvim.cross.fs.expand_path")
local notify = require("lib.nvim.notify").create("[Clipboard]", { messages = true })

local M = {}

--- Built-in targets: name -> directory (relative to `stdpath("config")`, or
--- absolute; `~` and `$ENV` are expanded).
---@type table<string, string>
M.TARGETS = {
  reports = "docs/ROADMAP/reports",
  handovers = "docs/ROADMAP/handovers",
}

--- Built-in snippets: space-separated command words -> text copied as is. Long strings, so the
--- backslashes stay literal.
---@type table<string, { text: string, desc: string }>
M.SNIPPETS = {
  ["remove citeX"] = {
    text = [[:%s/\[cite: \d\+\]//g]],
    desc = 'Remove all "[cite: N]" markers from the buffer (Ex command)',
  },
}

---@class Bindings.Clipboard.Opts
---@field targets? table<string, string>  Extra/overriding targets, merged over `M.TARGETS`.
---@field snippets? table<string, { text: string, desc?: string }>  Extra/overriding snippets, merged over `M.SNIPPETS`.
---@field form? "absolute"|"env"          How the path is written (default "absolute").

---@type { form: "absolute"|"env" }
local settings = { form = "absolute" }

---@param dir string
---@return boolean
local function is_absolute(dir)
  return dir:match("^%a:[/\\]") ~= nil or dir:sub(1, 1) == "/" or dir:sub(1, 1) == "~"
end

--- The absolute, forward-slash path of target `dir`.
---@param dir string  as configured (relative to the config dir, or absolute)
---@return string
function M.resolve(dir)
  local expanded = expand_path(dir)
  if not is_absolute(expanded) then
    expanded = vim.fs.joinpath(vim.fn.stdpath("config"), expanded)
  end
  return (vim.fs.normalize(expanded):gsub("/+$", ""))
end

--- The text to copy for an absolute `path`, per `settings.form`.
---@param path string
---@return string
function M.format(path)
  if settings.form ~= "env" then
    return path
  end
  local ok, gopath = pcall(require, "gopath.env_shorten")
  if ok and type(gopath.shorten_path) == "function" then
    local shortened = gopath.shorten_path(path)
    if shortened then
      return shortened
    end
  end
  local cfg = (vim.fs.normalize(vim.fn.stdpath("config")):gsub("/+$", ""))
  -- Case-insensitive only where the file system is (Windows).
  local fold = vim.fn.has("win32") == 1 and string.lower or function(s)
    return s
  end
  if fold(path) == fold(cfg) then
    return "$NVIM_CONFIG_DIR"
  end
  if fold(path:sub(1, #cfg + 1)) == fold(cfg .. "/") then
    return "$NVIM_CONFIG_DIR" .. path:sub(#cfg + 1)
  end
  return path
end

--- Shorten `text` for a one-line status message: past the editor width minus
--- room for the prefix only the tail is kept, behind an ellipsis. A message wider
--- than the command line raises a hit-enter prompt when no message UI is attached.
---@param text string
---@return string
local function shorten_for_echo(text)
  local max = math.max(20, vim.o.columns - 30)
  if vim.fn.strdisplaywidth(text) <= max then
    return text
  end
  local chars = vim.fn.strchars(text)
  local lo, hi = 1, chars
  while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    if vim.fn.strdisplaywidth(vim.fn.strcharpart(text, chars - mid)) <= max - 1 then
      lo = mid
    else
      hi = mid - 1
    end
  end
  return "…" .. vim.fn.strcharpart(text, chars - lo)
end
M.shorten_for_echo = shorten_for_echo

--- Copy the directory of target `name` to the clipboard.
---@param name string
---@return boolean ok
function M.copy(name)
  local dir = M.TARGETS[name]
  if not dir then
    notify.error(("unknown target %q (known: %s)"):format(name, table.concat(M.names(), ", ")))
    return false
  end

  local path = M.resolve(dir)
  if vim.fn.isdirectory(path) == 0 then
    notify.error(("directory does not exist: %s"):format(path))
    return false
  end

  local text = M.format(path)
  if not copy_to_clipboard(text) then
    notify.warn(("no clipboard provider accepted %s"):format(shorten_for_echo(text)))
    return false
  end
  notify.info(("copied %s -> %s"):format(name, shorten_for_echo(text)))
  return true
end

--- Copy the text of snippet `key` (e.g. "remove citeX") to the clipboard.
---@param key string
---@return boolean ok
function M.copy_snippet(key)
  local snippet = M.SNIPPETS[key]
  if not snippet then
    notify.error(("unknown snippet %q"):format(key))
    return false
  end
  if not copy_to_clipboard(snippet.text) then
    notify.warn(("no clipboard provider accepted %s"):format(shorten_for_echo(snippet.text)))
    return false
  end
  notify.info(("copied %s -> %s"):format(key, shorten_for_echo(snippet.text)))
  return true
end

--- Sorted target names.
---@return string[]
function M.names()
  local names = vim.tbl_keys(M.TARGETS)
  table.sort(names)
  return names
end

---@param opts? Bindings.Clipboard.Opts
---@return nil
function M.enable(opts)
  opts = opts or {}
  if type(opts.targets) == "table" then
    for name, dir in pairs(opts.targets) do
      if type(name) == "string" and type(dir) == "string" then
        M.TARGETS[name] = dir
      end
    end
  end
  if type(opts.snippets) == "table" then
    for key, snippet in pairs(opts.snippets) do
      if type(key) == "string" and type(snippet) == "table" and type(snippet.text) == "string" then
        M.SNIPPETS[key] = { text = snippet.text, desc = snippet.desc or "Copy a snippet" }
      end
    end
  end
  if opts.form == "absolute" or opts.form == "env" then
    settings.form = opts.form
  end

  local routes = {}
  for _, name in ipairs(M.names()) do
    local function run()
      M.copy(name)
    end
    local desc = ("Copy the path of %s to the clipboard"):format(M.TARGETS[name])
    routes[#routes + 1] = { path = { "path", name }, desc = desc, run = run }
    -- `path` is optional: `:Clipboard reports` keeps working.
    routes[#routes + 1] =
      { path = { name }, desc = desc .. " (short for `path " .. name .. "`)", run = run }
  end

  local keys = vim.tbl_keys(M.SNIPPETS)
  table.sort(keys)
  for _, key in ipairs(keys) do
    routes[#routes + 1] = {
      path = vim.split(key, " ", { plain = true, trimempty = true }),
      desc = M.SNIPPETS[key].desc .. " -> clipboard",
      run = function()
        M.copy_snippet(key)
      end,
    }
  end

  composer.verb("Clipboard", {
    desc = "Copy the path of a well-known directory of this config, or a ready-made snippet, to the clipboard",
    routes = routes,
  })
end

return M
