# Autocmd Audit – Neovim User Command

Dieses Modul stellt einen Neovim-User-Command bereit, mit dem Autocommand-Definitionen statisch analysiert werden können.
Die Analyse erfolgt ausschließlich auf Quelltextebene, ohne dass Lua-Code ausgeführt wird.

Ziel ist es, einen vollständigen Überblick über vorhandene `nvim_create_autocmd`-Aufrufe, deren Events, Häufigkeiten, Implementierungen und Herkunftsdateien zu erhalten.

---

## Table of content

- [Autocmd Audit – Neovim User Command](#autocmd-audit-neovim-user-command)
  - [Überblick](#berblick)
  - [Installation](#installation)
  - [User Command](#user-command)
  - [Argumente](#argumente)
    - [event](#event)
    - [sort](#sort)
    - [impl](#impl)
    - [summary](#summary)
    - [freq](#freq)
    - [root](#root)
  - [Beispiele](#beispiele)
  - [Ausgabeformat](#ausgabeformat)
  - [Technische Eigenschaften](#technische-eigenschaften)
  - [Einschränkungen](#einschrnkungen)
  - [Zielgruppe](#zielgruppe)

---

## Überblick

Der User-Command durchsucht rekursiv ein Lua-Verzeichnis (standardmäßig die Neovim-Config) und extrahiert:

* alle verwendeten Autocommand-Events
* die Anzahl der Registrierungen pro Event
* die genaue Quelldatei und Zeilennummer
* die vollständige Autocommand-Implementierung
* eine optionale Klassifikation nach Scope (buffer, window, global)

Die Ausgabe erfolgt in einem Scratch-Buffer.

---

## Installation

Das Modul muss lediglich im Runtimepath verfügbar sein und einmal aktiviert werden.

Beispiel:

```lua
require("tools.autocmd_audit").enable()
```

Danach steht der User-Command zur Verfügung.

---

## User Command

```text
:ListAutocmdSources [argumente]
```

Alle Argumente sind optional und werden als `key=value` übergeben.

---

## Argumente

### event

Filtert die Ausgabe auf ein einzelnes Neovim-Event.

```text
event=BufEnter
```

Ohne Angabe werden alle Events berücksichtigt.

Für dieses Argument ist Autocompletion aktiv, basierend auf der vollständigen Liste bekannter Neovim-Events.

---

### sort

Steuert die Sortierung der Detail-Liste.

Mögliche Werte:

```text
sort=source      -- Standard, Reihenfolge der Entdeckung
sort=event       -- sortiert nach Event-Namen
sort=frequency   -- Autocmds mit vielen Events zuerst
```

---

### impl

Schaltet die Anzeige der Autocommand-Implementierung ein oder aus.

```text
impl=true    -- Standard
impl=false
```

Bei `false` werden nur Metadaten (Pfad, Zeile, Events) angezeigt.

---

### summary

Steuert die Anzeige der Zusammenfassung am Anfang der Ausgabe.

```text
summary=true   -- Standard
summary=false
```

Die Zusammenfassung enthält u. a.:

* Anzahl eindeutiger Autocommand-Aufrufe
* Anzahl aller Event-Registrierungen
* optionale Scope-Übersicht

---

### freq

Schaltet die Event-Frequency-Liste ein oder aus.

```text
freq=true    -- Standard
freq=false
```

Die Frequency-Liste zeigt, wie oft jedes Event registriert wurde.

---

### root

Überschreibt das Wurzelverzeichnis, das gescannt werden soll.

```text
root=/pfad/zum/lua/verzeichnis
```

Standardwert:

```text
stdpath("config") .. "/lua"
```

---

## Beispiele

Alle Autocommands analysieren (Standardverhalten):

```text
:ListAutocmdSources
```

Nur `BufEnter`-Autocommands anzeigen:

```text
:ListAutocmdSources event=BufEnter
```

Sortiert nach Event, ohne Implementierungen:

```text
:ListAutocmdSources sort=event impl=false
```

Analyse eines alternativen Verzeichnisses ohne Summary:

```text
:ListAutocmdSources root=~/repos/nvim-config/lua summary=false
```

---

## Ausgabeformat

Die Ausgabe erfolgt in einem neuen Scratch-Buffer (`nofile`, `wipe`).

Typische Struktur:

```text
Autocmd Audit Summary
---------------------
Total unique autocmd calls: 110
Total event registrations: 98

Event frequency:
  "FileType": 17
  "BufEnter": 11
  ...

Detailed listing
----------------
1. autocmds/example.lua:42
Events: BufEnter, BufWinEnter
Implementation:
  vim.api.nvim_create_autocmd(...)
```

---

## Technische Eigenschaften

* keine Code-Ausführung
* rein textbasierte Analyse
* deterministische Ergebnisse
* LuaLS-freundlich
* keine Abhängigkeit von Runtime-Zustand
* funktioniert auch für inaktive oder bedingte Autocommands

---

## Einschränkungen

* nur einfache statische Muster werden erkannt
* komplexe dynamische Event-Erzeugung kann nicht aufgelöst werden
* Autocommands, die nicht über `nvim_create_autocmd` definiert sind, werden ignoriert
* Event-Filter erfolgt aktuell nicht während des Scans, sondern auf Basis der erfassten Daten

---

## Zielgruppe

Dieses Tool richtet sich an:

* fortgeschrittene Neovim-Konfigurationen
* Plugin- und Config-Autoren
* Performance- und Wartbarkeits-Audits
* Dokumentations- und Refactoring-Zwecke

---
