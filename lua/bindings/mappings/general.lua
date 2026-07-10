---@module 'bindings.mappings.general'

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  map("n", "<C-a>", "gg<S-v>G", { desc = "[General] Select all" })

  -- map({ "n", "i", "v", "t" }, "<C-s>", function()
  --   if vim.fn.mode() ~= "n" then
  --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  --   end
  --   vim.cmd "silent! w!"
  -- end, { desc = "[General] Save file silently" })
  map({ "n", "v", "t" }, "<C-s>", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")
    vim.api.nvim_win_set_cursor(0, pos)
  end, { desc = "[General] Save file" })
  map("i", "<C-s>", function() --- explicit because of vim.lsp.buf.signature_help()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")
    vim.api.nvim_win_set_cursor(0, pos)
  end, { desc = "[General] Save file", noremap = true })

  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })
  map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
  map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })
  map(
    { "n", "i", "v", "t", "c" },
    "<F1>",
    "<Nop>",
    { desc = "[General] Disable F1", silent = true }
  )

 -- TODO: personal plugins auslagern + usrcmds ertellen
  -- Fügt das aktuelle Datum ein (z. B. 10.07.2026) buffer-ctx.nvim!
  vim.keymap.set(
    "n",
    "<leader>date",
    'i<C-r>=strftime("%d.%m.%Y")<CR><Esc>',
    { desc = "Datum einfügen" }
  )

  -- ==========================================
  -- 1. ALT + - : Bullet Point Umschalter (- )
  -- ==========================================
  vim.keymap.set("n", "<A-->", function()
    local line = vim.api.nvim_get_current_line()
    -- Erkennt die Einrückung (Leerzeichen/Tabs) am Anfang der Zeile
    local indent = line:match("^([%s]*)")
    -- Entfernt die Einrückung temporär für die Prüfung
    local content = line:sub(#indent + 1)

    if content:match("^%- ") then
      -- Wenn bereits "- " vorhanden ist, wegschneiden
      local new_content = content:sub(3)
      vim.api.nvim_set_current_line(indent .. new_content)
    else
      -- Ansonsten "- " einfügen
      vim.api.nvim_set_current_line(indent .. "- " .. content)
    end
  end, { desc = "Toggle Bullet Point (-)" })

  -- ==========================================
  -- 2. ALT + 0 : Nummerierungs-Umschalter (X. )
  -- ==========================================
  vim.keymap.set("n", "<A-0>", function()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local indent = line:match("^([%s]*)")
    local content = line:sub(#indent + 1)

    -- Prüfen, ob die aktuelle Zeile bereits mit einer Nummerierung startet (z. B. "1. " oder "12. ")
    if content:match("^%d+%. ") then
      -- Wenn ja, Nummerierung wegschneiden
      local _, end_idx = content:find("^%d+%. ")
      local new_content = content:sub(end_idx + 1)
      vim.api.nvim_set_current_line(indent .. new_content)
    else
      -- Wenn nein, ermitteln wir die nächste logische Nummer
      local next_num = 1

      -- Zeile darüber prüfen (falls wir nicht in Zeile 1 sind)
      if row > 1 then
        local prev_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1]
        local prev_content = prev_line:match("^[%s]*(.*)")
        -- Suchen, ob die Zeile darüber mit einer Zahl + Punkt startet
        local prev_num_str = prev_content:match("^(%d+)%. ")
        if prev_num_str then
          next_num = tonumber(prev_num_str) + 1
        end
      end

      -- Nummerierung einfügen (z. B. "1. " oder "2. ")
      vim.api.nvim_set_current_line(indent .. next_num .. ". " .. content)
    end
  end, { desc = "Toggle Smart Numbered List" })

--[[ BUG:
-- gibt momentan nur aus:
^M
^M
OS             :
Version        : 10.0.26200
OSArchitecture : 64-bit
^M
^M
]]--

-- Funktion, um Systeminformationen anzuzeigen und in die Zwischenablage zu kopieren
local function show_system_info()
  local cmd = ""

  -- 1. Versuch: Externe CLI-Tools prüfen
  if vim.fn.executable("fastfetch") == 1 then
    cmd = "fastfetch --stdout"
  elseif vim.fn.executable("neofetch") == 1 then
    cmd = "neofetch --off"
  else
    -- 2. Fallback: OS-native Bordmittel verwenden
    if vim.fn.has("win32") == 1 then
      -- Kompakter PowerShell-Befehl, der garantiert Text zurückgibt
      cmd = 'powershell -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | Select-Object @{N=\'OS\';E={$_.Caption}}, Version, OSArchitecture | Format-List | Out-String"'
    elseif vim.fn.has("mac") == 1 then
      cmd = "sw_vers && system_profiler SPHardwareDataType | grep -E 'Model Name|Processor|Memory|Chip:'"
    else
      -- Linux Fallback
      cmd = "hostnamectl 2>/dev/null || (cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
    end
  end

  -- Befehl ausführen und Output als Tabelle (Zeilen) zurückerhalten
  -- systemlist verhindert das Einfrieren besser bei reinen CLI-Befehlen
  local data = vim.fn.systemlist(cmd)

  -- Fehlerprüfung: Falls gar nichts zurückgegeben wurde
  if not data or #data == 0 or (#data == 1 and data[1] == "") then
    print("Fehler: Systeminformationen konnten nicht abgerufen werden.")
    return
  end

  -- --- ZWISCHENABLAGE LOGIK ---
  -- Konvertiert die Tabelle in einen durchgehenden String für die Zwischenablage
  local full_text = table.concat(data, "\n")
  vim.fn.setreg("+", full_text) -- System-Zwischenablage (Ctrl+V)
  vim.fn.setreg("*", full_text) -- Maus-Zwischenablage (Mittelklick)
  print("📋 System-Infos erfolgreich in die Zwischenablage kopiert!")

  -- --- FLOATING WINDOW LOGIK ---
  -- Erstelle einen neuen, leeren Scratch-Buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)

  -- Berechne die Größe des Floating Windows (zentriert)
  local width = math.min(80, vim.o.columns - 10)
  local height = math.min(#data + 2, vim.o.lines - 5)
  local row = math.ceil((vim.o.lines - height) / 2 - 1)
  local col = math.ceil((vim.o.columns - width) / 2)

  -- Fenster-Optionen
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " 🖥️ System Informationen (Kopiert!) ",
    title_pos = "center",
  }

  -- Fenster öffnen
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Tasten zum Schließen des Fensters definieren
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
  vim.wo[win].wrap = false
end

-- 1. Erstelle das Benutzer-Kommando :SystemInfo
vim.api.nvim_create_user_command("SystemInfo", show_system_info, {})

-- 2. Erstelle die Keymap (<Leader>si für SystemInfo)
vim.keymap.set("n", "<Leader>si", ":SystemInfo<CR>", {
  desc = "Zeige System-Informationen & kopiere sie",
  silent = true
})
end

return M
