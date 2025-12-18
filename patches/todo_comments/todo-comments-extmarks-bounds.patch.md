# todo-comments.nvim – Fix: Invalid end_col in extmarks

## Table of content

  - [Plugin](#plugin)
  - [Problem](#problem)
  - [Lösung](#lsung)
  - [Patch-Typ](#patch-typ)
  - [Upstream-Status](#upstream-status)
  - [Hinweise bei Patch-Fehlschlag](#hinweise-bei-patch-fehlschlag)
  - [Referenz](#referenz)
  - [3. Erwartetes Verhalten beim späteren Hook (Ausblick)](#3-erwartetes-verhalten-beim-spteren-hook-ausblick)

---

## Plugin
- Name: todo-comments.nvim
- Datei: lua/todo-comments/highlight.lua
- Funktion: add_highlight

---

## Problem

Beim Scrollen oder schnellen Redraws tritt sporadisch folgender Fehler auf:

```vim
Invalid 'end_col': out of range
```

Ursache ist ein ungültiger `end_col`-Wert beim Aufruf von
`nvim_buf_set_extmark`, typischerweise größer als die tatsächliche
Zeilenlänge oder negativ.

Mögliche Trigger:
- Multibyte-Zeichen
- Race-Conditions beim Scrollen
- inkonsistente Match-Positionen aus der Plugin-Logik

Der Fehler ist fatal und beendet den Highlight-Callback.

---

## Lösung

Vor dem Setzen des Extmarks werden:

- die Zielzeile defensiv gelesen
- `from` und `to` validiert
- beide Werte auf `[0, #line]` geklemmt
- ungültige Bereiche verworfen (`from > to`)

Damit wird garantiert, dass Extmarks niemals außerhalb der Zeile liegen.

---

## Patch-Typ

- defensiver Bounds-Check
- keine API-Änderung
- keine semantische Änderung bei korrekten Eingaben

---

## Upstream-Status

- Lokal gepatcht
- Geeignet für PR
- Entfernen, sobald upstream ein äquivalenter Fix gemerged ist

---

## Hinweise bei Patch-Fehlschlag

Wenn dieser Patch nicht mehr anwendbar ist, bedeutet das sehr
wahrscheinlich:

- die Datei wurde upstream refaktoriert
- oder der Bug wurde bereits behoben

In diesem Fall:
- Patch manuell prüfen
- vergleichen, ob `add_highlight` bereits validiert
- Patch ggf. entfernen

---

## Referenz

Fehler:

```vim
Error executing vim.schedule lua callback:
.../todo-comments/highlight.lua: Invalid 'end_col'
```

---

---

## 3. Erwartetes Verhalten beim späteren Hook (Ausblick)

Dieser Patch ist so gestaltet, dass ein zukünftiger Hook:

* Patch erfolgreich angewendet → still
* Patch schlägt fehl → **explizite Ausgabe**, z. B.:

```vim
[patch] todo-comments-extmark-bounds.patch FAILED (possibly fixed upstream)
```

---

