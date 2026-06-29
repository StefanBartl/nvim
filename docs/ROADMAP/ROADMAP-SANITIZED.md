# Roadmap for `main-workstation` branch

## Inhaltsverzeichnis
- [1. Globale Core-Optimierungen (Neovim Base)](#1-globale-core-optimierungen-neovim-base)
- [2. Universal Custom Plugin Standard](#2-universal-custom-plugin-standard)
- [3. Custom Plugins Entwicklung](#3-custom-plugins-entwicklung)
  - [3.1 markdown.nvim & mdlinks.nvim](#31-markdownnvim--mdlinksnvim)
  - [3.2 project-insight.nvim & objtrack](#32-project-insightnvim--objtrack)
  - [3.3 fileops.nvim](#33-fileopsnvim)
  - [3.4 debugging.nvim](#34-debuggingnvim)
- [4. Drittanbieter-Plugins & Integrationen (Contrib)](#4-drittanbieter-plugins--integrationen-contrib)
  - [4.1 Neotree-Ökosystem](#41-neotree-ökosystem)
  - [4.2 AI Integrationen (Avante / Gp)](#42-ai-integrationen-avante--gp)
  - [4.3 Lazy & Sonstige Modifikationen](#43-lazy--sonstige-modifikationen)
- [5. Bug Tracker & Validierung](#5-bug-tracker--validierung)
  - [5.1 Bekannte Fehler (Bugs)](#51-bekannte-fehler-bugs)
  - [5.2 Laufende Funktionsprüfungen (QA)](#52-laufende-funktionsprüfungen-qa)

---

## 1. Globale Core-Optimierungen (Neovim Base)

- [ ] **Zentralisierung & Performance:** Alle verstreuten `autocmds` aus den Ordnern in eine zentrale `lua/config/autocmds.lua` migrieren. Sortierung nach Events optimieren, um die Startup-Time zu senken.
- [ ] **OS-Abstraktion:** Plattform-Abfragen (Windows vs. Unix) von Hardcoded-Expressions auf das dynamische `system.env` umstellen.
- [ ] **LSP Root-Switch:** Einen globalen Umschalter (Switch) implementieren, um das LSP-Wurzelverzeichnis (`root_dir`) dynamisch zwischen `cwd`, dem nächsten `.git`-Verzeichnis oder dem absoluten Datei-Pfad zu wechseln.
- [ ] **Zentrale User-Commands:** Alle `usrcmds` aus der `init.lua` extrahieren und in eine eigenständige `usrcmds.collection` überführen, sofern sie keinem spezifischen Plugin zugeordnet sind.
- [ ] **Kopier-Verhalten (Ctrl-C):** Beheben, dass `C-c` in manchen Kontexten ein `SIGINT` wirft und Neovim abbricht. Ziel: Konsistentes Kopieren des gesamten Buffers.
- [ ] **Spellchecking:** Rechtschreibprüfungs-Strategie finalisieren. Entscheidung treffen: Integriertes Modul debuggen oder externes Plugin einbinden.
- [ ] **Textumhüllung:** User-Command erstellen, um Suchtreffer innerhalb von `%/cwd/path` interaktiv mit Zeichen (z. B. \`\`, '', "", **) zu umschließen.

---

## 2. Universal Custom Plugin Standard
*Diese Checkliste gilt für jedes Plugin im Verzeichnis `/***.nvim` vor dem produktiven Release.*

- [ ] **Strikte Datei-Struktur:** Jedes Plugin muss folgendem Verzeichnis-Layout entsprechen:
  - `/config/DEFAULTS.lua` (Standardoptionen, überschreibbar durch den User via `.setup()`)
  - `/docs/BINDINGS.lua` oder `/bindings` (Zentrale Erfassung von `keymaps`, `usrcmds` und plugin-internen `autocmds`)
- [ ] **LSP & Typisierung:** Volle LuaCats/Emmett-Typisierung aller Konfigurationsschlüssel (z. B. `--@alias ProjectInsight.CompressEngine "auto"|"tar"|"zip"`), um Autovervollständigung in der User-Config zu garantieren.
- [ ] **Infrastruktur & Hygiene:**
  - [ ] `lib.nvim` konsequent als Core-Abhängigkeit (Dependency) einbinden.
  - [ ] Falls notwendig, Kompatibilitäts-Fallback für reine Vimscript-Umgebungen prüfen (`.vim`-Versionen).
  - [ ] `README.md` mit strukturiertem ToC, Badges ausstatten; Hardcoded-Pfade wie `dir = vim.env...` entfernen und korrekte Lizenz hinterlegen.
  - [ ] Sicherstellen, dass alle Plugins vollständig `lazy`-ladbar sind.
  - [ ] Validierung über nativen `:checkhealth`-Hook implementieren.
  - [ ] Nach Fertigstellung: Lokale Pfade kappen und alle Repositories auf Git-Remote (GitHub) umstellen.

---

## 3. Custom Plugins Entwicklung

### 3.1 `markdown.nvim` & `mdlinks.nvim`
- [ ] **Merge:** `mdlinks.nvim` vollständig in `markdown.nvim` integrieren und das alte Repo archivieren.
- [ ] **Feature-Portierung:** Sicherstellen, dass `markdown/core/wrap_links` und `markdown/core/headline_spacing` reibungslos laufen (Ex-Ordner vollständig migrieren).
- [ ] **Intelligente Link-Erkennung (`ml`):**
  - Wenn kein Link direkt unter dem Cursor liegt, die aktuelle Zeile scannen.
  - Bei exakt einem Fund: Diesen ausführen.
  - Bei mehreren Funden: Auswahl-UI via `lib.nvim -> hover_select` triggern.
- [ ] **Sammel-Command (`:Markdown`):** Erstellt ein User-Command, das alle Links im definierten Scope sammelt.
  - Steuerung des Outputs über Optionen: `lib.nvim -> hover_select`, `Telescope`, `fzf-lua` oder direkter Datei-Export.
  - Wichtig: Interaktive Picker müssen das Ziel bei `Enter` direkt öffnen.
- [ ] **Dateisystem-Generierung (`:MARKDOWN create fs`):** Neues User-Command implementieren. Liest markierte Markdown-Link-Pfade (z. B. `[Part 1](./PART1/Intro.md)`) und erzeugt die Verzeichnisse und Dateien automatisiert auf der Festplatte, falls nicht existent.
- [ ] **Rendering:** `markdown_render` innerhalb des `:Markdown [] []` Befehls implementieren.

### 3.2 `project-insight.nvim` & `objtrack`
- [x] **Architektur-Review:** `objtrack` analysiert. Ergebnis: kein eigenständiges Plugin — seine drei Scanner duplizierten `project-insight` (symbols/imports) und `recommender`. Das einzige Alleinstellungsmerkmal (Definition hinter `require("mod").field` auflösen & anzeigen) wurde nach `project-insight.nvim` (`imports/resolve.lua` + `imports/definition.lua`, `gd`/`gp` im Imports-Report) integriert; `objtrack` wurde gelöscht.
- [ ] **Deprecations:** Evaluieren, ob `monkeypatch` noch zeitgemäß ist, oder restlos entfernt werden kann.
- [ ] **Refactoring:** `migrate.nvim` abschließen.

### 3.3 `fileops.nvim`
- [ ] **Buffer-Handling:** Beheben, dass nach dem Ausführen von `:File delete %` zwar Datei und Buffer korrekt gelöscht werden, aber fälschlicherweise immer ein neuer, leerer Buffer geöffnet wird, obwohl noch andere valide Buffer im Hintergrund offen sind.

### 3.4 `debugging.nvim`
- [ ] **Keymap-Fix:** Beheben, warum die zentralen Keymaps `<lt>e` und `<lt>n` innerhalb von `debugging.nvim\debugging\views\keymaps.lua` nicht greifen.

### 3.4 `lib.nvim`

- [ ] Overlay/Fenster müssem sich oft im Normal-Mode intuitiv über `q` oder `Escape` schließen lassen. Dies könnte man in einer `lib.nvim`-Funktion anbieten: `function close_window_with_keymap(win_id){ ... }` Somit müsste man das nicht in jedem Plugin extra implementieren. Derartige weitere Features möglich?

---

## 4. Drittanbieter-Plugins & Integrationen (Contrib)

### 4.1 Neotree-Ökosystem
- [ ] **Abstraktion (`neotree-features.nvim`):** Alle im Team gesammelten Datei-Tree-Features sowie Skripte aus `/nvim/lua/config/neotree` extrahieren und in ein generisches, vom Filetree unabhängiges Plugin gießen (Kompatibilität für Neotree, NvimTree, Netrw garantieren).
- [ ] **UI-Zentralisierung:** Alle UI-spezifischen Anpassungen nach `config/neotree/ui` migrieren.
- [ ] **Maus-Scrolling:** Das störende automatische Zentrieren des Buffers (Centering) beim Scrollen mit dem Mausrad in Neotree deaktivieren.
- [ ] **UI-Highlighting:** Aktuelle Zeile in Neotree entweder deutlicher hervorheben (`hl`) oder eine Unterstreichung vom Cursor bis zum ersten Zeichen der Node rendern.
- [ ] **Feature-Merging:** Keymaps für Preview, Images und `pdfprot` vereinheitlichen.
- [ ] **Medien-Support:** Nach dem Refactoring prüfen, ob über `Snacks/image.nvim` native Bildvorschauen innerhalb des Trees realisiert werden können.

### 4.2 AI Integrationen (Avante / Gp)
- [ ] **Avante Deployment:** Den verbleibenden, finalen Abschnitt der `avante.md`-Roadmap implementieren.
- [ ] **User-Commands:** Dedizierte `usrcmds` für Steuerungs- und Prompt-Aktionen in Avante schreiben.
- [ ] **Benchmarking:** Das bestehende `gp.nvim`-Setup intensiv gegen das neue `avante`-Setup testen.

### 4.3 Lazy & Sonstige Modifikationen
- [ ] **Options-Konsolidierung:** Das Plugin `wkdoptions` mit der globalen `options.lua` verheiraten. Die UI-Dokumentation für den Linemarker gehört in die Haupt-README.
- [ ] **Lokale Patches sichern:** Vor dem Ausführen von `:Lazy` Updates für `todo-comments` und `ui` manuelle Sicherheitskopien der lokalen Monkeypatches anlegen. Nach dem Update die Änderungen neu bewerten und ggf. sauberer lösen.

---

## 5. Bug Tracker & Validierung

### 5.1 Bekannte Fehler (Bugs)
- [ ] **Line-Renumbering Crash (Visual Mode):**
  * *Fehler:* Absturz bei Zeilen-Einrückung via `A-Rght` im visuellen Modus.
  * *Log:* `helpers.lua:28: 'start' is higher than 'end'` in `visual_shift`.
- [ ] **Leader TOC:** `:leader toc` muss garantieren, dass am Ende jeder Markdown-Überschrift zwingend ein trennendes `---` injiziert wird.
- [ ] **ZenMode:** Ein globaler Umschalter (Toggle) über ein User-Command fehlt.
- [ ] **TableView Toggle:** Das Overlay/Fenster muss sich im Normal-Mode auch intuitiv über `q` oder `Escape` schließen lassen.
- [ ] **Ctrl-S Hänger:** Sporadische Aussetzer der Speicher-Keymap `C-s` analysieren und beheben.
- [ ] **Linemarker Logik-Bug:** * *Soll-Verhalten:* Relative Nummerierung von aktueller Zeile (0) nach oben zu Zeile 0 aufsteigend. Nach unten ebenfalls aufsteigend, jedoch mit der Ausnahme: Die letzte Zeile des Dokuments muss *immer* die absolute Gesamtzeilenzahl (z. B. 122) anzeigen.
  * *Task:* Prüfen, ob der Fehler im aktuellen Code-Stand noch reproduzierbar ist.

### 5.2 Laufende Funktionsprüfungen (QA)
*Folgende Integrations-Tests müssen nach jeder größeren Änderung fehlerfrei durchlaufen:*

- **QA-A (Debugging):** `:Debug module reload` auf einer aktiven Lua-Datei lädt das Modul live neu; `:checkhealth debugging` meldet Fehlerfreiheit.
- **QA-B (ProjectInsight):** `:ProjectInsight archive` generiert ein valides Archiv unter `~/temp/` via PowerShell auf Windows; `:checkhealth project-insight` ist grün.
- **QA-C (Open-Plugin):** `:Open` öffnet URLs im Standardbrowser, Verzeichnisse/Dateien im OS-nativem Dateimanager (Explorer/Finder); `:checkhealth open_nvim` ist grün.
- **QA-D (Formatierung):** `:Format trim`, `:Format sort` und `:Format column 40` transformieren den aktiven Testbuffer fehlerfrei; `:checkhealth buffer_ctx` ist grün.
- **QA-E (Markdown):** `:Format markdown headline_separators` validieren (inklusive API-Redirects); Alternativ bei Instabilität API-Zweig streichen.
- **QA-F (Linemarker):** Evaluierung der `require`-Pfade in der Config; Validierung, dass `MarkLineToggle` und `MarkLinesYank` feibungslos kooperieren.
- **QA-G (Pickers):** `:Pickers notes files` öffnet das Suchfenster; `NotesFiles` funktioniert als Aliases für die Abwärtskompatibilität; Unterordner werden via prefix-Collection sauber gelistet; `:checkhealth pickers` ist grün.
