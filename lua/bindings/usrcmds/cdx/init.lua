---@module 'bindings.usrcmds.cdx'
---@brief `:Cdx prompt <name>` -- copy one of the CDX prompt templates to the clipboard.
---@description
--- The templates live in `docs/NOTES/CDX/templates/PROMPT/` of this config and
--- are pasted into Claude Code by hand all day, so this saves the detour
--- through a file manager:
---
---   :Cdx prompt base                    Base.md
---   :Cdx prompt review                  review_w_ultracode.md
---   :Cdx prompt ultra_sha [sha ...]     ultra_sha.md, `{SHA}` filled in
---
--- `ultra_sha` takes any number of commit SHAs, as separate arguments, as one
--- comma-separated token (`abc1234,def5678`), or as a quoted string
--- (`"abc1234, def5678"`) -- all of them end up as `abc1234, def5678` in the
--- text. Without a SHA the template is copied unchanged, `{SHA}` included.
---
--- The template directory is read from `stdpath("config")`, not from the
--- repository the current window happens to be in, so the command works from
--- any project. The copy goes through `lib.nvim.cross.copy_to_clipboard`
--- (Windows, macOS, Linux X11/Wayland, WSL).

local composer = require("lib.nvim.bindings.usercmd.composer")
local copy_to_clipboard = require("lib.nvim.cross.copy_to_clipboard")
local notify = require("lib.nvim.notify").create("[Cdx]")

local M = {}

--- The token in `ultra_sha.md` that the SHA list replaces.
local SHA_PLACEHOLDER = "{SHA}"

--- Separator between several SHAs in the filled-in text.
local SHA_JOIN = ", "

---@return string
local function prompt_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "NOTES", "CDX", "templates", "PROMPT")
end

---@param name string  file name inside `prompt_dir()`
---@return string|nil text  the template without surrounding blank lines, LF line endings
---@return string|nil err
local function read_template(name)
  local path = vim.fs.joinpath(prompt_dir(), name)
  local fh, open_err = io.open(path, "rb")
  if not fh then
    return nil, ("cannot read %s: %s"):format(path, open_err or "unknown error")
  end
  local text = fh:read("*a")
  fh:close()
  -- Strip a leading blank line (in case a template ever has one) and CRLF
  -- endings from Windows; neither belongs in the pasted prompt.
  text = text:gsub("\r\n", "\n"):gsub("^%s*\n", ""):gsub("%s+$", "")
  return text, nil
end

--- Turn whatever the user typed after `ultra_sha` into a list of SHAs: tokens
--- may themselves contain commas, so `a,b c` and `"a, b" c` are three SHAs.
--- Quote characters are dropped: a user command's arguments are split on
--- whitespace only, so `"a, b"` arrives as the two tokens `"a,` and `b"`.
---@param tokens string[]
---@return string[]|nil shas
---@return string|nil err
function M.parse_shas(tokens)
  local shas = {}
  for _, token in ipairs(tokens) do
    for piece in token:gmatch("[^,%s\"']+") do
      -- Git accepts abbreviations down to 4 hex digits; a full SHA-1 has 40
      -- (SHA-256 repositories 64). Anything else is a typo, and copying it
      -- would only surface once the prompt has been pasted and run.
      if not (piece:match("^%x+$") and #piece >= 4 and #piece <= 64) then
        return nil, ("not a commit SHA: %q"):format(piece)
      end
      shas[#shas + 1] = piece
    end
  end
  return shas, nil
end

---@param text string
---@param label string  shown in the confirmation
---@return boolean
local function copy(text, label)
  if not copy_to_clipboard(text) then
    notify.error("Could not write to the clipboard")
    return false
  end
  notify.info(("Copied %s (%d chars)"):format(label, vim.fn.strchars(text)))
  return true
end

--- Copy a template verbatim.
---@param file string
---@return boolean
local function copy_template(file)
  local text, err = read_template(file)
  if not text then
    notify.error(err or "template not readable")
    return false
  end
  return copy(text, file)
end

--- Copy `ultra_sha.md`, with `{SHA}` replaced by `tokens` when there are any.
---@param tokens string[]
---@return boolean
function M.copy_ultra_sha(tokens)
  local text, err = read_template("ultra_sha.md")
  if not text then
    notify.error(err or "template not readable")
    return false
  end

  local shas, perr = M.parse_shas(tokens)
  if not shas then
    notify.error(perr or "invalid SHA")
    return false
  end

  if #shas == 0 then
    return copy(text, "ultra_sha.md")
  end
  if not text:find(SHA_PLACEHOLDER, 1, true) then
    notify.warn(
      ("ultra_sha.md has no %s placeholder; copying it unchanged"):format(SHA_PLACEHOLDER)
    )
    return copy(text, "ultra_sha.md")
  end
  -- Function replacement: the SHA list is data, `%` in it must not be read as
  -- a capture reference.
  local filled = text:gsub(vim.pesc(SHA_PLACEHOLDER), function()
    return table.concat(shas, SHA_JOIN)
  end)
  return copy(filled, ("ultra_sha.md (%d SHA)"):format(#shas))
end

---@return nil
function M.enable()
  composer.verb("Cdx", {
    desc = "Claude Code helpers: copy CDX prompt templates to the clipboard",
    routes = {
      {
        path = { "prompt", "base" },
        desc = "Copy PROMPT/Base.md to the clipboard",
        run = function()
          copy_template("Base.md")
        end,
      },
      {
        path = { "prompt", "review" },
        desc = "Copy PROMPT/review_w_ultracode.md to the clipboard",
        run = function()
          copy_template("review_w_ultracode.md")
        end,
      },
      {
        path = { "prompt", "ultra_sha" },
        args = {
          {
            name = "sha",
            type = "STRING",
            optional = true,
            desc = "Commit SHA of 4 to 64 hex digits; more may follow",
          },
        },
        desc = "Copy PROMPT/ultra_sha.md; SHAs (space- or comma-separated) replace {SHA}, none keeps it",
        run = function(ctx)
          local tokens = {}
          vim.list_extend(tokens, ctx.pos)
          vim.list_extend(tokens, ctx.rest)
          M.copy_ultra_sha(tokens)
        end,
      },
    },
  })
end

return M
