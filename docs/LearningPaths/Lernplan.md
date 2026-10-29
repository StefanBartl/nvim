# Lernplan Software Engineering

Stand: 2026-10-29. Ziel: in der Breite Bachelor-Niveau (Stufe 4) und in der Tiefe Master-Niveau (Stufe 5)
in Systemen und Programmiersprachen. Die Stufen und den aktuellen Stand zeigt die
[Kompetenzmatrix](Kompetenzmatrix.md); fehlende Bücher stehen in der
[Beschaffungsliste]($REPOS_DIR/Literatur/Beschaffungsliste.md).

Annahme: 8–10 Stunden pro Woche neben dem Job. Zwei Spuren laufen parallel: die **Hauptspur**
(Phasen 0–7, Informatik und Handwerk) und die **Mathe- und Theorie-Spur** (M1–M4, T1–T2).

## Grundregeln

1. **Ein Buch pro Thema.** Die Sammlung hat zu fast jedem Thema mehrere Bücher; die anderen nur
   nachschlagen.
2. **Jedes Kapitel endet mit Code oder gelösten Aufgaben, ohne KI geschrieben.** KI ist danach zum
   Review erlaubt. Siehe die Regel zur Praxis-Stufe in der Kompetenzmatrix.
3. **Feynman-Test:** Nach jedem Kapitel eine Notiz in WKDBooks, die das Thema ohne Nachschlagen erklärt.
4. **Phase abgeschlossen = Nachweis erbracht**, nicht „Buch zu Ende gelesen“. Danach die
   Kompetenzmatrix aktualisieren.

## Hauptspur

| Phase | Monate | Lesen | Selbst bauen (Nachweis) | Hebt in der Matrix |
|---|---|---|---|---|
| **0** | 0–2 | [Stallings OS (9th)]($REPOS_DIR/Literatur/01_Fundamentals/Operating_Systems/W_Stallings_OS/Operating-Systems-Internals-and-Design-Principles_Stallings_2018_9ed.pdf) abschließen: Kap. 9 (Uniprocessor-Scheduling), 11 (I/O), 12 (Dateisysteme) | Shell in C mit Pipes, `fork`/`exec`, Umleitungen | Betriebssysteme T 3→4 |
| **1** | 2–6 | **CS:APP** Kap. 1–9 (Beschaffungsliste). Daneben [Modern C]($REPOS_DIR/Literatur/02_Programming/C/Modern-C_Gustedt_2019.pdf), Level 1 und 2. Alternative aus dem Bestand: [Patterson/Hennessy RISC-V]($REPOS_DIR/Literatur/01_Fundamentals/Computer_Architecture/Computer-Organization-and-Design-RISC-V-Edition_Patterson-Hennessy_nd.pdf) Kap. 1–5 | CS:APP-Labs: Data Lab, Bomb Lab, Attack Lab, Malloc Lab | Rechnerarchitektur, C, Betriebssysteme P |
| **2** | 6–10 | [Crafting Interpreters]($REPOS_DIR/Literatur/01_Fundamentals/Compilers_Interpreters_etc/Crafting-Interpreters_Nystrom_2021.pdf), beide Teile komplett; danach [Implementation of Lua 5.0]($REPOS_DIR/Literatur/02_Programming/Lua/The-Implementation-of-Lua-5-0_Ierusalimschy-etal_2005.pdf) | jlox (Java oder Go), dann clox in C | Compiler 1→4, Lua T 3→4 |
| **3** | 10–14 | [CLRS (4th)]($REPOS_DIR/Literatur-Programming/01_Fundamentals/Data_Structures_Algorithms/Introduction-to-Algorithms_Cormen-etal_2022_4ed.pdf) Teil I–VI; kürzere Alternative [Weiss]($REPOS_DIR/Literatur/01_Fundamentals/Data_Structures_Algorithms/Data-Structures-and-Algorithm-Analysis-in-C_Weiss_1997_2ed.pdf) Kap. 1–10 | Jede Datenstruktur in C oder Rust; ~100 Aufgaben (LeetCode, Codeforces) | Algorithmen 2→4 |
| **4** | 14–18 | Ousterhout *A Philosophy of Software Design*, Fowler *Refactoring*, Khorikov *Unit Testing*, Starke *Effektive Softwarearchitekturen*; aus dem Bestand [Westphal: Testgetriebene Entwicklung]($REPOS_DIR/Literatur/Deutsch/Java/Testgetriebene-Entwicklung-mit-JUnit-und-FIT_Westphal_2006.pdf) | Ein eigenes Plugin mit Tests komplett refaktorieren, Entscheidungen als ADRs | Architektur, Testing 3→4 |
| **5** | 18–22 | Kemper/Eickler *Datenbanksysteme* Kap. 1–9, dann Kleppmann *Designing Data-Intensive Applications* | Key-Value-Store mit WAL und LSM-Tree in Rust | Datenbanken 1→4, Rust |
| **6** | 22–26 | [Kerrisk TLPI]($REPOS_DIR/Literatur/01_Fundamentals/Operating_Systems/Linux/System_Programming/The-Linux-Programming-Interface_Kerrisk_2010.pdf) Kap. 56–61 (Sockets); [Tanenbaum Computer Networks]($REPOS_DIR/Literatur/01_Fundamentals/Networking_Protocols/Computer-Networks_Tanenbaum-Wetherall_2011_5ed.pdf) Kap. 1, 5, 6; danach van Steen/Tanenbaum *Distributed Systems* (kostenlos) | HTTP-Server direkt auf Sockets; Raft nach den MIT-6.5840-Labs | Netze, Verteilte Systeme →3–4 |
| **7** | ab 24 | Pierce *Types and Programming Languages*; [SICP (deutsch)]($REPOS_DIR/Literatur/02_Programming/SICP/Struktur-und-Interpretation-von-Computerprogrammen_Abelson-Sussman_2001_4ed.pdf) komplett | Typchecker für Lox | PL-Theorie →3 |

## Mathe- und Theorie-Spur (parallel, ca. 3 Stunden pro Woche)

Alle Bücher stehen in der [Beschaffungsliste]($REPOS_DIR/Literatur/Beschaffungsliste.md) mit derselben
Phasen-Kennung.

| Phase | Monate | Inhalt | Nachweis |
|---|---|---|---|
| **M1** | 2–6 | Beweisen (Beutelspacher, Velleman), Diskrete Mathematik (MCS Teil I–II, Teschl Band 1 diskreter Teil) | Klausur MIT 6.042J |
| **M2** | 6–10 | Lineare Algebra (Teschl Band 1, Strang mit MIT 18.06) | Klausur MIT 18.06 |
| **M3** | 10–14 | Analysis (Teschl Band 2) | Alte Klausur „Analysis für Informatik“ |
| **M4** | 14–18 | Stochastik (Henze, Blitzstein & Hwang) | Alte Klausur Stochastik |
| **T1** | 18–24 | Theoretische Informatik (Schöning oder Hromkovič, dazu Sipser), Logik (Schöning) | Alte Klausur Theoretische Informatik |
| **T2** | ab 24 | Master-Niveau nach Wahl: Arora/Barak, Concrete Mathematics, Axler, Forster | Ausgewählte Kapitel mit allen Übungen |

Aus dem Bestand passend dazu: zum Einstieg in M1 [Stavely: Programming and Mathematical Thinking]($REPOS_DIR/Literatur-PythonAI/02_Programming/Python/Programming-and-Mathematical-Thinking-A-Gentle-Introduction-to-Discrete-Math-Featuring-Python_Stavely_2014.pdf)
(diskrete Mathematik mit Python, ersetzt MCS nicht); für Phase 4 als Alternative zu Khorikov
[Osherove: The Art of Unit Testing]($REPOS_DIR/Literatur-Programming/02_Programming/CSharp/The-Art-of-Unit-Testing-with-Examples-in-CSharp_Osherove_2014_2ed.pdf).

## Nur nachschlagen, nicht durcharbeiten

Aus dem Bestand: Holub, Terry, Louden, CS 132 und Morgan (Compiler; das Dragon Book nur als Referenz),
Knuth TAOCP (Referenz, frühestens nach Concrete Mathematics), alle Docker-Bücher außer Poulton,
React- und Node-Bücher außer dem jeweils neuesten, die Pentest-Bücher von 2004 und 2014.

Die Themen-Repos vom 2026-10-29 (`Literatur-Web`, `-Programming`, `-PythonAI`, `-Security`, `-Maker`, zusammen
rund 1.560 Bücher) sind Nachschlage-Bestand, kein Lesestoff für den Plan. Ausnahmen stehen oben in den Phasen.
Für die Zeit nach M4 liegt [Russell/Norvig: AI – A Modern Approach (4th)]($REPOS_DIR/Literatur-PythonAI/07_AI_ML/AI/Artificial-Intelligence-A-Modern-Approach_Russell-Norvig_2020_4ed.pdf)
bereit, [DasGupta: Probability for Statistics and Machine Learning]($REPOS_DIR/Literatur-PythonAI/07_AI_ML/Machine_Learning/Probability-for-Statistics-and-Machine-Learning_DasGupta_2011.pdf)
nur als Vertiefung zu M4 (Master-Niveau).

## Fortschritt

| Phase | Begonnen | Abgeschlossen | Nachweis (Link) |
|---|---|---|---|
| 0 | 2025-10 | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |
| 7 | | | |
| M1 | | | |
| M2 | | | |
| M3 | | | |
| M4 | | | |
| T1 | | | |
| T2 | | | |
