# Verbesserungsliste

## jetzt durchführen

### 1. Autocmds zentralisieren — ✅ erster Schritt erledigt

Viele Module nutzen direkt `vim.api.nvim_create_autocmd`, obwohl `lib.nvim.autocmd` existiert. Migriert wurden die drei genannten Beispiele: [options.lua](C:/Users/bartl/AppData/Local/nvim/lua/options.lua:78) (inkl. zweitem `OptionSet`-Autocmd), [hl_config/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/init.lua:212) sowie dessen [core/state.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/core/state.lua) (`get_augroup` delegiert jetzt an `lib.nvim.autocmd.get_augroup`), und [astro/autocmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/lsp/languages/webdev/astro/autocmds.lua). Damit profitieren diese Stellen von der pcall-geschützten Fehlerbehandlung in `lib.nvim.autocmd.create`.

Rest (ca. 60 weitere Fundstellen laut Bestandsaufnahme) bewusst noch offen — weiter "nach und nach" migrieren, keine Big-Bang-Änderung an ungetesteten Stellen.

### 2. High-Frequency-Events budgetieren — ✅ erster Schritt erledigt

Mehrere Features laufen auf `CursorMoved`, `WinScrolled`, `TextChanged`, `BufEnter`. Die drei genannten Stellen nutzen jetzt `lib.nvim.debounce` statt eigenem/keinem Timer: [indent_scope.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/features/indent_scope.lua) (vorher ungedrosselt, nur `vim.schedule`), [cword_occurrences/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/cword_occurrences/init.lua) (vorher handgerollter `uv.timer`, jetzt `lib.nvim.debounce.new`, pro `M.enable()`-Aufruf neu erzeugt damit `debounce_ms`-Config-Änderungen greifen), [breadcrumbs/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/breadcrumbs/init.lua) (vorher synchron bei jedem Event).

Ein gemeinsamer Dispatcher pro Eventklasse (statt nur Debounce pro Feature) bleibt offen — analog zum bestehenden `FileType`-Dispatcher in `autocmds/events/utils/filetype.lua`.

### 3. Direkte `vim.notify`, `print`, `vim.keymap.set` reduzieren — ✅ Beispiel erledigt

Die Checklisten wollen `lib.notify`, `lib.map`, `lib.usercmd`. [bindings/mappings/git.lua](C:/Users/bartl/AppData/Local/nvim/lua/bindings/mappings/git.lua) (tatsächlicher Pfad, nicht `mappings/git.lua`) nutzt jetzt durchgängig `lib.nvim.notify`, `vim.g.__map_helper` (`lib.nvim.map`) und `lib.nvim.usercmd.create` statt roher `vim.notify`/`vim.keymap.set`/`nvim_create_user_command`-Aufrufe.

Weitere ca. 60+ `vim.notify`- und ~15 `vim.keymap.set`-Fundstellen im restlichen Repo bleiben offen (siehe Bestandsaufnahme vom 2026-07-17 im Projektgedächtnis).

### 4. Buffer/Window-Handles in Deferred/Scheduled-Code härten — ✅ erster Schritt erledigt

Die drei in Punkt 2 migrierten Feature-Module snapshotten jetzt `winid`/`bufnr` beim Event und validieren sie (`nvim_win_is_valid`/`nvim_buf_is_valid`, bei breadcrumbs zusätzlich Vergleich mit dem aktuellen Fenster) bevor der verzögerte Callback tatsächlich arbeitet. `breadcrumbs/winbar.lua` hatte dieses Pattern für den reinen Fenster-Write bereits vorher.

### 5. Konfig-Duplikate und Altpläne aufräumen — ✅ erledigt

`config/menu-update` existiert nicht (mehr) — nur `config/menu/` ist vorhanden, hier gibt es aktuell kein Duplikat aufzuräumen. Die drei toten, auskommentierten Alt-Pläne in [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua) (BufReadPost-gated LSP-Lazyload, `astro_lsp_standalone`-defer, neo-tree-"tests"-Fix) wurden entfernt; Git-History bewahrt sie bei Bedarf.

### 6. Low-Level-Module ohne UI-Seiteneffekte halten — ✅ Beispiel erledigt

[lsp/core/capabilities.lua](C:/Users/bartl/AppData/Local/nvim/lua/lsp/core/capabilities.lua) gibt jetzt `caps, warnings` (bzw. `ok, warnings` bei `apply_globally`) zurück statt selbst `vim.notify` aufzurufen; der Call-Site in [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua) übernimmt das Notifying über `lib.nvim.notify`. Der zweite bestehende Call-Site in `lsp/init.lua` prüfte Completion-Capabilities bereits selbst und notifyt unverändert dort.

FS-/PDF-Port-Backendbereiche (zweites im Roadmap-Punkt genanntes Beispiel) noch nicht durchgesehen.

---

## Later (noch nicht durchführen)

### 1. **Startup-Phasen konsequenter machen**

Out [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua:80) wird LSP direkt geladen, obwohl der Kommentar noch BufReadPost/Lazy andeutet. Gleichzeitig werden `wkdoptions`, `autocmds`, `custom`, `usrcmds`, `mappings` per Timer geladen. Verbesserung: Startup-Plan als echte Policy dokumentieren und messen: was muss synchron sein, was kann auf `VeryLazy`, `BufReadPost`, `FileType`, `CmdlineEnter`.

---
