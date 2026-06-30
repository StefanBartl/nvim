# Neo-tree Autocmds, Usercmds und Event-Handler Übersicht

## Table of content

  - [Autocmds](#autocmds)
  - [Event-Handler](#event-handler)
  - [Usercmds](#usercmds)

---

## Autocmds

Augroup: `NeoTreeStatuslineDisable` (mit `clear = true` bei jeder Initialisierung neu erzeugt)

| Event | Pattern/Bedingung | Info |
| --- | --- | --- |
| `FileType` | pattern = `neo-tree` | Primärer, zuverlässigster Trigger: setzt `vim.wo.statusline = " "` (Statusline im Neo-tree-Fenster ausblenden) |
| `BufWinEnter` | Callback prüft `vim.bo[buf].filetype == "neo-tree"` | Zusätzliche Absicherung für den Fall, dass `FileType` nicht greift (z. B. bei Fensterwechsel auf existierenden Neo-tree-Buffer) |
| `WinEnter` | kein Pattern, generischer Callback | Fallback: ruft `neotree_statusline.disable_for_neotree_buffers` auf, periodische Prüfung bestehender Fenster |

Aktivierung erfolgt über `M.attach()`, welches intern `setup_disable_stl()` aufruft.

---

## Event-Handler

Neo-tree-interne Event-Handler, registriert über die `event_handlers`-Konfiguration des Plugins (kein `nvim_create_autocmd`, sondern Neo-tree-eigenes Event-System).

| Event | Info |
| --- | --- |
| `neo_tree_buffer_enter` | Macht den Cursor im Neo-tree-Fenster unsichtbar (`highlight! Cursor blend=100`), obwohl das Fenster fokussiert ist |
| `neo_tree_buffer_leave` | Macht den Cursor beim Verlassen des Neo-tree-Fensters wieder sichtbar (`highlight! Cursor guibg=#5f87af blend=0`) |
| `neo_tree_window_after_open` | Stellt sicher, dass nach dem Öffnen von Neo-tree nicht nur das Neo-tree-Fenster als normales Fenster übrig bleibt (deferred via `layout_guard.ensure_editor_window_deferred()`) |
| `neo_tree_preview_buffer_enter` | Setzt den Cursor im neu angezeigten Preview-Buffer auf Zeile 1, Spalte 0 zurück (Scroll-Position-Reset bei jeder neuen Datei-Vorschau) |

---

## Usercmds

Registrierung erfolgt über `M.enable()`.

| Command | Info |
| --- | --- |
| `:NeoTreeCheckHealth` | Führt Neo-tree-Config-Healthchecks aus (`config.neotree.checkhealth.check()`) |
| `:NeoTreeDebugSources` | Debug-Ausgabe zur Source-Erkennung (`config.neotree.sources.switcher.debug_sources()`) |
| `:NeoTreePdfPort` | pdfport-Integration: öffnet den Modus-Picker für den aktuellen Node im Filesystem-State (`actions.pdfport.open`). Bricht mit Warnung/Fehler ab, falls `neo-tree.sources.manager` oder ein aktiver Filesystem-State fehlt |
| `:NeoTreePdfPortQuick` | pdfport-Integration: öffnet den PDF-Node des aktuellen Filesystem-State direkt als Text via pdftotext, ohne Picker (`actions.pdfport.open_quick`). Gleiche Guard-Bedingungen wie bei `:NeoTreePdfPort` |

---

