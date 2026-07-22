# `polyglot-cmd.nvim` — Konzept

> Arbeitstitel, noch offen: `polyglot-cmd.nvim` vs. `rosetta-shell.nvim` (siehe [Offene Fragen](#offene-fragen))

## Table of content

- [`polyglot-cmd.nvim` — Konzept](#polyglot-cmdnvim--konzept)
  - [Table of content](#table-of-content)
  - [Problem](#problem)
  - [Idee in einem Satz](#idee-in-einem-satz)
  - [Kernfunktionen](#kernfunktionen)
    - [1. Intent-to-Syntax Baukasten](#1-intent-to-syntax-baukasten)
    - [2. Multi-OS Live-Vorschau](#2-multi-os-live-vorschau)
    - [3. Smart Argument Handling](#3-smart-argument-handling)
    - [4. Integration](#4-integration)
  - [Architektur-Skizze](#architektur-skizze)
    - [Datenmodell: Intent-Bausteine](#datenmodell-intent-bausteine)
    - [Shell-Targets](#shell-targets)
    - [Renderer/Template-Engine](#renderertemplate-engine)
    - [UI-Schicht](#ui-schicht)
  - [Lernmodus (optional, standardmäßig aus)](#lernmodus-optional-standardmäßig-aus)
    - [Zweck](#zweck)
    - [Was der Lernmodus zusätzlich einblendet](#was-der-lernmodus-zusätzlich-einblendet)
    - [Anbindung an `learn-cli.nvim`](#anbindung-an-learn-clinvim)
    - [Mögliche Integrationsrichtungen](#mögliche-integrationsrichtungen)
  - [Abgrenzung zu learn-cli.nvim](#abgrenzung-zu-learn-clinvim)
  - [Phasen](#phasen)
  - [Offene Fragen](#offene-fragen)
  - [Risiken / Komplexitätstreiber](#risiken--komplexitätstreiber)

---

## Problem

Wer regelmäßig zwischen Betriebssystemen und Shells wechselt (z. B. Windows
CMD/PowerShell im Job, Linux/macOS Bash/Zsh privat), verliert Zeit und Fokus
durch mentalen Overhead: Wie war das Flag für rekursives Suchen in
PowerShell nochmal? Heißt es `dir` oder `ls`? Welche Syntax hat `grep` unter
Windows? Das ständige Kontext-Switching zwischen Shell-Dialekten ist
Fehlerquelle und Reibungsverlust zugleich.

## Idee in einem Satz

Ein interaktives Neovim-Plugin, das als polyglotter Shell-Baukasten und
Übersetzer dient: Der Nutzer denkt in **Intent** ("ich will Text rekursiv
durchsuchen"), das Plugin übersetzt das in die korrekte Syntax der
Ziel-Shell — live, für mehrere Shells parallel sichtbar.

## Kernfunktionen

### 1. Intent-to-Syntax Baukasten

Statt Flags aus Manpages zu suchen, wählt der Nutzer verständliche
Bausteine aus einer Liste (z. B. "Groß-/Kleinschreibung ignorieren",
"rekursiv durchsuchen", "Regex verwenden", "nur Dateinamen ausgeben").
Jeder Baustein ist ein deklaratives Fragment, keine Shell-spezifische
Zeichenkette.

### 2. Multi-OS Live-Vorschau

Während der Nutzer Bausteine zusammenklickt, zeigt ein Floating-Window
parallel, wie derselbe Befehl in Bash, Zsh, PowerShell und CMD aussieht.
Nebeneffekt: hoher Lerneffekt beim bloßen Zusehen, auch ohne aktiven
Lernmodus.

### 3. Smart Argument Handling

Kein stumpfes String-Anfügen. Stattdessen system-bezogene Templates, die
auch strukturelle Unterschiede sauber abbilden (z. B. PowerShell-Pipelines
mit Objekten statt Text, CMD ohne native Pipes für manche Fälle,
Escaping-Regeln pro Shell).

### 4. Integration

Aufbau auf `Telescope` oder `fzf-lua` als Picker-Engine für Baukasten-Suche
und Auswahl — schnell, ohne Latenz, direkt aus Neovim. Ergebnis landet auf
Wunsch in der Zwischenablage oder wird direkt ins integrierte Terminal
geschrieben (analog zum Terminal-Handling in `learn-cli.nvim`).

## Architektur-Skizze

### Datenmodell: Intent-Bausteine

Jeder Baustein ("Fragment") beschreibt eine Absicht plus deren Übersetzung
pro Shell-Target, nicht als String-Konkatenation, sondern als
strukturiertes Objekt (Programm, Flags, Positional-Args, Pipe-Verhalten):

```lua
{
  id = "recursive_search",
  label = "Rekursiv durchsuchen",
  category = "search",
  applies_to = { "grep_family" },
  render = {
    bash = { flag = "-r" },
    zsh = { flag = "-r" },
    powershell = { cmdlet_param = "-Recurse" },
    cmd = { note = "kein natives Äquivalent, ggf. /S bei findstr" },
  },
}
```

Ein "Programm" (z. B. `grep`/`Select-String`/`findstr`) ist eine Sammlung
kompatibler Fragmente plus Basis-Template pro Shell.

### Shell-Targets

Mindestens: `bash`, `zsh`, `powershell`, `cmd`. Erweiterbar (`fish`,
`nushell`) — Targets sind Plugins/Module, kein hartkodiertes Set.

### Renderer/Template-Engine

Pro Shell-Target ein Renderer, der aus der Liste gewählter Fragmente einen
finalen Befehlsstring erzeugt. Muss Sonderfälle behandeln können (fehlende
Äquivalente, Reihenfolge-Constraints, Quoting-Regeln) — nicht nur
Templates mit Platzhaltern.

### UI-Schicht

- Picker (Telescope/fzf-lua) für Fragment-Auswahl
- Floating-Window für Multi-Shell-Live-Vorschau
- Output-Ziel: Clipboard oder Terminal-Injection

## Lernmodus (optional, standardmäßig aus)

### Zweck

Im Normalbetrieb soll das Plugin ein reines Produktivwerkzeug bleiben —
schnell, ohne zusätzliche Erklärungen. Der Lernmodus ist ein expliziter
Opt-in-Schalter (Command oder Config-Flag), der zusätzliche didaktische
Inhalte einblendet.

### Was der Lernmodus zusätzlich einblendet

- Zusatzinfos zu Fragmenten (warum funktioniert `-Recurse` nur bei
  bestimmten Cmdlets, warum kennt CMD kein Äquivalent)
- Verständnisfragen ("Was passiert, wenn du `-r` bei `grep` weglässt?")
- Notizen/Merkhilfen, die der Nutzer selbst anheften kann
- Übungsbeispiele: aus einem gebauten Befehl eine Aufgabe ableiten
  ("baue denselben Befehl nochmal ohne Baukasten")

Diese Inhalte sind im Normalbetrieb komplett unsichtbar — keine UI-Reste,
keine Performance-Kosten.

### Anbindung an `learn-cli.nvim`

`learn-cli.nvim` (siehe `E:\repos\learn-cli.nvim`, noch unfertig) ist
bereits ein eigenständiges Lernplattform-Plugin mit Exercises, Cycles,
Scoring, Spaced Repetition und Terminal-Integration
(`docs/padagogical-concept.md`, `README.md` dort). Statt eine zweite,
parallele Lern-Infrastruktur in `polyglot-cmd.nvim` zu bauen, sollte der
Lernmodus möglichst auf `learn-cli.nvim`s bestehenden Konzepten aufsetzen
(Exercise-Schema mit `id`, `program`, `hints`, `difficulty`,
`prerequisites`, `references`, `tags` ist bereits definiert und
wiederverwendbar).

### Mögliche Integrationsrichtungen

1. **polyglot-cmd als Exercise-Generator für learn-cli**: Jeder im
   Baukasten zusammengesetzte Befehl kann optional als
   `learn_cli`-Exercise exportiert werden (`task`, `hints`, `files` aus dem
   gewählten Fragment-Set ableiten). Loser Kopplungsgrad, kein Hard-Dep.
2. **learn-cli triggert polyglot-cmd im "Explain"-Modus**: Beim Lösen einer
   `learn-cli`-Exercise kann optional die Multi-OS-Vorschau von
   `polyglot-cmd` eingeblendet werden, um zu zeigen, wie derselbe Befehl in
   anderen Shells aussähe. Hard-Dep von `learn-cli.nvim` auf
   `polyglot-cmd.nvim` (analog zu `lib.nvim`-Abhängigkeiten,
   siehe [[lib-nvim-dependency]]).
3. **Gemeinsame Fragment-/Exercise-Bibliothek**: Ein geteiltes Datenformat
   (evtl. in `lib.nvim` oder einem dritten `*-data.nvim`), auf das beide
   Plugins lesend zugreifen — vermeidet Duplikat-Pflege von
   Command-Wissen in zwei Repos.

Diese drei Optionen sind keine gegenseitig exklusive Entscheidung —
Reihenfolge und Umfang sind aktuell offen, siehe
[Offene Fragen](#offene-fragen).

## Abgrenzung zu learn-cli.nvim

- `learn-cli.nvim`: Übung, Wiederholung, Fortschritt, Gamification —
  fokussiert auf **ein** Ziel-Kommando/eine Ziel-Shell pro Exercise.
- `polyglot-cmd.nvim`: Übersetzung/Baukasten für **beliebige** Shells
  gleichzeitig, primär Produktivwerkzeug, Lernaspekt ist Zusatzfeature.
- Beide teilen die Zielgruppe (CLI-Lernende/-Wechsler) und potenziell
  Datenformate, sind aber unabhängig nutzbar.

## Phasen

**Phase 1 — MVP**
- Fragment-Datenmodell + 1 Shell-Paar (Bash ↔ PowerShell) für 2–3
  Programme (`grep`/`Select-String`, `find`/`Get-ChildItem`)
- Statischer Picker (Telescope) ohne Live-Vorschau
- Ausgabe: Clipboard

**Phase 2 — Multi-OS Live-Vorschau**
- Floating-Window mit allen 4 Shell-Targets parallel
- Terminal-Injection statt nur Clipboard

**Phase 3 — Fragment-Bibliothek erweitern**
- Mehr Programme (`sed`/`awk`/`ls`/`cp`/`find`/`ps` je Shell)
- Custom-Fragment-Definition durch Nutzer (analog zu learn-cli
  Custom-Exercises)

**Phase 4 — Lernmodus (Opt-in)**
- Zusatzinfos/Fragen/Notizen-Overlay, standardmäßig deaktiviert
- Export gebauter Befehle als learn-cli-Exercise-Rohformat

**Phase 5 — Tiefere learn-cli-Integration**
- Entscheidung über Integrationsrichtung (siehe oben) treffen und
  umsetzen
- Ggf. gemeinsames Datenformat auslagern

## Offene Fragen

- Name: `polyglot-cmd.nvim` oder `rosetta-shell.nvim` (oder anderer
  Vorschlag)?
- Abhängigkeit von `lib.nvim`: ja/nein? (Vergleichbare Entscheidung bei
  anderen Extraktionen, siehe [[lib-nvim-dependency]] —
  `debugging.nvim`/`dap.nvim` behalten `lib.nvim`, `fileops.nvim` u. a.
  nicht)
- Wie weit reicht "Smart Argument Handling" realistisch? Volle
  PowerShell-Objekt-Pipeline-Semantik korrekt abzubilden ist deutlich
  aufwändiger als reines Flag-Mapping — Umfang für MVP eingrenzen.
- Integrationsrichtung zu `learn-cli.nvim` (siehe drei Optionen oben) noch
  nicht entschieden — evtl. erst nach `learn-cli.nvim`-Fertigstellung
  final festlegen.
- Datenpflege: Fragment-/Programm-Definitionen von Hand kuratieren oder
  aus vorhandenen Cheatsheets/Manpages teilautomatisiert ableiten?

## Risiken / Komplexitätstreiber

- Shell-Äquivalenz ist oft nicht 1:1 (CMD kennt viele Unix-Konzepte gar
  nicht) — UI muss "kein Äquivalent" sauber kommunizieren können, statt
  falsche Befehle vorzuschlagen.
- Pflegeaufwand der Fragment-Bibliothek wächst mit jedem Programm ×
  4 Shells — ohne klare Datenstruktur/Contribution-Format nicht skalierbar.
- Lernmodus als nachträglicher Layer (statt von Anfang an eingeplant)
  könnte das Datenmodell der Fragmente nachträglich verkomplizieren —
  Exercise-relevante Felder (Hints, Difficulty) besser von Phase 1 an im
  Fragment-Schema mitdenken, auch wenn sie erst in Phase 4 genutzt werden.
