---@module 'lib.buf_win_tab.resize_guarded'
--- Guarded resize helper.
--- Provides resize mappings that are skipped for specific buffers,
--- while still forwarding the original keypress to the terminal or plugin buffer.
---
--- Usage:
--- local resize_guarded = require("lib.buf_win_tab.resize_guarded")
--- local exclude_filetypes = { "terminal" }
--- local exclude_names = { ".*lazygit.*" }
--- vim.keymap.set({ "n", "t" }, "<S-h>", resize_guarded.create("vertical resize -5", exclude_filetypes, exclude_names, "<S-h>"), { desc = "[Window] Resize narrower" })
--- ...
---
--- Behaviour:
--- - If current buffer matches an exclusion (filetype or name pattern),
---   the module will forward the original keypress to the buffer (so terminals receive it).
--- - Otherwise the module executes the provided resize command.
--- - The `lhs` argument is used to derive the forwarded sequence when excluded.
---   If omitted, the module will attempt a best-effort fallback (common SHIFT mappings).
---
--- Notes:
--- - Code comments are in English per project style.
--- - API: create(cmd, exclude_filetypes?, exclude_names?, lhs?)
---   returns a function suitable for `vim.keymap.set` callbacks.

local api = vim.api
local replace_termcodes = vim.api.nvim_replace_termcodes
local feedkeys = vim.api.nvim_feedkeys

--- Map of common lhs -> fallback sequence when forwarding to terminal.
--- Expand if needed for more keys.
---@type table<string,string>
local COMMON_FALLBACK = {
  ["<S-h>"] = "H",
  ["<S-j>"] = "J",
  ["<S-k>"] = "K",
  ["<S-l>"] = "L",
  ["<S-Up>"] = "<S-Up>",
  ["<S-Down>"] = "<S-Down>",
  ["<S-Left>"] = "<S-Left>",
  ["<S-Right>"] = "<S-Right>",
  -- add more mappings if required
}

--- Derive a fallback key sequence from lhs.
--- If lhs is "<S-x>" where x is a single char, return the uppercase char.
--- Otherwise consult COMMON_FALLBACK. If nothing matches, return nil.
---@param lhs string|nil
---@return string|nil
local function derive_fallback(lhs)
  if type(lhs) ~= "string" then
    return nil
  end

  -- direct common table lookup
  local v = COMMON_FALLBACK[lhs]
  if v then
    return v
  end

  -- pattern: <S-x> where x is a single character
  local single = lhs:match("^<S%-(.)>$")
  if single and #single == 1 then
    return single:upper()
  end

  -- pattern: <S-(.+)> with longer token, return as-is to be fed as termcodes
  local token = lhs:match("^<S%-(.+)>$")
  if token and #token > 1 then
    -- recompose as <S-...> so termcode replacement can handle
    return "<S-" .. token .. ">"
  end

  return nil
end

--- Forward the original key to the active buffer/terminal.
--- Uses nvim_replace_termcodes + nvim_feedkeys to emulate user input.
---@param seq string
local function forward_key(seq)
  if not seq or seq == "" then
    return
  end
  -- seq may be a plain character like "H" or a termcode like "<S-Left>".
  local keys = replace_termcodes(seq, true, false, true)
  -- 'm' flag to remap? use 'n' (no remap) to avoid recursion; false for escape_ks
  feedkeys(keys, "n", false)
end

--- Create a guarded resize mapping callback.
--- @param cmd string Command to execute (e.g., "vertical resize -5")
--- @param exclude_filetypes? string[] List of filetypes to exclude
--- @param exclude_names? string[] List of Lua patterns to match buffer names to exclude
--- @param lhs? string Original mapping lhs (e.g. "<S-h>") used to derive forwarded key
--- @return fun()|nil
local function create(cmd, exclude_filetypes, exclude_names, lhs)
  exclude_filetypes = exclude_filetypes or {}
  exclude_names = exclude_names or {}

  -- Precompute fallback sequence if possible
  local fallback_seq = derive_fallback(lhs)

  return function()
    local buf = api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype or ""
    local name = api.nvim_buf_get_name(buf) or ""

    -- If buffer filetype is excluded -> forward key and do nothing
    for _, ftype in ipairs(exclude_filetypes) do
      if ft == ftype then
        -- Forward fallback or nothing
        if fallback_seq then
          forward_key(fallback_seq)
        end
        return
      end
    end

    -- If buffer name matches any excluded pattern -> forward key and do nothing
    for _, pat in ipairs(exclude_names) do
      if name:match(pat) then
        if fallback_seq then
          forward_key(fallback_seq)
        end
        return
      end
    end

    -- Otherwise perform the resize command
    pcall(function() vim.cmd(cmd) end)
  end
end

return {
  create = create,
}
