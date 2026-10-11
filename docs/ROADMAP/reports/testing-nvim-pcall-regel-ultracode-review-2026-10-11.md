# testing.nvim: Ultracode-Review der Commits `d4fa2dd` bis `cb38e5e` und der Nebenrepos

Stand 11.10.2026 · geprüft: `testing.nvim` `d4fa2dd`..`cb38e5e`, `lib.nvim` `437017e`, sieben `.luarc.json`-Commits, WKDBooks `3e45886` · Neovim 0.12.2 unter Linux
(Windows und macOS über die CI) · Fortsetzung von [testing-nvim-pcall-regel-runden-4-5-2026-10-10.md](testing-nvim-pcall-regel-runden-4-5-2026-10-10.md) ·
Werkzeug des Laufs: Workflow `wf_506ce16f-4d5` (28 Agenten, 3,8 Mio. Token der Teil-Agenten, 3,2 Stunden)

## Kurzfassung

Der Review fand **ein kritisches und zwei weitere Falsch-grün-Löcher** in den Commits, die selbst Fehler beheben sollten. Alle bestätigten Funde sind behoben, getestet und auf
`main`; die komplette Suite ist 172/172 grün (vorher 171 plus die neue `repo_script_spec`).

- Das kritische Loch (`cb38e5e`, `a.ask`): `ask` löste "wirft immer" aus, auch wenn zwischen Check und `ask` der `pcall` des Codes unter Test lag. Der fehlgeschlagene Check
  verschwand und der Fall war grün, wo der Stand davor ihn aufgezeichnet hatte. Betroffen waren `H.ask`, `a.error`, `a.no_error` und luassert `has_error` / `has_no.errors`.
- Zwei Rücknahme-Lücken (`9a18891`): Dialekt h und d nahmen Fehlschläge nach **Anzahl** zurück statt nach **Inhalt**. Wurde die Fehlerliste kürzer als zu Beginn oder enthielt
  sie schon Einträge, wurde der falsche Fehlschlag zurückgenommen und die Datei war grün. In einem Zufallslauf (ein Anfangseintrag, 1500 Läufe) war der Stand `cb38e5e`
  65-mal grün trotz neuer Fehler, der Stand davor 8-mal.
- Der **Mutationstest** zeigte die eigentliche Schwäche: Die vorhandenen Tests töteten nur **118 von 234 Mutanten (50,4 %)**, 77 Überlebende waren echte Testlücken. Mit den
  neuen Tests sind es 195 von 234 (83,3 %); die übrigen 39 sind gleichwertig oder nicht beobachtbar.
- Ein unabhängiger Review der **Fix-Commits dieses Laufs** hat nicht stattgefunden (siehe "Offen").

## Methode und Grenzen

| Phase | Inhalt |
|---|---|
| Review | 7 Perspektiven: Kern (`a.ask`, Buchung entkommener Raises), Dialekte (`harness_project`, `harness_d`, luassert, `lua_text`), Runner/CI/Skripte/Security/Performance, Nebenrepos, Mutationstest, Schwarzkasten-Vergleich BASE gegen CAND, Doku-Wahrheit/Typen/Zahlen |
| Dedupe | 77 Rohfunde zu 60 verschiedenen |
| Verifikation | 20 Funde (alle kritischen, hohen, mittleren und jeder Falsch-grün) von je einem unabhängigen Agenten gegen den unveränderten Stand nachgebaut: 19 bestätigt, 1 widerlegt |

Die ersten drei Linsen liefen nacheinander (ein Agent), die übrigen vier und die Verifikation mit bis zu 5 Agenten gleichzeitig auf 4 Kernen. Bei den Fünf-Agenten-Läufen waren
zeitabhängige Specs (`scan_hostile_line_spec`) anfällig; sie wurden einzeln wiederholt und gehärtet (siehe unten). Low- und Nit-Funde (40) hat kein Agent verifiziert; ich habe sie
selbst gelesen und beurteilt.

## Gefunden und behoben

| Fund | Schwere (Verifier) | Wirkung | Behoben in |
|---|---|---|---|
| `ask` gibt den Check an den `pcall` des Codes unter Test weiter (K1) | **hoch**, falsch grün | Fall grün, Check verschwunden | `9f8c3e0`: `ask` ist ein Einstiegspunkt für `protected.inside` (`asked`); Plugin-`pcall`, Handler und C-Frame unter `xpcall` zeichnen weiter auf |
| Frage-Zustand ist ein globaler Zähler plus ein Thread (K2, K3, B2) | mittel, falsch grün | eine Coroutine, die in einem `ask` yieldet, ließ den Hauptthread bis zum Ende des Workers "fragen" | `9f8c3e0`: schwache Tabelle je Thread; `begin_case` leert sie; `a.ask` behält das echte `pcall` |
| `deep_equal` tiefer als 100 Ebenen = "verschieden" (K4) | niedrig, falsch grün | `are_not.same` bestand bei gleichen tiefen Tabellen | `9f8c3e0`: "unentschieden" (raised) |
| Rücknahme in Dialekt h nach Anzahl (D1) | mittel, falsch grün | Datei grün trotz neuer Fehler, wenn die Liste kürzer endete | `c21899a`: pro Fehlschlag die eigenen Werte merken, nach Inhalt vergleichen |
| Rücknahme in Dialekt d nach Anzahl (D2) | mittel, falsch grün | falscher Fehlschlag zurückgenommen | `c21899a`: Inhalt statt Anzahl; ersetzte Liste enthält keine alten Einträge |
| luassert-Stellvertreter außerhalb eines Falls ohne `ask` (L1) | mittel, falsch rot | `assert.has_error(fn, expected)` in `describe`/`setup` stürzte ab | `c21899a` |
| `sniff.H_KEYS` ohne `ask` (S1) | mittel (F3) | `H.ask`-Specs wurden als "dialect unknown" nicht ausgeführt | `c21899a` |
| `error_site` ein Slot nach Text (E1), `record_escaped` bucht jeden FAIL-Text (E2), verschachtelte Collector (H2, B1) | niedrig | falsche Zeile, Plugin-Fehler "FAIL..." als Check gebucht, übrig gebliebene `[FAIL]`-Zeile | `c21899a` |
| Quadratischer Namens-Scan bei langen Bezeichnern (R1, P1) | niedrig (Security, Verifier) | 100 KB = 53 s vor jedem Guard | `c21899a`, `6e036f9`: `%f[%w_]` in `harness_project` und `harness_profile` |
| Fristfenster des nächsten Falls (R2) | niedrig | Zeit des Streamens ging auf den nächsten Fall | `6e036f9`: ganzer Block nach dem Fall unter `suspend`, Fenster danach |
| `nightly.yml` ohne `persist-credentials: false` (R6) | niedrig | Token blieb im Checkout | `6e036f9` |
| Test-Hygiene (R3, R4, R5, R8) | niedrig | Flake unter Last, `debug.sethook()` schaltete den Datei-Guard ab, cwd-Leck, Temp-Dateien | `6e036f9`, `5405eb7` |
| `prep_cov.sh` löscht ein Repo der Fleet (R7) | niedrig (Verifier) | `rm -rf` bei `<fleet-cov>` in `<fleet>`, `/`, `$HOME` | WKDBooks `654fbad` |
| Root-Harness: Einzeldatei-Plugin im Stamm zählt als Harness (R2 Dialekte) | niedrig, falsch grün | Check verschwand im `pcall` des Plugins | `5405eb7`: im Stamm zählen nur die Harness-Datei und `tests/ test/ spec/ specs/` |
| Dialekt d: Check beim Laden der Datei fehlt (F8) | niedrig, falsch grün (alt) | Datei grün, obwohl die Projektvariante rot gewesen wäre | `5405eb7`: Basislinie vor dem Laden |
| Kleinigkeiten | niedrig/nit | `__tostring`-Meldungen in luassert, Hinweis "guessed" trotz Buchung, `strip_comments` 20 % langsamer, veraltete Doku an acht Stellen | `851d2cb` |
| Testlücken G01–G12 | mittel/niedrig | 77 überlebende Mutanten | `d5b7de4` (880 Zeilen Test, 1 neue Spec, 7 Fixtures) |
| `H.skipped` ohne Zeilenumbruch, `peel_kind` ohne Ursache; `.deps` fehlt in fünf `.luarc.json`; relative Out-Dirs; leeres Verzeichnis bei Ablehnung | niedrig/nit | siehe Commits | lib.nvim `a54108b`, je ein Commit in fünf Repos, WKDBooks `8463157` |

## Bewusst nicht behoben

| Fund | Grund |
|---|---|
| Zweiter Stack-Lauf unter `xpcall` (F5, Verifier: niedrig) | kostet 2 bis 14 µs je **fehlschlagendem** Check, der in einem `xpcall` gefragt wird; die vorgeschlagene Variante A machte den häufigen `pcall`-Weg 15 bis 40 % teurer, Variante B ist es nicht wert |
| C-Frame-Regel zeichnet `xpcall`-Fragen durch `nvim_buf_call`, `table.sort`, `string.gsub`, `require` auf (K7/F4) | laut, nie grün; 0 Vorkommen in den Specs von testing.nvim und lib.nvim; bleibt dokumentiert |
| Helfer des Root-Harness in anderen Verzeichnissen als `tests/` zählen nicht als Harness (F3) | laut statt grün, gewollte Richtung |
| Negiertes `same` mit werfender Tabelle ist rot (F6) | gewollt (kein falsch grün) |
| Aufräumen von totem Code, den gleichwertige Mutanten zeigen (N01) | optional, keine Verhaltensänderung |
| Commit-Nachrichten `9a18891` / `d4fa2dd`: "jeder Test war gegen die vorherige Fassung rot" und "byte-identisch" sind zu stark | Historie wird nicht umgeschrieben; die Zahlen dieses Berichts gelten |
| Task `lib.nvim/git-run-spec-nested-tags-testbar` | die zwei Blöcke der verschachtelten Tags laufen mit git >= 2.44 auf keiner CI-Plattform; als Task angelegt |

## Zahlen

Gemessen (Minimum aus 7, Last etwa 5 auf 4 Kernen, BASE `d4fa2dd` gegen CAND `cb38e5e`):

| Fall | BASE | CAND | Änderung |
|---|---|---|---|
| 1e5 bestandene `a.eq` | 201,6 ms | 116,3 ms | -42 % |
| 1e4 fehlschlagende `a.eq`, aufgezeichnet | 53,1 ms | 52,6 ms | -1 % |
| 1e4 fehlschlagend im einfachen `pcall` | 102,2 ms | 93,5 ms | -9 % |
| 1e4 `run_case`, ein `a.ok` | 70,5 ms | 61,2 ms | -13 % |
| 1e4 fehlschlagend in `a.ask` | n. v. | 32,1 ms (3,2 µs je Check) | |

Nach der Behebung von K1 kostet ein gefragter Check 8 bis 10 µs mehr (Stack-Lauf in `ask`).

## Offen

- **Die Fix-Commits dieses Laufs sind nicht von einem Agenten gegengeprüft**: `9f8c3e0`, `c21899a`, `6e036f9`, `851d2cb`, `d5b7de4`, `5405eb7` (testing.nvim), `a54108b` (lib.nvim), die
  fünf `.luarc.json`-Commits und die drei WKDBooks-Commits. Die Suite (172/172), stylua, luacheck, die CI und die Tests, die gegen den Stand davor rot waren, decken sie, aber die
  Umschreibung der Rücknahme (`reconcile`, `sync` in `harness_d`) und der Fragezustand (`ASKS`) sind neuer Code. Empfohlen: eine Runde mit Kern-, Dialekt- und Schwarzkasten-Linse auf
  `cb38e5e..5405eb7` und ein Mutationstest dieses neuen Codes.
- Die Mutationstests liefen gegen `cb38e5e`, nicht gegen den jetzigen Stand.
- `lib.nvim/run-argv-spec-windows-flake` bleibt bei dir (lokal prüfen).
- Die Aktionen in den CI-Workflows sind nicht auf SHAs festgenagelt (Dependabot oder du).
