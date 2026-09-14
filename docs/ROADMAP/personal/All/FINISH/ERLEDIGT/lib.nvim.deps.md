# Technische Spezifikation: Dependency Checker (`lib.nvim/deps`)

> **Stand 2026-09-14 — Aufwand/Nutzen-Analyse nachgetragen, Umsetzungsstand
> geprüft.** Alle drei Punkte aus den ursprünglichen Notes/ToDo's sind
> inzwischen erledigt (siehe unten); dieser Ordner ist damit eher ein
> Abschlussbericht als eine offene Idee. Ursprünglich mit 8 Submodulen und
> drei Einstiegspunkten geschrieben; `deps.status` und `deps.require_tool`
> kamen am 2026-09-03 dazu (lib.nvim `b8c75ea`).

Die Dependency-Checker-Komponente in `lib.nvim/deps` besteht aus 10 Submodulen
und dient der Erkennung, Validierung, Auflösung und Installation externer
CLI-Tools, die von Neovim-Plugins benötigt werden.

---

## Table of content

  - [Aufwand/Nutzen-Analyse](#aufwandnutzen-analyse)
  - [Notes / ToDo's (Original, erledigt)](#notes-todos-original-erledigt)
  - [Architektur & Funktionsweise](#architektur-funktionsweise)
  - [Schnittstellen & Einstiegspunkte](#schnittstellen-einstiegspunkte)

---

## Aufwand/Nutzen-Analyse

Die drei ursprünglichen Notes/ToDo's waren zum Zeitpunkt des Entwurfs
(2026-09-03) offene Fragen. Ein Blick in beide Repos (`lib.nvim` und die 30+
Consumer-Plugins unter `E:/repos/`) zeigt: alle drei sind längst beantwortet
— zwei davon vollständig umgesetzt, der dritte (eigene Repos) sogar breiter
als ursprünglich angedacht.

| # | Idee | Aufwand (geschätzt/tatsächlich) | Nutzen | Status |
|---|---|---|---|---|
| 1 | Workflow/Anleitung ins Repo | mittel (1 README + 1 `:h`-Doc) | hoch — jeder Konsument kann die Doku direkt neben dem Code lesen statt in einem externen Roadmap-Ordner zu suchen | ✅ **erledigt** — [`lua/lib/nvim/deps/README.md`](../../../../../repos/lib.nvim/lua/lib/nvim/deps/README.md) (570 Zeilen, vollständig) + `doc/lib.nvim-deps.txt` (`:h lib.nvim-deps`) |
| 2 | Prüfen/korrigieren/erweitern, auf Englisch | gering, da mit #1 zusammenfällt | hoch — Englisch ist im Repo Konvention (siehe CLAUDE.md-Vorgabe „Code/Doku englisch") | ✅ **erledigt** — README ist vollständig Englisch, deutlich ausführlicher als dieser Entwurf hier (inkl. Begründungen für Designentscheidungen: `bin_alternatives`, `paths`, Merge-Regeln in `deps.status`, Throttling in `require_tool`) |
| 3 | In eigenen Repos implementieren? | hoch (pro Plugin: `docs/install.json` schreiben + `health.lua`-Zeile + `require_tool`/`show_once`-Call-Sites) | sehr hoch — einheitliche `:checkhealth`-Berichte, First-Run-Hinweise, ein Gesamtstatus über alle Plugins (`:Lib deps status`) statt 16× hand-geschriebener „X not found"-Strings | ✅ **erledigt für 16 Plugins**, siehe Tabelle unten |

**Fazit:** Es gibt an diesem Dokument nichts mehr zu entscheiden — die
Abwägung aus Punkt 3 ist durch die tatsächliche Umsetzung in 16 Plugins
bereits beantwortet (der Nutzen hat den Aufwand klar gerechtfertigt: kein
Plugin musste seine eigene Fehlerstring-Logik behalten, `require_tool`
ersetzt sie 1:1 mit Install-Kommando + `why`). Empfehlung: diesen
IDEAS-Ordner nach Rücksprache als **erledigt archivieren/löschen**, nach dem
gleichen Muster wie die plenary/libuv-Research-Roadmap
(`project_lib_nvim_plenary_libuv_research`, geschlossen 2026-08-17). Bis zur
Bestätigung bleibt er hier als Abschlussbericht stehen.

### Rollout-Stand je Consumer-Plugin (Stand 2026-09-14)

16 von ~30 Plugins unter `E:/repos/` deklarieren Tools über
`docs/install.json`:

`casedesk.nvim`, `diff.nvim`, `documentation.nvim`, `filetree.nvim`,
`gopath.nvim`, `hover.nvim`, `images.nvim`, `insights.nvim`,
`language.nvim`, `markdown.nvim`, `mdview.nvim`, `open.nvim`,
`pdfport.nvim`, `pickers.nvim`, `replacer.nvim`, `runtime-analysis.nvim`.

Davon binden 14 zusätzlich `deps.health.report_for`/`pointer_for` in ihre
`health.lua` ein (Ausnahmen: `casedesk.nvim`, `documentation.nvim` — dort
lohnt sich ein kurzer Nachtrag, siehe „offener Rest" unten). Alle 16 rufen
`require_tool`/`show_once` an mindestens einer Stelle auf.

**Offener Rest (klein, kein neues Feature, nur Nacharbeit):**

- `casedesk.nvim` und `documentation.nvim`: `docs/install.json` vorhanden,
  aber kein `report_for`/`pointer_for`-Aufruf in `health.lua` — Aufwand
  jeweils eine Zeile, Nutzen: konsistentes `:checkhealth`-Bild über alle 16
  Plugins statt 14/16. Lohnt sich, ist aber kein Grund, dieses Dokument
  offen zu halten.
- Plugins **ohne** `docs/install.json` unter `E:/repos/` (z. B. `ai.nvim`,
  `buffer-ctx.nvim`, `sessions.nvim`, `spotlight.nvim`, …) wurden nicht
  geprüft, ob sie überhaupt externe CLI-Tools voraussetzen — falls nicht,
  ist dort schlicht nichts zu deklarieren.

---

## Notes / ToDo's (Original, erledigt)

- ~~Dieser Workflow/Anleitung sollte auch im repo stehen~~ → README.md +
  `doc/lib.nvim-deps.txt` im lib.nvim-Repo.
- ~~Dafür muss er aber überprüft, ggf. korrigiert/erweitert werden und auf
  englisch umgeschrieben werden~~ → erledigt, README ist Englisch und
  deutlich detaillierter als dieser ursprüngliche Entwurf.
- ~~In meinen eigenen Repos implementieren? Abwägung...~~ → erledigt, 16
  Plugins nutzen die Spec bereits (siehe Tabelle oben).

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

Der Checker stellt fünf Opt-in-Einstiegspunkte bereit:

* **Befehlsschnittstelle (`:Lib deps show|install [plugin]`)**
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

* **Gesamtübersicht (`:Lib deps status`, `deps.status`)**
  * Führt die Specs **aller** Plugins zu einem Bericht zusammen; ein Tool, das mehrere Plugins wollen, erscheint einmal und nennt alle Herkünfte.
  * Rendert durch dasselbe `deps.view` wie die Einzelansicht — gleiche `i`/`I`-Keymaps, gleiches Live-Streaming, kein zweiter Renderer.
  * Erreicht über die lazy.nvim-Registry auch noch nicht geladene Plugins und umgeht damit das Timing-Problem des Erststart-Popups (das an `setup()` hängt und bei lazy geladenen Plugins beliebig spät kommt).
  * `:Lib deps install` **ohne** Plugin-Argument plant dasselbe für alle fehlenden Tools — gleiche Rückfrage, gleiche Terminal-Übergabe.

* **Fehlermoment (`deps.require_tool(plugin, bin)`)**
  * Die einzige Schnittstelle, die **nicht** vorausschauend ist: sie wird in dem Moment gefragt, in dem ein Kommando tatsächlich scheitert.
  * Meldet mit dem `why` aus dem Spec und dem Install-Kommando für *diesen* Host statt mit einem nackten „X not found".
  * Gibt den **Namen** zurück, unter dem das Tool gefunden wurde (nicht `true`) — wegen `bin_alternatives` muss der Aufrufer wissen, welche Schreibweise er starten soll.
  * Meldet pro (Plugin, Tool) höchstens alle 5 s, damit eine Prüfung in einer Schleife keine Notification-Lawine auslöst.
  * `require_tool.lines(plugin, bin)` liefert denselben Text **ohne** zu melden — für Aufrufer, die ihren Fehler nach oben durchreichen (Callback, `errors`-Liste), wo eine Notification daneben dasselbe zweimal sagen würde.
  * Funktioniert auch ohne Spec: dann ohne `why` und ohne Install-Zeile, aber ohne Fehler — ein Plugin kann also zuerst umstellen und danach deklarieren.

---
