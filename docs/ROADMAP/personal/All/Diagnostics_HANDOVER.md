# Handover -- Cluster A (`assert`), Stand 2026-08-29

Kurzübergabe zu `Diagnostics.md` Abschnitt 0. **Nichts ist committet.**

---

## Was sich gegenüber dem Report geändert hat

Der Report schlug ein Vier-Zeilen-Meta vor und schätzte 366 Warnungen. Beides
war zu kurz gegriffen -- die eigentliche Ursache ist eine andere:

`${3rd}/busted/library`, das lsp.nvim zur Laufzeit injiziert, verdrahtet den
globalen `assert` selbst, in seiner ersten Zeile:

```lua
assert = require("luassert")
```

Dieses `require` läuft über `runtime.path`. **24 der 32 `.luarc.json`
überschreiben `runtime.path` mit `{"lua/?.lua", "lua/?/init.lua"}`** und werfen
damit das Default-Muster `?.lua` weg -- das einzige, das die `luassert.lua` der
Meta-Bibliothek trifft. Die Verdrahtung scheitert also lautlos, `assert` behält
den stdlib-Typ, und jedes `assert.are.same(...)` liest sich als Feldzugriff auf
eine Funktion.

**Betroffen sind nur 4 Repos**, nicht alle: nur dort wird überhaupt im
luassert-Stil assertiert (lsp.nvim, sandbox.nvim, dap.nvim, github_stats.nvim;
mdview.nvim nutzt den Stil zwar, hat aber kein `runtime.path`-Problem).

## Warum nicht `runtime.path` reparieren

Gemessen, nicht vermutet: `?.lua` zurückzulegen behebt die Assertions, ändert
aber die Modulauflösung des ganzen Workspaces mit. In lsp.nvim allein entstanden
dadurch **54 neue `undefined-field`** (`cfg.keymaps`, `cfg.servers` …), davon
auch welche in Produktivcode. Verworfen.

## Was stattdessen gemacht wurde

1. **Neu: `lib.nvim/lua/lib/@types/luassert.lua`** -- typisiert den globalen
   `assert` als `luassert` und schließt zwei Lücken der ausgelieferten
   Definitionen: fehlende optionale Message-Parameter (`assert.is_true(x,
   "warum")` galt als `redundant-parameter`) sowie die fehlenden Namen `equals`
   und `errors`. Die Datei begründet jede Entscheidung inline, inklusive der
   einen bewussten Unterdrückung.
2. **`${3rd}/luassert/library`** in `.luarc.json` ergänzt bei: `lsp.nvim`,
   `dap.nvim`, `github_stats.nvim`, `lib.nvim`. (`sandbox.nvim` hatte es schon.)

## Messung (editorgetreu: echte `.luarc.json` + lsp.nvims Runtime-Injektion)

| Repo | vorher | nachher |
|---|---:|---:|
| lsp.nvim | 560 | 187 |
| sandbox.nvim | 183 | 68 |
| github_stats.nvim | 107 | 48 |
| dap.nvim | 33 | 8 |
| **Summe** | **883** | **311** |

`lib.nvim` als Träger der Meta-Datei: 515 → 515, die neue Datei selbst
warnungsfrei. `redundant-parameter` liegt nach dem Widen wieder auf
Ausgangsniveau (nur sandbox +1) -- es wurde also nichts nur verschoben.

---

## Offen -- genau hier weitermachen

1. **Verifikationsscan zu Ende bringen.** Lief bei Abbruch bei 19 von 31 Repos,
   **kein Repo verschlechtert**. Der Rest muss noch durchlaufen, bevor
   committet wird: die Meta-Datei wirkt über lib.nvim als Library global, also
   ist der Nachweis "nirgends schlechter" Teil des Fixes.
   Skript: `scratchpad/run_after.sh` (Configs: `scratchpad/luals/cfgE2/`,
   Vergleichsbasis: `scratchpad/luals/base/`). Scratchpad ist
   sitzungsflüchtig -- notfalls `mkcfgE2.py` neu laufen lassen.
2. **lsp.nvim-Suite läuft noch nicht durch.** Abgebrochen am 9-Minuten-Timeout,
   kein Testfehler, nur unbeantwortet:
   `nvim --headless --noplugin -u TESTS/minimal_init.lua -c "PlenaryBustedDirectory TESTS/lsp { minimal_init = 'TESTS/minimal_init.lua', sequential = true }"`
   lib.nvims Suite ist grün (`LIB_TESTS_OK`), `stylua --check` in allen fünf
   Repos sauber.
3. **Committen**, ein Commit pro Repo: lib.nvim (Meta + `.luarc.json`),
   lsp.nvim, dap.nvim, github_stats.nvim (je nur `.luarc.json`).
4. **`Diagnostics.md` korrigieren.** Abschnitt 4 A steht noch auf der falschen
   Ursache und der falschen Zahl; Abschnitt 0 muss den Punkt nach *Erledigt*
   umhängen. Der ausführliche Text gehört nach `Diagnostics_FINISHED.md`.

## Deine Entscheidung, die noch aussteht

**`need-check-nil` in Tests (925 Stück).** Zwei Wege, und es sollte nur einer
sein: entweder in einer `TESTS/.luarc.json` pro Repo abschalten (der Befund ist
dort meist Absicht -- schlägt `pcall(require, …)` fehl, *soll* der Test
krachen), oder überall `assert(mod)` davorsetzen und die Nil-Prüfung
auszementieren. Das ist Punkt 2 der horizontalen Vorarbeit; erst danach lohnt
der Wechsel in den vertikalen Modus.

## Nebenbefund aus dieser Runde

`.luarc.json` überschreibt `workspace.library` komplett -- was lsp.nvim in
`before_init` injiziert (`$VIMRUNTIME/lua`, `${3rd}/luv`, `${3rd}/busted`),
könnte in den 11 Repos, die ihre eigene Library-Liste führen, gar nicht
ankommen. Nicht verifiziert, aber es würde erklären, warum diese Repos im
Editor eine andere Typwelt sehen als im CI. Wäre einen eigenen Test wert.
