# TODO & ROADMAP: Refactoring & Plugin-Optimierung

**Notes:**
  - "Betroffene Dateien" sind als Beispiel genannt - darin nichts ändern, sondern im Plugin das bearbeitet wird.


- [ ] C:\Users\StefanBartl\AppData\Local\nvim\docs\NOTES\PersonelPlugins\BINDINGS\Usercmds\{PLUGIN_NAME}.md  erstelle dort ein vollständiges cheatsheet für das usrcmd/die usrcmds des plugins
- [ ] C:\Users\StefanBartl\AppData\Local\nvim\docs\NOTES\PersonelPlugins\BINDINGS\Keymaps\{PLUGIN_NAME}.md  erstelle dort ein vollständiges cheatsheet für die keymaps des plugins
- [ ] C:\Users\StefanBartl\AppData\Local\nvim\docs\NOTES\PersonelPlugins\BINDINGS\Autocmds\{PLUGIN_NAME}.md  erstelle dort ein vollständiges cheatsheet für die Autocmds des plugins


## Allgemeines & Medien


---

## Code-Architektur & API-Zentralisierung

### Autocmds zentralisieren

* [ ] **Problem:** Viele Module nutzen direkt `vim.api.nvim_create_autocmd`, obwohl `lib.autocmd` existiert.
  * *Betroffene Dateien:* `options.lua:79`, `hl_config/init.lua:212`, `astro/autocmds.lua:12`
  * *Verbesserung:* Nach und nach auf `lib.autocmd` bzw. den vorhandenen FileType-Dispatcher migrieren (für einheitliche Fehlerbehandlung, Gruppen und zuverlässiges Reload-Verhalten).

### Wrapper-Funktionen erzwingen

* [ ] **Problem:** Direkte Aufrufe von `vim.notify`, `print` und `vim.keymap.set` reduzieren. Die Checklisten verlangen die Nutzung von `lib.notify`, `lib.map` und `lib.usercmd`.
  * *Betroffene Dateien:* Direkte Treffer u. a. in `sessions/usercmds.lua:61`.
  * *Verbesserung:* Produktive Module migrieren; Debug- und Testmodule dürfen ggf. separat markiert bleiben.

### Robustheit (Buffer/Window-Handles)

* [ ] **Problem:** Einige Callbacks arbeiten verzögert (Deferred/Scheduled-Code) mit einem implizit aktuellen Window oder Buffer.
  * *Betroffene Dateien:* `pathprobe/init.lua:306`, `neotree/commands/clipboard/init.lua:286`
  * *Verbesserung:* Beim Scheduling `bufnr/winid` via Snapshot sichern und vor der tatsächlichen Nutzung erneut validieren.

### UI-Entkopplung

* [ ] **Problem:** Einige Core-nahe Module (Low-Level-Module) melden Fehler oder Status direkt per UI-Notify (z. B. LSP-Capabilities oder FS-/PDF-Port-Backendbereiche).
  * *Verbesserung:* Low-Level-Module geben stattdessen strukturiert `{ ok, err }` zurück. Die UI-Schicht entscheidet eigenständig über das `notify`. Das macht die Fehlerbehandlung konsistent.

### `lib.nvim` & UI-Kit Integration

* [ ] Fednefalls aus `lib.nvim` implementieren:
  * [ ] Aus `lib.nvim.ui.kit` z. B. `nice_quit` für alle Aufrufe von Windows prüfen und die entsprechende Variante aus dem UI-Kit implementieren.
  * [ ] Source code check, ob noch mehr von `lib.nvim` verwendet werden kann. Wenn ja, dann gleich implementieren

---

## Dokumentation, Cheatsheets & Benchmarks

### Plugin-Analyse & Cheatsheet-Generierung

* [ ] Plugin komplett durchgehen und folgende Dokumente befüllen:
  * [ ] **Keymaps:** Alle Keymaps als Cheatsheet nach `C:/Users/bartl/AppData/Local/nvim/docs/NOTES/PersonelPlugins/BINDINGS/Keymaps.md` schreiben.
    * [ ] Prüfen, dass es absolut keine Dopplungen bei den `lhs` der Keymaps mit anderen meiner personal Plugins gibt.
* [ ] **User Commands:** Alle Usrcmds als Cheatsheet nach `C:/Users/bartl/AppData/Local/nvim/docs/NOTES/PersonelPlugins/BINDINGS/Usermcds.md` schreiben.
* [ ] **Autocommands:** Alle Autocomands als Cheatsheet nach `C:/Users/bartl/AppData/Local/nvim/docs/NOTES/PersonelPlugins/BINDINGS/Autocmds.md` schreiben.
* [ ] **Sonstiges:** Sonstige Events, Actions und Features als Cheatsheet nach `C:/Users/bartl/AppData/Local/nvim/docs/NOTES/PersonelPlugins/Misc.md` schreiben.



### Hilfesystem & Tools

* [ ] `:Recommender` durch alle Module laufen lassen.
* [ ] `vimdoc`-Datei `doc/{NAME}.txt` erstellen + Funktion schreiben, die automatisch die `tags`-Datei für User generiert (`doc/tags` in `.gitignore` aufnehmen).
* [ ] Prüfen: Gibt es ein Autocmd, damit die Tags bei jedem User, der das Repo lädt, automatisch erstellt werden?


* [ ] `ProjectInsight stats lib` über alle Repositories ausführen und eine gesammelte Übersicht erstellen.

---

## Features, Keymaps & Selektions-Handling

### Anforderungen an Keymaps & Features

* [ ] Alle Keymaps und Features müssen zwingend auch via **User Command (usrcmd)** ausführbar sein.
* [ ] Verwendung von `lib.nvim.selection` durchsetzen:
* Ein wiederverwendbares Modul (`lines/reselect_lines/keep_lines` für Zeilenbereiche, `chars/reselect_chars/keep_chars` für Byte-Spaltenbereiche in derselben Zeile), das eine visuelle Auswahl wiederherstellt, nachdem ein Mapping den Buffer verändert hat (da `gv` hier nicht funktioniert, weil dessen Marks erst gesetzt werden, wenn der Visual-Mode tatsächlich endet). Inklusive vollständiger README.
* **Vorgehen:**
1. Zuerst noch einmal prüfen, ob das Modul am richtigen Ort in der `lib` liegt, verbessert werden muss usw.
2. Anschließend bei **jeder** Visual-Mode-Keymap, die zuvor die Selektion verloren hat, dieses Modul anwenden (sofern es sinnvoll ist).





---

## Sicherheit, Tests & CI/CD

### Code-Härtung

* [ ] Das Plugin explizit auf sicherheitsrelevante Aspekte abklopfen und härten.
* [ ] Evaluieren: Macht es Sinn, das Plugin oder bestimmte Teile davon als kompilierte Binaries auszugeben?

### Testing

* [ ] Wenn sinnvoll: Testdateien für die Features unter `TESTS/**` schreiben.
* [ ] Struktur anpassen: `docs/TESTS/**` verschieben nach `TESTS/**`, sodass sich die Tests im Root des Plugins befinden (nicht mehr im Ordner `docs`).

### DevOps & Repository-Struktur

* [ ] Alle Plugins auf die `.nvim`-Namensendung umstellen (sofern möglich).
* [ ] `Github Actions` einrichten (z. B. für `luacheck` etc.).
* [ ] Alle neuen Features und Bugfixes committen und pushen (falls nicht möglich: Commit-Message in der Konsole ausgeben).

---

## Strategie & Schlachtplan-Erstellung

* [ ] Einen dedizierten Schlachtplan für jeden dieser Punkte erstellen:
* [ ] **Checklisten einzeln und nacheinander anwenden:** Gehe dafür jede Liste separat durch und erstelle für jede eine `/docs/ROADMAP/**.md` Datei (wobei `**` dem jeweiligen Namen der Liste entspricht):
* [Architekur&Coding-Regeln](https://www.google.com/search?q=E:/repos/Notes/MyNotes/Checklists/Lua/Arch%26Coding-Regeln.md) `/docs/ROADMAP/Arch&Coding.md`
* [Zentrale Prinzipien](https://www.google.com/search?q=E:/repos/Notes/MyNotes/Checklists/Lua/Zentrale-Prinzipien.md) `/docs/ROADMAP/Zentral-Prinzipien.md`
* [Checklist.md](https://www.google.com/search?q=E:/repos/Notes/MyNotes/Checklists/Lua/Checklist.md) `/docs/ROADMAP/Checklist.md`


* [ ] Die vorhandene `/docs/ROADMAP.md` komplett durchgehen und einen konkreten Plan zur Implementierung ausarbeiten.
* [ ] Den Ordner `/NEOTREE_FEATURES` durchgehen und strukturiert bewerten, was mit den darin enthaltenen Elementen gemacht wird.
