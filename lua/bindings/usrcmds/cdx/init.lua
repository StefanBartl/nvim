---@module 'bindings.usrcmds.cdx'
---@brief `:Cdx prompt <name>` -- copy one of the CDX prompt templates to the clipboard.
---@description
--- The templates live in `docs/NOTES/CDX/templates/PROMPT/` of this config and
--- are pasted into Claude Code by hand all day, so this saves the detour
--- through a file manager:
---
---   :Cdx prompt <name> [sha ...] [--open]
---
--- With `--open` the text is not copied but shown in a new scratch buffer.
---
--- `<name>` is every `*.md` file of that folder, without the extension
--- (`Base`, `full`, `review_w_ultracode`, `ultra_sha`, a new file the moment it
--- is saved), and completes with `<Tab>`; the folder is read on every
--- completion and every call, so nothing has to be registered. The matching is
--- case-insensitive, and two short names stay for the two that were there first
--- (a file of that very name wins: `review.md` is used before the short name `review`):
---
---   base    Base.md
---   review  review_w_ultracode.md
---
--- A template that contains `{SHA}` takes any number of commit SHAs, as
--- separate arguments, as one comma-separated token (`abc1234,def5678`), or as
--- a quoted string (`"abc1234, def5678"`) -- all of them end up as
--- `abc1234, def5678` in the text. Without a SHA the template is copied
--- unchanged, `{SHA}` included; arguments for a template without the
--- placeholder are ignored with a warning.
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

---Short names that stay for templates whose file name is long.
---@type table<string, string>
local ALIASES = { base = "Base.md", review = "review_w_ultracode.md" }

---Every template of the folder: the file stem -> the file name.
---@return table<string, string> by_stem
---@return string[] stems  sorted
local function list_templates()
  local by_stem, stems = {}, {}
  local handle = vim.uv.fs_scandir(prompt_dir())
  while handle do
    local name, kind = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    local stem = name:match("^(.+)%.md$")
    if stem and kind ~= "directory" then
      by_stem[stem] = name
      stems[#stems + 1] = stem
    end
  end
  table.sort(stems)
  return by_stem, stems
end

---The file name a typed `<name>` means: the exact stem, the stem in any case, else a short name. A file named like
---a short name wins over it (`review.md` over `review` -> `review_w_ultracode.md`), in any case typed.
---@param typed string
---@return string|nil file
---@return string|nil err
function M.resolve(typed)
  local by_stem, stems = list_templates()
  if by_stem[typed] then
    return by_stem[typed], nil
  end
  for _, stem in ipairs(stems) do
    if stem:lower() == typed:lower() then
      return by_stem[stem], nil
    end
  end
  local alias = ALIASES[typed:lower()]
  if alias and vim.tbl_contains(vim.tbl_values(by_stem), alias) then
    return alias, nil
  end
  return nil,
    ("no prompt template '%s' in %s (have: %s)"):format(
      typed,
      prompt_dir(),
      table.concat(stems, ", ")
    )
end

---The words `<Tab>` offers: every stem, and the aliases whose file exists.
---@return string[]
function M.names()
  local by_stem, stems = list_templates()
  local files = vim.tbl_values(by_stem)
  local out = vim.list_extend({}, stems)
  for alias, file in pairs(ALIASES) do
    -- `base` for `Base.md` is the stem in another case: offering both says the same word twice
    local is_stem_in_other_case = false
    for _, stem in ipairs(stems) do
      if stem:lower() == alias then
        is_stem_in_other_case = true
      end
    end
    if vim.tbl_contains(files, file) and not is_stem_in_other_case then
      out[#out + 1] = alias
    end
  end
  table.sort(out)
  return out
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

--- Turn whatever the user typed after the template name into a list of SHAs: tokens
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

---Show the text in a new scratch buffer in the current window. The buffer number is part of the
---name, so opening the same template twice never collides on the name.
---@param text string
---@param label string  shown in the confirmation
---@return boolean
local function open_buffer(text, label)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "hide"
  vim.api.nvim_buf_set_name(buf, ("cdx-prompt://%d/%s"):format(buf, label))
  -- Fails in a 'winfixbuf' window (E1513) or with 'nohidden' over a modified buffer (E37): no orphan buffer then.
  local shown, serr = pcall(vim.api.nvim_win_set_buf, 0, buf)
  if not shown then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    notify.error(("Could not open %s: %s"):format(label, tostring(serr)))
    return false
  end
  notify.info(("Opened %s (%d chars)"):format(label, vim.fn.strchars(text)))
  return true
end

---@param text string
---@param label string  shown in the confirmation
---@param open? boolean  open as a buffer instead of copying to the clipboard
---@return boolean
local function copy(text, label, open)
  if open then
    return open_buffer(text, label)
  end
  if not copy_to_clipboard(text) then
    notify.error("Could not write to the clipboard")
    return false
  end
  notify.info(("Copied %s (%d chars)"):format(label, vim.fn.strchars(text)))
  return true
end

---Copy a template; `tokens` (SHAs) replace `{SHA}` when it has the placeholder and there are any.
---@param typed string  the name as typed
---@param tokens string[]
---@param open? boolean  open the text as a buffer instead of copying it
---@return boolean
function M.copy_prompt(typed, tokens, open)
  local file, rerr = M.resolve(typed)
  if not file then
    notify.error(rerr or "unknown prompt template")
    return false
  end
  local text, err = read_template(file)
  if not text then
    notify.error(err or "template not readable")
    return false
  end
  local has_placeholder = text:find(SHA_PLACEHOLDER, 1, true) ~= nil
  if #tokens == 0 then
    return copy(text, file, open)
  end
  if not has_placeholder then
    notify.warn(
      ("%s has no %s placeholder; the arguments are ignored"):format(file, SHA_PLACEHOLDER)
    )
    return copy(text, file, open)
  end
  local shas, perr = M.parse_shas(tokens)
  if not shas then
    notify.error(perr or "invalid SHA")
    return false
  end
  -- Function replacement: the SHA list is data, `%` in it must not be read as
  -- a capture reference.
  local filled = text:gsub(vim.pesc(SHA_PLACEHOLDER), function()
    return table.concat(shas, SHA_JOIN)
  end)
  return copy(filled, ("%s (%d SHA)"):format(file, #shas), open)
end

---@return nil
function M.enable()
  composer.register_type("CDX_PROMPT", {
    desc = "Name of a template in docs/NOTES/CDX/templates/PROMPT (file name without .md)",
    validate = function(raw)
      local file, err = M.resolve(raw)
      if not file then
        return false, nil, err
      end
      return true, raw, nil
    end,
    complete = function(arg_lead)
      local out, low = {}, (arg_lead or ""):lower()
      for _, name in ipairs(M.names()) do
        if name:lower():sub(1, #low) == low then
          out[#out + 1] = name
        end
      end
      return out
    end,
  })

  composer.verb("Cdx", {
    desc = "Claude Code helpers: copy CDX prompt templates to the clipboard",
    routes = {
      {
        path = { "prompt" },
        args = {
          {
            name = "name",
            type = "CDX_PROMPT",
            desc = "Template of the PROMPT folder, without .md (base and review are short names)",
          },
          {
            name = "sha",
            type = "STRING",
            optional = true,
            desc = "Commit SHA of 4 to 64 hex digits for {SHA}; more may follow",
          },
        },
        desc = "Copy a prompt template (any .md of PROMPT/) to the clipboard; SHAs (space- or comma-separated) replace {SHA}, none keeps it",
        flags = {
          {
            name = "open",
            bool = true,
            desc = "Open the text as a buffer instead of copying it to the clipboard",
          },
        },
        run = function(ctx)
          local tokens = {}
          if ctx.args.sha then
            tokens[#tokens + 1] = ctx.args.sha
          end
          vim.list_extend(tokens, ctx.rest)
          M.copy_prompt(ctx.args.name, tokens, ctx.flags.open)
        end,
      },
    },
  })
end

return M
