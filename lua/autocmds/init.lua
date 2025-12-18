---@module 'autocmds'
--- Initialize module for 'autocmds'

--FIX: Modularisere die submodule in eigene module
--FIX: Default's implementieren und h ier dann nur die notwendigstsen setzen

-- AUDIT: Wenn keine Probleme, dann dauerhaft implementieren:
require("autocmds.auto-center-fexplorer").setup()


-- Teste einen einzelnen Patch mit vollem Logging
require("autocmds.patches").setup({ verbose = true })
require("autocmds.patches.usercommands").setup()
require("autocmds.patches").apply_all_async()

  -- Integration with Lazy.nvim
  -- local group = vim.api.nvim_create_augroup("LocalPluginPatches", { clear = true })
-- require("autocmds.patches").apply_async({
--   keys = { "gitsigns-system-compat" },
--   callback = function(results)
--     print("\n=== RESULT ===")
--     print(vim.inspect(results[1]))
--   end
-- })


-- require("autocmds.patches")
-- local function measure_patch_time()
--   local start = vim.loop.now()
--
--   require("autocmds.patches").apply_all_async(function(results)
--     local duration = vim.loop.now() - start
--
--     local total = #results
--     local succeeded = vim.tbl_count(vim.tbl_filter(function(r)
--       return r.success
--     end, results))
--
--     vim.notify(
--       string.format(
--         "Patches applied: %d/%d in %.2fs (avg: %.2fs per patch)",
--         succeeded,
--         total,
--         duration / 1000,
--         duration / 1000 / math.max(1, total)
--       ),
--       vim.log.levels.INFO
--     )
--   end)
-- end
--
-- -- Keymap für Performance-Test
-- vim.keymap.set("n", "<leader>pat", measure_patch_time, {
--   desc = "Measure patch application time",
-- })
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "LazyUpdate",
--   callback = function()
--     vim.notify("Patching started...", 2)
--     -- Warte auf System-Patches (500ms + 100ms Buffer)
--     vim.defer_fn(function()
--       local status = require("autocmds.patches").get_status({
--         status_filter = { "failed" },
--       })
--
--       if #status > 0 then
--         vim.notify(
--           string.format(
--             "⚠️  %d patches failed after LazyUpdate. Check :lua require('autocmds.patches').show_logs_buffer()",
--             #status
--           ),
--           vim.log.levels.WARN
--         )
--       end
--     end, 600)
--   end,
--   desc = "Check patch status after LazyUpdate",
-- })

------------------------------------------------------
--- General
------------------------------------------------------

require("autocmds.general").enable({
  kitty = {
    enable = true, -- Sets Kitty padding/margin to compact values on VimEnter and restores them on VimLeavePre.
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },
  auto_mkdir = {
    enable = true, -- Creates missing parent directories on BufWritePre, optionally skipping URL/remote-like paths.
    skip_remote = true,
  },
  cursorline = {
    enable = false, -- Toggles the local 'cursorline' option on focus/normal events and hides it on insert/leave events.
    show_events = { "InsertLeave", "WinEnter" },
    hide_events = { "InsertEnter", "WinLeave" },
  },
  last_loc = {
    enable = false, -- On BufReadPost, jumps back to the last cursor position unless the filetype is excluded.
    exclude = { "gitcommit", "commit", "gitrebase" },
  },
  goto_file = {
    enable = true,
    debug = false,
  },
})

------------------------------------------------------
--- Git
------------------------------------------------------

local ok_g, git = pcall(require, "autocmds.git")
if ok_g then
  git.enable(true)
end

------------------------------------------------------
--- Markdown
------------------------------------------------------

-- require("autocmds.markdown").enable()

------------------------------------------------------
--- Terminals
------------------------------------------------------

require("autocmds.terminals").enable({
  numbers = {
    enable = true, -- On terminal open, turns off local 'number' and 'relativenumber' to declutter terminal panes.
    events = { "TermOpen" },
  },
  kitty = {
    enable = true, -- In Kitty, applies compact padding/margin on VimEnter and restores defaults on VimLeavePre.
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },
  auto_insert = {
    enable = false, -- Automatically enters Insert mode in terminal buffers; add "TermEnter" to events if desired.
    events = { "TermOpen" },
  },
})

------------------------------------------------------
--- Text
------------------------------------------------------

require("autocmds.text").enable({
  trim_trailing = {
    enable = true, -- On BufWritePre, removes trailing whitespace at end-of-line in normal, modifiable buffers.
    pattern = "*",
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  trim_blank = {
    enable = true, -- On BufWritePre, cleans whitespace-only (blank) lines; restores the exact cursor position afterwards.
    pattern = "*",
    preserve_cursor = true,
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  last_loc = {
    enable = true, -- On BufReadPost, jumps back to the last saved cursor position unless filetype is excluded.
    pattern = "*",
    exclude = { "commit", "gitrebase", "xxd" },
    min_line = 1,
  },
})
