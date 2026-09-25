# CLI-Lernplan

## Table of content

  - [Grundlegendes Mindset: Linux vs. PowerShell](#grundlegendes-mindset-linux-vs-powershell)
  - [3-Monats-Lernstruktur (Spaced Repetition System)](#3-monats-lernstruktur-spaced-repetition-system)
    - [Der tägliche 15-Minuten-Algorithmus:](#der-tgliche-15-minuten-algorithmus)
  - [Detaillierter 12-Wochen-Trainingsplan](#detaillierter-12-wochen-trainingsplan)
    - [MONAT 1: Die Grundlagen festigen & Einprägen](#monat-1-die-grundlagen-festigen-einprgen)
    - [MONAT 2: Erweiterte Filterung & PowerShell-Objektmodell](#monat-2-erweiterte-filterung-powershell-objektmodell)
    - [MONAT 3: Kombinationen, Troubleshooting & Automation](#monat-3-kombinationen-troubleshooting-automation)

---

## Grundlegendes Mindset: Linux vs. PowerShell

| Konzept | Linux CLI | PowerShell (PS) |
| --- | --- | --- |
| **Philosophie** | Textströme (String in, String out) | Objektströme (.NET Objects) |
| **Suchen in Dateien** | `grep "Pattern" file.txt` | `Select-String -Pattern "Pattern" -Path file.txt` |
| **Suchen von Dateien** | `find /path -name "*.txt"` | `Get-ChildItem -Path C:\path -Filter "*.txt" -Recurse` |
| **Pipes (`|`)** | Übergibt rohen Text an nächstes Tool | Übergibt ganze Objekte an nächstes Cmdlet |
| **Verzeichnis / Inhalt** | `ls -la`, `cat file.txt` | `Get-ChildItem` (Alias `ls`/`dir`), `Get-Content` (Alias `cat`) |

---

## 3-Monats-Lernstruktur (Spaced Repetition System)

Deine 12 Wochen (5 Tage/Woche) teilen sich in 3 Phasen auf:

  ```
  [Monat 1: Basis-Syntax & Muster]  ──>  [Monat 2: Pipes & Automation]  ──>  [Monat 3: Power-User & Troubleshooting]
     (Täglich 15-20 Min. Praxis)            (Echte Support-Anwendungsfälle)        (Skripting & Systemdiagnose)

  ```

---

### Der tägliche 15-Minuten-Algorithmus:

1. **Wiederholen (5 Min):** Nimm die Karte der *letzten Woche* und gehe 3 Kommandos/Flags durch.
2. **Neuer Stoff (5 Min):** Lerne die 2-3 neuen Kommandos der *aktuellen Woche*.
3. **Praxis-Übung (5 Min):** Führe die Kommandos sofort live in deiner CLI / PowerShell aus.

---

## Detaillierter 12-Wochen-Trainingsplan

### MONAT 1: Die Grundlagen festigen & Einprägen

* **Woche 1:**
  * *Linux:* `grep` Basis-Suche, `-i` (Case-Insensitive), `-v` (Invertieren).
  * *PowerShell:* `Select-String` (Alias `sls`), Verhalten von String-Matching in PS verstehen.

* **Woche 2:**
  * *Linux:* `grep -r` (Rekursiv), `-n` (Line numbers), `-C` (Context).
  * *PowerShell:* `sls -Path ... -Recurse`, `-Context` Parameter nutzen.

* **Woche 3:**
  * *Linux:* `find` Basis-Suche (`-name`, `-type f`, `-type d`).
  * *PowerShell:* `Get-ChildItem` (Alias `gci`), `-Filter`, `-Recurse`, `-File`, `-Directory`.

* **Woche 4:**
  * *Wiederholung Woche 1–3.* Fokus auf schnelles Tippen ohne auf das Cheat Sheet zu schauen.

---

### MONAT 2: Erweiterte Filterung & PowerShell-Objektmodell

* **Woche 5:**
  * *Linux:* `find -mtime` (Änderungsdatum).
  * *PowerShell:* Kombination von `gci` mit `Where-Object` (Alias `where` oder `?`) und `Get-Date`.

* **Woche 6:**
  * *Linux:* `find -size` (Dateigröße), `-maxdepth`.
  * *PowerShell:* `gci | where {$_.Length -gt 50MB}`, `-Depth` Parameter.

* **Woche 7:**
  * *Linux:* `head`, `tail`, `tail -f`.
  * *PowerShell:* `Get-Content` (Alias `gc`), `-Head`, `-Tail`, `-Wait`.

* **Woche 8:**
  * *Wiederholung Monat 1 & 2.* Erstelle dir eigene Kombi-Aufgaben (z. B. *"Finde alle Dateien > 10MB der letzten 3 Tage, die das Wort 'Exception' enthalten"*).

---

### MONAT 3: Kombinationen, Troubleshooting & Automation

* **Woche 9 (Pipeline-Magie):**
  * *Linux:* `find ... -exec grep ... {} +`
  * *PowerShell:* `gci -Filter *.log -Recurse | sls "Error"`

* **Woche 10 (Aktionen ausführen):**
  * *Linux:* `find . -name "*.tmp" -delete`
  * *PowerShell:* `gci -Filter *.tmp -Recurse | Remove-Item -Force`

* **Woche 11 (Daten-Exfiltration & Berichte):**
  * *PowerShell Spezial:* Ergebnisse als CSV exportieren (`Export-Csv`) oder als formatierte Tabelle ausgeben (`Format-Table` / `ft`). Das ist im Support-Alltag bei Tricentis goldwert!

* **Woche 12 (Finale Mastery):**
  * Alle 3 Sheets abdecken. Arbeiten komplett ohne Maus nur im Terminal.

---
