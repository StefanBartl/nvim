# Verbesserungsliste

## jetzt durchführen

### 1. Autocmds zentralisieren — ✅ erledigt

Alle `vim.api.nvim_create_autocmd`/`api.nvim_create_autocmd`-Aufrufe im Repo (ca. 50 Dateien, ~90 Call-Sites) sind auf `lib.nvim.autocmd.create` migriert — reine mechanische Verschiebung des `callback`-Felds in den zweiten Positionsparameter, `group`/`pattern`/`desc`/`once`/`nested` unverändert durchgereicht. Augroup-Erzeugung (`nvim_create_augroup`) selbst wurde nicht angefasst, nur die Registrierung profitiert jetzt von `lib.nvim.autocmd`s pcall-geschützter Fehlerbehandlung.

Bewusst nicht migriert: zwei Fälle in `autocmds/terminals/init.lua` (`kitty_enter`/`kitty_leave`), die `command = "..."`-Strings statt `callback`-Funktionen nutzen — `Autocmd.create` erwartet eine Callback-Funktion, eine Umstellung wäre keine reine mechanische Änderung mehr.

### 2. High-Frequency-Events budgetieren — ✅ erledigt (für die drei genannten Stellen)

[indent_scope.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/features/indent_scope.lua), [cword_occurrences/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/cword_occurrences/init.lua) und [breadcrumbs/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/breadcrumbs/init.lua) nutzen jetzt `lib.nvim.debounce` statt eigenem/keinem Timer.

Ein gemeinsamer Dispatcher pro Eventklasse (statt nur Debounce pro Feature) bleibt offen — analog zum bestehenden `FileType`-Dispatcher in `autocmds/events/utils/filetype.lua`.

### 6. Low-Level-Module ohne UI-Seiteneffekte halten — ✅ erledigt (im Scope dieses Repos)

[lsp/core/capabilities.lua](C:/Users/bartl/AppData/Local/nvim/lua/lsp/core/capabilities.lua) gibt jetzt `caps, warnings` (bzw. `ok, warnings` bei `apply_globally`) zurück statt selbst `vim.notify` aufzurufen; der Call-Site in [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua) übernimmt das Notifying über `lib.nvim.notify`.

FS-/PDF-Port-Backendbereiche (zweites im Roadmap-Punkt genanntes Beispiel) leben in eigenen Repos (`fileops.nvim`, `pdfport.nvim`) außerhalb von `lua/` dieses Repos — hier nicht im Zugriff, müsste dort separat angegangen werden.

---

## Später erledigt (beim Testen gefunden, nicht Teil der ursprünglichen Liste)

- `lua/lsp/usercmds/recovery.lua:150` ruft `M.health_check(bufnr)` auf, das nirgends definiert ist — `:LspRecover` crasht deshalb immer. Vorbestehender Bug, nicht durch diese Session verursacht; als eigene Aufgabe ausgelagert statt hier mitgefixt.

---

## Later (noch nicht durchführen)

### 1. **Startup-Phasen konsequenter machen**

Out [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua:80) wird LSP direkt geladen, obwohl der Kommentar noch BufReadPost/Lazy andeutet. Gleichzeitig werden `wkdoptions`, `autocmds`, `custom`, `usrcmds`, `mappings` per Timer geladen. Verbesserung: Startup-Plan als echte Policy dokumentieren und messen: was muss synchron sein, was kann auf `VeryLazy`, `BufReadPost`, `FileType`, `CmdlineEnter`.

---
