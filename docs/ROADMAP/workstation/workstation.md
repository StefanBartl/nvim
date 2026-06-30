# `workstation`-Roadmap

## Table of content

  - [`C-a`: Sollte alles markieren](#c-a-sollte-alles-markieren)
    - [1. Ein globales Windows-Shortcut fängt `<C-a>` ab](#1-ein-globales-windows-shortcut-fngt-c-a-ab)
    - [2. Das Terminal (oder die Shell) fängt `<C-a>` ab](#2-das-terminal-oder-die-shell-fngt-c-a-ab)
      - [Der Diagnose-Befehl in Neovim](#der-diagnose-befehl-in-neovim)
    - [3. Neovim-interne Überlagerung (Shadowing)](#3-neovim-interne-berlagerung-shadowing)
    - [Zusammenfassung zur schnellen Lösung:](#zusammenfassung-zur-schnellen-lsung)

---

- `leader[` toc funktiert ncih

## `C-a`: Sollte alles markieren

### 1. Ein globales Windows-Shortcut fängt `<C-a>` ab

Auf Laptops installieren Hersteller (oder IT-Abteilungen bei Firmen-Workstations) oft Hintergrund-Tools für Grafik, Audio oder Hotkeys. Wenn ein anderes Programm unter Windows `<C-a>` als *globalen Hotkey* registriert hat, kommt das Signal niemals bei deinem Terminal oder Neovim an.

* **Verdächtige Tools:** AMD Software, Nvidia GeForce Experience, Intel Graphics Command Center, Powertoys (Keyboard Manager) oder Audio-Control-Panels (Realtek/Waves).
* **Test:** Drücke `<C-a>`, während du einfach nur auf dem Windows-Desktop bist. Passiert irgendwas? Öffnet sich ein Menü oder flackert ein Overlay?

---

### 2. Das Terminal (oder die Shell) fängt `<C-a>` ab

Verwendest du auf beiden Rechnern exakt dasselbe Terminal (z.B. WezTerm, Alacritty, Windows Terminal)?

* **Terminal-Ebene:** Manche Terminals haben eigene Keybindings. Im *Windows Terminal* oder *WezTerm* könnte `<C-a>` für "Aktionen" oder "Tab wechseln" belegt sein. Wenn das Terminal die Kombo abfängt, sieht Neovim sie nicht.
* **Shell-Ebene (PowerShell / WSL):** Wenn du PowerShell nutzt, ist `<C-a>` dort standardmäßig an `SelectAll` oder den Zeilenanfang gebunden (über `PSReadLine`). Manchmal beißt sich das mit der Weitergabe an Konsolen-Anwendungen.

---

#### Der Diagnose-Befehl in Neovim

Finde heraus, was Neovim *wirklich* sieht. Öffne Neovim auf der Workstation und tippe:

```vim
:help key-codes

```

Oder noch besser, geh in den Insert-Modus und drücke:

```text
<C-v><C-a>

```

* Wenn dort nun `^A` im Buffer erscheint, empfängt Neovim die Taste korrekt.
* Wenn sich gar nichts tut oder etwas völlig anderes passiert, fängt das Terminal oder Windows die Taste ab.

---

### 3. Neovim-interne Überlagerung (Shadowing)

Es kann sein, dass auf der Workstation ein bestimmtes Plugin geladen wird (oder eine andere Version davon), das `<C-a>` nach deiner `init.lua` erneut überschreibt.

Gib auf beiden Rechnern in Neovim folgenden Befehl ein:

```vim
:verbose nmap <C-a>

```

Dieser Befehl zeigt dir exakt, wer das Mapping für `<C-a>` im Normal-Mode (`nmap`) als Letztes definiert hat und in welcher Datei das passiert ist.

* **Gutes Ergebnis:** Es zeigt auf deine Keymap-Datei.
* **Schlechtes Ergebnis:** Es zeigt auf ein Plugin (z.B. ein Copilot-Plugin, Dial.nvim, oder ein tmux/navigator-Klon) oder sagt "No mapping found".

---

### Zusammenfassung zur schnellen Lösung:

1. Führ zuerst `:verbose nmap <C-a>` in Neovim aus. Siehst du dein Mapping?
2. Wenn ja: Starte Neovim im Windows-Standard-Terminal (`cmd.exe`) statt deiner gewohnten Shell/Terminal-Umgebung und teste es dort. Funktioniert es da? Wenn ja, liegt es am Terminal/der Shell deiner Workstation.

---

