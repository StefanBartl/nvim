# Farben in wkdoptions

| Name           | Kurzbeschreibung            | Farbeindruck          | Wann/Situation sichtbar   |
| -------------- | --------------------------- | --------------------- | ------------------------- |
| CursorLine     | Grundtönung der aktuellen   | sehr dunkles          | wenn cursorline aktiv ist |
|                | Zeile                       | Blau-Grau (#2a2e36)   | und kein Modus-Spezialton |
|                |                             |                       | gesetzt ist               |
| CursorColumn   | Dezente vertikale Spur      | sehr dunkles          | wenn cursorcolumn         |
|                | unter der Cursor-Spalte     | Blau-Grau (#2a2e36)   | aktiviert ist             |
| CursorLineNr   | Hervorgehobene Zeilennummer | warmes Gelb, fett     | Line-Numbers an, Fokus    |
|                | der Cursor-Zeile            | (#ffd75f, bold)       | auf aktueller Zeile       |
| LineNrDim      | Abgedunkelte Zeilennummern  | entsättigtes          | via winhighlight für      |
|                | in Nebenfenstern            | Schiefer-Grau         | inaktive/Side-Windows     |
|                |                             | (#5a6374)             |                           |
| CursorLineN    | CursorLine-Tönung in        | wie Basis (#2a2e36)   | bei ModeChanged → Normal  |
|                | Normal-Modus                |                       |                           |
| CursorLineI    | CursorLine-Tönung in        | kühles Blaugrün       | bei ModeChanged → Insert  |
|                | Insert-Modus                | (#24313a)             |                           |
| CursorLineV    | CursorLine-Tönung in        | gedämpftes            | bei ModeChanged →         |
|                | Visual/Select-Modus         | Pflaumen-Violett      | Visual/Select             |
|                |                             | (#322b3a)             |                           |
| CursorLineR    | CursorLine-Tönung in        | dunkles Rotbraun      | bei ModeChanged → Replace |
|                | Replace/Op-pending          | (#3a2323)             |                           |
| Cursor         | Fallback-Cursorfläche (wenn | kräftiges             | allgemeiner Rückfall      |
|                | keine per-Modus-Gesichter   | Pink-Magenta auf      |                           |
|                | aktiv)                      | dunklem FG (#ff5f87/  |                           |
|                |                             | #1e1e1e)              |                           |
| CursorNormal   | Cursor-Gesicht im           | helles Amber          | guicursor-Mapping für     |
|                | Normal-Modus                | (#ffcc00)             | n-Modus                   |
| CursorInsert   | Cursor-Gesicht im           | helles                | guicursor-Mapping für     |
|                | Insert-Modus                | Cyan/Himmelblau       | i-Modus                   |
|                |                             | (#5fd7ff)             |                           |
| CursorVisual   | Cursor-Gesicht im           | orange/korallenfarben | guicursor-Mapping für     |
|                | Visual-Modus                | (#ff5f2a)             | v/V/⌃v                    |
| CursorReplace  | Cursor-Gesicht im           | reines Rot (#ff0000)  | guicursor-Mapping für     |
|                | Replace-Modus               |                       | R-Modus                   |
| YankFlash      | Kurzzeitiger                | olivgrüner Schimmer   | unmittelbar nach Kopieren |
|                | Hintergrund-Blitz für       | (#3e5f2a)             |                           |
|                | „yank“                      |                       |                           |
| PutFlash       | Kurzzeitiger                | kühles Stahl-Blau     | unmittelbar nach Einfügen |
|                | Hintergrund-Blitz für       | (#2a4d6b)             |                           |
|                | „put/paste“                 |                       |                           |
| SignColError   | SignColumn-Hintergrund bei  | dunkles Rotbraun      | wenn Diagnostics mit      |
|                | Fehlern (schlimmste Stufe   | (#3a2323)             | ERROR existieren          |
|                | gewinnt)                    |                       |                           |
| SignColWarn    | SignColumn-Hintergrund bei  | erdiges Ocker-Braun   | wenn WARN (und kein       |
|                | Warnungen                   | (#3a3623)             | ERROR)                    |
| SignColInfo    | SignColumn-Hintergrund bei  | tiefes Blau-Teal      | wenn INFO (und kein       |
|                | Infos                       | (#22333e)             | WARN/ERROR)               |
| SignColHint    | SignColumn-Hintergrund bei  | tiefes Grün (#1f2f2a) | wenn nur HINTS vorhanden  |
|                | Hinweisen                   |                       |                           |
| SignColNeutral | Neutrale SignColumn ohne    | transparent (NONE)    | keine Diagnostics bzw.    |
|                | Tönung                      |                       | Feature aus               |
| TermNormal     | Terminal-Buffer-Hintergrund | sehr dunkles          | in \:terminal-Fenstern    |
|                |                             | Marine-Grau (#151a1f) |                           |
| TermCursorLine | CursorLine-Tönung speziell  | dunkles Schiefer-Grau | in \:terminal-Fenstern    |
|                | für Terminal-Buffer         | (#20262d)             | mit cursorline            |
| CursorWord     | Unterstreichung des         | nur Underline         | optional per              |
|                | aktuellen Worts (niedrige   |                       | Feature/Plugin            |
|                | Störung)                    |                       |                           |
| MatchParen     | Markierung passender        | kühles Anthrazit,     | über                      |
|                | Klammern                    | fett (#3b4048, bold)  | Matchparen-Feature/Plugin |
| IndentScope    | Vollzeilige Tönung für      | dunkles Blau-Grau     | viewport-begrenzt um den  |
|                | aktuellen Einrückungs-Block | (#2f3440)             | aktiven Einzug            |

## Ausführlich (nach Gruppen)

Basis-Tönungen für Zeile/Spalte

* CursorLine: Legt den Hintergrund der aktuellen Zeile fest. Wirkt, sobald man cursorline aktiviert oder das Fenster via winhighlight entsprechend setzt. Dient als ruhige Fokusfläche ohne starken Kontrast; per-Modus-Varianten überschreiben diese Basis.
* CursorColumn: Schlanke vertikale Orientierungshilfe unter der Cursor-Spalte; hilfreich bei Code mit vielen Spalten (Tabellen, Alignments). Sollte dezent sein, um nicht zu flimmern.
* CursorLineNr: Hebt die Zeilennummer der aktiven Zeile hervor (meist als „Anker“ für Blickführung). Ein warmes Gelb wirkt präsent, ohne aggressiv zu sein.
* LineNrDim: Für nicht-fokussierte Fenster werden Zeilennummern gedimmt. Unterstützt die visuelle Hierarchie: Fokusfenster ist hell, Nebenfenster leiser.

Modus-spezifische CursorLine-Varianten

* CursorLineN/I/V/R: Gleiche Funktion wie CursorLine, aber je Modus unterschiedlich getönt. Ein kühlerer Ton im Insert-Modus (CursorLineI) suggeriert „Eingabekontext“, ein rötlicher Ton (CursorLineR) warnt vor Ersetzen-Operationen. Aktivierung typischerweise über ein ModeChanged-Autocmd, das winhighlight dynamisch setzt.

Cursor-Gesichter (guicursor)

* Cursor/CursorNormal/Insert/Visual/Replace: Bestimmen die Cursor-Farbe (Hinter-/Vordergrund) pro Modus. Gelb für Normal (neutral, klar), Cyan für Insert (präzise, frisch), Orange für Visual (Auswahl), Rot für Replace (Achtung/risikobehaftet). Der generische Cursor dient als Fallback, wenn per-Modus-Gesichter deaktiviert sind.
* Hinweis: In vielen Terminals wirkt primär Form und Invertierung; GUI/Terminal-UIs mit ext. Clients können Farbflächen direkt nutzen. Farbkombis sollten ausreichenden Kontrast zum Editor-Hintergrund bieten.

Kurzzeitige Rückmeldungen (Flash)

* YankFlash/PutFlash: Kurze, flächige Hintergrund-Impulse nach Kopieren/Einfügen. Grünliche Töne transportieren „erfolgreich/ok“, blau wirkt „Drop-off/Einfügen“. Sie verschwinden nach wenigen 100 ms; sie sollen informativ, aber nicht ablenkend sein.

SignColumn-Tönungen nach Schweregrad

* SignColError/Warn/Info/Hint/Neutral: Hintergrund der SignColumn wechselt je nach vorhandenem maximalem Schweregrad („worst wins“). Rotbraun bei Fehler, Ocker bei Warnung, Blau-Teal bei Info, Grün bei Hinweisen, transparent wenn nichts da ist. Unterstützt schnelles „peripheres“ Erkennen von Problemzuständen ohne auf einzelne Icons/Symbole zu zielen.

Terminal-Palette

* TermNormal/TermCursorLine: Spezielle Hintergründe für \:terminal-Buffer, oft etwas dunkler als normale Edit-Fenster, damit Terminal-Inhalte eigenständiger wirken. Die CursorLine im Terminal kann für Eingabe-Kommandos und Prompt-Zeilen helfen.

Wort/Klammern/Einrückungs-Kontext

* CursorWord: Nur Unterstreichung des aktuellen Worts (geräuscharm). Gut für semantische Orientierung ohne den Fluss zu stören. Funktioniert besonders angenehm mit gedämpfter Farbe statt Vollfläche.
* MatchParen: Markiert passende Klammern; neutral dunkler Hintergrund plus fett macht die Paarung sichtbar, ohne den Rest zu überblenden. Für LISP/TS/Java-Code mit vielen Klammern essenziell.
* IndentScope: Vollzeilige Tönung um den aktuellen Einrückungs-Block (viewport-begrenzt). Gut für verschachtelte Code-Blöcke; die Farbe sollte so gewählt sein, dass sie nicht mit CursorLine kollidiert (leichter Helligkeits-Versatz genügt).

Praktische Hinweise zur Gestaltung

* Kontrast: Für Flächen (CursorLine/IndentScope) dezente Helligkeitssprünge wählen; für Cursor-Gesichter gesättigtere Farben, damit der Cursor „greifbar“ bleibt.
* Stacking-Regeln: winhighlight kann Gruppen je Fenster überschreiben. Per-Modus-CursorLine greift typischerweise vor der Basis-CursorLine. Bei Konflikten stets die letzte, fensterspezifische Zuweisung.
* Transparenz: „NONE“ lässt das darunterliegende Theme „durchscheinen“ – sinnvoll, wenn man SignColumn nicht färben will.
* Barrierefreiheit: Rot/Grün-Kombis bei Flash/Severity möglichst mit Helligkeits- und nicht nur Farbton-Unterschieden kombinieren.

---

