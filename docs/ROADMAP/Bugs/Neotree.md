Ich analysiere die Bugs in deiner Neovim Neo-tree Konfiguration und erstelle Fixes:Ich habe eine umfassende Bugfix-Suite für deine Neo-tree Probleme erstellt. Hier ist die Zusammenfassung der Fixes:

## 1. **EPERM Error (friert Neovim ein)**
- **Problem**: File watchers bleiben aktiv während Löschvorgängen
- **Fix**:
  - Watchers werden komplett gestoppt BEVOR gelöscht wird
  - EPERM errors werden während Refresh unterdrückt
  - Längere Delays für Filesystem-Operationen

## 2. **Invalid 'window' Error nach Renaming**
- **Problem**: Window handles werden invalid während Navigation
- **Fix**:
  - Window-Validierung vor jeder Operation
  - Protected calls mit Fallbacks
  - Besseres Error handling in `sync_now()`

## 3. **Preview Error (truth field nil)**
- **Problem**: Preview bricht wenn Neo-tree als Buffer angezeigt wird
- **Fix**:
  - Validierung ob wir in echtem Neo-tree Window sind
  - Safe preview cleanup mit pcall
  - Fallback-Mechanismen für Preview-Operationen

## 4. **Neo-tree fällt auf CWD root zurück**
- **Problem**: Auto-reveal überschreibt manuelle Navigation
- **Fix**:
  - User-Navigation wird getracked (`user_navigated` flag)
  - 2-Sekunden Grace-Period nach manueller Navigation
  - `updir` markiert sich als User-Action
  - Debounce erhöht auf 150ms

## 5. **Linker Neo-tree schließt und öffnet rechts**
- **Problem**: `force_position_left` zu aggressiv
- **Fix**:
  - Prüft ob wirklich ein problematisches rechtes Window existiert
  - Nur relocate wenn tatsächlich nötig
  - Schließt rechtes Window BEVOR links geöffnet wird

## Installation

Ersetze die entsprechenden Funktionen in diesen Files:
1. `lua/config/neotree/trash.lua` - cleanup & refresh Funktionen
2. `lua/config/neotree/cwd_sync.lua` - sync_now & schedule_sync
3. `lua/config/neotree/keymaps/init.lua` - `<CR>` und `<Tab>` mappings
4. `lua/config/neotree/updir.lua` - up_one_level Funktion
5. `lua/plugins/neotree.lua` - debounce_ms auf 150 erhöhen

Die Fixes sind defensiv programmiert mit vielen pcalls und Validierungen, sodass auch bei unerwarteten Zuständen keine Crashes mehr auftreten sollten.
