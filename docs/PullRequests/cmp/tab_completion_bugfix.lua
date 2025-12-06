---File: nvim-data\lazy\nvim-cmp\lua\cmp\config\mapping.lua
---@module 'config.cmp.tab_completion_bugfix'
--- This module addresses an Insert-mode Tab issue caused by nvim-cmp.
---
--- Fix Insert-mode <Tab> issue in NvChad with nvim-cmp.
--- Problem: Pressing <Tab> to indent text in Insert mode is intercepted
--- by nvim-cmp, which causes cursor shifts and extra spaces instead of
--- inserting a real Tab character.
--- Solution: Override <Tab> mapping to insert a real Tab when no completion
--- menu is visible, while still allowing navigation through completion items.
---
--- Problem:
--- In Insert mode, pressing <Tab> to indent text does not behave as expected.
--- Normally, a Tab should move the cursor and shift the word, respecting
--- 'tabstop', 'shiftwidth', and 'softtabstop'. However, with nvim-cmp active,
--- <Tab> is remapped to trigger completion navigation, so pressing Tab at the
--- beginning of a word inserts a space before the first character instead of
--- shifting the word correctly. For example:
---
---   Before pressing Tab:
---   local
---
---   After pressing Tab at start of line:
---   l   ocal
---
--- The root cause is that nvim-cmp maps <Tab> in Insert mode to select the
--- next completion item, overriding the standard Tab behavior.
---
--- Solution:
--- 1. Manuell fix:
--- `<C-V><Tab>` in Insert-Modus inserts a true tab character.
--- 2. Programmatic fix:
--- The recommended approach is to modify the <Tab> mapping to conditionally
--- fallback to the default Tab insertion when no completion menu is visible.
--- This ensures that normal Tab behavior is preserved outside of completion.
---
--- Note:
--- If this module does not fix the issue, it may be due to:
--- 1. Another plugin or mapping overriding <Tab> after this module is loaded.
--- 2. The module being required before nvim-cmp is fully initialized.
--- 3. Misordering in the plugin configuration (e.g., lazy-loading).
---
--- In such cases:
--- - Ensure this module is loaded **after** nvim-cmp is setup.
--- - Use `:verbose imap <Tab>` to check which mapping is active.
--- - Make sure no other plugin (snippets, completion, keymaps) remaps <Tab> afterwards.

---@diagnostic disable

local cmp = require("cmp")

-- Function to insert a real Tab character if completion menu is not visible
---@diagnostic disable-next-line: unused-local
local function insert_real_tab(_fallback)
  if cmp.visible() then
    cmp.select_next_item()
  else
    -- Insert a real Tab character regardless of expandtab/softtabstop
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-V><Tab>", true, false, true), "n", false)
  end
end

-- Override cmp default mapping for <Tab>
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(insert_real_tab, { "i", "s" }),
  }),
})



--- ==== Teil 1:

mapping.preset.insert = function(override)       --- Zeile 36
  return merge_keymaps(override or {}, {
    ['<Tab>'] = {                                --- NEU
      i = function()
        local cmp = require('cmp')
        if cmp.visible() then
          cmp.select_next_item()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-V><Tab>', true, false, true), 'n', false)
        end
      end,
      s = function()
        local cmp = require('cmp')
        if cmp.visible() then
          cmp.select_next_item()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-V><Tab>', true, false, true), 'n', false)
        end
      end,
    },
    ['<Down>'] = {                              --- Zeile 58
      i = mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Select }),
    },

--- ==== Teil 2:

    ['<Tab>'] = {                                --- Zeile 105
      c = function()
        local cmp = require('cmp')
        if cmp.visible() then
          cmp.select_next_item()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-V><Tab>', true, false, true), 'n', false) --- NEU, statt cmp.complete()
        end
      end,
    },                                           --- Zeile 114
