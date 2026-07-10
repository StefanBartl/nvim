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

  -- Fügt das aktuelle Datum ein (z. B. 10.07.2026) buffer-ctx.nvim!
  vim.keymap.set("n", "<leader>date", function()
    vim.api.nvim_put({ os.date("%d.%m.%Y") }, "c", false, true)
  end, { desc = "Datum einfügen" })

  -- ==========================================
  -- 1-3. Bullet-/Nummerierungs-/Checkbox-Umschalter (- , 1. , - [ ])
  -- Ausgelagert nach cascade.nvim (lua/cascade/lists/quick_toggle.lua):
  -- <A-->/<A-0>/<A-c>, per lists.features.{bullet,number,checkbox}_toggle
  -- an/abschaltbar, siehe lua/plugins/personal/init.lua.
  -- ==========================================

  -- ==========================================
  -- 4. Systeminformationen anzeigen und in die Zwischenablage kopieren (Cross-Platform)
  -- ==========================================

  --- Baut das Kommando zur Systeminformations-Abfrage als Argument-Tabelle statt als
  --- Shell-String. Neovim führt Listen-Kommandos direkt aus (ohne 'shell'/cmd.exe),
  --- wodurch die ursprünglichen Quoting-Probleme (^M-Reste, leere Felder durch
  --- kaputt escapte Anführungszeichen) gar nicht erst entstehen.
  local function build_system_info_cmd()
    if vim.fn.executable("fastfetch") == 1 then
      return { "fastfetch", "--logo", "none" }
    elseif vim.fn.executable("neofetch") == 1 then
      return { "neofetch", "--off" }
    end

    if vim.fn.has("win32") == 1 then
      local ps_exe = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
      local ps_script = [[
$ErrorActionPreference = 'SilentlyContinue'
$os    = Get-CimInstance Win32_OperatingSystem
$cs    = Get-CimInstance Win32_ComputerSystem
$cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu   = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join ', '
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$uptime = (Get-Date) - $os.LastBootUpTime

Write-Output "OS           : $($os.Caption)"
Write-Output "Version      : $($os.Version)"
Write-Output "Architecture : $($os.OSArchitecture)"
Write-Output "Hostname     : $($cs.Name)"
Write-Output "Manufacturer : $($cs.Manufacturer)"
Write-Output "Model        : $($cs.Model)"
Write-Output "CPU          : $($cpu.Name.Trim())"
Write-Output "RAM          : $ramGB GB"
Write-Output "GPU          : $gpu"
Write-Output "User         : $env:USERNAME"
Write-Output "Uptime       : $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
]]
      return { ps_exe, "-NoProfile", "-NonInteractive", "-Command", ps_script }
    elseif vim.fn.has("mac") == 1 then
      local script = [[
echo "OS           : $(sw_vers -productName) $(sw_vers -productVersion)"
echo "Build        : $(sw_vers -buildVersion)"
echo "Architecture : $(uname -m)"
echo "Hostname     : $(scutil --get ComputerName 2>/dev/null || hostname)"
echo "Model        : $(sysctl -n hw.model)"
echo "CPU          : $(sysctl -n machdep.cpu.brand_string)"
echo "RAM          : $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
echo "GPU          : $(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model/{print $2; exit}')"
echo "User         : $(whoami)"
echo "Uptime       : $(uptime | sed 's/.*up //;s/,.*load.*//')"
]]
      return { "/bin/bash", "-c", script }
    else
      local script = [[
echo "OS           : $( . /etc/os-release 2>/dev/null; echo "$PRETTY_NAME" )"
echo "Kernel       : $(uname -r)"
echo "Architecture : $(uname -m)"
echo "Hostname     : $(hostname)"
echo "Manufacturer : $(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo unknown)"
echo "Model        : $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo unknown)"
echo "CPU          : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
echo "RAM          : $(free -h --si 2>/dev/null | awk '/Mem:/{print $2}')"
echo "GPU          : $(lspci 2>/dev/null | grep -Ei 'vga|3d controller' | cut -d: -f3 | sed 's/^ //' | paste -sd ', ')"
echo "User         : $(whoami)"
echo "Uptime       : $(uptime -p 2>/dev/null)"
]]
      local sh = vim.fn.executable("bash") == 1 and "bash" or "sh"
      return { sh, "-c", script }
    end
  end

  --- Führt das Kommando aus, kopiert das Ergebnis in die Zwischenablage und
  --- zeigt es in einem Floating Window an.
  local function show_system_info()
    local ok, data = pcall(vim.fn.systemlist, build_system_info_cmd())
    if not ok then
      vim.notify("Systeminfo-Abfrage fehlgeschlagen: " .. tostring(data), vim.log.levels.ERROR)
      return
    end

    -- CRLF-Reste (^M) entfernen und leere Zeilen rausfiltern
    local lines = {}
    for _, line in ipairs(data) do
      line = line:gsub("\r$", "")
      if line:match("%S") then
        lines[#lines + 1] = line
      end
    end

    if #lines == 0 then
      vim.notify("Systeminformationen konnten nicht abgerufen werden.", vim.log.levels.ERROR)
      return
    end

    -- In die Zwischenablage kopieren
    local full_text = table.concat(lines, "\n")
    vim.fn.setreg("+", full_text) -- System-Zwischenablage (Ctrl+V)
    vim.fn.setreg("*", full_text) -- Maus-Zwischenablage (Mittelklick)
    vim.notify("System-Infos in die Zwischenablage kopiert", vim.log.levels.INFO)

    -- Floating Window anzeigen
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    local width = math.min(60, vim.o.columns - 10)
    local height = math.min(#lines + 2, vim.o.lines - 5)

    local win = vim.api.nvim_open_win(buf, true, {
      style = "minimal",
      relative = "editor",
      width = width,
      height = height,
      row = math.ceil((vim.o.lines - height) / 2 - 1),
      col = math.ceil((vim.o.columns - width) / 2),
      border = "rounded",
      title = " System Information ",
      title_pos = "center",
    })
    vim.wo[win].wrap = false

    for _, key in ipairs({ "q", "<Esc>" }) do
      vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
    end
  end

  vim.api.nvim_create_user_command("SystemInfo", show_system_info, {})
  vim.keymap.set("n", "<leader>si", show_system_info, {
    desc = "Zeige System-Informationen & kopiere sie",
    silent = true,
  })

    -- ==========================================
  -- 5. Char changing (TODO: auch nach cascade.nvim auslagern!)
  -- ==========================================chen mit dem rechten Nachbarn tauschen (Ctrl+Shift+Rechts)
  -- Zeichen mit dem rechten Nachbarn tauschen (Leader + Pfeiltaste Rechts)
  vim.keymap.set('n', '<leader><Right>', 'xp', { desc = 'Tausche aktuellen Char mit rechts' })
  -- Zeichen mit dem linken Nachbarn tauschen (Leader + Pfeiltaste Links)
  vim.keymap.set('n', '<leader><Left>', 'xhP', { desc = 'Tausche aktuellen Char mit links' })


end

return M
