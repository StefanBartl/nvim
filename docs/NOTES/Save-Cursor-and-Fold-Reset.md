# Springender Cursor beim Speichern & TOC-Fold öffnet sich wieder

Untersuchung zweier gemeldeter Symptome beim Speichern von Markdown-Dateien
(`:w` / `<C-s>`):

1. Der Cursor springt gelegentlich, nicht zuverlässig reproduzierbar, an eine
   andere Stelle im Buffer.
2. Ein manuell geschlossener Fold (z. B. das Inhaltsverzeichnis, `za` auf der
   Heading-Zeile) öffnet sich nach jedem Save wieder — zuverlässig
   reproduzierbar.

Betroffener/geänderter Code: [`lua/bindings/autocmds/text/init.lua`](../../lua/bindings/autocmds/text/init.lua),
[`lua/bindings/autocmds/text/defaults.lua`](../../lua/bindings/autocmds/text/defaults.lua),
[`lua/bindings/autocmds/text/@types/init.lua`](../../lua/bindings/autocmds/text/@types/init.lua),
[`lua/bindings/autocmds/init.lua`](../../lua/bindings/autocmds/init.lua).

## 1. Springender Cursor — Ursache gefunden und bestätigt

`bindings.autocmds.text` registriert zwei `BufWritePre`-Hooks, die je ein
buffer-weites `:substitute` fahren:

- `trim_trailing`: `%s/\s\+$//e` (Trailing Whitespace entfernen)
- `trim_blank`: `%s/^\s*$//e` (Whitespace-only Zeilen leeren)

Wie jedes `:substitute` lässt Vim den Cursor danach auf der **letzten
tatsächlich geänderten Zeile** stehen — `keepjumps` verhindert nur einen
Jumplist-Eintrag, bewegt aber den Cursor selbst nicht zurück. `trim_blank`
hatte das schon immer abgefangen (Cursor vor dem Substitute sichern, danach
wiederherstellen). `trim_trailing` — obwohl technisch dasselbe Muster — hatte
diese Absicherung nie bekommen.

Effekt: Liegt irgendwo im Dokument eine Zeile mit Trailing Whitespace (egal
wie weit vom aktuell bearbeiteten Punkt entfernt), zieht `trim_trailing` beim
Speichern den Cursor dorthin. Da das nur bei tatsächlich vorhandenem Trailing
Whitespace passiert, war es nicht zuverlässig reproduzierbar — genau das
gemeldete Verhalten.

Bestätigt per Headless-Test gegen die echte Config (`nvim --headless` +
`vim.api.nvim_win_get_cursor`/`nvim_win_set_cursor` vor/nach einem echten
`:write`): Cursor stand vor dem Save auf Zeile 400, nach dem Save (unfixed)
auf Zeile 301 — der Zeile mit der einzigen Trailing-Whitespace-Stelle im
Testdokument.

**Fix:** `trim_trailing` sichert jetzt genauso wie `trim_blank` Cursor-Row/Col
vor dem Substitute und stellt sie danach wieder her — zusätzlich mit einem
Clamp auf die (durchs Trimmen ggf. kürzere) Zeilenlänge, sonst würde
`nvim_win_set_cursor` bei einer jetzt zu kurzen Spalte einen Fehler werfen,
den das umschließende `pcall` nur stillschweigend schluckt und den Cursor
wieder an der vom Substitute hinterlassenen Stelle liegen lässt. Denselben
Clamp hat `trim_blank` nachträglich auch bekommen (identische Lücke, nur
seltener getroffen: nur wenn die eigene Zeile des Cursors zur leeren Zeile
wird).

`<C-s>` ([`lua/bindings/mappings/general.lua`](../../lua/bindings/mappings/general.lua))
hatte bereits einen eigenen Cursor-Save/Restore-Wrapper um `vim.cmd("write")`
— das federte einen Teil der Fälle ab, aber nicht alle (z. B. wenn die
gespeicherte Spalte durch das Trimmen ungültig wird und der interne `pcall`
dort ebenfalls scheitert). Reines `:w` hatte gar keinen Schutz. Mit dem Fix
in `bindings.autocmds.text` ist das Problem an der Quelle behoben, unabhängig davon,
über welchen Weg gespeichert wird.

## 2. TOC-Fold öffnet sich nach jedem Save — Ursache nicht abschließend isoliert

### Ausgangslage

Markdown-Buffer laufen mit `foldmethod=expr` (Heading-basiert, aus
[`markdown.nvim`](https://github.com/StefanBartl/markdown.nvim)'s
`core.fold`, parallel dazu setzt auch `nvim-treesitter` einen eigenen
`foldexpr` auf `FileType`). `foldlevel`/`foldlevelstart` stehen auf `99`
(alles offen per Default), ein einzelner Fold ist also nur zu, weil er
manuell mit `za`/`zc` geschlossen wurde.

### Was durchgetestet und ausgeschlossen wurde

Mit `nvim --headless` gegen die echte Config und echte Dokumente
(`docs/BINDINGS.md` als Testkopie, inkl. einer echten "Table of contents"-
Section) wurden folgende Kandidaten einzeln durchgespielt — in **keinem**
Fall ging der zuvor geschlossene Fold nach einem echten `:write` wieder auf:

- `trim_trailing`/`trim_blank`s `:substitute` über den ganzen Buffer, auch
  wenn die geänderte Zeile *innerhalb* des gefoldeten Bereichs lag.
- `markdown.nvim`s `link_sanitize.buffer()` (`BufWritePre`, Default an) —
  ersetzt betroffene Zeilen einzeln per `nvim_buf_set_lines(buf, i-1, i, ...)`.
- Simulierter Multi-Line-Hunk-Replace innerhalb des gefoldeten Bereichs
  (gleiche und unterschiedliche Zeilenzahl vorher/nachher).
- `markdown.nvim`s `core.toc.update_markdown_toc()` (löscht+erzeugt den
  gesamten TOC-Block neu) — ist nicht automatisch an `BufWritePre` gehängt,
  nur über `:MarkdownToc`/`:Markdown toc` manuell erreichbar. Scheidet als
  automatische Ursache aus.
- `refs`/`link diagnostics`/`table.wrap.selective_reflow` — mit
  `opts = {}` (aktueller Stand in
  [`lua/plugins/personal/init.lua`](../../lua/plugins/personal/init.lua))
  alle auf Default `"off"`, laufen also gar nicht mit.
- Format-on-Save (`lsp.formatter`, siehe
  [`docs/NOTES/ExternPlugins/Bindings/Usercmds/Conform.md`](ExternPlugins/Bindings/Usercmds/Conform.md)) —
  Default `false`, keine Stelle im Code setzt es auf `true`.
- Ein zweites, unabhängiges Fenster auf demselben Buffer (`:tabnew` +
  `:enew` + `:buffer N`, bewusst *nicht* über `:split` abgeleitet) — Folds
  wurden trotzdem übernommen, keine Divergenz beobachtet.

Fazit aus den Tests: In einer einzelnen, headless nachgestellten Session mit
Default-Konfiguration ist der Fold-Zustand über `foldmethod=expr`
erstaunlich robust gegenüber Bufferänderungen. Der tatsächliche Auslöser in
der interaktiven Session — vermutlich ein Zusammenspiel mit Redraw-Timing,
mehreren Fenstern/Tabs, oder einem Plugin-Hook, der sich headless nicht
identisch verhält — konnte damit nicht zweifelsfrei benannt werden.

### Vorgehen: Fix am Symptom statt an der (unklaren) Ursache

`foldmethod=expr`-Implementierungen sind grundsätzlich dafür bekannt, den
Fold-Zustand bei einer Neuberechnung auf `foldlevel` zurückzusetzen statt den
manuell geschlossenen Zustand zu erhalten — unabhängig davon, welcher
konkrete Hook die Neuberechnung auslöst. Statt jede denkbare Ursache einzeln
zu jagen, wurde ein neues Feature `preserve_folds` in `bindings.autocmds.text`
ergänzt:

- `BufWritePre`: für jedes Fenster, das den Buffer zeigt, wird gescannt,
  welche Fold-Bereiche aktuell geschlossen sind (`foldclosed`/
  `foldclosedend`), und pro Buffer zwischengespeichert.
- `BufWritePost`: dieselben Bereiche werden wieder geschlossen
  (`:{start},{end}foldclose`) — aber nur, wenn sie zu diesem Zeitpunkt
  tatsächlich offen sind.

Der letzte Punkt war nötig, weil `:foldclose` auf einem *bereits*
geschlossenen Bereich sich wie ein zweites `zc` verhält und stattdessen den
**äußeren** Fold schließt (auf der eigenen Ebene gibt es nichts mehr zu
schließen). Ohne diese Prüfung hätte das Feature bei jedem Save, der den
Fold gar nicht verloren hatte, den übergeordneten Fold mit zugemacht — ein
Bug, der erst bei der Verifikation des Fixes selbst auffiel (Test: Bereich
schließen, Snapshot nehmen, sofort erneut schließen → Ergebnis war fälschlich
der Fold ab Zeile 1 statt der TOC-Fold ab Zeile 15).

Bei der Selbstprüfung des ersten Commits kamen zwei weitere Punkte dazu:

- **Korrektheit:** Der Snapshot (`pending[buf]`) wurde nur gesetzt, wenn
  gerade etwas geschlossen war, aber nie explizit auf `nil` zurückgesetzt.
  Schlägt ein Save fehl, bevor `BufWritePost` feuert, blieb der alte Snapshot
  stehen — ein späterer, erfolgreicher Save (bei dem der Nutzer den Fold
  zwischenzeitlich bewusst wieder geöffnet hat) hätte ihn dann fälschlich
  erneut zugemacht. Jetzt wird der Eintrag bei jedem `BufWritePre`
  bedingungslos neu gesetzt, auch auf `nil`.
- **Performance:** Der Scan lief zeilenweise über den *gesamten* Buffer bei
  jedem Save jedes normalen Buffers — auch bei Dateien ganz ohne Folds
  (`foldmethod=manual`, der Default für die meisten Filetypes). Jetzt gated
  auf `foldmethod == "expr"`: genau die Fold-Art, die das Problem hat.
  `manual`/`marker`/`syntax`/`indent`/`diff`-Buffer überspringen den Scan
  komplett — per Test bestätigt, dass `manual`-Folds über einen Save ohnehin
  von Haus aus stabil bleiben (Vim erhält sie unabhängig von dieser
  Absicherung).

### Falls das Fold-Problem wieder auftritt

Der Fix wirkt am Symptom, nicht an einer bestätigten Einzelursache. Sollte
sich ein Fold trotzdem wieder öffnen, wäre der nächste Schritt, direkt vor
und direkt nach einem Save zu vergleichen:

```vim
:verbose set foldmethod? foldexpr? foldlevel?
```

Ändert sich dabei `foldexpr` selbst (nicht nur der Fold-Zustand), steckt
vermutlich ein `FileType`-Handler dahinter, der sich erneut registriert
(z. B. Treesitter vs. `markdown.nvim`, siehe konkurrierende `FileType`-Fold-
Handler in [`lua/plugins/treesitter.lua`](../../lua/plugins/treesitter.lua)
und `markdown.nvim`s `lua/markdown/bindings/autocmds.lua`) — das wäre dann
die eigentliche, bisher nicht bestätigte Ursache.
