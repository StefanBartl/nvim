---@module 'lib.debug.terminals.keylogger'
-- Terminal-Keylogger für Neovim
-- Startet und stoppt Keylogging über User-Commands.
-- Alle gedrückten Keys im Terminal-Modus werden über vim.notify angezeigt.

local M = {}

-- interne Variable, ob Logging aktiv ist
M.logging = false
M.bufnr = nil

-- Funktion, die alle gedrückten Keys im Terminal puffert
local function log_key()
    -- nur wenn Logging aktiv ist
    if not M.logging then return end

    -- aktuelle Puffer-ID prüfen
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= "terminal" then
        return
    end

    -- getcharstr blockiert, daher über vim.schedule wiederholt aufrufen
    vim.schedule(function()
        if not M.logging then return end
        local ok, key = pcall(vim.fn.getcharstr)
        if ok and key then
            vim.notify(string.format("[terminal_keylogger] Key pressed: %q", key), vim.log.levels.INFO)
        end
        -- wieder rekursiv aufrufen, solange Logging aktiv ist
        if M.logging then
            log_key()
        end
    end)
end

-- Startfunktion
function M.start()
    if M.logging then
        vim.notify("[terminal_keylogger] Already logging!", vim.log.levels.WARN)
        return
    end
    M.logging = true
    M.bufnr = vim.api.nvim_get_current_buf()
    vim.notify("[terminal_keylogger] Started logging keys in this terminal buffer. Press keys now.", vim.log.levels.INFO)
    log_key()
end

-- Stopfunktion
function M.stop()
    if not M.logging then
        vim.notify("[terminal_keylogger] Not currently logging!", vim.log.levels.WARN)
        return
    end
    M.logging = false
    vim.notify("[terminal_keylogger] Stopped logging keys.", vim.log.levels.INFO)
end

-- User-Commands
vim.api.nvim_create_user_command("TerminalKeyLoggerStart", function()
    M.start()
end, { desc = "Start logging all keys in current terminal buffer" })

vim.api.nvim_create_user_command("TerminalKeyLoggerStop", function()
    M.stop()
end, { desc = "Stop logging keys in current terminal buffer" })

return M
