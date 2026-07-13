---@module 'config.neotree.keymaps.filesystem'
--- Entry point that merges all filesystem keymap modules into a single mapping table.
--- Only files.lua remains; every other module was handled by filetree.nvim.

-- Modules handled by filetree.nvim (removed, files deleted):
--   filter, save, replace, mark, navigation, path, info, search,
--   preview, images, pdfport, trash, clipboard, create, commands
-- Each removal follows the same pattern: filetree.nvim's own feature
-- (default-on) binds the same key via a buffer-local vim.keymap.set on
-- FileType, so a second native implementation here was pure dead weight
-- racing the same key -- e.g. the old `trash` module bound `d` a second time
-- and raced filetree's own `d`, causing intermittent buffer-close bugs.
-- Confirmed duplicates removed in this pass: clipboard.lua (c/x/p/<C-c> vs
-- copy_move), create.lua (a/r/D vs smart_create/smart_rename/diff),
-- commands.lua (i/tf/tg/ML/MR/MM vs shell_run/find_files/grep_in_dir/
-- markdown_links), and files.lua's B/<S-CR>/gb/sg/sv/st (vs reveal_alt/
-- open_variants) -- see the trimmed files.lua for what stayed and why.
-- Remaining: neotree-native operations only.
local modules = {
  require("config.neotree.keymaps.filesystem.files"),
}

---@type table<string, any>
local mappings = {}

for _, mod in ipairs(modules) do
  for key, value in pairs(mod) do
    mappings[key] = value
  end
end

return mappings
