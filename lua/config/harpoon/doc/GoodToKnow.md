# Harpoon v2 – Good to know

* beschreibt, wie Harpoon v2 in dieser Konfiguration arbeitet
* erklärt zentrale Begriffe (Project Key, Autosave, Sanitize, Dedup, Labels)
* dokumentiert Besonderheiten: stabile Projekt-Erkennung, sichere Persistenz, deduplizierte Liste, gekürzte Pfad-Labels, FZF-UI, Windows/UNC-Support
* zeigt Integrationsschritte und häufige Fehlerbilder mit Abhilfe

## Funktionsumfang im Überblick

* einmaliges, robustes `harpoon:setup()` mit stabilem Project-Key (Git-Root → `cwd`)
* Autosave beim Schließen des Quick-Menus, zusätzlich auf Editor-Events (`BufLeave`, `FocusLost`)
* Sanitize/Dedup der Items ohne hartes Ersetzen der internen Tabellen
* UI-Liste mit gekürzten Pfad-Labels, plattformübergreifend (Linux/macOS/Windows inkl. UNC)
* FZF-basierte Harpoon-Liste auf `<C-h>`; Fallback auf das Harpoon-Quick-Menu, falls `fzf-lua` nicht vorhanden ist
* Debug-Command `:HarpoonDebug` (aktueller Zustand/Labels)
* defensive Guards und klare Rückgaben, kompatibel mit strengen Lint/Coding-Regeln

## Glossar der wichtigsten Begriffe

* project key: eindeutiger Schlüssel, unter dem Harpoon eine Liste speichert. In dieser Konfiguration ist das standardmäßig der Git-Root des aktuellen Projekts (Fallback: absolutes `cwd`). So bleibt die Liste stabil, auch wenn man in Unterordnern arbeitet.
* autosave: Persistiert Listenänderungen automatisch bei UI-Aktionen und ausgewählten Editor-Events, um in-memory-Verlust zu vermeiden.
* sanitize: Normalisiert Einträge auf ein einheitliches Format (`{ value=..., context={row=..., col=...} }`).
* dedup: Entfernt Dubletten anhand eines normalisierten, realpath-basierten Schlüssels (Windows-Laufwerk groß, Slashes vereinheitlicht).
* label: gekürzte Anzeigeform eines absoluten Pfads für die UI (z. B. `C:/..../mynotes/spickzettel.md`, `~/..../some/file.lua`, `//SERVER/Share/..../proj/file.txt`).
* quick menu: Harpoon-eigene Liste/Popup; in dieser Konfiguration zusätzlich eine FZF-Variante mit denselben Daten.
* UNC: Windows-Netzpfade über `//SERVER/Share/...`; werden korrekt als Root erfasst und in Labels beibehalten.

## Verzeichnisstruktur der Konfigurationsmodule

```
lua/
  types/harpoon.lua              # zentrale Typ-Definitionen (EmmyLua)
  utils/safe_call.lua            # strukturierte pcall-/Fehler-Wrapper
  utils/fs_project_key.lua       # stabile Project-Key-Ermittlung
  utils/path_label.lua           # Pfad -> gekürztes UI-Label (plattformübergreifend)
  utils/harpoon_sanitize.lua     # sanitize + dedup (ohne Full-Replace)
  ui/harpoon_menu_fzf.lua        # FZF-basierte Harpoon-Liste (Fallback: Quick-Menu)
  dev/harpoon_debug.lua          # :HarpoonDebug (Zustandsdump)
  config/harpoon_hardening.lua   # orchestriert Setup, Autosave, Keymaps, Debug
```

## Integration

1. Module in das Neovim-Runtime legen (siehe Struktur).
2. Harpoon-Plugin wie gewohnt installieren (v2).
3. Härtung nach dem Laden des Plugins initialisieren:

```lua
-- init.lua or a plugin config file
-- All comments in English by convention.

-- Require once after harpoon is available:
require("config.harpoon_hardening").setup()
```

4. vorhandene doppelte Setup-Aufrufe oder manuelles Ersetzen von `list.items` entfernen.

## Pfad-Labels in der UI

* Darstellung ist stets absolut, aber kompakt: `<root>..../<parent>/<file>`
* Root bleibt sichtbar:

  * Home: `~/...`
  * Unix: `/...` oder `/mnt/xy/...`
  * Windows-Laufwerk: `C:/...` (Drive-Letter wird stabil groß geschrieben)
  * UNC: `//SERVER/Share/...`
* Beispiele:

  * `C:/..../mynotes/spickzettel.md`
  * `~/..../some/file.lua`
  * `/mnt/xy/..../some/huhu.c`
  * `//SERVER/Share/..../proj/file.txt`

## Project-Key (Stabilität pro Projekt)

* Ziel: innerhalb eines Projekts immer dieselbe Liste – unabhängig von `:cd`, Rooter-Plugins oder Unterordnern.
* Standard: Git-Root, Fallback `cwd`, normalisierte Schreibung (Slash-Separator, Drive-Letter groß).
* Anpassung möglich (z. B. LSP-Workspace-Root, Markerdateien).

```lua
-- Example: override the key function if needed
local harpoon = require("harpoon")
harpoon:setup({
  settings = {
    key = function()
      -- return a custom absolute, normalized project key string
      return require("utils.fs_project_key").project_key()
    end,
  },
})
```

## Autosave-Strategie

* `save_on_toggle = true`, `sync_on_ui_close = true` bei Harpoon
* zusätzlicher Save auf `BufLeave`/`FocusLost` (deferred, um Races zu vermeiden)
* Save-Hook nach `ui.toggle_quick_menu()` (deferred über `vim.schedule`)
* Ziel: Änderungen werden auch bei Hot-Reloads/Modul-Neuladen zuverlässig persistiert.

## Sanitize & Dedup

* Sanitize: sorgt dafür, dass alle Items einheitlich ausgestattet sind (`value`, `context`).
* Dedup: entfernt Dubletten anhand von `fs_realpath`/normalisierten Pfaden; Reihenfolge stabil außer entfernten Duplikaten.
* wichtig: kein Full-Replace von `list.items` → UI/Interner Zustand bleibt konsistent.

## FZF-UI auf `<C-h>` (Fallback Quick-Menu)

* Wenn `fzf-lua` vorhanden ist, öffnet `<C-h>` eine FZF-Liste mit denselben Items und gekürzten Labels.
* Aktionen: Enter (edit), Ctrl-v (vsplit), Ctrl-x (split), Ctrl-t (tab).
* Preview verwendet `bat` (falls vorhanden) oder `cat`.
* Ohne `fzf-lua` fällt `<C-h>` auf das Harpoon-Quick-Menu zurück.

```lua
-- Keymap installed by config/harpoon_hardening.lua:
-- <C-h> opens FZF-based Harpoon list (fallback to Quick Menu)
-- Preview scroll/hotkeys can be tuned via fzf-lua "--bind" if desired.
```

## Windows- und UNC-Besonderheiten

* Pfade werden intern für Vergleiche/Schlüssel normalisiert (`\` → `/`, Drive-Letter groß).
* UNC-Wurzeln (`//SERVER/Share`) bleiben als Root erhalten, Labels beginnen entsprechend mit `//SERVER/Share/..../...`.
* Die Anzeige nutzt stets `/` als Trennzeichen; beim Öffnen werden Originalpfade verwendet.

## Häufige Ursachen für „leere Liste“ und Abhilfe

* Project-Key wechselt (Rooter, `:cd`, abweichende Pfad-Schreibweise) → stabilen Key wie oben beschrieben verwenden.
* Doppeltes `setup()`/Re-Initialisierung → sicherstellen, dass nur einmal initialisiert wird.
* Items wurden per Full-Replace überschrieben → nur in-place bereinigen/entfernen.
* Sehr frühes Speichern vor vollständigem Laden → Save/Normalize „deferred“ ausführen (bereits berücksichtigt).
* Unterschiedliche Listenquellen (benannte Listen vs. Default) → Keymaps/Kommandos auf die gleiche Quelle ausrichten.

## Performance-Hinweise

* keine großen Tabellenkopien; Pre-Allocation für temporäre Arrays
* `table.remove` nur t nur das Quick-Menu zur Verfügung; die Label-Kürzung betrifft die FZF-Ansicht und den Debug-Dump, nicht automatisch das Harpoon-Popup

## Minimalbeispiele (Code)

```lua
-- Example: quick binding to open the hardened FZF menu (already set by the module)
vim.keymap.set("n", "<C-h>", function()
  require("ui.harpoon_menu_fzf").open()
end, { desc = "Harpoon menu (short labels)" })
```

```lua
-- Example: on-demand dedup/sanitize trigger (useful during debugging)
vim.api.nvim_create_user_command("HarpoonNormalize", function()
  local harpoon = require("harpoon")
  local list = harpoon:list()
  require("utils.harpoon_sanitize").sanitize_items_in_place(list)
  require("utils.harpoon_sanitize").dedup_in_place_safe(list)
  pcall(harpoon.save, harpoon)
end, {})
```

```lua
-- Example: show current project key (optional helper)
vim.api.nvim_create_user_command("HarpoonKey", function()
  print(require("utils.fs_project_key").project_key())
end, {})
```

## Checkliste zur Validierung dieser Konfiguration

* einmaliges `harpoon:setup()` vorhanden
* `settings.key` liefert stabilen, normalisierten Root-Pfad
* Autosave aktiv (UI-Close + Editor-Events)
* Sanitize/Dedup ohne Full-Replace implementiert
* `<C-h>` öffnet die Liste; FZF-Variante aktiv, Quick-Menu als Fallback
* Labels sind gekürzt und führen Root (Home/`/`/Drive/UNC) sichtbar
* Windows/UNC getestet; Drive-Letter wird groß geschrieben
* Debug-Command verfügbar (`:HarpoonDebug`)
rückwärts (bei Massen-Entfernung)
* I/O-Saves kurz entkoppelt (Scheduler-Tick)
* Label-Erzeugung ist rein funktional und schnell; `fs_realpath` wird sparsam eingesetzt

## Debug und Tests

* `:HarpoonDebug` zeigt eine Momentaufnahme: Anzahl, Index und Label jeder Zeile.
* optional: eigener Command `:HarpoonKey` kann den aktuellen Project-Key ausgeben (einfach ergänzbar).
* Sanitize/Dedup sind pure Functions und lassen sich separat unit-testen.

## Konfiguration anpassen

```lua
-- English-only comments; tune as needed.

local ok, harpoon = pcall(require, "harpoon")
if not ok then return end

harpoon:setup({
  settings = {
    -- Choose the key strategy that fits your workspace
    key = require("utils.fs_project_key").project_key,  -- default in this setup
    save_on_toggle = true,
    sync_on_ui_close = true,
  },
})

-- Optional: prefer LSP root if present
-- harpoon:setup({
--   settings = { key = my_lsp_root_or_git_or_cwd }
-- })
```

## Migrationshinweise

* frühere Autocmd-basierte Re-Setup-Routinen entfernen
* direkte Zuweisungen wie `list.items = ...` durch in-place-Operationen ersetzen
* Keymaps auf die FZF-Variante oder das Quick-Menu vereinheitlichen
* bestehende State-Dateien werden weiterverwendet; Dubletten werden einmalig reduziert

## Bekannte Grenzen

* wenn ein Projekt bewusst mehrere Listen benötigt, muss man einen anderen `settings.key` wählen (z. B. per Markerdatei je Teilprojekt)
* extrem tiefe UNC-Pfade oder Spezialfälle mit ungewöhnlichen Mounts können eine manuelle Label-Policy erfordern (die Label-Funktion ist leicht erweiterbar)
* ohne `fzf-lua` steh
