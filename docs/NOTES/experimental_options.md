
Gliederung nach Setup-Funktionsaufruf (Kurzfassung)

| Aufruf                    | Relevante Optionen/Keys                                                            | Betroffene HL-Gruppen/Optionen                                                                                                                                                                            | Kurzbeschreibung                                                                               |
| ------------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| apply_base_highlights() | colors.\*                                                                          | CursorNormal/Insert/Visual/Replace, CursorLineN/I/V/R, CursorLineNr, LineNrDim, IndentScope, YankFlash, PutFlash, SignColError/Warn/Info/Hint/Neutral, NormalTerm, CursorLineTerm, CursorWord, MatchParen | Legt alle benötigten Highlight-Gruppen an.                                                     |
| apply_guicursor()        | colors.CursorNormal/Insert/Visual/Replace                                          | 'guicursor'                                                                                                                                                                                               | Cursorform/-farbe je Modus (Fallbacks eingebaut).                                              |
| setup_mode_changed()    | enable_insert_submode_colors                                                    | winhighlight: CursorLine→CursorLineN/I/V/R, CursorLineNr, LineNrDim                                                                                                                                       | Tönt CursorLine je Modus; reagiert auf ModeChanged.                                            |
| setup_view_updates()    | enable_breadcrumbs, breadcrumbs_max_len, enable_indent_scope, large_file_kb | winbar, IndentScope                                                                                                                                                                                       | Aktualisiert Winbar und Indent-Block bei Bewegung/Scrollen; setzt Farben nach ColorScheme neu. |
| setup_yank_put_flash() | enable_yank_flash, enable_put_flash, map_put_flash                           | YankFlash, PutFlash                                                                                                                                                                                       | Kurzzeit-Highlight der kopierten/eingefügten Regionen; optionales Remapping von p/P.           |
| setup_term_palette()    | enable_terminal_palette                                                          | winhighlight: Normal→NormalTerm, CursorLine→CursorLineTerm, CursorLineNr, LineNrDim                                                                                                                       | Eigene Palette für Terminal-Fenster; CursorLine im Terminal nur als Linie.                     |
| setup_matchparen()       | (keine Toggle-Option)                                                              | MatchParen, 'showmatch', 'matchtime'                                                                                                                                                                      | Klammer-Blinken dezent aktivieren.                                                             |
| setup_current_word()    | enable_current_word                                                              | CursorWord                                                                                                                                                                                                | Unterstreicht das aktuelle Wort außerhalb des Insert-Mode.                                     |
| setup_diag_tint()       | enable_signcolumn_tint                                                           | winhighlight: SignColumn→SignColError/Warn/Info/Hint/Neutral                                                                                                                                              | SignColumn-Hintergrund spiegelt schlimmste Diagnostic-Severity.                                |
| setup_diff_peek()       | enable_diff_peek                                                                 | (keine HL-Gruppen)                                                                                                                                                                                        | Mappt „gh“ auf gitsigns-Hunk-Preview (falls installiert).                                      |

Details pro Setup-Funktion

apply_base_highlights()

* Wirkung: Definiert alle Highlight-Gruppen zentral, damit spätere Mappings (winhighlight/guicursor/Extmarks) nur referenzieren müssen.
* Gruppen:

  * Cursor\* für guicursor (Normal/Insert/Visual/Replace).
  * CursorLineN/I/V/R für Modus-abhängige CursorLine-Tönung.
  * CursorLineNr (aktiv fett/farbig) und LineNrDim (übrige Zeilen gedimmt).
  * IndentScope als Hintergrundfüllung für den Einrück-Block.
  * YankFlash/PutFlash für ephemere Region-Highlights.
  * SignColError/Warn/Info/Hint/Neutral für den SignColumn-Hintergrund.
  * NormalTerm/CursorLineTerm für TermOpen-Fenster.
  * CursorWord (Underline) und MatchParen (dezentes Blinken).
* Einfluss: Keine Toggle-Option, aber sämtliche Farben lassen sich über `colors.*` überschreiben.

apply_guicursor()

* Wirkung: Setzt eine robuste 'guicursor'-Spezifikation mit Form und per-Mode-HL-Gruppen.
* Bezieht sich auf: `colors.CursorNormal/Insert/Visual/Replace`.
* Fehlerrobustheit: Fällt auf eine minimale, immer gültige Spezifikation zurück oder setzt Defaults, falls das Setzen scheitert.
* Hinweis: Manche Terminals erzwingen Cursorfarben; dann ist primär die Form (Block/Bar/Underline) sichtbar.

setup_mode_changed()

* Wirkung: Reagiert auf `ModeChanged` und mappt fensterlokal `CursorLine` auf `CursorLineN/I/V/R`. Dadurch sieht man Moduswechsel sofort an der aktiven Zeile.
* Optionen: Aktiv nur bei `enable_insert_submode_colors=true`.
* Details:

  * `winhighlight` wird pro Fenster gesetzt: `CursorLine:CursorLineX, CursorLineNr:CursorLineNr, LineNr:LineNrDim`.
  * Falls `cursorcolumn` aktiv ist, wird dessen Hintergrund parallel an die CursorLine angeglichen.
  * Initialer Tint wird beim Setup einmalig angewandt, damit der Startmodus sichtbar ist.

setup_view_updates()

* Wirkung:

  * Bei `BufEnter`, `CursorMoved`, `WinScrolled` wird die Winbar aktualisiert und der Einrück-Block neu berechnet.
  * Bei `ColorScheme` werden alle HL-Gruppen neu gesetzt und die Modus-Tönung erneut angewandt.
* Winbar (enable_breadcrumbs, breadcrumbs_max_len):

  * Zeigt den Repo-relativen Pfad (Fallback `:~:.`) und – wenn verfügbar – den aktuellen Symbol/Scope (LSP-Variable oder Treesitter-Heuristik).
  * Zu lange Inhalte werden mittig gekürzt auf `breadcrumbs_max_len`.
* Indent-Scope (enable_indent_scope, large_file_kb):

  * Hebt den zusammenhängenden Bereich hervor, dessen Einrückung ≥ Einrückung der Cursorzeile ist (Leerzeilen beenden den Block).
  * Bei Dateien größer als `large_file_kb` KB wird die Block-Hervorhebung aus Performancegründen ausgesetzt.
  * Technisch bevorzugt `vim.hl.range`/`vim.highlight.range`, mit Extmark-Fallback (volle Zeilen via `hl_eol`).

setup_yank_put_flash()

* Wirkung:

  * `enable_yank_flash`: Nach Yank kurzes Highlight der kopierten Region.
  * `enable_put_flash`: Nach Paste kurzes Highlight der eingefügten Region.
  * `map_put_flash`: Remappt `p`/`P` nicht-rekursiv, um den Put-Flash automatisch zu triggern; bestehende Custom-Mappings können das deaktivieren und stattdessen gezielt `flash_changed_region("PutFlash", 160)` aufrufen.
* Technische Basis: Region via Marks `[`/`]`, Rendering über `vim.hl.range`/`Extmarks`.
* Dauer/Intensität: Per HL-Gruppe (`colors.YankFlash`/`colors.PutFlash`) steuerbar, Timeout fest codiert (150–160 ms).

setup_term_palette()

* Wirkung: In Terminal-Fenstern (`TermOpen`) wird `Normal` auf `colors.TermNormal` und `CursorLine` auf `colors.TermCursorLine` gemappt; CursorLine ist dort als reine Linie (`cursorlineopt="line"`) aktiv.
* Ziel: Visuelle Trennung zwischen Editor- und Terminal-Puffern, ohne das globale Farbschema zu verändern.
* Keine Seiteneffekte auf normale Edit-Fenster.

setup_matchparen()

* Wirkung: Aktiviert `showmatch` mit kurzer Blinkzeit (`matchtime≈200 ms`), sodass passende Klammern kurz aufleuchten.
* Stil: `colors.MatchParen`.
* Keine Toggle-Option im Modul; bei Bedarf kann man die Zeile leicht auskommentieren.

setup_current_word()

* Wirkung: Unterstreicht das aktuelle Wort unter dem Cursor; bewusst keine Vollflächen-Hinterlegung, um die Lesbarkeit auf dunklen Themes zu verbessern.
* Bedingungen:

  * Nur außerhalb von Insert-Mode aktiv.
  * Wird bei InsertEnter/BufLeave/WinLeave sauber entfernt.
  * Wörter unter Mindestlänge (z. B. 1 Zeichen) werden ignoriert.
* Stil: `colors.CursorWord` (i. d. R. nur `underline=true`).

setup_diag_tint()

* Wirkung: Setzt den Hintergrund der SignColumn fensterlokal entsprechend der schlimmsten Diagnostic-Severity im aktuellen Buffer.
* Mapping: Error→`SignColError`, Warn→`SignColWarn`, Info→`SignColInfo`, Hint→`SignColHint`; ohne Diagnostics `SignColNeutral`.
* Trigger: `DiagnosticChanged` und `BufEnter`.
* Vorteil: Auf einen Blick erkennen, ob „rote“ Probleme im Buffer sind, ohne Textinhalt zu lesen.
* Kollisionsarm: Es wird nur der Hintergrund via `winhighlight` gemappt; Icons/Zeichen in der SignColumn bleiben unverändert.

setup_diff_peek()

* Wirkung: Bindet `gh` an die Hunk-Vorschau von gitsigns (inline, wenn verfügbar, sonst im Float).
* Option: `enable_diff_peek`.
* Abhängigkeit: Wenn `gitsigns.nvim` nicht geladen ist, zeigt die Taste einen freundlichen Hinweis statt eines Fehlers.
* Nutzen: Kontext der letzten Änderung schnell prüfen, ohne eine Diff-Ansicht zu öffnen.

Kurzreferenz: Optionen je Aufruf

* apply_base_highlights(): colors.\*
* apply_guicursor(): colors.CursorNormal, colors.CursorInsert, colors.CursorVisual, colors.CursorReplace
* setup_mode_changed(): enable_insert_submode_colors, colors.CursorLineN/I/V/R, colors.CursorLineNr, colors.LineNrDim
* setup_view_updates(): enable_breadcrumbs, breadcrumbs_max_len, enable_indent_scope, large_file_kb, colors.IndentScope
* setup_yank_put_flash(): enable_yank_flash, enable_put_flash, map_put_flash, colors.YankFlash, colors.PutFlash
* setup_term_palette(): enable_terminal_palette, colors.TermNormal, colors.CursorLineTerm
* setup_matchparen(): colors.MatchParen
* setup_current_word(): enable_current_word, colors.CursorWord
* setup_diag_tint(): enable_signcolumn_tint, colors.SignColError/Warn/Info/Hint/Neutral
* setup_diff_peek(): enable_diff_peek


##

| Option (Lua-Key)                | Typ   | Standard | Wirkung (kurz)                                                                               |
| ------------------------------- | ----- | -------- | -------------------------------------------------------------------------------------------- |
| enable_indent_scope           | Bool  | true     | Hebt den aktuellen Einrück-Block im sichtbaren Fensterbereich als Hintergrundtönung hervor.  |
| enable_breadcrumbs             | Bool  | true     | Zeigt im Winbar einen Repo-relativen Pfad und (wenn ermittelbar) den aktuellen Symbol/Scope. |
| enable_yank_flash             | Bool  | true     | Kurzes Aufleuchten der kopierten Region nach Yank.                                           |
| enable_put_flash              | Bool  | true     | Kurzes Aufleuchten der eingefügten Region nach Paste.                                        |
| map_put_flash                 | Bool  | true     | Remappt `p`/`P`, damit Put-Flash automatisch ausgelöst wird.                                 |
| enable_signcolumn_tint        | Bool  | true     | Färbt die SignColumn je nach schlimmster Diagnostic-Severity des Buffers.                    |
| enable_terminal_palette       | Bool  | true     | Eigene Hintergrundtöne für Terminal-Buffer (Normal/ CursorLine).                             |
| enable_insert_submode_colors | Bool  | true     | Tönt CursorLine je Modus (Normal/Insert/Visual/Replace) per `ModeChanged`.                   |
| enable_current_word           | Bool  | true     | Unterstreicht das aktuelle Wort (kein Vollflächen-BG).                                       |
| enable_diff_peek              | Bool  | true     | `gh` zeigt Git-Hunk-Vorschau (mit gitsigns, falls installiert).                              |
| large_file_kb                 | Int   | 5000     | Drosselt teure Effekte für große Dateien (Indent-Scope wird dann deaktiviert).               |
| breadcrumbs_max_len           | Int   | 80       | Max. Länge der Winbar; überlange Pfade/Symbole werden mittig gekürzt.                        |
| colors.CursorNormal             | table | s. Code  | HL-Gruppe für Cursor im Normal-/Cmdline-Modus (für `guicursor`).                             |
| colors.CursorInsert             | table | s. Code  | HL-Gruppe für Cursor im Insert-/Cmdline-Insert-Modus.                                        |
| colors.CursorVisual             | table | s. Code  | HL-Gruppe für Cursor im Visual-Modus.                                                        |
| colors.CursorReplace            | table | s. Code  | HL-Gruppe für Cursor im Replace-/Cmdline-Replace-Modus.                                      |
| colors.CursorLineN/I/V/R        | table | s. Code  | Per-Modus-Hintergrund für CursorLine (via `winhighlight`).                                   |
| colors.CursorLineNr             | table | s. Code  | Hervorhebung der Zeilennummer der Cursor-Zeile.                                              |
| colors.LineNrDim                | table | s. Code  | Gedimmte Zeilennummern für alle anderen Zeilen.                                              |
| colors.IndentScope              | table | s. Code  | Hintergrund für den hervorgehobenen Einrück-Block.                                           |
| colors.YankFlash                | table | s. Code  | Kurzzeit-HL für yanked Text.                                                                 |
| colors.PutFlash                 | table | s. Code  | Kurzzeit-HL für eingefügten Text.                                                            |
| colors.SignColError/Warn/…      | table | s. Code  | Hintergrundtöne für SignColumn je Severity (Error/Warn/Info/Hint).                           |
| colors.SignColNeutral           | table | s. Code  | Neutraler Hintergrund der SignColumn (wenn keine Diagnostics).                               |
| colors.TermNormal               | table | s. Code  | Hintergrund für Terminal-Buffer (`Normal`).                                                  |
| colors.TermCursorLine           | table | s. Code  | Hintergrund für Terminal-Buffer (`CursorLine`).                                              |
| colors.CursorWord               | table | s. Code  | Stil (Underline) für aktuelles Wort.                                                         |
| colors.MatchParen               | table | s. Code  | Stil für kurzzeitige Klammer-Markierung (showmatch).                                         |


