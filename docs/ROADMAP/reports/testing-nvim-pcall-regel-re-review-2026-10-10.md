# testing.nvim: die pcall-Regel im Re-Review

Stand 10.10.2026 · geprüft: `testing.nvim` `74bf1d4`, `fbcba7d`, `20f33d1` und die Folgekorrektur, die WKDBooks-Task-Notizen · Neovim 0.12.2 unter Linux
(Windows und macOS nur über die CI) · Werkzeuge der Läufe: Workflows `wf_8c4add6c-5ff` und `wf_b7270a7a-e4e`

## Kurzfassung

Die Regel "ein fehlgeschlagener Check wirft, wenn der `pcall` des Specs ihn fängt, sonst wird er aufgezeichnet" (Befund F-1 des
[Flotten-Audits](testing-nvim-flotten-audit-abdeckung-und-extraktion-2026-10-09.md)) ist eine **Vermutung aus dem Aufruf-Stack**. Drei Fassungen
(`74bf1d4`, `fbcba7d`, `20f33d1`) und zwei unabhängige Re-Reviews zeigen, wo sie trägt:

- Sie trägt für das Muster, das F-1 ausgelöst hat (`pcall(H.with_patched, ..., function() H.eq(1, 2) end)` in `lib.nvim/TESTS/harness_spec.lua`), und für
  alle Fleet-Suiten: keine Verdikt-Flips in ui.nvim (0 von 1906), tasks.nvim (0 von 44), runtime-analysis.nvim (0 von 30); in lib.nvim kippt nur
  `harness_spec.lua` (von `error` auf `pass`, gewollt).
- Sie hatte **Falsch-grün-Löcher**: Ein Check, der in einem Callback des Plugins unter Test fehlschlug, wurde in dessen `pcall` geworfen und verschwand.
  Die erste Fassung (`74bf1d4`) tat das bei jedem fremden `pcall`; `fbcba7d` bei allen außer Tail-Call, Rekursion ab 195 Ebenen, Koroutinen mit
  passender Tiefe, Plugins unter einem Verzeichnis `lua/testing/` und Harness-Exporten; die letzten Löcher sind in der Folgekorrektur zu `20f33d1`
  geschlossen (`testing.nvim@2d9c817`).
- Was sich nicht beheben lässt, ist dokumentiert (`docs/DIALECTS.md`, Abschnitt "A spec that asks"): die Callbacks, die Neovim selbst fängt, und ein
  Spec-eigener Mock. Die strukturelle Antwort ist eine **explizite Frage-API** statt Stack-Raten (Task `dialect-pcall-ask-api`).

## Methode und Grenzen

| Lauf | Prüfer | Befunde | Gegenprüfung |
|---|---|---|---|
| 1 (`wf_8c4add6c-5ff`) | Algorithmus, Integration und Flotte, Tests/Doku/Werkzeuge, WKDBooks-Commit | 47 | 13 von 47 vollständig (je ein Prüfer, der reproduziert, und einer, der widerlegt); 58 von 87 Agenten scheiterten am Sitzungslimit, der Vollständigkeits-Kritiker ist ausgefallen |
| 2 (`wf_b7270a7a-e4e`) | "Break it" (etwa 120 neue Fälle, 50 Mutanten), Tests und Doku (69 Mutanten), WKDBooks-Tasks | 14 + 13 + 13 | keine zweistufige Gegenprüfung; die Befunde habe ich einzeln gelesen und die Korrekturen durch Tests belegt |

Die nicht gegengeprüften Befunde sind nicht alle durch Ausführung bestätigt. Wo ein Befund den Code betraf, steht ein Test dafür in
`TESTS/testing/core_assert_spec.lua`, `dialect_h_spec.lua` oder `dialect_busted_spec.lua`.

## Ursachen und Stand

| Ursache | Befunde (Lauf 1 / 2) | Stand |
|---|---|---|
| Suche bei 200 Frames abgeschnitten; `stack_size()` quadratisch; Kommentar versprach das Gegenteil | algorithm-2, -10, integration-2, -7, tests-docs-1, -7 / break-it-6 | behoben: Halbierung statt Schrittfolge; Suche über 500 Ebenen zeichnet auf |
| Stapelhöhen über Thread-Grenzen verglichen (Koroutinen) | algorithm-3, integration-1 / tests-docs-4 | behoben: Thread wird beim Einstieg gemerkt; Test über 201 Tiefen |
| Runner als Teilstring `lua/testing/` | algorithm-4, -5 / break-it-7 | behoben: Runner ist das Verzeichnis des eigenen Chunks (auf Windows über die CI belegt); Selbst-Test dokumentiert |
| Harness nur die Datei `harness.lua`; später jede Datei mit einer `H`-Funktion | integration-5, tests-docs-8 / tests-docs-1, break-it-1, -3, -8 | behoben: Harness sind `harness.lua` und die Dateien unterhalb ihres Verzeichnisses, die eine `H`-Funktion definieren (eine Tabellenebene tief, nur eigene Felder); der Chunk des laufenden Specs gehört nie dazu |
| Tail-Call-`pcall` im Plugin-Helfer | algorithm-7, integration-6 / break-it-2 | behoben: Ein Frame zählt nur, wenn er als `pcall`/`xpcall` (global, lokal, Upvalue) aufgerufen wurde |
| Wrapper in fremder Datei, der den Spec unter eigenem `pcall` ausführt | algorithm-6 / tests-docs-2 | behoben: Der Dialekt gibt die Datei des Specs mit; ein Dispatcher mit gemeinsamer Fallsammlung, eine Helferdatei und `vim.F.npcall` bleiben "aufzeichnen" (laut, dokumentiert) |
| `a.fail` (negierte luassert-Prüfungen) wirft nicht im `pcall` des Specs | integration-3, wkdbooks-4 | behoben |
| `debug.getinfo` im Spec ersetzt: Suche läuft endlos | integration-7 / break-it-5, wkdbooks-8 | behoben: `debug.getinfo` und `coroutine.running` werden beim Laden gemerkt |
| Von Neovim geschützte Callbacks (Autocmd, Keymap, Timer, `vim.schedule` beim Warten, getippte Tasten) | algorithm-1, integration-4, tests-docs-2 / break-it-9, tests-docs-12 | nicht lösbar auf Lua-Ebene; dokumentiert (inklusive der Pfade, die den Fehler weitergeben); Guard `scheduled_error` macht die meisten rot |
| Spec-eigener Mock; Check im Message-Handler des eigenen `xpcall` | algorithm-8 / break-it-4 | dokumentiert; Task `dialect-pcall-ask-api` |
| `a.error` / `a.no_error` / luassert `has_error` fangen selbst, zählen aber als Runner | algorithm-9, integration-8, wkdbooks-5 / tests-docs-8 | offen; Task `dialect-pcall-ask-api` |
| Entkommener `FAIL`-Fehler endet als `error` ohne `file:line` | integration-9 / wkdbooks-6 | offen, bewusst dokumentiert; Task `dialect-escaped-fail-verdict` (mit Traceback-Fallstrick) |
| Testlücken (Mutanten überlebten) | tests-docs-3, -4 / tests-docs-3 bis -6, break-it-11 | behoben: 37 Mutanten laufen gegen die Specs, überlebt haben nur äquivalente (`entry.height - 1`, ein Chunk ohne `@`) |
| Veraltete oder falsche Doku, Typen, Kommentare | integration-10, tests-docs-5, -6, algorithm-11, -12 / tests-docs-9 bis -12, break-it-9, -10, -12 | behoben: DIALECTS.md, README, `doc/testing.txt`, core-README, dialect-README, `@types`, Kopfkommentare |
| WKDBooks-Task-Notizen: falsche Aussagen, zu gemischt, Datum, unbelegte Zahl, lib-Task mit nur einem von zwei Gates, Widerspruch zu Entscheidung A | wkdbooks-1 bis -13 / wkdbooks-1 bis -13, tests-docs-13 | behoben: zwei Tasks (Verdikt-Klasse; Frage-API), lib-Task für beide gegateten Blöcke, Notiz zur verlorenen `.luarc`-Welle im Task `luarc-globals-and-ignoredir` |

## Offene Arbeit

- `testing.nvim/dialect-escaped-fail-verdict`: entkommener `FAIL`-Fehler als aufgezeichneter Fehlschlag buchen.
- `testing.nvim/dialect-pcall-ask-api`: explizite Frage, `a.error`/`has_error` darauf umstellen, Beobachtbarkeit geworfener Checks im IR.
- `lib.nvim/git-run-spec-skip-visible`: die zwei gegateten Blöcke in `git_run_spec.lua` sichtbar auslassen.
- `ALL/luarc-globals-and-ignoredir`: NEW-37 (`.claude` in `workspace.ignoreDir`); das Skript der ersten Welle ist verloren.

## Nebenbefunde

- Die Welle `vim` aus `diagnostics.globals` (40 Commits am 09.10.): 38 öffentliche Commits gelesen, alle ändern nur `.luarc.json` und entfernen nur `vim`;
  `my` und `casedesk` (privat) nicht prüfbar.
- Zwei Specs von testing.nvim (`core_result_spec`, `dialect_busted_spec`) sind rot, wenn `lib.nvim` als Nachbarverzeichnis statt unter `.deps/` liegt
  (der Pfad `/home/<nutzer>/` im Traceback gilt als Heimatpfad). Das gilt vor und nach der Korrektur; die CI nutzt `.deps/`.
- `tasks.lua check testing.nvim` meldet weiterhin den vorbestehenden Fehler `done-in-roadmap` (Task `event-stream-and-cooldown` liegt als `done` noch in
  `ROADMAP/tasks/`) und vier Warnungen `plan-acceptance-uncovered`.
