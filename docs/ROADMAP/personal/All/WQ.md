Übergabe liegt in [HANDOVER.md](./docs/ROADMAP/personal/All/HANDOVER.md).

## Was ich in dieser Runde gefunden habe

Der empfohlene Punkt war „vier Zeilen assert-Meta, 366 Warnungen". Beim Messen stellte sich heraus, dass die Diagnose im Report falsch war — und die echte Ursache ist interessanter:

`${3rd}/busted/library`, das lsp.nvim zur Laufzeit injiziert, verdrahtet den globalen `assert` in seiner ersten Zeile selbst: `assert = require("luassert")`. Dieses `require` läuft über `runtime.path` — und **24 von 32 `.luarc.json` überschreiben `runtime.path` mit `{"lua/?.lua","lua/?/init.lua"}`** und werfen damit `?.lua` weg, das einzige Muster, das die `luassert.lua` der Meta-Bibliothek trifft. Die Verdrahtung scheitert lautlos.

Betroffen sind nur 4 Repos, nicht alle 31: nur dort wird im luassert-Stil assertiert.

Den naheliegenden Fix — `?.lua` zurücklegen — habe ich verworfen, weil er messbar teurer ist: er ändert die Modulauflösung des ganzen Workspaces mit und erzeugte in lsp.nvim allein **54 neue `undefined-field`**, auch in Produktivcode. Stattdessen: Typ-Deklaration in `lib.nvim/lua/lib/@types/luassert.lua` plus `${3rd}/luassert/library` in vier `.luarc.json`.

| Repo | vorher | nachher |
|---|---:|---:|
| lsp.nvim | 560 | 187 |
| sandbox.nvim | 183 | 68 |
| github_stats.nvim | 107 | 48 |
| dap.nvim | 33 | 8 |
| **Summe** | **883** | **311** |

`redundant-parameter` liegt nach dem Widen der Signaturen wieder auf Ausgangsniveau (sandbox +1) — es wurde also nichts nur verschoben. `lib.nvim` als Träger: 515 → 515, die neue Datei selbst warnungsfrei.

Ein Detail, das ich unterwegs beinahe falsch gemacht hätte: die Meta-Datei liegt in `lua/`, und in diesem Codebase werden `@types`-Module tatsächlich zur Laufzeit `require`t. `assert = nil` wäre dort eine Landmine gewesen. Die Datei nutzt jetzt eine Selbstzuweisung und begründet das inline.

## Was offen ist

Nichts ist committet. Der Verifikationsscan lief bei 19 von 31 Repos, kein Repo verschlechtert — der Rest fehlt, und weil die Meta-Datei über lib.nvim global wirkt, gehört der Nachweis zum Fix. Die lsp.nvim-Suite ist am 9-Minuten-Timeout hängengeblieben, kein Testfehler, nur unbeantwortet; lib.nvims Suite ist grün, `stylua --check` in allen fünf Repos sauber. Beides plus die vier Commits und die Korrektur von `Diagnostics.md` Abschnitt 4 A steht im Handover.

Und deine Entscheidung steht noch aus: **`need-check-nil` in Tests** — in einer `TESTS/.luarc.json` abschalten (der Befund ist dort meist Absicht) oder mit `assert(mod)` auszementieren. Das ist Punkt 2 der horizontalen Vorarbeit, danach lohnt der Wechsel in den vertikalen Modus.
