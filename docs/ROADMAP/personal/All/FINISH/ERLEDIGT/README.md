# FINISH/ — was hier welche Rolle hat

Sechs Dateien, die sich leicht verwechseln lassen. Kurz, damit niemand
(ich eingeschlossen) das nächste Mal in der falschen sucht.

## Die zwei Arbeitsdateien

| Datei | Rolle |
| --- | --- |
| **`MERGED.md`** | Die **offene** Liste. Zusammengeführt und dedupliziert aus den vier Quellen unten, geteilt in *Liste A — braucht dich* und *Liste B — delegierbar*. Hier wird gearbeitet. |
| **`Merged_Finished.md`** | Das **Erledigte**, neueste zuerst. Was aus `MERGED.md` herausfällt, landet hier — mit dem Was *und* dem Warum, samt der Fälle, in denen sich die ursprüngliche Annahme als falsch herausstellte. |

Ein Punkt gilt als erledigt, wenn er aus `MERGED.md` verschwindet und in
`Merged_Finished.md` auftaucht. Nicht durch ein `[x]` in `MERGED.md` — das
ist nur ein Zwischenzustand für Punkte, die noch einen Rest offen haben.

## Die vier Quellen

`MERGED.md` ist aus diesen entstanden. Sie sind **nicht** überflüssig, weil
zwei davon einen anderen Zweck haben als eine Aufgabenliste:

| Datei | Rolle |
| --- | --- |
| **`CHECKLIST.md`** | Eine **wiederverwendbare Qualitätscheckliste pro Plugin** (Module, README, Healthchecks, Cross-Plattform, Defaults, Konfigurierbarkeit, which-key, Git). Nicht einmalig abzuarbeiten, sondern bei jedem Plugin durchzugehen. Deshalb bleibt sie stehen, auch wenn Punkte abgehakt sind. |
| **`CDX.md`** | „Auf alle Plugins anwenden" — dieselbe Idee, gröber. |
| **`FINISH_ME.md`** | Cheatsheet-Ziele, vimdoc, Selektions-Handling. |
| **`Meins.md`** | Ausdrücklich manuell, mit der Zeile *„AN CLAUDE: NOCH NICHT IMPLEMENTIEREN: EINFACH IGNORIEREN!"* im Kopf. Bitte respektieren. |

Wo ein Punkt in einer Quelle durch konkrete Arbeit geschlossen wurde, steht
dort ein `[x]` mit ✅-Datum und dem Verweis auf `Merged_Finished.md` — der
Rest der Datei bleibt als Checkliste brauchbar.

## Die Reports

Die Ergebnisse der größeren Analysen sind **keine** Roadmap-Einträge, liegen
aber inzwischen in genau diesem Ordner (der Satz „eine Ebene höher in
`docs/ROADMAP/`" stand hier bis 2026-09-02 und stimmte da schon nicht mehr):

- `keymap-command-parity.md` — ist jede Keymap auch als Kommando erreichbar?
- `nicht-konfigurierbare-features.md` — benannte Konstanten, die Config-Keys sein sollten
- `zahlen-ohne-namen.md` — Zahlen direkt im Aufruf, plus Plattform-Verzweigungen
- `roadmap-tools-analysis.md` — was aus den Skripten wurde, die diese drei
  Reports erzeugt haben

Die Skripte selbst gibt es nicht mehr als Skripte. Sechs sind zu
Plugin-Commands geworden (`:LibBindingsAudit`, `:LibBindingsAuditGaps`,
`:LibDuplicateScan`, lib.nvims `scripts/bench_dispatcher.lua`,
`:Insights smells`), einer wurde verworfen, und `run_all_tests.sh` liegt in
[`scripts/`](../../../../../../scripts/run_all_tests.sh). Wiederholbar sind die
Analysen damit weiterhin — nur über die Commands statt über den Ordner.
`roadmap-tools-analysis.md` sagt für jedes Skript, welcher es ist und warum.

`Merged_Finished.md` fasst zusammen, was daraus umgesetzt wurde, und
verweist auf den jeweiligen Report für die Details.
