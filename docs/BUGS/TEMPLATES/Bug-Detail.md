# BUG-XXX – <Kurzer, präziser Titel>

## Table of content

  - [Metadaten](#metadaten)
  - [Kurzbeschreibung](#kurzbeschreibung)
  - [Erwartetes Verhalten](#erwartetes-verhalten)
  - [Tatsächliches Verhalten](#tatschliches-verhalten)
  - [Reproduktionsschritte](#reproduktionsschritte)
  - [Fehlermeldungen / Logs](#fehlermeldungen-logs)
  - [Technische Analyse](#technische-analyse)
  - [Vermutete Ursache](#vermutete-ursache)
  - [Auswirkungen](#auswirkungen)
  - [Bisherige Fix-Versuche](#bisherige-fix-versuche)
  - [Offene Fragen](#offene-fragen)
  - [Nächste Schritte](#nchste-schritte)
  - [Referenzen](#referenzen)

---

## Metadaten

Bug-ID: BUG-XXX
Kategorie: Core | UI | LSP | Trees | Completion | Debugging | Keymaps | Autocmds | Performance | Sonstiges
Severity: CRITICAL | IMPORTANT | NORMAL | LOW
Status: OPEN | WIP | FIXED | UPSTREAM | WONTFIX
Betroffene Module / Plugins:
Erstmals beobachtet: YYYY-MM-DD
Plattform: Windows | Linux | macOS | alle
Reproduzierbarkeit: immer | häufig | sporadisch | unklar

---

## Kurzbeschreibung

Ein bis zwei Sätze, die aus Nutzersicht beschreiben, was nicht funktioniert.
Keine technischen Details, keine Ursachenannahmen.

---

## Erwartetes Verhalten

Beschreibung dessen, was korrekt passieren sollte.
Fokus auf User-Workflow, nicht auf Implementierung.

---

## Tatsächliches Verhalten

Beschreibung dessen, was stattdessen passiert.
Inklusive sichtbarer Symptome (Freeze, Crash, falsches Verhalten).

---

## Reproduktionsschritte

1. Neovim starten
2. Relevantes Plugin / Feature aktivieren
3. Bestimmte Aktion ausführen
4. Fehler tritt auf

Optional:

* benötigte Plugins
* relevante Optionen / Feature-Flags
* bestimmter Projektzustand (Git-Repo, Monorepo, große Dateien, etc.)

---

## Fehlermeldungen / Logs

### Lua Errors

```vim
E5108: Error executing lua: ...
attempt to index field 'xyz' (a nil value)
```

### Vim Errors / Messages

```tvim
E5113: Error while calling lua chunk
```

### Notifications

````vim
[Plugin WARN] Something went wrong
```

---

## Technische Analyse

### Betroffene Codepfade

* lua/<plugin>/module/file.lua
* function_a()
* function_b()

### Beobachtungen

* bestimmte Variablen sind nil
* Fehler tritt nur bei bestimmten Window-/Buffer-Zuständen auf
* abhängig von Reihenfolge oder Timing (Autocmds, Debounce)

---

## Vermutete Ursache

Strukturierte Hypothesen, zum Beispiel:

* implizite Annahmen über State oder Initialisierung
* fehlende Guards für nil / invalid Handles
* Race-Conditions durch Autocmds oder asynchrone Jobs
* Unterschiedliches Verhalten zwischen Plattformen

Keine endgültigen Aussagen, nur begründete Vermutungen.

---

## Auswirkungen

* Welche Workflows sind blockiert
* Ob Datenverlust möglich ist
* Ob ein Neustart von Neovim notwendig wird
* Ob der Fehler kaskadierend weitere Fehler auslöst

---

## Bisherige Fix-Versuche

### Implementierte Workarounds

* pcall um kritische Aufrufe
* zusätzliche Validierungen
* Deaktivieren einzelner Features
* Verzögerungen (defer_fn, debounce)

Ergebnis:

* teilweise Verbesserung
* keine Änderung
* neue Nebenwirkungen

---

## Offene Fragen

* Wem gehört der betroffene State?
* Welche Invarianten werden vorausgesetzt?
* Sollte dieses Modul defensiver sein?
* Gehört der Fix in die eigene Config oder upstream?

---

## Nächste Schritte

* Minimal-Repro isolieren
* Logging an kritischen Stellen ergänzen
* Code-Pfad vereinfachen
* Issue oder PR upstream vorbereiten

---

## Referenzen

* Upstream Issues / PRs
* Eigene Commits / Patches
* Relevante Doku oder Code-Stellen

---
