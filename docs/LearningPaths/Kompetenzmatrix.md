# Kompetenzmatrix

Wo stehe ich fachlich, gemessen am intellektuellen Niveau der akademischen Stufen? Es geht nicht um den
Titel, sondern um das Können dahinter. Verknüpft mit dem [Lernplan](Lernplan.md); fehlende Bücher stehen
in der [Beschaffungsliste]($REPOS_DIR/Literatur/Beschaffungsliste.md).

## Die Skala

Jedes Gebiet bekommt **zwei** Werte auf derselben Skala:

- **T (Theorie):** Was ich erklären, herleiten und beweisen kann.
- **P (Praxis):** Was ich selbst bauen kann, ohne KI-Hilfe beim Schreiben.

Der Grund für zwei Werte: „Profi“ ist eine Praxis-Stufe, „Bachelor“ eine Wissens-Stufe. Ein Profi-Entwickler
liegt in der Theorie oft unter Bachelor-Niveau und ein frischer Bachelor in der Praxis unter Profi. Mit nur
einem Wert würde die Skala diese beiden Achsen vermischen.

| Stufe | Name | T: Theorie (Kriterium) | P: Praxis (Kriterium) | Nachweis, damit die Stufe zählt |
|---|---|---|---|---|
| 0 | Unbekannt | Begriffe sagen mir nichts | nie benutzt | – |
| 1 | Newbie | kenne die Begriffe, kann sie grob einordnen | Tutorials nachbauen | – |
| 2 | Fortgeschritten | kann die Kernkonzepte frei erklären (Feynman-Test: ohne Notizen, einem Laien) | kleine eigene Programme ohne Vorlage | Erklärung schriftlich in WKDBooks, ohne Nachschlagen |
| 3 | Profi | kenne die Trade-offs und typischen Fehler, lese Fachbücher flüssig | baue und warte produktive Software, andere nutzen sie | Projekt, das andere einsetzen; Code-Review durch Dritte |
| 4 | Bachelor | löse die Übungen und Klausur eines Bachelor-Moduls unter Zeitdruck | Abschlussprojekt-Niveau: nicht triviales System von Grund auf (z. B. Shell, malloc, Interpreter) | alte Uni-Klausur ohne Hilfsmittel bestanden **und** Projekt ohne KI |
| 5 | Master | lese aktuelle Fachpaper und reproduziere ihre Ergebnisse; kenne die Grenzen des Gebiets | implementiere ein klassisches Paper nach (z. B. Raft, ein GC, ein Register-Allokator) | reproduziertes Paper mit Messungen, öffentlich |
| 6 | Doctor | erzeuge **neues** Wissen: ein Ergebnis, das es vorher nicht gab | Werkzeug oder Methode, die über den Stand der Technik hinausgeht | Begutachtete Veröffentlichung (Konferenz, Journal) oder gleichwertig anerkannter Beitrag |
| 7 | Professor | überblicke das ganze Gebiet, ordne Forschung ein, kann es lehren | leite Vorhaben, an denen andere forschen | Lehrbuchkapitel, Survey, betreute Arbeiten |
| 8 | Mastermind | präge das Gebiet; andere bauen auf meinen Ideen auf | (Knuth, Lamport, Liskov, Thompson) | Das Gebiet sieht nach dir anders aus |

**Regeln:**

- **Ohne Nachweis gilt die Stufe darunter.** Gelesen ist nicht verstanden; ein Kapitel zu Ende gelesen gibt
  noch keine Stufe.
- **Lesen bringt dich bis Stufe 5.** Ab Stufe 6 muss etwas Neues entstehen, das kein Buch liefern kann.
  Ab dort zählen Forschung, Austausch und Kritik durch Fachleute.
- **Mit KI gebaut zählt für P höchstens bis 3.** Ab Stufe 4 muss ich jede Zeile selbst geschrieben haben
  oder herleiten können.
- **Halbe Stufen** sind erlaubt (`3.5` = Nachweis für 4 begonnen).
- **Jedes Quartal neu einstufen** und die alte Zeile in die [Historie](#historie) verschieben.

## Profilziel: T-Form

Nicht überall Master. Sinnvoll ist ein **T-Profil**: in ein bis zwei Gebieten in die Tiefe (Stufe 5 als
Ziel), in der Breite Bachelor-Niveau (Stufe 4). Naheliegend für die Tiefe, nach Interessen und Bestand:
**Systeme** (Betriebssysteme, Rechnerarchitektur) und **Programmiersprachen** (Compiler, Interpreter, Lua).

## Aktuelle Einstufung

Erste Schätzung von Claude am 2026-10-29, abgeleitet aus Notizen und Repos. **Noch nicht durch Nachweise
geprüft**, `?` = keine Grundlage für eine Schätzung, zuerst einen Einstufungstest machen.

| Gebiet | T | P | Ziel 12 Mon. | Ziel 24 Mon. | Lernplan | Begründung / nächster Nachweis |
|---|---|---|---|---|---|---|
| **Informatik-Kern** | | | | | | |
| Algorithmen & Datenstrukturen | 2 | 2 | 3 | 4 | Phase 3 | Notizen zu Skip-List, Levenshtein, Komplexität. Nachweis 4: Klausur „Algorithmen und Datenstrukturen“ |
| Betriebssysteme | 3 | 1 | 4 | 4.5 | Phase 0, 1 | Stallings Kap. 1–8 und 10 mit gelösten Problems. Nachweis 4: Klausur Betriebssysteme und eigene Shell in C |
| Rechnerarchitektur | 2 | 1 | 3 | 4 | Phase 1 | Notizen zu Cache, MESI, Pipelines. Nachweis: CS:APP-Labs |
| Compiler & Interpreter | 1 | 1 | 3 | 4 | Phase 2 | Viele Bücher, kaum Notizen. Nachweis 4: clox komplett selbst geschrieben |
| Programmiersprachen-Theorie | 1 | 1 | 2 | 3 | Phase 7 | Notizen zu Monaden, SICP begonnen. Nachweis: Typchecker für Lox |
| Datenbanken | 1 | 1 | 2 | 4 | Phase 5 | Kaum Material. Nachweis 4: Klausur Datenbanksysteme und eigener KV-Store |
| Rechnernetze | 2 | 1 | 2 | 4 | Phase 6 | Viele Bücher, wenig eigene Notizen. Nachweis: HTTP-Server auf Sockets |
| Verteilte Systeme | 1 | 1 | 1 | 3 | Phase 6 | Nachweis: Raft (MIT 6.5840 Labs) |
| IT-Security | 2 | 2 | 3 | 3 | – | Cyber-Security-Repo, Reverse-Engineering-Bücher; seit 2026-10-29 rund 200 Bücher in `Literatur-Security` (u. a. Web Application Hacker's Handbook). Nachweis: CTF-Ergebnisse |
| Machine Learning / KI | 1 | 1 | 1 | 2 | nach M4 | LLM-Integration (ai.nvim, ai-desktop) ist Engineering, kein ML. Setzt Stochastik und LA voraus. Bücher liegen in `Literatur-PythonAI/07_AI_ML` (u. a. Russell/Norvig 4th) |
| **Software Engineering** | | | | | | |
| Softwarearchitektur & Design | 2 | 3 | 3 | 4 | Phase 4 | Plugin-Ökosystem auf lib.nvim, rules-vault mit Gates. Nachweis: ADRs und Review eines Dritten |
| Testing & QA | 2 | 3 | 3 | 4 | Phase 4 | testing.nvim, Beruf bei Tricentis. Nachweis: Testsuite eines Plugins nach Khorikov neu aufgebaut |
| Tooling, Git, Shell, CI | 3 | 3 | 3.5 | 4 | – | Neovim-Config, PowerShell-Setup, CI-Skripte |
| **Sprachen** | | | | | | |
| Lua | 3 | 3 | 4 | 4.5 | Phase 2 | Über 30 Plugins. Nachweis 4: Paper „Implementation of Lua 5.0“ erklären können, Beitrag zu Neovim-Core |
| C | 1 | 1 | 3 | 4 | Phase 1 | Nachweis: malloc-Lab, clox |
| C++ | 2 | 1 | 2 | 3 | – | 162 Notizen, wenig eigener Code (ai-desktop) |
| Rust | 1 | 2 | 2 | 3 | Phase 5 | Tauri-Apps (tasks-desktop, rules-desktop). Nachweis: KV-Store in Rust ohne KI |
| TypeScript / Web | 2 | 2 | 2 | 3 | – | Astro, Svelte, wkd |
| **Mathematik** | | | | | | |
| Beweistechnik & Logik | ? | – | 3 | 4 | M1, T1 | Einstufungstest: MCS Kap. 1–3, Übungen |
| Diskrete Mathematik | ? | – | 3 | 4 | M1 | Nachweis 4: Klausur MIT 6.042J |
| Lineare Algebra | ? | – | 2 | 4 | M2 | Nachweis 4: Klausur MIT 18.06 |
| Analysis | ? | – | 2 | 4 | M3 | Nachweis 4: Klausur Analysis für Informatik |
| Stochastik | ? | – | 1 | 4 | M4 | Nachweis 4: Klausur Stochastik |
| Theoretische Informatik | 1 | – | 1 | 4 | T1 | Nachweis 4: Klausur Theoretische Informatik (Automaten, Berechenbarkeit, NP) |
| **Weitere** | | | | | | |
| Elektronik & Digitaltechnik | ? | ? | – | – | – | Skripte vorhanden, kein Ziel gesetzt |
| Wissenschaftliches Arbeiten | 1 | 2 | 2 | 3 | T2 | Strukturierte Notizen und Quellenarbeit mit litindex sind eine gute Basis. Nachweis 3: ein Paper gründlich lesen und schriftlich zusammenfassen |

## Weitere Ideen zu diesem Punkt

- **Einstufung kalibrieren, nicht schätzen.** Für jedes Gebiet mit `?` zuerst eine alte Klausur
  ohne Vorbereitung schreiben. Das Ergebnis ist der Startwert, nicht das Gefühl.
- **Stufe 5 braucht Austausch.** Ein Lesekreis (z. B. Papers We Love), Konferenzvorträge (CppCon,
  Handmade, Strange Loop sind archiviert) und Beiträge zu großen Open-Source-Projekten. Ein angenommener
  Patch in Neovim-Core oder LuaJIT ist ein echter Praxis-Nachweis über Stufe 3.
- **Stufe 6 ohne Titel ist möglich**, aber selten: Es braucht ein offenes Problem, Zeit und Gutachter.
  Der realistische Weg dorthin führt über einen Workshop-Beitrag oder eine Zusammenarbeit mit einem
  Lehrstuhl.
- **Feynman-Test als Gewohnheit:** Nach jedem Kapitel eine Erklärung in WKDBooks ohne Nachschlagen. Was
  dabei hakt, ist noch nicht Stufe 2.

## Historie

| Datum | Änderung |
|---|---|
| 2026-10-29 | Erste Einstufung (Schätzung Claude, ungeprüft) |
| 2026-10-29 | Bestand um rund 1.560 Bücher in fünf Themen-Repos erweitert; Hinweise bei IT-Security und ML/KI ergänzt, Einstufung unverändert |
