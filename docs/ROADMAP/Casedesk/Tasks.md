<!-- INBOX für schnelle Ideen zu casedesk.nvim — hier unsortiert sammeln.
     Der Plan steht in IMPLEMENTIERUNGSPLAN.md (Verweis daneben), die offenen
     Aufgaben in wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md.
     Bei Sitzungsbeginn als RM-nn einsortieren und hier streichen. -->


## :Cases week

Der Befehl zeigt die Fälle, an denen du im gewählten Zeitraum Dateien geändert hast. Sortiert wird nach Priorität (P1 zuerst, Fälle ohne Priorität zuletzt), innerhalb einer Priorität nach dem jüngsten Stand. Ein Treffer öffnet die Infocard.

Eingabe	Zeitraum
:Cases week	diese Woche, Montag bis heute
:Cases week last oder last week	die letzte volle Woche, Montag bis Sonntag
today, yesterday	heute, gestern
last 4 weeks, last 10 days	28 bzw. 10 Tage rückwärts, heute eingeschlossen
month, last month, last 3 months	Monat bis heute, voller Vormonat, 3 Monatsanfänge zurück
year, last year	Jahr bis heute, volles Vorjahr

Task: In der autocompletion im usrcmd werden last usw. nicht angezgit; solte aber
