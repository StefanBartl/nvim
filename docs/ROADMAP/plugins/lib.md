
# Repository `StefanBartl/lib.nvim` erstellen

## Ziel

Die bisherige interne `lib` aus der Neovim-Konfiguration in ein eigenständiges Repository auslagern und als Dependency über `lazy.nvim` einbinden.

## Aufgaben

* Neues Repository `StefanBartl/lib.nvim` anlegen.
* Bestehende `lua/lib`-Struktur übernehmen.
* Klare Trennung der APIs nach Verantwortungsbereich einführen:

  * `lib.lua.*` – allgemeine, editorunabhängige Lua-Hilfsfunktionen.
  * `lib.nvim.*` – Neovim-spezifische Funktionen und Erweiterungen.
  * `lib.vim.*` – optionale Implementierungen für klassisches Vim mit möglichst kompatibler API zu `lib.nvim`.
* Öffentliche API definieren und interne Module von öffentlichen Modulen trennen.
* README mit Modulübersicht und Namenskonventionen erstellen.
* Die eigene Neovim-Konfiguration auf die externe Library umstellen.
* Alle eigenen Plugins künftig über `dependencies = { "StefanBartl/lib.nvim" }` an die Library anbinden.
* Langfristig prüfen, welche Module vollständig editorunabhängig sind und gegebenenfalls später in ein separates `lib.lua`-Repository ausgelagert werden können.

> Alles, was keine `vim`-API benötigt, gehört grundsätzlich nach `lib.lua.*`. `lib.nvim.*` sollte lediglich als Adapter auf Neovim dienen.

Diese Trennung sorgt langfristig dafür, dass die generischen Teile der Library unabhängig testbar und auch außerhalb von Neovim wiederverwendbar bleiben.
