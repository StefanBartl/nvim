# recommender.nvim — Notizen zum `perf`-Analyzer

Was beim ersten echten Durchlauf über diese Config (2026-08-26, 353 Lua-Dateien)
aufgefallen ist, und was man später verbessern könnte.

## Was der Analyzer gut macht

Er ist bewusst schmal: vier Muster, jedes mit einem gemessenen Benchmark
hinterlegt, und dotted-chain-Aliasing wurde *rausgeworfen*, weil es unter
LuaJIT keinen messbaren Gewinn brachte. Das ist die richtige Haltung — ein
Analyzer, der nur meldet, was sich belegen lässt, ist mehr wert als einer mit
vielen Regeln.

## Der Durchlauf

398 Funde: 353× `ipairs`, 28× `table.insert`, 14× `string.format`, 3× Concat-
Akkumulator.

Die Verteilung ist selbst die Information: **nur der Akkumulator ist
algorithmisch** (O(n²)), der Rest sind konstante Faktoren. Ein konstanter Faktor
auf Nanosekunden lohnt nur in einer Schleife, die oft genug läuft — und der
einzige wirklich heiße Pfad hier ist die Statusline, gemessen bei 0,033 ms pro
Redraw. Da ist nichts zu holen.

## Gefixt (2026-08-26)

Alle drei Akkumulator-Funde waren False Positives, in zwei Formen:

1. **`local` innerhalb der Schleife neu deklariert**

   ```lua
   while u do
     local ident = ts_identifier_of(u)
     if ident then ident = ident .. "()" end
   end
   ```

   `ident` startet jede Iteration frisch — ein 2-Zeichen-Suffix auf einem neuen
   String, kein Wachstum über Iterationen.

2. **Tabellenfeld, das eine gleichnamige äußere Variable liest**

   ```lua
   entries[#entries + 1] = { short = short, dir = dir .. "/" .. short }
   ```

   Die ungeankerte Rückreferenz `x = x ..` las den *Schlüssel* `dir` als
   Zuweisungsziel.

Behoben: der Block-Tracker führt die pro Frame deklarierten `local`-Namen mit,
und der Match ist an den Zeilenanfang geankert. Vier Regressionsfälle in
`TESTS/perf_analyzer_spec.lua`, beide Richtungen.

## Ideen für später

Kein Anspruch auf Vollständigkeit, und nichts davon ist dringend — der Analyzer
ist heute nützlich. Aber wenn man ihn mal anfasst:

- **Der Zeilen-basierte Block-Tracker ist die Wurzel der meisten Grenzen.**
  `classify_line` ist billig und robust, kann aber weder Mehrfach-Anweisungen
  auf einer Zeile noch mehrzeilige Tabellen-Konstruktoren sehen. Ein
  Treesitter-Pass (`vim.treesitter.get_parser`, Lua-Grammatik ist ohnehin da)
  würde `local`-Scopes, Tabellenfelder und Schleifenkörper exakt liefern statt
  heuristisch. Kostet Laufzeit — wäre also eher ein Opt-in (`--strict`) als der
  Default.

- **`table.insert(t, 1, v)` ist ein anderer Fall als `table.insert(t, v)`.**
  Der Drei-Argument-Form kann man nicht `t[#t+1] = v` entgegenhalten; sie
  verschiebt alle Elemente und ist selbst O(n). Aktuell werden beide gleich
  gemeldet, mit einem Tipp, der für die eine Form falsch ist. Entweder eigenes
  Muster mit eigenem Tipp, oder die Drei-Argument-Form ausnehmen.

- **`ipairs` könnte nach Schleifen-Kontext gewichtet werden.** 353 Treffer sind
  als Liste unbrauchbar — niemand arbeitet 353 Stellen ab. Interessant wäre nur
  `ipairs` in einer Funktion, die selbst aus einer Schleife oder aus einem
  Autocmd/Statusline-Callback gerufen wird. Ohne Call-Graph nicht sauber
  entscheidbar, aber `documentation.nvim` hat einen — das wäre die
  Cross-Plugin-Idee dahinter.

- **Ein `--hot`-Modus, der nur meldet, was in einem gemessen heißen Pfad
  liegt.** Zusammen mit `runtime-analysis.nvim`s Telemetrie: nur Funde in
  Funktionen zeigen, die laut Telemetrie oft genug betreten werden. Das würde
  aus 395 Treffern eine Handvoll machen, und zwar die richtige Handvoll.

- **Der `string.format`-Tipp ist etwas absolut formuliert.** „reserve it for
  one-off formatting" stimmt für die Performance, aber `..` mit fünf Operanden
  und `%5.2f` ist nicht dasselbe. Ein Hinweis, dass die Ersetzung nur bei
  einfacher Konkatenation gleichwertig ist, wäre ehrlicher.

## Querverweis

- Analyzer: `recommender.nvim/lua/recommender/analyzers/perf.lua`
- Benchmarks: `recommender.nvim/docs/FEATURES.md#perf-analyzer`
- Der Durchlauf und die Statusline-Messung stehen in
  `docs/ROADMAP/personal/All/FINISH/Merged_Finished.md`, Abschnitt Performance.
