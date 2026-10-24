# Plan: Restarbeiten aus dem Chat der Ansichten (2026-10-22)

Ziel: die offenen Punkte nach `tasks.nvim/tasks-app-ansichten-gruppieren-und-visualisieren` (abgeschlossen
2026-10-21) so abarbeiten, dass nichts auf etwas wartet, das schon gehen koennte. Jeder Punkt ist eine Task; hier steht
nur die Reihenfolge und warum. Der Stand steht in den Tasks, nicht hier.

## Schon erledigt (2026-10-22, beim Schreiben dieses Plans)

- `:Cases tasks` gibt es nicht: die Routen von `:Cases` (`lua/casedesk/bindings/usrcmds.lua`, `cases_routes`) haben
  kein `tasks`. Tasks der Faelle: `:Case task new|list|open|done`; ohne Fall und Liste: `:Tricentis task new`,
  `:Tricentis tasks`; Vault `$REPOS_DIR/tricentis-vault`.
- `tasks-desktop@b54aa71` gehoert zur Ansichten-Task: die Nachricht nennt die Setup-Seite, der Commit enthaelt aber die
  Route `groupings` (`routes.rs`, `engine/mod.rs`, Testkit) aus Schritt 3.

## Reihenfolge

Grundsatz: zuerst, was dich nur Minuten kostet und Arbeit freigibt (Entscheidungen); dann kurze Arbeiten mit festem
Termin; dann die groesseren, die schon bereit sind; zuletzt, was auf andere Tasks wartet. Ein Agent zur Zeit.

### 1. Deine Entscheidungen (du, je ca. 5 bis 10 min, gibt Arbeit frei)

| Task | Was du tust | gibt frei |
|---|---|---|
| `casedesk.nvim/swat-stand-quelle-entscheiden` | Quelle des SWAT-Stands waehlen (Empfehlung in der Task: von Hand im Fall) | `casedesk.nvim/offene-swats-auflisten` |
| `tasks-desktop/tasks-desktop-vaults-gemischte-ansichten-erledigt-und-verbin` | Kontext und Akzeptanz eintragen (die Task ist leer) | sich selbst |

### 2. Mit Termin (ich, je ca. 5 bis 15 min)

| Task | Wann | Warum jetzt |
|---|---|---|
| `tasks.nvim/mindestreife-ausnahmen-entfernen` | ab 2026-10-23 ~01:30 UTC (Erinnerung gesetzt) | die beiden Ausnahmen sind dann ohne Wirkung |

(`appkit/ui-kit-markdown-it-15-0-3` ist schon erledigt: `appkit@8c25148`, mit appkit v0.13.1 in `tasks-desktop@8555dd7`.)

### 3. Bereit, ich (in dieser Reihenfolge)

| Task | Aufwand | Warum diese Stelle |
|---|---|---|
| `tasks.nvim/ansichten-fix-commits-nachreview` | ca. 1 h | klein, und jedes Review der Strecke fand echte Fehler: vor neuem Code auf denselben Dateien |
| `casedesk.nvim/offene-swats-auflisten` | ca. 1 d | sobald Schritt 1 entschieden ist |
| `tasks.nvim/tasks-desktop-verbindungen-gruppierung-netz-darstellung-rust` | ca. 1 d | baut auf dem Gruppieren der Ansichten auf, das jetzt steht |
| `tasks-desktop/tasks-app-abhaengigkeits-ansicht-reihen-pfeile-drag-drop` | Entwurf ca. 0,5 d, dann du | ich schreibe den Konzeptentwurf (Akzeptanz 1 und 2 der Task), du nimmst ab; erst dann bauen |
| `tasks.nvim/tasks-nvim-engine-optionale-datumsfelder-due-und-start` | ca. 1 d (Engine) | Voraussetzung (weich) des Kalenders |
| `tasks-desktop/tasks-app-kalender-und-zeitleisten-ansicht` | ca. 2 d | erst nach den Datumsfeldern; Layout-Bibliothek gemeinsam mit der Abhaengigkeits-Ansicht entscheiden |

### 4. Nebenher beobachten (keine Arbeit, solange nichts auffaellt)

- `tasks-desktop/flackernder-browser-test-the-link-pairs-the-tab` (Windows-Runner).

## Was am schnellsten geht

1. Du: die zwei Entscheidungen aus Schritt 1 (zusammen ca. 15 min). Danach kann ich ohne Rueckfrage durchgehen.
2. Ich: `ansichten-fix-commits-nachreview`, danach `offene-swats-auflisten` oder `verbindungen-...` (je nachdem, was dir
   wichtiger ist), am 23.10. zwischendurch `mindestreife-ausnahmen-entfernen`.
3. Parallel nur, was dich nicht bindet: der Konzeptentwurf der Abhaengigkeits-Ansicht liegt bereit, waehrend ich baue.
