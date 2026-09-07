---@module 'bindings.mappings.editing'
--- `p`/`P`/visual-`p` strip leading/trailing blank lines and edge whitespace
--- from what they paste, and squeeze interior blank runs of `BLANK_RUN_LIMIT`+
--- down to one (a browser/chat-UI copy drags the page around it along).
--- `]p`/`[p`/`gp`/`gP` stay vanilla as the untrimmed escape hatch.
---
--- `install_paste_trim()` applies the same to terminal paste (Ctrl+V &c.),
--- which never touches a register or a keymap — it goes straight to
--- `vim.paste()`, the only interception point that covers every mode.
---
--- Why the register/clipboard/`vim.paste`-phase details are the way they are:
--- wkdbook-Neovim/MyNotes/Paste-Register-Clipboard-vim.paste.md

local M = {}

---True for a line that is empty or made up entirely of whitespace.
---@param line string
---@return boolean
local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

---Interior blank runs of this length or more get squeezed to one (see
---`squeeze_blank_runs`). 3 keeps the 2-blank-line spacing Python/Go use
---between top-level defs untouched.
local BLANK_RUN_LIMIT = 3

---Collapse every run of `BLANK_RUN_LIMIT`+ consecutive blank lines in
---`lines` down to a single blank line. Runs shorter than the limit, and
---non-blank lines, pass through unchanged; relative order is preserved.
---@param lines string[]
---@return string[]
local function squeeze_blank_runs(lines)
  local out = {}
  local run = 0
  for _, line in ipairs(lines) do
    if is_blank(line) then
      run = run + 1
    else
      if run > 0 then
        for _ = 1, (run >= BLANK_RUN_LIMIT) and 1 or run do
          out[#out + 1] = ""
        end
        run = 0
      end
      out[#out + 1] = line
    end
  end
  -- Trailing run: keep it (possibly squeezed) rather than dropping it here —
  -- callers that care about trailing blanks (trim_edges, the vim.paste
  -- wrapper's final-phase trim) already strip them after this runs.
  for _ = 1, (run >= BLANK_RUN_LIMIT) and 1 or run do
    out[#out + 1] = ""
  end
  return out
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

---Drop leading/trailing blank lines, squeeze interior blank runs (see
---`squeeze_blank_runs`), then strip leading whitespace off the first
---remaining line and trailing whitespace off the last one — i.e. everything
---before the first real character and after the last one.
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
  trimmed = squeeze_blank_runs(trimmed)
  trimmed[1] = trimmed[1]:gsub("^%s+", "")
  trimmed[#trimmed] = trimmed[#trimmed]:gsub("%s+$", "")
  return trimmed
end

---Resolve the unnamed register `"` to the `+`/`*` that `'clipboard'` backs it
---with — `vim.fn.getreg()` does not follow that redirection itself (see the
---note linked in the module doc).
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

---Flash the region a put just wrote, via wkdoptions' put-flash. That layer
---used to map `p`/`P` itself and lost the key to this module (registered
---later, on UIReady); calling it from here gets both on one keypress.
---`nvim_put` sets the `[`/`]` marks it reads. Soft: a paste must not fail if
---the highlight layer is absent or errors.
---@return nil
local function flash_put()
  local ok, flash = pcall(require, "wkdoptions.hl_config.features.flash")
  if ok and type(flash.flash_put) == "function" then
    pcall(flash.flash_put)
  end
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
  flash_put()
end

---Wrap `vim.paste` so bracketed-paste gets the same trimming/squeezing as
---`p`/`P` (module doc says why this can't be a keymap).
---
---Streamed pastes arrive in chunks (`phase` 1/2/3) that concatenate *directly*
---— a chunk boundary is not a line break — so leading trim only left-strips
---inside the still-blank leading run, and trailing trim runs only at `-1`/`3`.
---A chunk that empties out is forwarded as `{}`, not `{ "" }`. Accepted gap: a
---blank run split across a chunk boundary can escape squeezing; irrelevant for
---the one-shot (`phase == -1`) browser copies this exists for.
---See wkdbook-Neovim/MyNotes/Paste-Register-Clipboard-vim.paste.md.
---
---Idempotent: `M.setup()` may run more than once.
---@return nil
local function install_paste_trim()
  if vim.g.__paste_trim_installed then
    return
  end
  vim.g.__paste_trim_installed = true

  local original = vim.paste
  local seen_content = false

  -- Deliberate override: `vim.paste` is core's documented paste entry point,
  -- and the wrapper documented above calls `original` for every chunk. LuaLS
  -- reports any write to a `vim.*` field it already types.
  ---@param lines string[]
  ---@param phase integer
  ---@return boolean
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    if phase == -1 or phase == 1 then
      seen_content = false
    end

    local out = {}
    for _, line in ipairs(lines) do
      if seen_content then
        out[#out + 1] = line
      elseif not is_blank(line) then
        -- First real line: also drop the indentation the page/editor added in
        -- front of it — the paste position dictates the indent, not the source.
        seen_content = true
        out[#out + 1] = (line:gsub("^%s+", ""))
      end
    end

    out = squeeze_blank_runs(out)

    if phase == -1 or phase == 3 then
      while #out > 0 and is_blank(out[#out]) do
        out[#out] = nil
      end
      if #out > 0 then
        out[#out] = (out[#out]:gsub("%s+$", ""))
      end
    end

    return original(out, phase)
  end
end

function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  install_paste_trim()

  -- Branch-aware redo/undo that survives auto-changes by plugins
  map("n", "<C-r>", "g+", { desc = "Redo (branch-aware)" })

  -- Insert blank lines
  map("n", "<leader><CR>", "o<Esc>k", { desc = "Insert blank line below" })
  map("n", "<CR>", "0i<CR><Esc>k", { desc = "Insert blank line" })

  -- Paste after/before cursor, trimmed of leading/trailing blank lines and
  -- edge whitespace (see module doc). A count prefix (e.g. "3p") is not
  -- specially handled and just performs a single trimmed paste.
  map("n", "p", function()
    put_trimmed('"', true)
  end, {
    silent = true,
    desc = "Paste after cursor (leading/trailing blank lines trimmed)",
  })
  map("n", "P", function()
    put_trimmed('"', false)
  end, {
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
    desc = "[Text] Paste from system clipboard (insert mode, literal)",
  })
end

return M
