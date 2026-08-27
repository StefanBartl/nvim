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
--- The outermost lines are trimmed entirely; interior blank *runs* of
--- `BLANK_RUN_LIMIT` or more are additionally squeezed down to a single
--- blank line (see `squeeze_blank_runs`) — copying a bullet list out of a
--- rich-text editor (e.g. a chat UI) routinely serializes each `<li>` as its
--- own block, which round-trips through HTML-to-plaintext as 2-3 blank
--- lines between bullets instead of none. Runs of 1-2 blank lines are left
--- untouched so conventional double-blank-line spacing (Python/Go top-level
--- defs) survives a paste. `]p`/`[p`/`gp`/`gP` are deliberately left vanilla
--- as an untrimmed escape hatch for the rare paste where the blank lines
--- were actually meaningful.
---
--- `install_paste_trim()` extends the same trimming to terminal paste
--- (Ctrl+V / Ctrl+Shift+V / middle-click). That route never touches a register
--- and never runs a keymap: the terminal wraps the clipboard in bracketed-paste
--- escape sequences and Neovim hands the raw chunks to `vim.paste()`. So the
--- `p`/`P` mappings above cannot see it, which is why the exact same browser
--- copy arrived clean via `p` but kept its leading blank lines via Ctrl+V.
--- Wrapping `vim.paste` is the only interception point that covers it, and it
--- covers every mode at once (Normal, Insert, cmdline, terminal).

local M = {}

---True for a line that is empty or made up entirely of whitespace.
---@param line string
---@return boolean
local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

---Consecutive interior blank lines at/above this count get squeezed to one
---(see `squeeze_blank_runs`). 3 is deliberately above the conventional
---2-blank-line spacing some code styles use between top-level definitions
---(Python, Go), so pasting such code leaves it untouched.
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

---Flash the region a put just wrote, if wkdoptions' put flash is enabled.
---
---That feature used to own `p`/`P` itself (`wkdoptions.hl_config.features
---.flash`), which put it in a fight with this module over the same two keys —
---and it lost, because these mappings are registered on `UIReady` and
---therefore later. So the flash was switched on in the config and did nothing
---at all.
---
---The two were never in conflict about behaviour, only about the key: one
---decides *what* is pasted, the other adds feedback afterwards. Calling it
---from here gets both on one keypress. `nvim_put` sets the `[`/`]` marks the
---flash reads, so no replay of the native `p` is needed.
---
---Soft: wkdoptions is part of this config, but a paste must not fail because
---its highlight layer is absent or errored.
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

---Wrap `vim.paste` so bracketed-paste input gets the same edge trimming and
---interior blank-run squeezing (see `squeeze_blank_runs`) as `p`/`P` (see
---module doc for why this cannot be a keymap).
---
---`vim.paste` may be called in one shot (`phase == -1`) or streamed across
---several chunks (`1` start, `2` middle, `3` end), so the two edges are handled
---separately: leading blank lines are dropped until the first line with real
---content has been seen — which can take more than one chunk if the paste
---starts with a long blank run — and trailing blank lines only at the final
---chunk. Every chunk (including middle ones) is run through
---`squeeze_blank_runs` before being forwarded, and a chunk that empties out
---completely is forwarded as an empty list rather than as `{ "" }`, which would
---insert a blank line the original text did not have.
---
---Note that chunks concatenate *directly* — a chunk boundary is not a line
---break, the last entry of one chunk and the first of the next are two halves
---of the same line — which is why lines are only ever dropped or left-stripped
---while still inside the leading blank run, where both halves are blank anyway.
---The one accepted gap: if a paste ends with a blank run long enough to start
---in an earlier chunk, only the part in the final chunk is removed, since the
---rest is already in the buffer by then — and the same applies to
---`squeeze_blank_runs`, which only sees one chunk's lines at a time, so a
---blank run split across a chunk boundary can escape squeezing. Streaming
---only kicks in for very large pastes, and the browser copies this exists
---for are one-shot (`phase == -1`).
---
---Idempotent: `M.setup()` may run more than once, and wrapping the wrapper
---would trim already-trimmed chunks (harmless) while growing the call chain.
---@return nil
local function install_paste_trim()
  if vim.g.__paste_trim_installed then
    return
  end
  vim.g.__paste_trim_installed = true

  local original = vim.paste
  local seen_content = false

  ---@param lines string[]
  ---@param phase integer
  ---@return boolean
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
    desc = "Aus System-Zwischenablage im Insert-Modus einfügen",
  })
end

return M
