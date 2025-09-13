---@module 'mappings.surround'
--- Visual-mode double-tap mappings to surround the current selection.

local M = {}

M.cfg = {
  single_quote  = true,
  double_quotes = true,
  backticks     = true,
  parens        = true,
  brackets      = true,
  braces        = true,
  desc_prefix   = "Surround selection with ",
}

--- Safely feed a key sequence with termcode translation in Visual context.
--- Using "x" as the mode flag preserves Visual selection semantics for 'c'.
---@param keys string
---@return nil
local function feed(keys)
  -- Translate termcodes like <C-o>, <Esc> into keycodes Neovim understands.
  local seq = vim.api.nvim_replace_termcodes(keys, true, false, true)
  -- Feed in Visual context; noremap=false so raw keys execute as intended.
  vim.api.nvim_feedkeys(seq, "x", false)
end

--- Surround the current Visual selection with the given single-character delimiter.
---@param ch string  -- expected: '"', "'", or "`"
---@return nil
local function surround_with(ch)
  -- Perform: c {open} <C-o>P {close} <Esc>
  feed("c" .. ch .. [[<C-o>P]] .. ch .. [[<Esc>]])
end

--- Surround the current Visual selection with an opening/closing pair.
---@param open string  -- e.g. "(", "[", "{"
---@param close string -- e.g. ")", "]", "}"
---@return nil
local function surround_pair(open, close)
  -- Perform: c {open} <C-o>P {close} <Esc>
  feed("c" .. open .. [[<C-o>P]] .. close .. [[<Esc>]])
end

---@param lhs string
---@param cb fun()
---@param desc string
local function xmap(lhs, cb, desc)
  -- Optional project-specific helper:
  local map = M.cfg.mapfun or vim.g.__map_helper or vim.keymap.set
  map("x", lhs, cb, { desc = desc, silent = true, noremap = true })
end

--- Apply user overrides into M.cfg.
local function apply_opts(opts)
  if type(opts) ~= "table" then return end
  for k, v in pairs(opts) do
    M.cfg[k] = v
  end
end

--- Create all requested mappings based on M.cfg.
---@return nil
local function define_mappings()
  local pfx = M.cfg.desc_prefix or "Surround selection with "

  if M.cfg.double_quotes ~= false then
    xmap('""', function() surround_with('"') end, pfx .. 'double quotes (")')
  end

  if M.cfg.single_quote ~= false then
    xmap("''", function() surround_with("'") end, pfx .. "single quotes (')")
  end

  if M.cfg.backticks ~= false then
    xmap("``", function() surround_with("`") end, pfx .. "backticks (`)")
  end

  if M.cfg.parens ~= false then
    xmap("((", function() surround_pair("(", ")") end, pfx .. "()")
  end

  if M.cfg.brackets ~= false then
    xmap("[[", function() surround_pair("[", "]") end, pfx .. "[]")
  end

  if M.cfg.braces ~= false then
    xmap("{{", function() surround_pair("{", "}") end, pfx .. "{}")
  end
end

--- Public setup entrypoint.
---@return nil
function M.setup(opts)
  apply_opts(opts)
  define_mappings()
end

return M
