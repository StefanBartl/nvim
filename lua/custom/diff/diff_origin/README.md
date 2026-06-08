# Funktionale Bedeutung von `:DiffOrig`

## Table of content

  - [Einleitung](#einleitung)
  - [Schritt-für-Schritt-Aufschlüsselung](#schritt-fr-schritt-aufschlsselung)
    - [1. `vert new`](#1-vert-new)
    - [2. `set buftype=nofile`](#2-set-buftypenofile)
    - [3. `read ++edit #`](#3-read-edit)
    - [4. `0d_`](#4-0d)
    - [5. `diffthis`](#5-diffthis)
    - [6. `wincmd p`](#6-wincmd-p)
    - [7. `diffthis`](#7-diffthis)
  - [Endresultat](#endresultat)
  - [Wichtige Eigenschaften](#wichtige-eigenschaften)
  - [Warum `#` funktioniert](#warum-funktioniert)
  - [Typische Einsatzfälle](#typische-einsatzflle)

---

## Einleitung

Der Befehl implementiert einen **klassischen Neovim-Trick**, um

* den aktuellen Buffer
* gegen die **zuletzt gespeicherte Version derselben Datei**

zu vergleichen.

Es handelt sich um einen **In-Buffer-Diff gegen den Dateistand auf der Platte**, nicht gegen eine andere Datei.

---

## Schritt-für-Schritt-Aufschlüsselung

Der relevante Code ist der in `vim.cmd` eingebettete Ex-Befehl:

```
vert new
set buftype=nofile
read ++edit #
0d_
diffthis
wincmd p
diffthis
```

### 1. `vert new`

* öffnet ein **neues vertikales Split-Fenster**
* darin liegt ein **leerer, neuer Buffer**

Ziel:
einen Platzhalter für den Vergleichsinhalt erzeugen.

---

### 2. `set buftype=nofile`

* markiert den neuen Buffer als **nicht dateigebunden**
* kein Schreiben auf Platte möglich
* kein Swapfile
* kein Bufname

Ziel:
der Buffer dient nur als Anzeigecontainer.

---

### 3. `read ++edit #`

* `#` bedeutet: **alternate file**
* das ist die zuletzt bearbeitete Datei
* im typischen Fall: die aktuelle Datei **in gespeicherter Form**
* `++edit` erzwingt das Laden über den normalen Edit-Mechanismus

Effekt:
der Buffer wird mit dem **Dateiinhalt von der Platte** gefüllt,
unabhängig vom aktuellen, evtl. modifizierten Buffer.

---

### 4. `0d_`

* löscht **die erste Zeile**
* `_` als Register unterdrückt Side-Effects

Warum notwendig:
`read` fügt Inhalt **nach** der Cursor-Zeile ein.
Der neue Buffer hatte initial eine leere Zeile → diese wird entfernt.

---

### 5. `diffthis`

* aktiviert Diffmodus **für diesen Buffer**
* Neovim merkt sich ihn als Diff-Partner

---

### 6. `wincmd p`

* springt zurück ins **vorherige Fenster**
* das ist der originale Arbeitsbuffer

---

### 7. `diffthis`

* aktiviert Diffmodus auch dort

Ergebnis:
beide Fenster sind jetzt im Diffmodus miteinander verknüpft.

---

## Endresultat

Man erhält:

* links oder rechts: gespeicherter Dateistand (readonly, nofile)
* gegenüber: aktueller Buffer mit evtl. Änderungen
* vollständiger Neovim-Diff:

  * `]c`, `[c`
  * `:diffget`
  * `:diffput`
  * `:diffupdate`

Ohne externe Tools, ohne Shell, ohne Wrapper.

---

## Wichtige Eigenschaften

Klartext-Tabelle:

| Eigenschaft       | Bedeutung                               |
| ----------------- | --------------------------------------- |
| Vergleichsbasis   | aktueller Buffer vs. gespeicherte Datei |
| Externe Tools     | keine                                   |
| Plattformabhängig | nein                                    |
| Schreibbar        | nur aktueller Buffer                    |
| Patch-Erzeugung   | nein                                    |

---

## Warum `#` funktioniert

Neovim hält intern:

* `%` → aktueller Buffer
* `#` → alternativer Buffer

Beim Öffnen einer Datei wird deren gespeicherter Stand als Alternate File gesetzt.

Dadurch kann man den Plattenstand **ohne Reload** in einen separaten Buffer laden.

---

## Typische Einsatzfälle

* vor dem Speichern Änderungen prüfen
* versehentliche Modifikationen inspizieren
* Diff wie in Git, aber ohne Git
* schnelles Review ohne Datei neu zu laden

---

