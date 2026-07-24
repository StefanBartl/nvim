---@module 'bindings.usrcmds'
-- Initialize module for 'bindings.usrcmds'

local usercmd = require("lib.nvim.usercmd")

--FIX: Funktoinert, aber einen neotree/nvimtree/netrw reload muss ausgelöst werden damit dieser aktualisert das neue cwd in ihm.
usercmd.create("CwdHere", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local dir = vim.fn.fnamemodify(bufname, ":p:h")
    vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  end
end, { force = true })

usercmd.create('PowershellProfile', function()
    if vim.fn.executable("powershell") ~= 1 then
        print("Fehler: powershell ist auf diesem System nicht verfügbar.")
        return
    end
    -- argv array instead of io.popen with an embedded shell string
    local res = vim.system(
        { "powershell", "-NoProfile", "-Command", "[Console]::Write($PROFILE)" },
        { text = true }
    ):wait()
    local profile_path = res.code == 0 and res.stdout or nil

    if profile_path and profile_path ~= "" then
        vim.cmd('edit ' .. vim.fn.fnameescape(profile_path))
        return
    end
    print("Fehler: Der PowerShell Profil-Pfad konnte nicht ermittelt werden.")
end, { desc = 'Öffnet das aktuelle PowerShell-Profil', force = true })
