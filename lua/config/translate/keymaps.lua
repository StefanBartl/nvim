---@module 'translate.keymaps'
---Defines keymaps for translate.nvim

local map = require("lib.map")
local desc_tag = "[translate.nvim]: "

map("v", "<leader>tr", ":TranslateReplace DE<CR>", { desc = desc_tag .. "Visual mode keymap for quick translation" })
