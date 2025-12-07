# bugs levenmsteindistanz

## umlaute


beispiel:

P├ñdagogische Schlussfolgerungen und praktische Hinweise
- Kleine Distanz = hohe ├ähnlichkeit; gro├ƒe Distanz = viele ├änderungen erforderlich.
- Muster:
  * Viele 'M' entlang der Hauptdiagonale zeigen gleiche Zeichen an korrespondierenden Positionen.
  * L├ñngere Folge von 'I' oder 'D' deutet auf eingef├╝gte oder gel├Âschte Teiler (verschobene Sequenzen).
  * 'S' weist auf positionsgleiche, aber unterschiedliche Zeichen hin.
- F├╝r Lehrzwecke: Paare w├ñhlen, die nur kleine Verschiebungen oder einzelne Substitutionen haben,
  dann sind die Matrizen ├╝bersichtlich. F├╝r Transpositionen ist Levenshtein nicht optimal (DamerauÔÇôLevenshtein
  erlaubt Transpositions als einzelne Operation).
- Erweiterungen: unterschiedliche Kosten pro Operation (weighted edits), oder Damerau-Erweiterung.


Jedes Beispiel zeigt:
- die numerische DP-Matrix,
- die Operationsmatrix (gew├ñhlte Operation pro Zelle),
- einen Backtrace und die explizite Ausrichtung,
- die numerische Distanz, und
- eine strukturierte, beispielspezifische Erkl├ñrung.

F├╝hrt weitere Paare aus, um zu sehen, wie Matrizen und Backtraces sich ├ñndern.

## imports

mit args arbeiten, denn wenn der pfad wie levenstein aufgerufen wird `lua/levenstin/visual.lua` ist, dann muss auch `try_require("lua.levenstein.lang_de")`, also lua. vorangestellt werden, da require in lua cli anscheinend auf das cwd geht?
wenn aber über nvim aufgerufenm wird, dann muss es nicht wie implemntiert gemacht werden

```lua
  if use_de then
    -- local de = try_require("levenstein.lang_de")
    local de = try_require("lua.levenstein.lang_de")
    if de then return de end
  else
    -- local en = try_require("levenstein.lang_en")
    local en = try_require("lua.levenstein.lang_en")
    if en then return en end
  end

  -- Attempt other file if primary not found
  if use_de then
    -- local en = try_require("levenstein.lang_en")
    local en = try_require("lua.levenstein.lang_en")
    if en then return en end
  else
    -- local de = try_require("levenstein.lang_de")
    local de = try_require("lua.levenstein.lang_de")
    if de then return de end
  end
```
