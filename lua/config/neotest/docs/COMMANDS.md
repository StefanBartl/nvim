# Neotest commands

## Table of content

- [Neotest commands](#neotest-commands)
  - [1. User Commands](#1-user-commands)
  - [2. Keymaps (Tastenkürzel)](#2-keymaps-tastenkrzel)
    - [Test-Steuerung](#test-steuerung)
    - [UI & Übersicht](#ui-bersicht)
    - [Wartung & Diagnose](#wartung-diagnose)
  - [3. Autocommands (Detailliert)](#3-autocommands-detailliert)
    - [Initial Test Discovery](#initial-test-discovery)
    - [Was ich jetzt für dich tun kann:](#was-ich-jetzt-fr-dich-tun-kann)

---

## 1. User Commands

Diese Befehle bilden das Rückgrat deiner Konfiguration und können direkt über die Befehlszeile aufgerufen werden.

| Befehl | Kategorie | Beschreibung |
| --- | --- | --- |
| `:NeotestActions` | UI | Öffnet den Telescope Picker für alle Neotest-Aktionen. |
| `:NeotestRunNearest` | Execution | Führt den Test unter oder nah am Cursor aus. |
| `:NeotestRunFile` | Execution | Führt alle Tests in der aktuellen Datei aus. |
| `:NeotestRunAll` | Execution | Führt das gesamte Test-Suite des Projekts aus. |
| `:NeotestDebugNearest` | Debug | Startet den Test im Debug-Modus (via DAP). |
| `:NeotestSummaryToggle` | UI | Zeigt/Versteckt die Test-Struktur in einer Sidebar. |
| `:NeotestOutput` | UI | Zeigt das Resultat/Log des letzten Tests an. |
| `:NeotestOutputPanelToggle` | UI | Öffnet/Schließt das horizontale Output-Panel. |
| `:NeotestStop` | Control | Bricht alle laufenden Test-Prozesse sofort ab. |
| `:NeotestWatchToggle` | Control | Überwacht Dateiveränderungen und testet automatisch. |
| `:NeotestDebugAdapters` | Info | Detaillierte Liste der konfigurierten Adapter. |
| `:NeotestDebugState` | Info | Diagnose-Info zum aktuellen Buffer und Test-Status. |

---

## 2. Keymaps (Tastenkürzel)

### Test-Steuerung

| Keymap | Aktion | Funktion |
| --- | --- | --- |
| `<leader>ntt` | `run_nearest` | Nächsten Test ausführen. |
| `<leader>ntf` | `run_file` | Aktuelle Datei testen. |
| `<leader>nta` | `run_all` | Projektweit testen. |
| `<leader>ntd` | `debug_nearest` | Debugger für nächsten Test starten. |
| `<leader>ntw` | `toggle_watch` | Watch-Modus an/aus. |
| `<leader>ntS` | `stop` | Tests stoppen. |

### UI & Übersicht

| Keymap | Aktion | Funktion |
| --- | --- | --- |
| `<leader>nts` | `toggle_summary` | Summary Sidebar öffnen/schließen. |
| `<leader>nto` | `open_output` | Test-Output einblenden. |
| `<leader>ntO` | `toggle_output_panel` | Output Panel (unten) umschalten. |

### Wartung & Diagnose

| Keymap | Aktion | Funktion |
| --- | --- | --- |
| `<leader>ntr` | `Refresh Discovery` | Erzwingt Neusuche der Tests (löscht Cache). |
| `<leader>ntD` | `Show Adapters` | Zeigt alle aktuell geladenen Neotest-Adapter. |

---

## 3. Autocommands (Detailliert)

### Initial Test Discovery

* **Trigger:** `VimEnter` (Sobald Neovim geladen ist).
* **Logik:** 1.  Verzögerung von **2000ms**, um den Startvorgang nicht zu verlangsamen.
2.  `neotest.state.clear()` wird aufgerufen, um sicherzustellen, dass keine veralteten Daten vorhanden sind.
3.  Ein Scan wird im Hintergrund initiiert.
4.  Nach weiteren **1000ms** wird ein Refresh auf den **Neo-tree Manager** für die Source `tests` ausgeführt.
* **Ziel:** Dies stellt sicher, dass du sofort beim Öffnen eines Projekts siehst, welche Dateien Tests enthalten (z. B. durch Icons im File-Explorer), ohne erst manuell einen Test starten zu müssen.

---
