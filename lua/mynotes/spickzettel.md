# Spickzettel

- `<C-6>` oder `edit #` öffnet letzte datei
- `:edit #`: springe zum letzten buffer
- `goto smth` in branches verwenden
- `vert res +10`
- `checkhealth vim.lsp` statt `LspInfo`

## Custom Usrcommands

`:NewFile {path}`           -> set buffer name, create parents, do NOT write by default
`:NewFileWrite {path}`      -> like NewFile, but also :write immediately
`:SaveAsR[!] {path}`        -> save-as, create parents; with ! force overwrite
`:writetor[!] {path} `      -> write copy, create parents; with ! force overwrite
`:MkParent`                 -> ensure parent dir for the current buffer name
`FindFiles{Telescope/Fzf}`  -> Find files in Telescope or Fzf
`Grep{Telescope/Fzf}`       -> Grep in Telescope or Fzf

## Custom mappings

`<A-m>`                     -> Öffnet 'find files or grep' selector
`telf /telg / fzff / fzfg`  -> {find files or grep} in custom dir with {telescope or fzf}

## 1. Operator + Textobjekt (präzise und schnell)

   * ciw → „change inner word“: ändert nur das Wort, Satzzeichen bleiben.
   * caw → „change a word“: wie oben, nimmt nachfolgendes Leerzeichen mit.
   * ci" / ci' / ci( / ci[ → „change inside …“: Inhalt zwischen Anführungszeichen/Klammern ändern.
   * ca" / ca' / ca( / ca[ → wie oben, inklusive der Klammern/Anführungszeichen selbst.

## 2. Visual + Textobjekt (explizit markieren)

   * viw gefolgt von c → markiert nur das Wort, kein Komma.
   * vaw gefolgt von c → wie oben, plus nachfolgendes Leerzeichen.
   * vi" / vi' / vi( / vi[ → markiert nur den inneren Inhalt von Anführungszeichen/Klammern.
   * va" / va' / va( / va[ → markiert inkl. Anführungszeichen/Klammern selbst.

## 3. Bewegung bis zum Trennzeichen (wenn das nächste Zeichen bekannt ist)

   * ct, → „change till ,“: ändert bis vor das Komma, Komma bleibt erhalten.
   * dt, / yt, → analog für delete/yank ohne das Komma.
   * f, → springt direkt zum nächsten Komma (inklusive).
   * t, → springt bis vor das nächste Komma.
   * ; / , → wiederholt f/t in Vorwärts- / Rückwärtsrichtung.

## 4. Alternative Bewegung statt w in Visual

   * ve statt vw → „bis Wortende“ statt „zum nächsten Wortanfang“; so wird das Komma nicht mit ausgewählt.
   * vE → bis Wortende (großes E = WORD, inkl. Bindestriche etc. als ein Block).
   * vb / vB → markiert rückwärts bis Wort- / WORD-Anfang.

## 5. Bewegungen innerhalb einer Zeile

   * ^ → zum ersten Nicht-Leerzeichen der Zeile.
   * 0 → zum absoluten Zeilenanfang.
   * $ → zum Zeilenende.
   * g_ → zum letzten Nicht-Leerzeichen der Zeile.

## 6. Direkt in den Insert-Modus springen (Bewegung + sofort Einfügen)

   * ea → springt ans Ende des aktuellen Wortes und startet Insert dahinter.
   * eA → wie ea, aber WORD (inkl. Bindestriche etc.).
   * a → fügt direkt hinter dem aktuellen Zeichen ein.
   * A → fügt am Zeilenende ein.
   * I → fügt am ersten Nicht-Leerzeichen der Zeile ein (wie ^ + i).
   * gI → fügt am absoluten Zeilenanfang ein (wie 0 + i).
   * o → öffnet eine neue Zeile unterhalb und wechselt in Insert.
   * O → öffnet eine neue Zeile oberhalb und wechselt in Insert.

## 7. Nützliche Wort- und Satzbewegungen

   * w / W → vorwärts zum Anfang des nächsten Wortes / WORDs.
   * e / E → vorwärts zum Ende des aktuellen Wortes / WORDs.
   * b / B → rückwärts zum Anfang des aktuellen Wortes / WORDs.
   * ge / gE → rückwärts zum Ende des vorherigen Wortes / WORDs.

## 8. Wiederholen & Korrigieren

   * . → wiederholt die letzte Änderung.
   * u → macht letzte Änderung rückgängig.
   * U → stellt ganze Zeile wieder her.
   * Ctrl-r → stellt rückgängig gemachte Änderungen wieder her (redo).

## 9. nach "oben" / "rechts" usw..
   * d3k → 3 Zeilen nach oben löschen
   * c3k → 3 Zeilen nach oben ändern
   * c3l → 3 chars nach rechts ändern
   * ...

---

## Markdown

### Link unter Cursor in System app öffnen

```lua
" Windows:
:lua vim.fn.jobstart({"cmd.exe", "/c", "start", '""', vim.fn.resolve(vim.fn.expand("%:h") .. "/" .. vim.api.nvim_get_current_line():match("%[.-%]%((.-)%)"))}, {detach=true})

" Oder kürzer mit relativen Pfad direkt:
:!start ./Figures/Figure_4.7_Performance-Effect-of-Mulitple-Cores.png

" Oder am einfachsten mit expandcmd:
:lua vim.fn.jobstart({"cmd.exe", "/c", "start", "", "./Figures/Figure_4.7_Performance-Effect-of-Mulitple-Cores.png"}, {detach=true})
```

