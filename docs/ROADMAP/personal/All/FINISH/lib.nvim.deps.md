# Technische Spezifikation: Dependency Checker (`lib.nvim/deps`)

Die Dependency-Checker-Komponente in `lib.nvim/deps` besteht aus 8 Submodulen und dient der Erkennung, Validierung, Auflösung und Installation externer CLI-Tools, die von Neovim-Plugins benötigt werden.

---

## Table of content

  - [Notes / ToDo's](#notes-todos)
  - [Architektur & Funktionsweise](#architektur-funktionsweise)
  - [Schnittstellen & Einstiegspunkte](#schnittstellen-einstiegspunkte)

---

## Notes / ToDo's

- Dieser Workflow / ANleitung sollte  auch im repo stehen
- Dafür muss er aber überprüft, ggf. korrigiert /erweitert werden und auf englisch umgeschrieben werden
- In meinen eigenen Repos implementiern ? Abwägung...

---

## Architektur & Funktionsweise

1. **Deklaration (Plugin-Seite)**
  * Externe Abhängigkeiten werden pro Plugin in `docs/install.json` oder `docs/INSTALL.md` deklariert.
  * **Pflichtfelder:** `bin` (Name des Executables) und `why` (Zweck/Begründung; darf nicht leer sein).
  * **Optionale Felder:** `pkg` (Mapping für Paketmanager), `required` (Boolean), `bin_alternatives` und `see` (Referenz-URLs).


2. **Auflösung (`spec.find`)**
  * Sucht Spezifikationen zunächst über den aktiven `runtimepath` (unabhängig vom Plugin-Manager).
  * Greift bei Bedarf per `pcall` auf die Registry von lazy.nvim zu, um auch inaktive/pending Plugins zu erfassen, die noch nicht im `runtimepath` liegen.


3. **Prüfung & Ausführungsplanung**
  * **`deps.detect`:** Prüft das Vorhandensein der Binaries (inklusive definierter Alternativ-Namen).
  * **`deps.pm`:** Erkennt den Paketmanager des Betriebssystems und generiert das passende Installationskommando.
  * **`deps.install.plan()`:** Eine reine Funktion (Pure Function), die fehlende Tools analysiert und in `installable` (installierbar) oder `unsupported` (nicht unterstützt) einsortiert.

---

## Schnittstellen & Einstiegspunkte

Der Checker stellt drei Opt-in-Einstiegspunkte bereit:

* **Befehlsschnittstelle (`:Lib deps show|install <plugin>`)**
  * Öffnet ein interaktives Popup.
  * `i`: Installiert ein einzelnes gewähltes Tool.
  * `I`: Installiert alle fehlenden Abhängigkeiten.
  * `<CR>`: Klappt Log-Outputs auf oder zu.
  * Unprivilegierte Installationen werden direkt inline gestreamt. Bei benötigten Admin-/Root-Rechten wird die Ausführung an ein Terminal-Buffer übergeben, in dem der Befehl voreingetippt (aber **nicht** automatisch abgesendet) bereitsteht. (Designentscheidung)

* **Checkhealth-Integration (`deps.health.report_for("plugin.nvim")`)**
  * Einzeilige Einbindung für `health.lua`-Dateien von Plugins zur Ausgabe strukturierter Berichte in `:checkhealth`.

* **Erststart-Hinweis (`require("lib.nvim.deps").show_once("plugin.nvim")`)**
  * Wird beim initialen Aufruf von `setup()` eines Plugins ausgeführt.
  * Zeigt bei fehlenden CLI-Tools beim ersten Start ein Hinweis-Popup mit Erklärung (`why`) und Install-Keymaps.
  * Der Status ("bereits gesehen") wird dauerhaft in `cache.disk` gespeichert.
  * Deaktivierbar über `vim.g.lib_nvim_deps_disable_first_run` (global) oder `vim.g.lib_nvim_deps_disabled_plugins` (pro Plugin).

---

