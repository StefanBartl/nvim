---@module 'usrcmds'
-- Initialize module for 'usrcmds'

--AUDIT :
local emojis = require("usrcmds.emojis")
emojis.setup({
  -- Ändert das Standard-Verhalten, falls kein Scope übergeben wird
    -- Gültig: "word", "line", "visual", "%", "cwd"
  default_scope = "%",
})
-- vim.keymap.set({ "n", "i" }, "<C-o>", "<cmd>Emojis insert<cr>", { desc = "Emoji: Picker öffnen" })
-- vim.keymap.set("n", "<leader>ec", "<cmd>Emojis count %<cr>", { desc = "Emoji: Zählen im Puffer" })
-- vim.keymap.set("n", "<leader>el", "<cmd>Emojis list %<cr>", { desc = "Emoji: In Quickfix auflisten" })

require("usrcmds.copy").enable()
require("usrcmds.gather").setup({ lua = true })
require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.newfile").enable_usercmds()
require("usrcmds.migrate").setup({
    opt = true,    -- `:MigrateOpt`
    notify = true, -- `MigrateNotify`
})
require("usrcmds.reload").enable()
require("usrcmds.update_repos").enable()
require("usrcmds.uv_doc").enable_usercmd()

require("usrcmds.list.autocmd_audit").enable()
--FIX:
vim.api.nvim_create_user_command("CwdHere", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local dir = vim.fn.fnamemodify(bufname, ":p:h")
    vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  end
end, {})

---TODO: AUDIT:
vim.api.nvim_create_user_command('PowershellProfile', function()
    -- Startet eine schnelle PowerShell-Abfrage im Hintergrund, um den echten Pfad zu ermitteln
    local handle = io.popen('powershell -NoProfile -Command "[Console]::Write($PROFILE)"')
    if handle then
        local profile_path = handle:read("*a")
        handle:close()

        -- Wenn ein Pfad zurückgegeben wurde, öffne ihn in Neovim
        if profile_path and profile_path ~= "" then
            vim.cmd('edit ' .. vim.fn.fnameescape(profile_path))
            return
        end
    end
    print("Fehler: Der PowerShell Profil-Pfad konnte nicht ermittelt werden.")
end, { desc = 'Öffnet das aktuelle PowerShell-Profil' })
