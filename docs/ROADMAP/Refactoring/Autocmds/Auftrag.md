# Event-zentrierte Dispatch-Logik

## Table of content

- [Event-zentrierte Dispatch-Logik](#event-zentrierte-dispatch-logik)
  - [Klarstellung](#klarstellung)
  - [Architektur-Muster: Event-zentral, Daten einmal holen](#architektur-muster-event-zentral-daten-einmal-holen)
  - [Was sich nicht lohnt zu zentralisieren](#was-sich-nicht-lohnt-zu-zentralisieren)
  - [Kritische Events (Hot Path)](#kritische-events-hot-path)
  - [Zielstruktur (Event-zentriert)](#zielstruktur-event-zentriert)
  - [Beispielstruktur](#beispielstruktur)
  - [Liste aller Autocmds](#liste-aller-autocmds)
  - [Auftrag](#auftrag)

---

## Klarstellung

Event-zentrierte Struktur ist **keine Optimierung um jeden Preis**, sondern:

* eine Maßnahme zur **Kontrolle von Seiteneffekten**
* eine Voraussetzung für **deduplizierte Arbeit**
* eine Grundlage für **messbare Performance-Verbesserungen**
* vor allem: eine **Lesbarkeits- und Wartbarkeitsstrategie**

---

## Architektur-Muster: Event-zentral, Daten einmal holen

* genau **ein Autocommand pro Event**
* Dispatch erfolgt **innerhalb eines zentralen Callbacks**
* frühe Abbrüche (`if not relevant then return end`)
* klare Zuständigkeiten (Event entscheidet, nicht Feature)
* genau **ein Einstiegspunkt** pro Event
* Buffer-Inhalt wird **maximal einmal gelesen**
* Ergebnis wird an Subsysteme / Feature-Module weitergereicht
* kontrollierte Verzweigung statt impliziter Nebenwirkungen
* minimale Arbeit pro Event
* Lazy / On-Demand Parsing, falls nicht jedes Feature immer den Inhalt benötigt
* Caching verhindert doppelte Arbeit bei wiederholten Events
* ideal: **Cache pro Buffer**, nicht global

Cache-Invalidierung bei:

* `TextChanged`
* `TextChangedI`
* `BufWritePost`
* optional: `BufUnload` / `BufWipeout` (Speicherhygiene)

---

## Was sich nicht lohnt zu zentralisieren

nicht jedes Event profitiert strukturell oder performancetechnisch von Zentralisierung.

unproblematisch:

* `FileType`
* `BufReadPost`
* `BufNewFile`

Begründung:

* seltene Trigger
* wenig Logik
* meist einmalige Initialisierung

---

## Kritische Events (Hot Path)

diese Events profitieren **stark** von Event-zentrierter Dispatch-Logik:

* `BufEnter`
* `BufWinEnter`
* `WinEnter`
* `CursorMoved`
* `InsertCharPre`

Begründung:

* hohe Frequenz
* häufig redundanter Buffer-Zugriff
* hohes Risiko für unkoordinierte Mehrfacharbeit

---

## Zielstruktur (Event-zentriert)

* Ordnung nach **Event**
* nicht nach Feature
* nicht primär nach Filetype
* Feature-Code bleibt modular und unabhängig
* Event-Module agieren als Dispatcher, nicht als Logikcontainer

---

## Beispielstruktur

```sh
autocmds/
  init.lua          # Registrierung aller Events
  groups.lua        # augroup-Definitionen

  events/
    buf_enter.lua
    buf_leave.lua
    win_enter.lua
    win_leave.lua
    filetype.lua
```

---

## Liste aller Autocmds

Die Statistik + Implementierungen aller autocmds inkl. Pfadangabe zur Analyse findest du unter `docs\ROADMAP\Refactoring\Autocmds\List.md`

---

## Auftrag

Analysiere alle autocmds nach der liste und erstelle eine Roadmap mit Meilensteinen, Architekturvorschlag usw, wie ich die ~110 autocmds in meiner nvim config am besten refactoren kann. Schätze auch ab, wieviel Performance-Gewinn erreichbar wäre bzw. welche anderen Goodies man erreichen kann.
---

