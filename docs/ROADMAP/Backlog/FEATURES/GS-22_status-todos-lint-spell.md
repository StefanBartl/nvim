# GS-22 — `:Git status todos|lint|spell` (Pre-Commit-Gates)

**Repos:** gitsuite.nvim (insights.nvim als optionaler Konsument) ·
**Nutzen** 3 · **Aufwand** 1,0 · **Risiko** mittel · **Welle** 5 · erledigt
2026-09-22.

## Ausgangslage — Spike zuerst (laut Plan verpflichtend)

Zwei vermutete Einschränkungen wurden vor der Implementierung geprüft, nicht
angenommen:

1. **LSP-Diagnostics existieren nur für einen geladenen Buffer** — es gibt
   keine Möglichkeit, einen Language Server nach einer Datei zu fragen, ohne
   sie zu öffnen und auf einen angehängten Client zu warten. Bestätigt: es
   gibt keinen Weg darum herum.
2. **`insights.todos.scan()` ist ein Whole-Tree-Ripgrep-Lauf, keine
   Dateilisten-Abfrage** — bestätigt durch Lesen von `insights/todos/init.lua`:
   `opts.cwd` ist der Ripgrep-Suchpfad, keine Filterliste.

Drittens, nicht ursprünglich im Plan erwähnt: `vim.spell.check()` braucht
**keinen** geladenen Buffer — es arbeitet auf rohem Text über `'spelllang'`,
sodass `spell` den beiden anderen Gates NICHT dieselbe Einschränkung teilt.

## Umsetzung

- **gitsuite.nvim** (`25955a6`): neues Modul
  `lua/gitsuite/features/status/gates.lua` mit `M.todos()`/`M.lint()`/
  `M.spell()`, alle über eine gemeinsame `changed_files()` (absolute Pfade
  aus `git.status_porcelain()`, Löschungen ausgeschlossen — für gelöschte
  Dateien gibt es nichts mehr zu prüfen):
  - `todos()`: `insights.todos.scan({cwd = repo_root})` (Whole-Tree), Ergebnis
    nachträglich auf die geänderten Dateien gefiltert — kein Umbau an
    insights.nvim nötig, Ripgrep ist schnell genug, dass der Mehraufwand
    keine neue API rechtfertigt. Optionale weiche Abhängigkeit
    (`pcall(require, "insights.todos")`).
  - `lint()`: `vim.diagnostic.get(bufnr)` für jede geänderte Datei, die
    bereits einen geladenen Buffer hat; ungeladene werden gezählt, nicht
    verworfen (`notify.warn`/`notify.info` nennt die Zahl explizit).
  - `spell()`: `vim.fn.readfile(path)` + `vim.spell.check()` pro Zeile
    gegen den On-Disk-Inhalt jeder geänderten Datei — genau das, was
    committet würde, kein Buffer nötig.
  - Drei neue `:Git status todos|lint|spell`-Routen in
    `lua/gitsuite/bindings/usrcmds.lua`.

## Tests

`TESTS/gitsuite/gates_spec.lua` (8 Fälle, echte Throwaway-Git-Repos wie
`relink_spec.lua`): `todos` ohne insights.nvim, ohne geänderte Dateien, und
der eigentliche Filter-Beweis (zwei simulierte Scan-Treffer, nur der
geänderte geht in die Quickfix-Liste — ein Pfad-Trennzeichen-Bug dabei
gefunden und gefixt: `git.repo_root()` normalisiert auf Forward-Slashes,
`vim.fn.tempname()` unter Windows nicht — der Test verglich ursprünglich
gegen die falsche Schreibweise). `lint` ohne geänderte Dateien und mit einem
offenen/einem geschlossenen geänderten File (Diagnostic nur vom offenen,
Skip-Zähler in der Notify-Nachricht). `spell` ohne geänderte Dateien, mit
einer echten Rechtschreibprüfung gegen einen absichtlichen Tippfehler
(`vim.spell.check` funktioniert bereits mit `nvim --clean`, kein
Wörterbuch-Download nötig) und gegen eine saubere Datei. `stylua`/`luacheck`
grün, volle gitsuite-Suite grün.

## Ergebnis

CI grün auf allen drei Systemen (`gh run view 35762877954` bestätigt
`completed success`).

## Dokumentation mitgezogen

`docs/BINDINGS.md` (drei neue Zeilen), `docs/requirements.md` (insights.nvim
jetzt auch für `:Git status todos` genannt). `doc/gitsuite.txt` bewusst
nicht angefasst — einzelne `:Git`-Subcommands werden dort laut eigenem
Konzept nicht manuell aufgezählt.
