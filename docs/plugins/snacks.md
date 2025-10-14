# snacks todo

## dashboard

---

### sessions

 - delete wäre gut mit 'd' oder leader d
 - ganz rechts symbole wie C-1, -C2, C-3 zur schnellauswahl

---

#### sessions dashboard auch nach vim enter wenn kein window mehr da ist

Kurzfassung der Ursache
Sehr wahrscheinlich triggert Snacks beim „leeren“ Editor (wenn kein gelisteter Buffer mehr offen ist) ein eigenes Autocommand (typisch um BufEnter/BufDelete herum), das das Dashboard erneut öffnet. Dieses Re-Open verwendet intern ein „on-empty“-Layout/Pre-Set der Sections. Wenn das Layout für diesen Pfad nicht explizit überschrieben wurde, nimmt Snacks hier die Default-Sections („header“, „keys“, „startup“) – eure benutzerdefinierte „Sessions“-Section erscheint dann nicht.

Warum es beim Start klappt, aber nach „letzter Buffer geschlossen“ nicht
Beim Start greift euer in `snacks.setup({ dashboard = { sections = … } })` gesetztes Layout. Beim „on-empty“-Reopen greift hingegen ein separater Codepfad, der (je nach Version) die Sections nicht aus der Setup-Konfiguration übernimmt, sondern eine eigene Defaultliste verwendet. Ergebnis: Das Dashboard kommt zurück, aber ohne „Sessions“.

Zwei robuste Fix-Varianten (wählt genau eine)

Variante A: Layout beim Re-Open erzwingen (nicht invasiv; kompatibel)
Man hakt sich bei Erzeugung des Dashboard-Buffers ein (FileType `snacks_dashboard`) und fordert sofort einen Re-Draw mit euren Sections an. Das wirkt nur beim Dashboard selbst und lässt andere Snacks-Features unberührt.

```lua
-- snacks_dashboard_on_empty_fix.lua
-- English comments inside code by request.

---@param dash_sections fun(): table
---@return nil
local function ensure_dashboard_sections(dash_sections)
  -- Try to (re)open/redraw dashboard with our section list.
  local ok_dash, dash = pcall(require, "snacks.dashboard")
  if not ok_dash then return end

  -- If Snacks exposes a redraw, prefer it. Otherwise call open() with overrides.
  local sections = dash_sections()
  if type(dash.redraw) == "function" then
    -- Some versions support redraw with an opts table
    pcall(dash.redraw, { sections = sections })
  else
    -- Fallback: open (idempotent if already on dashboard)
    pcall(dash.open, { sections = sections })
  end
end

-- Provide your section list as a function to avoid upvalue staleness.
---@return table
local function my_sections()
  return {
    { section = "header" },
    { section = "keys", gap = 1, padding = 1 },
    { title = "Sessions", icon = "󰆓 ", section = "my_sessions", indent = 2, padding = 1 },
    { section = "startup" },
  }
end

-- Autocmd: whenever the dashboard buffer is (re)created, enforce our sections.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_dashboard",
  callback = function()
    ensure_dashboard_sections(my_sections)
  end,
  desc = "Snacks dashboard: enforce custom sections also on empty-reopen",
})
```

Voraussetzung: Eure `dash.sections.my_sessions = function(item) ... end` bleibt wie in eurem Code vor `snacks.setup()` registriert.

Variante B: „Open“-Wrapper nur für das Dashboard (invasiver, aber effektiv)
Man dekoriert `snacks.dashboard.open()` einmalig und injiziert die gewünschte Sections-Liste, falls keine explizit übergeben wurde. So ist garantiert, dass alle Aufrufe – auch die aus Snacks’ on-empty-Autocmd – eure Sections sehen.

```lua
-- snacks_dashboard_open_patch.lua
-- English comments inside code by request.

do
  local ok_dash, dash = pcall(require, "snacks.dashboard")
  if ok_dash and type(dash) == "table" and type(dash.open) == "function" then
    local orig_open = dash.open

    -- Return our standard sections list
    local function my_sections()
      return {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { title = "Sessions", icon = "󰆓 ", section = "my_sessions", indent = 2, padding = 1 },
        { section = "startup" },
      }
    end

    -- Patch open(): inject sections if missing
    dash.open = function(opts)
      opts = opts or {}
      -- Only add if caller did not specify sections explicitly
      if opts.sections == nil then
        opts.sections = my_sections()
      end
      return orig_open(opts)
    end
  end
end
```

Empfohlene zusätzliche Checks

1. Verifizieren, dass eure Section wirklich registriert bleibt

```lua
:lua print(type((require('snacks.dashboard').sections or {}).my_sessions))
-- Erwartet: "function"
```

2. Sicherstellen, dass nicht eine andere Config Snacks erneut „lean“ setzt
   Wenn irgendwo ein zweites `snacks.setup` (oder eine Lazy-Spec mit `opts = {...}` ohne euren Eintrag) geladen wird, überschreibt das eure Dashboard-Konfiguration. In Lazy prüfen: genau eine Quelle, die `dashboard.sections` setzt.

3. Session-Pfad unabhängig vom CWD halten
   Ihr nutzt `stdpath("config")/lua/sessions/storage` – das ist gut. Falls sich euer Loader an ein anderes Verzeichnis gebunden hat, die Logik in `my_sessions_section` mit einem `vim.notify` im Fehlerfall instrumentieren.

4. Race-Conditions beim (Neu-)Laden vermeiden
   Falls `my_sessions_section` das Modul `sessions` braucht: `pcall(require, "sessions")` beibehalten und Fehler melden; beim leeren Editor kann Lazy ggf. noch Module entladen haben.

Minimaländerung direkt in eurer bestehenden Datei
Wenn man Variante A möchte, könnte man am Ende eurer `config = function(_, opts)` nach `snacks.setup(opts)` folgendes anhängen:

```lua
-- Enforce custom sections on dashboard re-open (empty editor case)
do
  -- English comments inside code by request:
  local function my_sections()
    return {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { title = "Sessions", icon = "󰆓 ", section = "my_sessions", indent = 2, padding = 1 },
      { section = "startup" },
    }
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "snacks_dashboard",
    callback = function()
      local ok_dash, dash = pcall(require, "snacks.dashboard")
      if not ok_dash then return end
      -- Prefer redraw if present; otherwise open with overrides
      if type(dash.redraw) == "function" then
        pcall(dash.redraw, { sections = my_sections() })
      else
        pcall(dash.open, { sections = my_sections() })
      end
    end,
    desc = "Ensure Sessions section also when dashboard opens on empty",
  })
end
```

Ergebnis
Mit dieser kleinen Ergänzung bleibt die „Sessions“-Section sowohl beim initialen Start als auch beim automatischen Re-Open des Dashboards nach dem Schließen des letzten Buffers konsistent sichtbar – unabhängig davon, welchen internen Pfad Snacks für das on-empty-Dashboard nutzt.

---

## end

--
