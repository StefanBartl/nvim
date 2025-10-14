# sessions – portable Neovim-Sessions ohne Drittplugins

## Überblick

Dieses Modul speichert und lädt Neovim-Sessions ausschließlich mit Bordmitteln (:mksession/:source). Ziel ist ein portabler, robuster Workflow über mehrere Geräte hinweg, ohne separate Repos oder externe Abhängigkeiten.

## Eigenschaften

• Speicherort unter stdpath("config")/sessions
• Saubere Trennung: config, core, commands, types
• Minimalistische sessionoptions für Stabilität auf unterschiedlichen Hosts
• Blacklist für flüchtige Buffer (quickfix, nofile, prompt), temporäre Pfade und volatile Filetypes
• Autoload der „last“-Session beim Start ohne Dateiargumente
• Autosave beim Beenden
• Klare User-Commands und wenige, merkbare Keymaps

## Verzeichnisstruktur

```sh
nvim/lua/sessions/
  init.lua
  config.lua
  core.lua
  commands.lua
  types/types.lua
nvim/init.lua
```

## Installation

1) Dateien in den oben genannten Pfad legen.
2) In der Neovim-Config (nvim/init.lua) einbinden:
   require("sessions")
3) Optional Neovim neu starten.

## Konfiguration

• nvim/lua/sessions/config.lua definiert alle Optionen zentral.
• Wichtigste Felder:
  root            = vim.fn.stdpath("config") .. "/sessions"
  default_name    = "last"
  sessionoptions  = "buffers,curdir,tabpages,winsize,help,folds"
  blacklist = {
    buftypes  = { "quickfix", "nofile", "prompt" },
    filetypes = { "gitcommit", "gitrebase" },
    paths     = { "/tmp/", "/private/tmp/" },
  }

Warum diese Defaults?
• sessionoptions bewusst klein halten, damit Sessions zwischen Geräten stabil bleiben.
• terminal/globals/localoptions sind absichtlich nicht enthalten, um Host-Divergenzen zu vermeiden.
• Blacklists verhindern, dass temporäre Zustände oder Editor-Hilfsfenster persistiert werden.

## Benutzung

• Session speichern:
  :SessionSave                → speichert unter default_name („last“)
  :SessionSave NAME           → speichert unter NAME
• Session laden:
  :SessionLoad                → lädt default_name („last“)
  :SessionLoad NAME           → lädt NAME (mit Completion)
• Sessions auflisten:
  :SessionList
• Keymaps (Normal-Mode):
  <leader>ss  → :SessionSave
  <leader>sl  → :SessionLoad
  <leader>sn  → timestamped :SessionSave (z. B. sess-20250924-104200)
  <leader>sh  → :SessionList

**Autoload/Autosave**
• Beim Start ohne Dateiargumente wird automatisch versucht, die default_name-Session zu laden.
• Vor dem Beenden wird die default_name-Session automatisch gespeichert.

**Portabilität und Pfade**
• root liegt unter stdpath("config")/sessions. Das ist bewusst user-/hostlokal, aber überall identisch strukturiert.
• Datei-Namen sind reine Labels (NAME.vim). Inhalte verweisen auf lokal existierende Pfade. Für identische Ergebnisse sollten Projektpfade auf allen Geräten konsistent sein (z. B. via gleichartiger Workspace-Struktur).

**Sicherheit und Datenschutz**
• Keine geheimen Variablen oder Tokens in Sessiondateien ablegen; die Module speichern bewusst keine globals/localoptions.
• Temporäre bzw. sensible Buffertypen werden vor dem Speichern entfernt.

**Erweiterungen (optional)**
• Host-spezifische Defaults: default_name = vim.loop.os_gethostname()
• Terminal-Persistenz: „terminal“ zu sessionoptions hinzufügen (nur wenn Shell-Umgebungen wirklich identisch sind).
• Dashboard-Integration: Eine Taste „Restore last session“ kann in Snacks.dashboard ergänzt werden (siehe frühere Beispiele).

**Fehlersuche**
• Beim Laden „no such session“ → Datei existiert nicht im root. Mit :SessionList prüfen.
• Nach Plugin- oder LSP-Änderungen inkonsistenter Zustand → :SessionSave mit neuem Namen und versprachlichen state neu einfangen.
• Unerwünschte Fenster werden gespeichert → Blacklist in config.lua erweitern.

## Entwurfskriterien

• Klare Verantwortlichkeiten: config (Daten), core (Funktionen), commands (UX), types (Annotationen).
• Defensive Programmierung: pcall-Guards, keine UI-Seitenwirkungen im Low-Level.
• Performance: keine Pattern-Suche im Hot-Path, einfache Präfixprüfungen, begrenzte Serialisierung.

## API für andere Module

```lua
local S = require("sessions")
S.save(name?)   → (ok, path_or_err)
S.load(name?)   → (ok, path_or_err)
S.list()        → { "/abs/path/to/name.vim", ... }
```

---
