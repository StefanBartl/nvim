# Code-Architektur & API-Zentralisierung

## Table of content

  - [Autocmds zentralisieren](#autocmds-zentralisieren)
  - [Wrapper-Funktionen erzwingen](#wrapper-funktionen-erzwingen)
  - [Robustheit (Buffer/Window-Handles)](#robustheit-bufferwindow-handles)
  - [UI-Entkopplung](#ui-entkopplung)
  - [`lib.nvim` & UI-Kit Integration](#libnvim-ui-kit-integration)

---

## Autocmds zentralisieren

* [ ] **Problem:** Viele Module nutzen direkt `vim.api.nvim_create_autocmd`, obwohl `lib.autocmd` existiert.
  * *Verbesserung:* Nach und nach auf `lib.autocmd` bzw. den vorhandenen FileType-Dispatcher migrieren (für einheitliche Fehlerbehandlung, Gruppen und zuverlässiges Reload-Verhalten).

---

## Wrapper-Funktionen erzwingen

* [ ] **Problem:** Direkte Aufrufe von `vim.notify`, `print` und `vim.keymap.set` reduzieren. Die Checklisten verlangen die Nutzung von `lib.notify`, `lib.map` und `lib.usercmd`.
  * *Betroffene Dateien:* Direkte Treffer u. a. in `sessions/usercmds.lua:61`.
  * *Verbesserung:* Produktive Module migrieren; Debug- und Testmodule dürfen ggf. separat markiert bleiben.

---

## Robustheit (Buffer/Window-Handles)

* [ ] **Problem:** Einige Callbacks arbeiten verzögert (Deferred/Scheduled-Code) mit einem implizit aktuellen Window oder Buffer.
  * *Betroffene Dateien:* `pathprobe/init.lua:306`, `neotree/commands/clipboard/init.lua:286`
  * *Verbesserung:* Beim Scheduling `bufnr/winid` via Snapshot sichern und vor der tatsächlichen Nutzung erneut validieren.

---

## UI-Entkopplung

* [ ] **Problem:** Einige Core-nahe Module (Low-Level-Module) melden Fehler oder Status direkt per UI-Notify (z. B. LSP-Capabilities oder FS-/PDF-Port-Backendbereiche).
  * *Verbesserung:* Low-Level-Module geben stattdessen strukturiert `{ ok, err }` zurück. Die UI-Schicht entscheidet eigenständig über das `notify`. Das macht die Fehlerbehandlung konsistent.

---

## `lib.nvim` & UI-Kit Integration

* [ ] Jednefalls aus `lib.nvim` implementieren:
  * [ ] Aus `lib.nvim.ui.kit` z. B. `nice_quit` für alle Aufrufe von Windows prüfen und die entsprechende Variante aus dem UI-Kit implementieren.
  * [ ] Source code check, ob noch mehr von `lib.nvim` verwendet werden kann. Wenn ja, dann gleich implementieren

---
