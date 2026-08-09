# bindings-explorer — Konzept: Picker über die eigenen BINDINGS-Cheatsheets

> **Status: Phase 1+2+3 implementiert** (Phase 1: 2026-08-07; Phase 2+3:
> 2026-08-09) — `lua/bindings/usrcmds/bindings_explorer/`. Damit ist das
> gesamte Konzept unten umgesetzt; diese Datei bleibt als Architektur-
> Begründung stehen. Vollständige Feature-/Command-Liste inkl. Beispielen:
> [`FEATURES.md`](../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md).
> Vimdoc: `:help bindings_explorer`
> (`lua/bindings/usrcmds/bindings_explorer/doc/bindings_explorer.txt`).

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

`:Bindings search [keymaps|usercmds|autocmds] [query]` (Live-Grep über
`pickers.nvim`s Engine-Schicht, statische Prompt+Liste als Fallback) und
`:Bindings path [personal|extern]`. Details, Beispiele, Testnachweis:
[`FEATURES.md`](../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md).

### Phase 2 — Tabellenzeilen als durchsuchbare Datensätze ✅ implementiert (2026-08-09)

`:Bindings browse [keymaps|usercmds|autocmds] [personal|extern]` — ein
toleranter Scraper (`records.lua`) macht jede `|…|…|`-Zeile unter einer
Überschrift zu einem flachen Datensatz, Picker darüber in `browse.lua`.
Details, Beispiele, Testnachweis:
[`FEATURES.md`](../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md).

### Phase 3 — Drift-Erkennung ✅ implementiert (2026-08-09)

`:Bindings check [plugin]` (`drift.lua`) — dokumentierte gegen tatsächlich
registrierte Bindings abgleichen, read-only, kein Autofix (dieselbe
Haltung wie casedesks `:Cases doctor`). Der reale Scope ist enger als
ursprünglich hier skizziert — siehe `drift.lua`s Moduldoc und
[`FEATURES.md`](../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md)
für die vollständige, verifizierte Begründung: Keymaps nur eine Richtung
(dokumentiert-aber-nicht-live, Personal only), Usercmds beide Richtungen.
Zwei reale Bugs unterwegs gefunden und gefixt (Config-Key-Name statt
literalem Key extrahiert; `.lhs`/`keytrans()`-Vergleich statt exaktem
`.lhsraw` verwendet — beide nur durch Testen gegen den echten, voll
geladenen Bestand sichtbar geworden, nicht durch Code-Lesen). Die
Filetype-Scoping-Falle unten erwies sich als noch breiter als gedacht:
buffer-lokale UI-Plugins (filetree.nvim, github_stats.nvim, ...) sind
strukturell nie über globale `nvim_get_keymap` sichtbar, nicht nur
filetype-gescopte Einzelfälle — jetzt explizit im Report benannt statt
stillschweigend falsch gemeldet.

## 4. Command-Oberfläche (Skizze)

Ein Verb, analog zu `:Case`/`:Cases` und `:Image`, nicht drei Flat-Commands:

| Command | Phase | Wirkung |
| --- | --- | --- |
| `:Bindings search [query]` | 1 ✅ | Volltextsuche über beide BINDINGS-Bäume, Picker |
| `:Bindings browse [keymaps\|usercmds\|autocmds] [personal\|extern]` | 2 ✅ | Tabellenzeilen als Picker, optional gescoped |
| `:Bindings check [plugin]` | 3 ✅ | Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert |

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
| Phase 1 ✅ (Grep + Picker) | `casedesk.query`s `:Cases grep` | **klein** — dünne Picker-Verdrahtung, siehe FEATURES.md |
| Phase 2 ✅ (toleranter Tabellen-Scraper) | `casedesk.terminology`s Parser | **mittel** — abgeschlossen, `records.lua`/`browse.lua`, gegen den echten 137-Datei-Bestand verifiziert (1641 Zeilen geparst) |
| Phase 3 ✅ (Drift-Erkennung) | `casedesk.doctor` (Scan → Findings-Liste, rein lesend, kein Autofix) | **war am größten, wie erwartet** — abgeschlossen, `drift.lua`; die reale Fleißarbeit war nicht das Freitext-Matching selbst, sondern zwei durch echte Verifikation gefundene Bugs (siehe Phase-3-Abschnitt oben) plus die breiter als gedacht ausgefallene Filetype/Buffer-Scoping-Falle |

Alle drei Phasen sind jetzt umgesetzt — der eigentliche Wert (Drift zwischen
Doku und Realität sichtbar machen, wie beim `images.nvim.md`-Fund, der die
ganze Idee ausgelöst hat) ist damit vollständig eingelöst.
