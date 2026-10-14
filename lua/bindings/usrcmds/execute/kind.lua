---@module 'bindings.usrcmds.execute.kind'
---@brief What kind of text it is (Ex command, Lua, shell), the commands in it, and whether it leaves the editor.
---@description
--- `:Execute` takes any text. This module turns it into a `Execute.Plan`: the kind, the individual commands
--- with their markers stripped, a display form, and a `risky` flag.
---
--- Kind detection (`as = "auto"`), first match wins:
---   1. the language of a fenced block: bash / sh / zsh / shell / console / pwsh / powershell / cmd / bat
---      are shell, lua is Lua, vim / vimscript / ex are Ex
---   2. the first character of the first line: `!` or `$ ` is shell, `:` is Ex
---   3. otherwise Ex
---
--- A leading `:` / `!` / `$ ` is only a marker (`` `:set wrap` ``, `` `!git status` ``, `$ git status`), it is
--- removed before anything runs. `as` pins the kind and skips the detection.
---
--- `risky` is true for what reaches outside the editor: every shell command, an Ex command that is a
--- shell filter or `:terminal`, and a Lua chunk that names an obvious shell entry point. The command asks
--- before it runs such a plan. Ex and Lua are otherwise not guarded: they are what the user could type in
--- the command line, and the default of `:Execute` (without a bang) shows them there first.
---
--- Not its job: finding the text (`execute.source`), running it (`execute.sink`).

local M = {}

---Every value `as` takes, in the order the completion shows them.
---@type string[]
M.AS = { "auto", "ex", "lua", "shell" }

---What each `as` value means (shown by the completion).
---@type table<string, string>
M.AS_DESC = {
  auto = "decide from the fence language or the first character (`!`, `$ `, `:`)",
  ex = "Ex commands, one per line (:set wrap)",
  lua = "a Lua chunk or expression (vim.o.shiftwidth)",
  shell = "shell commands, one per line, run through 'shell'",
}

---@alias Execute.As "auto"|"ex"|"lua"|"shell"
---@alias Execute.Kind "ex"|"lua"|"shell"

---What will run.
---@class Execute.Plan
---@field kind Execute.Kind
---@field commands string[]  Ex: one command per entry, without the leading ":"; shell: one command line per
---                          entry; Lua: exactly one entry, the whole chunk
---@field display string     the plan as the user would type it (shown in the confirmation and the preview)
---@field risky boolean      true when it reaches outside the editor (ask before running)

---Fence languages, lower-case, and the kind they stand for.
---@type table<string, Execute.Kind>
local LANG_KIND = {
  bash = "shell",
  sh = "shell",
  zsh = "shell",
  fish = "shell",
  shell = "shell",
  console = "shell",
  terminal = "shell",
  pwsh = "shell",
  powershell = "shell",
  ps1 = "shell",
  cmd = "shell",
  bat = "shell",
  batch = "shell",
  lua = "lua",
  vim = "ex",
  vimscript = "ex",
  viml = "ex",
  ex = "ex",
}

---The first line that has text.
---@param lines string[]
---@return string|nil
local function first_text(lines)
  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      return trimmed
    end
  end
  return nil
end

---Decide the kind of `lines` when the user did not say.
---@param lines string[]
---@param lang? string  fence language
---@return Execute.Kind
function M.detect(lines, lang)
  if lang and LANG_KIND[lang] then
    return LANG_KIND[lang]
  end
  local first = first_text(lines)
  if first then
    if first:sub(1, 1) == "!" or first:match("^%$%s") then
      return "shell"
    end
  end
  return "ex"
end

---Strip the marker a kind may carry from one line.
---@param line string  trimmed
---@param kind Execute.Kind
---@return string
local function unmark(line, kind)
  if kind == "shell" then
    return (line:gsub("^!%s*", ""):gsub("^%$%s+", ""))
  elseif kind == "ex" then
    return (line:gsub("^:+%s*", ""))
  end
  return line
end

---Ex commands of `lines`: one per entry. Blank lines and `"` comments are dropped; a line that starts with `\`
---continues the one before (Vimscript's rule).
---@param lines string[]
---@return string[]
local function ex_commands(lines)
  local out = {}
  for _, raw in ipairs(lines) do
    local line = vim.trim(raw)
    if line:sub(1, 1) == "\\" and #out > 0 then
      -- Vim keeps what follows the backslash as written (`\ wrap` adds " wrap"), only the indent before it goes
      out[#out] = out[#out] .. line:sub(2)
    elseif line ~= "" and line:sub(1, 1) ~= '"' then
      out[#out + 1] = unmark(line, "ex")
    end
  end
  return out
end

---Shell command lines of `lines`: one per entry. Blank lines and `#` comments are dropped; a line that ends
---in a space and a backslash continues on the next one. The backslash needs the space in front of it: on
---Windows a path such as `dir C:\` also ends in one.
---
---A leading `!` is the marker of `` `!git status` ``, so it is stripped from the first command only, and only
---when `strip_bang` says the text is no code block: in a bash block `! grep -q x file` is a negation.
---@param lines string[]
---@param strip_bang boolean
---@return string[]
local function shell_commands(lines, strip_bang)
  local out = {}
  local pending
  local function add(line)
    if #out > 0 or not strip_bang then
      -- only the "$ " prompt is a marker here
      out[#out + 1] = (line:gsub("^%$%s+", ""))
    else
      out[#out + 1] = unmark(line, "shell")
    end
  end
  for _, raw in ipairs(lines) do
    local line = vim.trim(raw)
    if pending then
      line = pending .. " " .. line
      pending = nil
    end
    if line:match("%s\\$") then
      pending = vim.trim(line:sub(1, -2))
    elseif line ~= "" and line:sub(1, 1) ~= "#" then
      add(line)
    end
  end
  if pending and pending ~= "" then
    add(pending)
  end
  return out
end

---Whether `name` is `full` or an abbreviation of it that Vim accepts (at least `min` letters).
---@param name string
---@param full string
---@param min integer
---@return boolean
local function abbrev(name, full, min)
  return #name >= min and #name <= #full and full:sub(1, #name) == name
end

---Command modifiers that run the command after them (`:silent !ls`, `:vertical terminal`), as
---`{ full name, shortest abbreviation }`.
---@type { [1]: string, [2]: integer }[]
local MODIFIERS = {
  { "aboveleft", 3 },
  { "belowright", 3 },
  { "botright", 2 },
  { "browse", 3 },
  { "confirm", 4 },
  { "hide", 3 },
  { "keepalt", 5 },
  { "keepjumps", 5 },
  { "keepmarks", 3 },
  { "keeppatterns", 5 },
  { "leftabove", 5 },
  { "lockmarks", 3 },
  { "noautocmd", 3 },
  { "noswapfile", 3 },
  { "rightbelow", 6 },
  { "silent", 3 },
  { "tab", 3 },
  { "topleft", 2 },
  { "unsilent", 3 },
  { "verbose", 4 },
  { "vertical", 4 },
  { "sandbox", 3 },
  { "legacy", 3 },
  { "vim9cmd", 4 },
}

---Commands that run another command for each buffer / window / tab / entry: the command after them counts.
---@type { [1]: string, [2]: integer }[]
local REPEATERS = {
  { "argdo", 5 },
  { "bufdo", 5 },
  { "cdo", 3 },
  { "cfdo", 4 },
  { "ldo", 3 },
  { "lfdo", 4 },
  { "tabdo", 4 },
  { "windo", 5 },
}

---Commands that run an external program on their own, without a `!` in the line.
---@type { [1]: string, [2]: integer }[]
local EXTERNALS = {
  { "make", 3 },
  { "lmake", 4 },
  { "grep", 2 },
  { "lgrep", 3 },
  { "grepadd", 5 },
  { "lgrepadd", 5 },
  { "shell", 2 },
  { "terminal", 2 },
}

---Commands that take an expression or a script and can start a program in it.
---@type { [1]: string, [2]: integer }[]
local SCRIPTED = {
  { "execute", 3 },
  { "call", 3 },
  { "cexpr", 5 },
  { "lexpr", 5 },
  { "python", 2 },
  { "py3", 3 },
  { "python3", 3 },
  { "perl", 3 },
  { "ruby", 3 },
  { "lua", 3 },
  { "luado", 4 },
  { "pyx", 3 },
}

---@param name string
---@param list { [1]: string, [2]: integer }[]
---@return boolean
local function in_list(name, list)
  for _, entry in ipairs(list) do
    if abbrev(name, entry[1], entry[2]) then
      return true
    end
  end
  return false
end

---Split a command line at the bars that join commands (`set wrap | !ls`). A bar after a backslash or a
---Ctrl-V belongs to the argument.
---@param cmd string
---@return string[]
local function split_bars(cmd)
  local parts, start = {}, 1
  for i = 1, #cmd do
    local c = cmd:sub(i, i)
    local before = i > 1 and cmd:sub(i - 1, i - 1) or ""
    if c == "|" and before ~= "\\" and before ~= "\22" then
      parts[#parts + 1] = cmd:sub(start, i - 1)
      start = i + 1
    end
  end
  parts[#parts + 1] = cmd:sub(start)
  return parts
end

---Remove the range in front of a command name: numbers, `.`, `$`, `%`, marks (`'a`, `'<`), patterns
---(`/foo/`, `?foo?`), offsets and the separators `,` and `;`.
---@param text string
---@return string
local function strip_range(text)
  local s = text
  while true do
    local before = s
    s = s:gsub("^%s+", "")
    s = s:gsub("^[%d%.%$%%,;%+%-]+", "")
    s = s:gsub("^'[%w<>%[%]'`\"%^%.]", "")
    s = s:gsub("^/[^/]*/?", "")
    s = s:gsub("^%?[^?]*%??", "")
    if s == before then
      return s
    end
  end
end

---Whether one Ex command (no bars) hands something to the shell.
---@param part string
---@param depth integer
---@return boolean
local function part_is_risky(part, depth)
  if depth > 8 then
    return true -- nested deeper than anything sensible: ask
  end
  local rest = strip_range(part)
  if rest:sub(1, 1) == "!" then
    return true
  end
  local name = rest:match("^(%a+)")
  if not name then
    return false
  end
  local after = rest:sub(#name + 1)

  -- modifiers and repeaters: the command behind them is what counts
  if in_list(name, MODIFIERS) or in_list(name, REPEATERS) then
    after = after:gsub("^!", "")
    return part_is_risky(after, depth + 1)
  end
  if name == "g" or name == "global" or name == "v" or name == "vglobal" then
    -- :g/pattern/command, with any delimiter
    local delim = after:gsub("^!", ""):sub(1, 1)
    if delim == "" then
      return false
    end
    local cmd = after:gsub("^!", ""):match(
      "^" .. vim.pesc(delim) .. "[^" .. vim.pesc(delim) .. "]*" .. vim.pesc(delim) .. "(.*)$"
    )
    return cmd ~= nil and part_is_risky(cmd, depth + 1)
  end

  if abbrev(name, "read", 1) then
    return after:match("^%s*!") ~= nil
  end
  if abbrev(name, "write", 1) or abbrev(name, "wall", 2) then
    -- ":w !cmd" pipes the buffer into a command; ":w! file" is a forced write
    return after:match("^%s+!") ~= nil
  end
  if in_list(name, EXTERNALS) then
    return true
  end
  if in_list(name, SCRIPTED) then
    -- a program name or a `!` somewhere in the script: ask. A plain `:call Foo()` stays quiet.
    return rest:find("!", 1, true) ~= nil
      or rest:find("system", 1, true) ~= nil
      or M.lua_is_risky(rest)
  end
  return false
end

---Whether an Ex line hands something to the shell: a `!` command or filter (`!ls`, `%!sort`, `'a,'b!sort`,
---`/foo/!sort`, `r !ls`, `w !sh`), `:terminal`, `:make`, `:grep`, `:shell`, such a command behind a modifier
---(`silent !ls`, `vertical terminal`) or a repeater (`bufdo !ls`, `g/x/!ls`) or after a bar (`set wrap | !ls`),
---and a script command whose text names a shell entry point (`execute '!ls'`, `lua os.execute(...)`).
---
---A heuristic: Vim has too many commands to list them all. It errs towards asking.
---@param cmd string  without the leading ":"
---@return boolean
function M.ex_is_risky(cmd)
  for _, part in ipairs(split_bars(cmd)) do
    if part_is_risky(part, 0) then
      return true
    end
  end
  return false
end

---Lua names that start another program. A heuristic, not a sandbox: a chunk can do anything, this only
---catches the entry points people reach for.
---@type string[]
local LUA_SHELL_PATTERNS = {
  "os%.execute",
  "io%.popen",
  "vim%.system",
  "vim%.fn%.system",
  "vim%.fn%.jobstart",
  "vim%.fn%.termopen",
  "vim%.uv%.spawn",
  "vim%.loop%.spawn",
  "vim%.cmd%s*[%(%[\"']%s*[\"'%[=]*!",
}

---@param chunk string
---@return boolean
function M.lua_is_risky(chunk)
  for _, pattern in ipairs(LUA_SHELL_PATTERNS) do
    if chunk:find(pattern) then
      return true
    end
  end
  return false
end

---Build the plan for a piece of text.
---@param lines string[]
---@param as? Execute.As  default "auto"
---@param lang? string    fence language, used by the detection
---@return Execute.Plan|nil plan
---@return string|nil err  when there is nothing to run
function M.build(lines, as, lang)
  as = as or "auto"
  local kind = as == "auto" and M.detect(lines, lang) or as
  ---@cast kind Execute.Kind

  if kind == "lua" then
    local chunk = vim.trim(table.concat(lines, "\n"))
    if not chunk:find("\n", 1, true) then
      chunk = chunk:gsub("^:?lua%s+", "")
    end
    if chunk == "" then
      return nil, "nothing to run: the text is empty"
    end
    return {
      kind = "lua",
      commands = { chunk },
      display = "lua: " .. chunk,
      risky = M.lua_is_risky(chunk),
    },
      nil
  end

  local commands = kind == "shell" and shell_commands(lines, lang == nil) or ex_commands(lines)
  if #commands == 0 then
    return nil, "nothing to run: the text is empty (or only comments)"
  end
  local prefix = kind == "shell" and "!" or ":"
  local shown, risky = {}, kind == "shell"
  for i, cmd in ipairs(commands) do
    shown[i] = prefix .. cmd
    if kind == "ex" and M.ex_is_risky(cmd) then
      risky = true
    end
  end
  return {
    kind = kind,
    commands = commands,
    display = table.concat(shown, "\n"),
    risky = risky,
  },
    nil
end

---The text for the command line (to be typed after ":"), or why it cannot go there.
---
---The command line holds one line: several commands, or a Lua chunk with line breaks, do not fit. A shell
---command goes as `!<cmd>`, Lua as `lua <chunk>`.
---@param plan Execute.Plan
---@return string|nil text
---@return string|nil err
function M.cmdline_text(plan)
  if plan.kind == "lua" then
    local chunk = plan.commands[1]
    if chunk:find("\n", 1, true) then
      return nil,
        "a Lua chunk with several lines does not fit the command line: use :Execute! to run it"
    end
    return "lua " .. chunk, nil
  end
  if #plan.commands > 1 then
    return nil,
      ("%d commands do not fit the command line: use :Execute! to run them"):format(#plan.commands)
  end
  return (plan.kind == "shell" and "!" or "") .. plan.commands[1], nil
end

return M
