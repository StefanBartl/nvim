# neotree keymaps

## Fenster/Navigation

| Taste(n)      | Aktion/Command    | Kontext          | Beschreibung                                                                                                                        |
| ------------- | ----------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| q             | close\_window     | Neo-tree Fenster | Schließt das Neo-tree-Fenster.                                                                                                      |
| <Esc>         | custom            | Neo-tree Fenster | Beendet Suche/Filter, versteckt Preview, löscht Suchhervorhebungen und setzt eine ggf. gesetzte PDF-Statusline des Fensters zurück. |
| <2-LeftMouse> | open              | Neo-tree Fenster | Öffnet den Eintrag unter dem Cursor.                                                                                                |
| l             | open/toggle\_node | Neo-tree Fenster | Bei Verzeichnis/ungeöffnetem Knoten: Ein-/Ausklappen; sonst Datei öffnen.                                                           |
| h             | close\_node       | Neo-tree Fenster | Knoten einklappen.                                                                                                                  |
| C             | close\_node       | Neo-tree Fenster | Knoten einklappen (Alias von h).                                                                                                    |
| z             | close\_all\_nodes | Neo-tree Fenster | Alle Knoten einklappen.                                                                                                             |
| <C-r>         | refresh           | Neo-tree Fenster | Baumansicht aktualisieren.                                                                                                          |
| g?             | noop              | Neo-tree Fenster | Deaktiviert                                                                                                  |
| ?            | show\_help        | Neo-tree Fenster | Hilfe/Keymap-Übersicht von Neo-tree anzeigen.                                                                                       |
| <leader>      | noop              | Neo-tree Fenster | Deaktiviert Leader im Neo-tree-Buffer.                                                                                              |
| <S-Tab>       | prev\_source      | Neo-tree Fenster | Zur vorherigen Quelle wechseln (z. B. Filesystem → Buffers).                                                                        |

#0 Öffnen/Splits/Tabs

| Taste(n) | Aktion/Command                            | Kontext          | Beschreibung                                                                                                                           |
| -------- | ----------------------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| <CR>     | open/toggle\_node                         | Neo-tree Fenster | Verzeichnis: ein-/ausklappen; Datei: öffnen. Nutzt window-picker, falls installiert, sonst Standard-Open. Versteckt zuvor die Preview. |
| SV       | split\_with\_window\_picker/open\_split   | Neo-tree Fenster | Horizontal teilen und öffnen; präferiert window-picker.                                                                                |
| SG       | vsplit\_with\_window\_picker/open\_vsplit | Neo-tree Fenster | Vertikal teilen und öffnen; präferiert window-picker.                                                                                  |
| sv       | open\_split                               | Neo-tree Fenster | Horizontaler Split und öffnen.                                                                                                         |
| sg       | open\_vsplit                              | Neo-tree Fenster | Vertikaler Split und öffnen.                                                                                                           |
| st       | open\_tabnew                              | Neo-tree Fenster | In neuem Tab öffnen.                                                                                                                   |

# Dateioperationen (Kopieren/Einfügen/Umbenennen/Löschen/Erstellen)

| Taste(n) | Aktion/Command         | Kontext          | Beschreibung                                                  |
| -------- | ---------------------- | ---------------- | ------------------------------------------------------------- |
| c        | copy\_to\_clipboard    | Neo-tree Fenster | Markiert Eintrag für Kopiervorgang (Neo-tree-Zwischenablage). |
| x        | cut\_to\_clipboard     | Neo-tree Fenster | Markiert Eintrag für Ausschneiden.                            |
| p        | paste\_from\_clipboard | Neo-tree Fenster | Führt Kopieren/Verschieben aus.                               |
| r        | rename                 | Neo-tree Fenster | Umbenennen.                                                   |
| a        | add                    | Neo-tree Fenster | Neue Datei anlegen; Pfad relativ anzeigen.                    |
| A        | add\_directory         | Neo-tree Fenster | Neues Verzeichnis anlegen; Pfad relativ anzeigen.             |
| dd       | delete                 | Neo-tree Fenster | Datei/Ordner löschen.                                         |

# Vorschau/Scrollen

| Taste(n)   | Aktion/Command  | Kontext          | Beschreibung                                                                                                                  |
| ---------- | --------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| <Tab>      | smart\_preview  | Neo-tree Fenster | Intelligente Vorschau: Bilder inline (image\_preview\.nvim), PDFs gerendert mit Seitenanzeige, sonst Source-Preview im Float. |
| <PageDown> | scroll\_preview | Neo-tree Fenster | Vorschau seitenweise nach unten (\~10 Zeilen).                                                                                |
| <PageUp>   | scroll\_preview | Neo-tree Fenster | Vorschau seitenweise nach oben (\~10 Zeilen).                                                                                 |
| <C-f>      | scroll\_preview | Neo-tree Fenster | Vorschau eine Zeile nach unten.                                                                                               |
| <C-b>      | scroll\_preview | Neo-tree Fenster | Vorschau eine Zeile nach oben.                                                                                                |

# PDF-Spezialfunktionen (nur bei PDF unter dem Cursor)

| Taste(n)     | Aktion/Command  | Kontext          | Beschreibung                                                                                            |
| ------------ | --------------- | ---------------- | ------------------------------------------------------------------------------------------------------- |
| <S-PageDown> | pdf\_next\_page | Neo-tree Fenster | Zur nächsten PDF-Seite wechseln (begrenzt auf letzte Seite). Aktualisiert Fenster-Statusline „PDF X/Y“. |
| <S-PageUp>   | pdf\_prev\_page | Neo-tree Fenster | Zur vorherigen PDF-Seite wechseln (begrenzt auf erste Seite). Aktualisiert Fenster-Statusline.          |

# Pfad-Utilities/Clipboard

| Taste(n) | Aktion/Command | Kontext          | Beschreibung                                                                                     |
| -------- | -------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| [p      | custom         | Neo-tree Fenster | Absoluten Pfad des Knotens in die System-Zwischenablage (+) kopieren.                            |
| ]p       | custom         | Neo-tree Fenster | Basisverzeichnis des Knotens (bei Datei: Verzeichnis) in die System-Zwischenablage (+) kopieren. |
| [r       | custom         | Neo-tree Fenster | Relativen Pfad des Knotens in die System-Zwischenablage (+) kopieren. |
| ]r       | custom         | Neo-tree Fenster | Rel. Pfad des Basisverz. d. Knotens (bei Datei: Verz.) in die System-Zwischenablage (+) kopieren. |
| Y        | custom         | Neo-tree Fenster | Pfad des Knotens in die System-Zwischenablage (+) kopieren.                                      |

# Arbeitsverzeichnis/CWD-Management

| Taste(n) | Aktion/Command | Kontext          | Beschreibung                                                                                        |
| -------- | -------------- | ---------------- | --------------------------------------------------------------------------------------------------- |
| +        | custom         | Neo-tree Fenster | Neovim-CWD auf den Knoten setzen (bei Datei: dessen Ordner) und Neo-tree dort fokussieren/revealen. |
| -        | custom         | Neo-tree Fenster | Eine Ebene nach oben: CWD auf Elternverzeichnis setzen und Neo-tree dort fokussieren.               |

# Fenstergröße

| Taste(n) | Aktion/Command | Kontext          | Beschreibung                                                                 |      |
| -------- | -------------- | ---------------- | ---------------------------------------------------------------------------- | ---- |
| w        | custom         | Neo-tree Fenster | Fensterbreite zyklisch umschalten: klein ↔ normal ↔ groß (setzt per \`wincmd | \`). |
/
# Systemintegration

| Taste(n) | Aktion/Command                 | Kontext          | Beschreibung                                                 |
| -------- | ------------------------------ | ---------------- | ------------------------------------------------------------ |
| O        | custom                         | Neo-tree Fenster | Mit System-Anwendung öffnen (`lazy.util.open`, system=true). |
| M        | custom (open\_fm.win/wsl/unix) | Neo-tree Fenster | Im System-Dateimanager öffnen (plattformabhängiges Modul).   |

# Suchen/Greppen

| Taste(n) | Aktion/Command             | Kontext          | Beschreibung                                                                       |
| -------- | -------------------------- | ---------------- | ---------------------------------------------------------------------------------- |
| `grep`        | custom (fzf\_grep\_picker) | Neo-tree Fenster | `fzf-lua`: Live-Grep im Verzeichnis des aktuellen Knotens (plattformübergreifend). |

# Quelle „filesystem“

| Taste(n) | Aktion/Command     | Kontext           | Beschreibung                        |
| -------- | ------------------ | ----------------- | ----------------------------------- |
| d        | noop               | Filesystem-Quelle | Deaktiviert Standardbindung für d.  |
| /        | noop               | Filesystem-Quelle | Deaktiviert In-Source-Suchen auf /. |
| f        | filter\_on\_submit | Filesystem-Quelle | Dateiliste nach Eingabe filtern.    |
| F        | fuzzy\_finder      | Filesystem-Quelle | Fuzzy-Finder für Dateien starten.   |
| <C-c>    | clear\_filter      | Filesystem-Quelle | Aktiven Filter zurücksetzen.        |

# Quelle „buffers“

| Taste(n) | Aktion/Command | Kontext        | Beschreibung                           |
| -------- | -------------- | -------------- | -------------------------------------- |
| dd       | buffer\_delete | Buffers-Quelle | Buffer aus der Buffer-Liste entfernen. |

# Quelle „git\_status“

| Taste(n) | Aktion/Command | Kontext           | Beschreibung                                    |
| -------- | -------------- | ----------------- | ----------------------------------------------- |
| d        | noop           | Git-Status-Quelle | Deaktiviert Standardbindung für d.              |
| dd       | delete         | Git-Status-Quelle | Datei/Änderung entfernen (laut Source-Command). |

# Quelle „document\_symbols“

| Taste(n) | Aktion/Command | Kontext                 | Beschreibung                        |
| -------- | -------------- | ----------------------- | ----------------------------------- |
| /        | noop           | Document-Symbols-Quelle | Deaktiviert In-Source-Suchen auf /. |
| F        | filter         | Document-Symbols-Quelle | Symbol-Liste filtern.               |

---
