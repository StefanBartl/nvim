---@module 'translate.usercommands'
---Defines usercommands for translate.nvim

local replace = require("config.translate.replace")
local nvim_create_user_command = vim.api.nvim_create_user_command
local desc_tag = "[translate.nvim]: "

nvim_create_user_command("TranslateReplace", function(opts)
  local start_line = opts.line1
  local end_line = opts.line2
  local target_lang = opts.args

  if target_lang == "" then
    vim.notify("Please specify a target language, e.g., :TranslateReplace EN", vim.log.levels.WARN)
    return
  end

  replace.replace_range(start_line, end_line, target_lang)
end, {
  nargs = 1,
  range = true,
  complete = function()
    return { "EN", "DE", "FR", "ZH", "JA" }
  end,
  desc = desc_tag .. "Translate selected text and replace it",
})
