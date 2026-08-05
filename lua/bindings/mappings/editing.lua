---@module 'bindings.mappings.editing'
--- `p`/`P`/visual-`p` strip leading/trailing blank lines and edge whitespace
--- from whatever they paste (see `trim_edges` below) — copying a snippet out
--- of a browser routinely drags along blank lines/indentation from the page
--- around the real content, and with 'clipboard' = unnamedplus (options.lua)
--- that lands straight in the unnamed register `p`/`P` read from. Deliberately
--- unconditional, no config flag: it is one keymap tweak among several
--- already in this file (the visual-`p`/`<C-A-S-p>` mappings below predate
--- it), not a toggleable subsystem like `autocmds.text`.
---
--- Only the outermost lines are touched — internal blank lines/indentation in
--- the pasted content are left exactly as they are. `]p`/`[p`/`gp`/`gP` are
--- deliberately left vanilla as an untrimmed escape hatch for the rare paste
--- where the leading/trailing whitespace was actually meaningful.

local M = {}

---True for a line that is empty or made up entirely of whitespace.
---@param line string
---@return boolean
local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

---`nvim_put`'s `type` argument for a `getregtype()` result.
---@param regtype string
---@return "c"|"l"|"b"
local function put_type(regtype)
  local first = regtype:sub(1, 1)
  if first == "V" then
    return "l"
  elseif first == "\22" then
    return "b"
  end
  return "c"
end

---Drop leading/trailing blank lines, then strip leading whitespace off the
---first remaining line and trailing whitespace off the last one — i.e.
---everything before the first real character and after the last one.
---Content in between is returned untouched.
---@param lines string[]
---@return string[]
local function trim_edges(lines)
  local first, last = 1, #lines
  while first <= last and is_blank(lines[first]) do
    first = first + 1
  end
  while last >= first and is_blank(lines[last]) do
    last = last - 1
  end
  if first > last then
    return { "" }
  end

  local trimmed = {}
  for i = first, last do
    trimmed[#trimmed + 1] = lines[i]
  end
  trimmed[1] = trimmed[1]:gsub("^%s+", "")
  trimmed[#trimmed] = trimmed[#trimmed]:gsub("%s+$", "")
  return trimmed
end

---Resolve the unnamed register `"` to whatever `'clipboard'` actually backs
---it. Native `p`/`y` redirect through the clipboard provider when
---'clipboard' contains "unnamed"/"unnamedplus"; `vim.fn.getreg()` does not
---do this redirection itself and returns Neovim's internal (stale) register
---content instead of the live system clipboard, so callers going through
---`getreg()` — like `put_trimmed` below — must resolve it manually.
---@param regname string
---@return string
local function resolve_unnamed(regname)
  if regname ~= '"' then
    return regname
  end
  local cb = vim.o.clipboard
  if cb:find("unnamedplus") then
    return "+"
  elseif cb:find("unnamed") then
    return "*"
  end
  return regname
end

---Read register `regname`, trim it (see `trim_edges`), and put it via
---`nvim_put` — never through the register system, so the register itself
---(and, with unnamedplus, the real system clipboard) is left untouched and
---still holds the original, un-trimmed text for pasting elsewhere.
---@param regname string
---@param after boolean true = after cursor ("p"), false = before ("P")
local function put_trimmed(regname, after)
  regname = resolve_unnamed(regname)
  local lines = vim.fn.getreg(regname, 1, true) --[[@as string[] ]]
  local regtype = vim.fn.getregtype(regname)
  vim.api.nvim_put(trim_edges(lines), put_type(regtype), after, true)
end

function M.setup()
  local map = vim.g.__map_helper

  -- Branch-aware redo/undo that survives auto-changes by plugins
  map("n", "<C-r>", "g+", { desc = "Redo (branch-aware)" })

  -- Insert blank lines
  map("n", "<leader><CR>", "o<Esc>k", { desc = "Insert blank line below" })
  map("n", "<CR>", "0i<CR><Esc>k", { desc = "Insert blank line" })

  -- Paste after/before cursor, trimmed of leading/trailing blank lines and
  -- edge whitespace (see module doc). A count prefix (e.g. "3p") is not
  -- specially handled and just performs a single trimmed paste.
  map("n", "p", function() put_trimmed('"', true) end, {
    silent = true,
    desc = "Paste after cursor (leading/trailing blank lines trimmed)",
  })
  map("n", "P", function() put_trimmed('"', false) end, {
    silent = true,
    desc = "Paste before cursor (leading/trailing blank lines trimmed)",
  })

  -- Visual mode paste without overwriting the yank register, also trimmed.
  map("x", "p", function()
    local regname = resolve_unnamed('"')
    local lines = vim.fn.getreg(regname, 1, true) --[[@as string[] ]]
    local ptype = put_type(vim.fn.getregtype(regname))
    vim.cmd('normal! "_d')
    vim.api.nvim_put(trim_edges(lines), ptype, false, true)
  end, {
    silent = true,
    desc = "Paste over selection, trimmed, without yanking it",
  })

  -- Insert clipboard (+) literally, without triggering auto-indent doubling.
  -- NOTE: some terminals cannot encode <C-A-S-p>; if it never fires, the
  -- terminal/GUI is swallowing the chord, not this mapping.
  map("i", "<C-A-S-p>", "<C-r><C-o>+", {
    noremap = true,
    silent = true,
    desc = "Aus System-Zwischenablage im Insert-Modus einfügen",
  })

end

return M
