---@module 'config.translate.usercommands'
---Defines usercommands for translate.nvim
---
---Responsibilities:
---- provide a single user command :TranslateReplace that accepts:
---  - a required language code (first argument)
---  - optional flags such as --nocode to skip fenced and inline code
---- keep parsing small and explicit; delegate translation work to replace module
local replace = require("config.translate.replace")
local nvim_create_user_command = vim.api.nvim_create_user_command
local desc_tag = "[translate.nvim]: "

---Helper: parse args array to extract language and flags
---@param fargs string[] array of command arguments (split by whitespace)
---@return string target_lang, boolean nocode
local function parse_args(fargs)
  -- default values
  local target_lang = ""
  local nocode = false

  if not fargs or #fargs == 0 then
    return target_lang, nocode
  end

  -- first non-flag token is treated as language
  for _, tok in ipairs(fargs) do
    if not tok:match("^%-%-") and target_lang == "" then
      target_lang = tok
    end
  end

  -- detect --nocode anywhere in args
  for _, tok in ipairs(fargs) do
    if tok == "--nocode" or tok == "-nocode" then
      nocode = true
      break
    end
  end

  return target_lang, nocode
end

nvim_create_user_command("TranslateReplace", function(opts)
  -- opts.line1/line2 are the range (1-based)
  local start_line = opts.line1
  local end_line = opts.line2

  -- opts.fargs contains split arguments (may include flags)
  local target_lang, nocode = parse_args(opts.fargs)

  if target_lang == "" then
    vim.notify("Please specify a target language, e.g., :TranslateReplace EN", vim.log.levels.WARN)
    return
  end

  replace.replace_range(start_line, end_line, target_lang, { nocode = nocode })
end, {
  nargs = "+", -- at least one argument (language); optionally flags
  range = true,
  complete = function(ArgLead)
    -- provide basic completion for language codes and the --nocode flag
    local completions = { "EN", "DE", "FR", "ZH", "JA", "--nocode" }
    -- simple prefix filtering
    local res = {}
    for _, v in ipairs(completions) do
      if v:lower():match("^" .. vim.pesc(ArgLead):lower()) then
        table.insert(res, v)
      end
    end
    return res
  end,
  desc = desc_tag .. "Translate selected text and replace it. Use --nocode to skip fenced and inline code.",
})
