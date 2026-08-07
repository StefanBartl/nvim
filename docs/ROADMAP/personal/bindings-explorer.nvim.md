# bindings-explorer — Konzept: Picker über die eigenen BINDINGS-Cheatsheets

> **Status: Phase 1 implementiert** (2026-08-07) — `:Bindings search
> [query]`, siehe `lua/bindings/usrcmds/bindings_explorer/`. Phase 2/3
> unten sind weiterhin nur Konzept.

Auslöser: beim Aufräumen von `docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/
images.nvim.md` diese Sitzung fiel auf, dass das Sheet seit der ersten
Fassung veraltet war — mehrere Subcommands fehlten komplett. Genau dieses
Drift-Problem (Doku vs. Realität) ist der eigentliche Kern dieser Idee,
nicht nur "ein Picker über Markdown".

Vor der Implementierung wurde außerdem `docs/NOTES/BINDINGS-FORMAT.md`
geschrieben und rückwirkend auf den ganzen 137-Datei-Bestand angewendet —
siehe dort. Ohne diesen Schritt hätte Phase 1 (reine Volltextsuche)
trotzdem funktioniert, aber Phase 2/3 (Tabellenzeilen als Datensätze,
Drift-Erkennung) hätten auf einem deutlich uneinheitlicheren Korpus
aufgesetzt.

## 1. Was schon da ist

Zwei Verzeichnisse, drei Kategorien, **137 Dateien**:

```
docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/<plugin>.nvim.md   (99 Dateien)
docs/NOTES/ExternPlugins/Bindings/{Keymaps,Usercmds,Autocmds}/<Plugin>.md          (38 Dateien)
```

Jede Datei ist handgeschrieben und enthält mehr als reine Tabellen: Rationale
("warum diese Taste statt jener"), Cross-References zu anderen Sheets,
`[default]`/`[custom]`-Markierungen (v. a. bei Extern-Plugins, die eigene
Werksbelegungen mitbringen), offene Fragen ("nicht zur Laufzeit verifiziert"),
und datierte Changelog-Einträge. Genau das ist der Unterschied zu Telescopes
eigenem Keymap-Picker oder `snacks.picker`s Äquivalent — die zeigen nur, *was*
gerade gebunden ist (`vim.keymap.set`-Introspektion), nie *warum*, nie die
Historie, nie einen Vergleich mit dem Plugin-Default.

**Es gibt bereits einen Präzedenzfall für "konsolidiert statt pro Datei"**:
[`autocmds-by-plugin.md`](../../NOTES/PersonelPlugins/BINDINGS/autocmds-by-plugin.md)
(plus `-by-event.md`, `-by-filetype.md`) — ein von Hand gepflegtes
Sammel-Dokument, ein Abschnitt pro Plugin, kondensierte Tabelle
(`Event(s) | Augroup | Pattern | Action`). Genau die Konsolidierung, die du
jetzt für Keymaps/Usercmds willst, existiert für Autocmds also schon —
nur statisch (eine weitere Markdown-Datei, von Hand synchron zu halten) und
nicht als etwas, das man in Neovim aufruft und durchsucht.

## 2. Das eigentliche Hindernis: keine einheitliche Struktur

Ein naiver "parse jede Tabelle in ein festes Schema"-Ansatz bricht an der
Realität des Korpus. Zwei Beispiele als Gegenpol:

- `Keymaps/images.nvim.md` (diese Sitzung geschrieben): eine Haupttabelle
  `| Key | Mode | Effect | Option |`, danach ein Notes-Abschnitt, danach
  datierte Changelog-Zeilen. Diszipliniert, vorhersagbar.
- `ExternPlugins/Bindings/Keymaps/Telescope.md`: **sechs** verschiedene
  Tabellen mit unterschiedlichen Spalten (`Mapping|Aktion|Ziel|Status`,
  `Taste|Aktion|Status`, `Insert/Normal|Aktion|Beschreibung`, …), dazwischen
  mehrere Absätze Fließtext, ein "Kollisions-Hinweis (offene Frage, nicht
  abschließend verifiziert)" — echte, wichtige Information, die in keiner
  Tabellenzelle steht.

Ein Tool, das ein festes Spaltenschema über den ganzen Korpus voraussetzt,
würde entweder an Telescope.md scheitern oder die Hälfte des Inhalts
stillschweigend verwerfen. Das Konzept unten geht deshalb bewusst
zweigleisig statt einer einzigen "richtigen" Parse-Strategie.

## 3. Architektur — drei Ausbaustufen, jede für sich nutzbar

### Phase 1 — Volltextsuche ✅ implementiert (2026-08-07)

`:Bindings search [query]` (`lua/bindings/usrcmds/bindings_explorer/`,
`M.enable()` in `bindings.usrcmds.init` neben casedesk registriert).

**Kein `ripgrep`**, wie ursprünglich hier skizziert — stattdessen exakt
casedesks eigenes Muster übernommen (`case.query.M.grep`s
`collect_recursive.files()` + `lib.nvim.fs.read` + reines Lua-Pattern-
Matching, kein externer Prozess): dieselbe Aufgabe, dasselbe Werkzeug,
schon vorhandener Präzedenzfall im selben Repo, keine zusätzliche
Abhängigkeit (ripgrep-Verfügbarkeit wäre eine neue Voraussetzung gewesen,
die dieses Config-Modul sonst nirgends hat).

**Picker-Backend: `lib.nvim.ui.kit.select`, nicht `pickers.nvim`** — die
hier vorher offene Frage ist geklärt: `pickers.nvim/lua/pickers/sources/`
ist ausschließlich Dateisystem-Quellen (cwd/folder/repos/drives/system),
kein generischer "Picker über eine beliebige Liste"-Einstieg. Genau das
bereits dokumentierte Ergebnis aus casedesks eigener Prüfung
(`ROADMAP.md`, "Backend-Kaskade… zurückgestellt") — hier bestätigt, nicht
neu herausgefunden. `kit.select.open({ items, format_item, on_select })`
übernimmt stattdessen, mit `<CR>` → Datei öffnen + Cursor auf die
Fundzeile.

Headless end-to-end verifiziert: `search.M.search("which-key")` liefert
86 echte Treffer aus dem gerade frisch überarbeiteten Korpus,
`nvim_get_commands()` bestätigt `:Bindings` als registriert. Die
interaktive Picker-UI selbst (`kit.select`/`kit.input`) bleibt ungeprüft
wie überall in diesem Ökosystem — braucht ein echtes Fenster.

### Phase 2 — Tabellenzeilen als durchsuchbare Datensätze

Ein toleranter Scraper: jede `|…|…|`-Zeile unter einer Überschrift wird zu
einem flachen Datensatz
`{ scope = "Personal"|"Extern", category = "Keymaps"|"Usercmds"|"Autocmds",
plugin, heading, columns = {…}, file, lnum }` — Spaltenzahl/-namen bleiben
Freitext, keine feste Schema-Annahme. Ein zweiter Picker-Modus ("nach Zeile
statt nach Zeile-im-Fließtext filtern") baut direkt darauf. Dateien ohne
saubere Tabellen (Telescope.md streckenweise) liefern hier einfach weniger
Treffer, bleiben aber über Phase 1 weiter auffindbar — kein Totalausfall,
nur ein graduell schwächerer Signal.

### Phase 3 — Drift-Erkennung (der eigentliche Mehrwert, am aufwändigsten)

Das, was heute manuell und zufällig passiert (wie bei `images.nvim.md`
diese Sitzung), automatisch: dokumentierte gegen tatsächlich registrierte
Bindings abgleichen.

- **Usercmds**: `vim.api.nvim_get_commands({})` liefert jeden aktuell
  registrierten User-Command. Jede `Usercmds/*.md`-Zeile, die ein Command
  wie `:Image redact` nennt, wird gegen diese Liste geprüft.
- **Keymaps**: `vim.api.nvim_get_keymap(mode)` (global) plus
  `vim.api.nvim_buf_get_keymap(bufnr, mode)` (buffer-lokal, filetype-
  gescoped — ein `<leader>im` aus `keymaps.filetypes = {"markdown",…}`
  taucht nur auf, wenn der Vergleichsbuffer diesen Filetype hat, was der
  Report explizit berücksichtigen muss, sonst wird jede filetype-gescopte
  Bindung als "fehlt" gemeldet).
- Zwei Richtungen, beide interessant: **dokumentiert, aber nicht (mehr) live**
  (genau der Fund von heute — ein gestrichenes oder umbenanntes Feature, das
  im Cheatsheet übrig blieb) und **live, aber undokumentiert** (ein Keymap/
  Command, das im Code existiert, aber nie ins Sheet nachgezogen wurde — die
  Umkehrung desselben Problems).
- Bewusst **nur ein Bericht**, kein Autofix — dieselbe Haltung wie casedesks
  `:Cases doctor` (reine Findings-Liste, `:Cases normalize` ist der separate
  Fix-Schritt mit Dry-Run/Confirm). Ein Cheatsheet automatisch umschreiben
  würde die handgeschriebene Rationale zerstören, die der ganze Sinn dieses
  Korpus ist.

## 4. Command-Oberfläche (Skizze)

Ein Verb, analog zu `:Case`/`:Cases` und `:Image`, nicht drei Flat-Commands:

| Command | Phase | Wirkung |
| --- | --- | --- |
| `:Bindings search [query]` | 1 | Volltextsuche über beide BINDINGS-Bäume, Picker |
| `:Bindings browse [keymaps\|usercmds\|autocmds] [personal\|extern]` | 2 | Tabellenzeilen als Picker, optional gescoped |
| `:Bindings check [plugin]` | 3 | Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert |

## 5. Wo das hingehört

Am ehesten ein neues Modul innerhalb der nvim-Config,
`lua/bindings/usrcmds/bindings_explorer/`, nach demselben Muster wie
casedesk (`lua/bindings/usrcmds/case/`) — kein Grund, das gleich als
eigenes `*.nvim`-Repo zu starten. Siehe die dokumentierte
Plugin-Extraction-Pattern: config-Modul zuerst, Extraktion erst wenn es
sich als eigenständig nützlich erweist, genau wie es bei casedesk selbst
lief.

## 6. Aufwand-Einschätzung

| Teil | Vergleichbar mit | Aufwand |
| --- | --- | --- |
| Phase 1 (ripgrep + Picker) | `casedesk.query`s `:Cases grep` (existiert bereits, dieselbe Grep-über-Markdown-Idee) | **klein** — im Kern eine dünne Picker-Verdrahtung um einen vorhandenen ripgrep-Aufruf |
| Phase 2 (toleranter Tabellen-Scraper) | `casedesk.terminology`s Parser (sammelt `## `/`### `-Begriffe über einen ganzen Doku-Baum, mit genau demselben "nicht jede Datei ist gleich strukturiert"-Problem, siehe dessen Moduldoc) | **mittel** — der Scraper selbst ist einfach, die Zahl der Randfälle (wie viele verschiedene Tabellenformen wirklich vorkommen) zeigt sich erst beim Testen gegen den echten Bestand |
| Phase 3 (Drift-Erkennung) | `casedesk.doctor` (Scan → Findings-Liste, rein lesend, kein Autofix) | **am größten** — Matching von Freitext-Bindings-Notation (`<leader>iv`, `:Image redact [path]`) gegen `nvim_get_keymap`/`nvim_get_commands`-Ausgabe ist die eigentliche Fleißarbeit, plus die Filetype-Scoping-Falle oben |

**Reihenfolge-Vorschlag:** Phase 1 zuerst und für sich allein schon nützlich
lassen — sie deckt den ganzen Korpus ab, ohne dass irgendein Parsing-Risiko
eingegangen wird. Phase 2 nur, wenn sich Phase 1 im Alltag als "ich will
öfter nach einer bestimmten Taste/Command filtern, nicht nur nach Text
suchen" zeigt. Phase 3 ist der eigentliche Grund, warum diese Idee mehr ist
als ein Telescope-Ersatz — aber auch der Teil, bei dem sich der Aufwand erst
beim Bauen genau zeigt.
