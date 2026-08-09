# `telescope.nvim` — externes Plugin

Angelegt 2026-08-08 aus der Analyse von `E:/repos/Notes/MyPlugin-Notes/`.

Enthält nur, was **telescope selbst** betrifft. Alles, was in `pickers.nvim`
gehört, steht in `docs/ROADMAP/personal/pickers.nvim.md`.

---

## 1. Extensions liefern kein verlässliches Row→Index-Mapping

Quelle: `MyPlugin-Notes/telescope_selected_index/doc/ROADMAP/Bugs.md`.

Beobachtung: `builtin.buffers`, `git_status` und die `lsp_*`-Picker liefern die
für eine Nummerierung nötigen Daten sauber. `telescope-file_browser` (und früher
der cmdlog-Picker) tun das nicht — dort fehlt die Nummerierung.

`pickers.nvim` fällt dafür über drei Pfade:

1. `picker:get_index(row)` — telescopes eigene, autoritative Zuordnung
2. `entry.index` — falls der `entry_maker` das setzt
3. `compute.compute_index_from_picker` — letzter Ausweg, zählt Nicht-nil-Einträge

Der Docstring von `pickers/selected_index/compute.lua` hält fest, dass echte
Telescope-`Picker` **immer** `get_index` haben. Wenn Extensions dennoch
durchfallen, stimmt eine der beiden Annahmen nicht — entweder bauen manche
Extensions kein echtes `Picker`-Objekt, oder das Ergebnis von `get_index` ist
bei ihnen nicht das, was der Anzeigezeile entspricht.

- [ ] Mit `file_browser` reproduzieren und feststellen, welcher der drei Pfade
      greift und was er zurückgibt.
- [ ] Falls es ein echter Mangel auf Telescope-Seite ist (nicht bloss ein Mangel
      der Extension): Issue upstream, sonst Issue beim Extension-Autor.
- [ ] Andernfalls in `pickers.nvim` dokumentieren, dass bestimmte Extensions
      keine Nummerierung zeigen können — und warum.

**Aufwand:** Quick Win (Diagnose), offen (Fix, je nach Befund)
**Nutzen:** mittel.

## 2. Beobachtung zur Ergebnisliste bei leerer Trefferliste

Quelle: dieselbe Datei.

Notiert wurden drei Verhaltensweisen: Bei leerer Ergebnisliste steht trotzdem
eine Zeile da; und nach schnellem Leeren des Prompts bleibt der zuletzt
angezeigte Zustand stehen, obwohl die Liste bereits leer ist.

Ob das Telescope oder die eigene Anzeigeschicht ist, war nie geklärt.
Nachkontrolle steht in `personal/pickers.nvim.md` Punkt 5 — **zuerst dort**
prüfen. Erst wenn sich zeigt, dass Telescope die Events in dieser Reihenfolge
liefert, ist es hier ein Thema.

**Aufwand:** Quick Win (Nachkontrolle)
**Nutzen:** niedrig — vermutlich längst behoben.
