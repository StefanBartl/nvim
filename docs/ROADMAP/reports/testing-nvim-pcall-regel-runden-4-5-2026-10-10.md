# testing.nvim: die pcall-Regel, Review von `2d9c817` und seiner Fixes

Stand 10.10.2026 · geprüft: `testing.nvim` `2d9c817`, danach die Fixes `d4fa2dd`, `3dfdd8d`, `2deff10`, `9a18891`, `fd95123` · Neovim 0.12.2 unter Linux
(Windows und macOS über die CI) · Fortsetzung von [testing-nvim-pcall-regel-re-review-2026-10-10.md](testing-nvim-pcall-regel-re-review-2026-10-10.md) ·
Werkzeuge der Läufe: Workflows `wf_462c165c-4fd` (Review von `2d9c817`, abgebrochen) und `wf_caa579d6-759` (Review der Fixes)

## Kurzfassung

`2d9c817` hielt die Kernfälle, hatte aber noch **Falsch-grün-Löcher** und zwei Regressionen entstanden erst beim Beheben. Alles Beschriebene ist behoben,
getestet (jeder neue Test war gegen die vorherige Fassung rot) und auf `main`; offen ist nur Kosten- und Hygienekram (Task
`testing.nvim/pcall-regel-reste-nach-review-runde-4`).

- Die Regel ist weiter eine **Vermutung aus dem Aufruf-Stack**. Was sie nicht entscheiden kann, steht in `docs/DIALECTS.md` ("What can still go missing").
- Der Aufwand der Regel sank um etwa 28 % je fehlschlagendem Check (6,6 statt 9,2 µs im Fall "Plugin-`pcall` außen"), bei identischen Verdikten auf
  8 x 15000 Zufalls-Stacks und im Grenz-Sweep.
- Gesamtsuite 171/171; die CI ist auf Linux, macOS und Windows grün (zwei Rotläufe waren ein macOS-Pfadfehler im eigenen neuen Test und ein Flake in
  lib.nvims Windows-Timeout-Test `run_argv_spec.lua:220`, beim Neustart grün).

## Methode und Grenzen

| Lauf | Prüfer | Befunde | Gegenprüfung |
|---|---|---|---|
| 1 (`wf_462c165c-4fd`), 7 Perspektiven: Kern, Dialekte, Security/Robustheit, Performance, Tests/Docs/Typen, Mutationstest (156 Mutanten), realistische Spec-Stile | 60 roh, 44 verschieden | 17 von 44 mit Reproduktion **und** Widerlegung; dann **abgebrochen** (Dauer). Die übrigen habe ich anhand der Repros der Prüfer selbst nachgestellt und beim Beheben belegt |
| 2 (`wf_caa579d6-759`), mittleres Reasoning, 4 Agenten: Kern-Fixes, Dialekt-Fixes/Tests/Docs, Mutationstest (135 Mutanten, 112 getötet; die 22 überlebenden gleichwertig, nur Kosten oder nur Windows), Schwarzkasten-Regression (48 Projekte alt gegen neu) | 3 + 5 + 8 + 3 | keine zweistufige Gegenprüfung; die Befunde habe ich einzeln gelesen und durch Tests belegt |

Es gab nie mehr als 4 Agenten gleichzeitig. Ein dritter, unabhängiger Review der letzten Fixes (`9a18891`) hat nicht stattgefunden.

## Gefunden und behoben

| Ursache | Wirkung | Stand |
|---|---|---|
| Doc-Kommentar über der nächsten Funktion wurde als Teil der vorherigen gelesen (`assertion_names`) | schluckender Cleanup-Helfer galt als Assertion, Spec ohne Check bestand (falsch grün) | `strip_comments`, jetzt `testing.discover.lua_text.strip_comments` |
| Check im Message-Handler eines `xpcall` | wirft in "error in error handling", verloren (falsch grün) | `error`/`assert`-Frame vor dem Fänger und fremder C-Frame unter einem `xpcall`-Fänger zeichnen auf; nur ein Lua-Laufzeitfehler (nil-Index) bleibt (dokumentiert) |
| Harness im Projektstamm | ganzes Plugin zählte als Harness (falsch grün) | `lua/ plugin/ after/ ftplugin/ autoload/ src/` zählen nie; ein Harness im Stamm zählt nur Dateien direkt im Stamm oder unter `tests/` |
| Helfer früherer Spec-Dateien und Wrapper-Schichten in einer überlebenden Harness-Tabelle | transparent oder verdeckt (falsch grün/rot) | `spec_chunks`, `ORIGINAL`-Map |
| `deep_equal` und `a.error` warfen aus dem Check | in einem schluckenden `pcall` verloren (falsch grün) | Vergleich in `pcall`, Muster in `pcall`; zweites Ergebnis "raised", damit `are_not.same` bei werfendem Vergleich fehlschlägt (Regression des ersten Fixes, im Review 2 gefunden) |
| Nicht-String-Meldung (`H.eq(a, b, i)`) | jeder Lauf mit Report endete mit Exit 3 | als Text gespeichert |
| Relativer Chunk-Name (`package.path` `./?.lua`) | Harness-Helfer fiel heraus (falsch rot, Regression gegenüber `20f33d1`) | `absolute()`; Pfad je Funktion beim ersten Sehen gemerkt (`cwd`-Wechsel) |
| `locate()` nutzte das lebende `debug.getinfo` | Stub hängte jede Assertion | beim Laden gemerkt |
| `inspect`-Budget um ein Zeichen zu früh | Marke `...(truncated)` ging bei genau 2000 Zeichen verloren (Regression des ersten Fixes) | Grenze `< 0` / `>= 0`, Test gegen eine Formel über 1980..2000 |
| `strip_comments` klebte Tokens und schnitt Strings nach `\z` | falsch erkannte Helfer | Leerzeichen je Kommentar, `\z` und Backslash-CRLF |
| Zurückgenommene Fehlschläge (`table.remove(t.failures)`) | blieben im Fall; der nächste echte Fehlschlag war in Dialekt d unsichtbar | Dialekt d und h ziehen sie zurück |
| Pool-Race (älter als `2d9c817`) | Nacharbeit nach Timeout lief unter der abgelaufenen Frist, vergiftete den `require` des JSON-Encoders im Pool-Mitglied (Timeout wurde Crash) | `guard:suspend` um `on_case_early`, deterministischer Test |
| Kosten der Regel | `getinfo(level, "fSn")` je Ebene, volle `stack_size()` hinter der Kappung, Quelltext namenloser Chunks kopiert | früher Abbruch, eine Sonde, Kappung bei 4096 Zeichen |
| `scripts/test.sh` ohne `mktemp`-Prüfung; Kommentar versprach zu viel | Läufe schrieben nach `/state` und `/cache` | Abbruch mit Exit 3, Kommentar korrigiert |
| Zwei Specs von `HOME` abhängig | rot bei fremdem `HOME` | eigene Wurzel für lib.nvims Pfad |

## Offene Arbeit

Alles in Task `testing.nvim/pcall-regel-reste-nach-review-runde-4` (Kosten-Nits, XDG, CI-Hygiene, zeitbasierte Specs, hinterlassener Zustand, lib.nvim-Flake)
sowie `dialect-escaped-fail-verdict` und `dialect-pcall-ask-api`. Bleibende Grenzen (falsch grün): Lua-Laufzeitfehler vor dem `xpcall`-Handler, eine per `H`
exportierte Support-Datei im Harness-Verzeichnis, die Fehler behält, und Code, der unter dem Chunk-Namen des Specs geladen wird.

## Nebenbefunde

- `scan_hostile_line_spec.lua` ist zeitbasiert (250 ms) und war im Gesamtlauf einmal unter Last rot.
- lib.nvim `run_argv_spec.lua:220` (Windows, erwartet Exit-Code 124, bekam 1) ist ein Flake; Neustart grün.
- `health_guards_spec` lässt `LIB_NVIM_ROOTS_EXPORTED` und `NVIM_CONFIG_DIR` zurück (Warnung des State-Guards bei jedem Lauf).
- Im Vault melden `tasks.lua check` und der Index weiterhin vorbestehende Befunde (`event-stream-and-cooldown` liegt als `done` noch in `ROADMAP/tasks/`).
