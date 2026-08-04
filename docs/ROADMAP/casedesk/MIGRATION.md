# casedesk — Struktur-Migration

> **Status: durchgeführt**, 2026-08-04. Dieses Dokument ist jetzt das
> Protokoll dessen, was migriert wurde — nicht mehr ein Vorschlag.

## Ausgangslage

`C:/repos/WKDBook-Tricentis/Cases/SAP_Support/Cases/` war uneinheitlich: die
meisten Cases lagen flach (`Cases/<nr>`), drei lagen eine Ebene tiefer unter
einem Company-Ordner (`Cases/Scania/711373`, `Cases/SiemensEnergy/855601`,
`Closed/SiemensEnergy/862734` — letzterer sogar unter einem separaten
Top-Level-`Closed/`, nicht unter `Cases/`). `Cases/OtherAgentTookIt/` hielt
lose `.md`-Notizen zu Cases, die an andere Agenten gingen — teils in
Konflikt mit einem echten, parallel bearbeiteten Case (933790 existierte
kurzzeitig doppelt).

## Was der Nutzer vorab erledigt hat

- `OtherAgentTookIt/` gelöscht — der Konflikt mit `933790` war damit vom
  Tisch, bevor die Migration lief.
- Das Repo committet (`3e2b545 safe backup vor :Cases`) als Sicherheitsnetz.

## Der Umzug (`migrate.lua`)

`M.plan()` (rein, nur `fs_scandir`) → `M.run(steps)` (schreibt `.case.json`
**vor** dem Move, dann `fs_rename`) → `M.cleanup()` (entfernt leere
Alt-Ordner). Erst gegen eine Sandbox-Fixture getestet (Plan/Move/Cleanup/
Idempotenz — alles grün), dann gegen die echten Daten.

**Ergebnis: 20 von 20 Umzügen erfolgreich, 0 Fehler.**

| Von                                       | Nach                            | Company gerettet |
| ------------------------------------------ | -------------------------------- | ------------------ |
| 17× `Cases/<nr>` (flach)                   | `Cases/Open/<nr>`                | — |
| `Cases/Scania/711373`                      | `Cases/Open/711373`              | `Scania` |
| `Cases/SiemensEnergy/855601`               | `Cases/Open/855601`              | `SiemensEnergy` |
| `Closed/SiemensEnergy/862734`              | `Cases/Closed/862734`            | `SiemensEnergy` |

`.case.json` wurde für alle 20 Cases neu geschrieben (`case`, `year`,
`company` aus dem alten Pfad, `title`/`name`/`links` per `detect.lua`
best-effort aus dem vorhandenen Inhalt, `created`, `blueprint`).

Cleanup entfernte die jetzt leeren `Cases/Scania/`, `Cases/SiemensEnergy/`,
`Closed/SiemensEnergy/` und den Top-Level-Ordner `Closed/` selbst.

Verifiziert über `registry.list()`: **19 Open, 1 Closed, 0 Reassigned**,
Company-Felder für 711373/855601/862734 korrekt in `.case.json` gelandet.
Zweiter `migrate.plan()`-Lauf liefert 0 Schritte (idempotent bestätigt).

## Endstruktur

```
Cases/SAP_Support/Cases/
  Open/         1007631/ 711373/ 855601/ 859769/ 888622/ 904938/ 913070/
                913901/ 933790/ 934106/ 940561/ 940875/ 941543/ 941948/
                948965/ 968475/ 977283/ 989508/ 996010/
  Closed/       862734/
  Reassigned/   (leer — bereit für den nächsten "an anderen Agenten"-Fall)
```

`Notes/` und `Terminologie/` (Geschwister von `Cases/`, case-übergreifend)
waren nie Teil der Migration und blieben unberührt.

## Was noch offen ist

Die Namens-Inkonsistenzen im Bestand (Case-Notiz heißt an 5 Stellen anders,
`Research` als Ordner *und* Datei, zwei Tippfehler) sind unverändert — siehe
[ROADMAP.md](ROADMAP.md) v6 (`:Cases doctor`/`normalize`). Die Struktur-
Migration war Voraussetzung dafür, nicht dasselbe wie das Aufräumen selbst.
