# bindings-explorer — Features

`:Bindings` — Picker über die eigenen BINDINGS-Cheatsheets
(`docs/NOTES/PersonelPlugins/BINDINGS/` + `docs/NOTES/ExternPlugins/Bindings/`,
137 Dateien, drei Kategorien: Keymaps/Usercmds/Autocmds).
Vimdoc: `:help bindings_explorer` (siehe [`doc/bindings_explorer.txt`](../doc/bindings_explorer.txt)).
Diese Datei ist die aktuelle Doku — der ursprüngliche Konzept-Entwurf unter
`docs/ROADMAP/personal/bindings-explorer.nvim.md` wurde beim Aufräumen der
Roadmap gelöscht (Feature ist längst umgesetzt, Phase 1–3 alle fertig).

Module: `lua/bindings/usrcmds/bindings_explorer/` — `init.lua` (Composer-
Verb + Routen), `config.lua` (die zwei BINDINGS-Wurzeln), `search.lua` +
`ui.lua` (Phase 1 Fallback-Suche), `live.lua` (Phase 1 Live-Grep),
`records.lua` + `browse.lua` (Phase 2 Tabellen-Scraper + Picker),
`drift.lua` + `source.lua` + `repo.lua` (Phase 3 Drift-Bericht, vier Achsen),
`report.lua` + `status.lua` (Phase 4 Berichtsdatei + Dashboard).

## Volltextsuche (`:Bindings search`)

`:Bindings search [keymaps|usercmds|autocmds] [query]`

Durchsucht beide BINDINGS-Bäume (oder nur eine der drei Unterkategorien)
Zeile für Zeile nach `query`, case-insensitiv. Zwei Backends, automatisch
gewählt:

- **Live-Grep-in-Picker** (bevorzugt): über `pickers.nvim`s Engine-Schicht
  (`pickers.engines.load()` → `engine.live_grep({ roots, prompt, query })`),
  einheitlich über telescope/fzf-lua/snacks hinweg. Tippen filtert live,
  `<CR>` springt an die Fundstelle.
- **Fallback ohne Picker-Engine**: `kit.input` (Prompt für `query`, falls
  keiner mitgegeben wurde) → `kit.select` (statische Trefferliste). Greift
  automatisch, wenn keine Engine/kein ripgrep verfügbar ist.

Beispiele:

```vim
:Bindings search <leader>iv
:Bindings search keymaps redact
:Bindings search usercmds
:Bindings search autocmds BufEnter
```

## Wurzelpfade kopieren (`:Bindings path`)

`:Bindings path [personal|extern]`

Kopiert die BINDINGS-Wurzel(n) in die Zwischenablage — ohne Argument beide,
newline-getrennt. Löst denselben Zweck wie das ältere, separate
`:BindingsPath` (`lua/bindings/usrcmds/init.lua`), aber mit den zwei
tatsächlichen Pfaden statt dessen einzelnem, nie existierenden
`docs/NOTES/BINDINGS`.

```vim
:Bindings path
:Bindings path personal
:Bindings path extern
```

## Tabellenzeilen-Picker (`:Bindings browse`)

`:Bindings browse [keymaps|usercmds|autocmds] [personal|extern]`

Statt Volltext über rohe Zeilen durchsucht `browse` **geparste
Tabellenzeilen**: `records.lua` liest jede Cheatsheet-Datei, findet jede
`|…|…|`-Zeile unter der nächsten `##`/`###`-Überschrift darüber und macht
daraus einen Datensatz —

```lua
{ scope = "Personal"|"Extern",
  category = "Keymaps"|"Usercmds"|"Autocmds",
  plugin,       -- Dateiname ohne Endung, z.B. "images.nvim" oder "Telescope"
  heading,      -- die Überschrift direkt über der Tabelle
  columns,      -- Kopfzeile der Tabelle, Freitext, keine feste Spaltenzahl
  cells,        -- diese Zeile, gleiche Länge wie columns
  file, line }
```

Spaltenzahl/-namen sind bewusst nicht festgeschrieben (siehe
[`docs/NOTES/BINDINGS-FORMAT.md`](../../../../../docs/NOTES/BINDINGS-FORMAT.md)) —
`Keymaps/*.md` hat meist `Key|Mode|Effect|Option`, Extern-Dateien wie
`Telescope.md` bringen mehrere Tabellen unterschiedlicher Form mit. Dateien
ohne saubere Tabelle unter einer Überschrift liefern hier einfach keine
Treffer, bleiben aber über `:Bindings search` weiterhin auffindbar.

Getrennt wird nur an **unescapten** `|`. Ein `\|` ist markdowns
Literal-Pipe-Escape und bleibt Teil der Zelle, im Zellwert zu einem schlichten
`|` aufgelöst — `Keymaps/markdown.nvim.md`s Zelle `` `]\|` / `[\|` `` ist eine
Zelle, keine drei. Bis 2026-08-30 trennte der Scraper auch dort: das gab 74
Zeilen des Korpus mehr Zellen, als ihre Kopfzeile Spalten hat, und verschob
damit jede Spaltenzuordnung dahinter. Sichtbar wurde es erst über den
Drift-Bericht, der das Bruchstück `` `]\ `` als dokumentierten lhs meldete.

`browse.lua`s Picker (`kit.select`, wie Phase 1s Fallback) zeigt jede Zeile
als `[Scope/Plugin] Heading — Spalte1: Wert1  Spalte2: Wert2  ...`; `<CR>`
springt an die Fundstelle in der Quelldatei.

Beispiele:

```vim
:Bindings browse
:Bindings browse keymaps
:Bindings browse keymaps personal
:Bindings browse usercmds extern
```

Gegen den echten Bestand verifiziert (headless, 2026-08-30):
`records.list()` liefert 1940 Datensätze über den ganzen Korpus, davon 561
für `Keymaps personal` allein — und in keinem einzigen weicht die Zellenzahl
von der Spaltenzahl seiner Kopfzeile ab.

## Drift-Bericht (`:Bindings check`)

`:Bindings check [plugin]`

Read-only, kein Autofix (gleiche Haltung wie casedesks `:Cases doctor`) —
vergleicht dokumentierte Personal-Bindings gegen das, was gerade tatsächlich
registriert ist (`vim.api.nvim_get_keymap`/`nvim_get_commands`).
`drift.lua` parst dafür `records.lua`s Tabellenzeilen weiter: die lhs-Zelle
wird über `nvim_replace_termcodes` in die rohe Byte-Form gebracht (dieselbe
Form, die `nvim_get_keymap`s `.lhsraw`-Feld liefert — `<leader>` wird dabei
mit dem tatsächlichen `mapleader` expandiert), Usercmd-Zellen über ein
`:(%u[%w_]*)`-Pattern auf den Basisbefehl reduziert.

Bewusst eingeschränkter Scope (siehe `drift.lua`s Moduldoc für die volle
Begründung):

- **Keymaps: nur eine Richtung** (dokumentiert-aber-nicht-live). Die
  Rückrichtung würde gegen JEDEN globalen Keymap abgleichen (jedes Plugin,
  jeder Vim-Default) und wäre Rauschen ohne Ende.
- **Nur Personal, nicht Extern** — Extern dokumentiert fremde
  Plugin-Defaults, die dieses Config selbst meist nie registriert.
- **Buffer-lokale/filetype-gescopte Keymaps sind ein bekannter
  False-Positive-Fall**: `nvim_get_keymap` sieht nur globale Maps. UI-Plugins
  mit eigenem Buffer (filetree.nvim, github_stats.nvim, pickers.nvim, ...)
  tauchen deshalb systematisch als "missing" auf, obwohl sie korrekt
  registriert sind — manuell verifizieren, nicht blind vertrauen.
- **Noch nicht geladene Plugins werden übersprungen, nicht fälschlich als
  fehlend gemeldet**: `records.lua`s `plugin`-Feld wird gegen
  `require("lazy.core.config").plugins[name]._.loaded` geprüft; ein
  Plugin, das lazy.nvim in dieser Session noch nicht geladen hat, wird
  namentlich als "skipped" aufgeführt statt Falschalarme zu erzeugen.
  Empirisch wichtig: in einer frisch gestarteten Session war das kein
  Randfall — die Mehrheit der Personal-Keymaps-Plugins war noch ungeladen.
- **Usercmds: beide Richtungen**, da `nvim_get_commands({})` nie
  Vim-Defaults enthält (kein Rauschen von dort). Die Rückrichtung
  (live-aber-undokumentiert) zieht zur Rauschreduktion auch Extern-Doku
  heran, zeigt aber weiterhin Infra-/Plugin-Manager-Commands (`:Lazy`,
  `:Mason`, ...) an, für die keine Ignore-Liste gepflegt wird.
- **Ein geladenes Plugin kann ein Command trotzdem erst bei erster
  API-Nutzung registrieren, nicht beim Laden** — enger als der
  Lazy-Plugin-Fall oben, siehe `drift.lua`s Moduldoc Punkt 5. Ein
  einzelner `usercmd-not-live`-Fund für ein als "lazy" dokumentiertes
  Command (z. B. eine "Registered when: ..."-Spalte) ist verdächtig —
  erst das Feature einmal auslösen, dann erneut prüfen.

Gegen den echten, voll geladenen Bestand verifiziert (headless, über einen
`XDG_CONFIG_HOME`-Junction-Trick, der `stdpath("config")` auf diesen
Branch zeigen lässt, ohne `stdpath("data")`/die echten Plugin-Installationen
anzufassen — siehe git-Historie dieser Datei für die Kommandos): fand u.a.
`Usercmds/dap.nvimMERGE.md`s bereits in `BINDINGS-FORMAT.md` §5 als
Merge-Artefakt vermuteten `:Dap` (mittlerweile geprüft: enthielt echten,
nirgends sonst dokumentierten Inhalt zum `languages/<lang>.lua`-Merge und
`auto_install`/`replace = true` — in `dap.nvim.md` nachgezogen, Datei
gelöscht) und ein vermeintlich verwaistes `:LibLogger` in `lib.nvim.md`
(headless nachgestellt: genau der oben neu dokumentierte Fall 5 — die
Cheatsheet-Zeile sagt selbst "Registered when: automatically, on the
first `logger.new()`"; nach einem echten `logger.new({name=...})`-Aufruf
taucht `:LibLogger` sofort in `nvim_get_commands({})` auf — bestätigter
False Positive, kein Bug).

Beispiele:

```vim
:Bindings check
:Bindings check images.nvim
```

### Die vierte Achse: der lokale Checkout (`:Bindings check repo`)

`:Bindings check repo [plugin]` — oder, mit dem Plugin zuerst,
`:Bindings check <plugin> repo`.

Die Einschränkung "noch nicht geladene Plugins werden übersprungen" oben ist
ehrlich, aber leer: übersprungen ist nicht geprüft, und in einer normalen
Session ist das die Mehrheit der Personal-Plugins. Für die gibt es genau eine
Quelle, die keine laufende Session braucht — den lokalen Checkout auf der
Platte. `repo.lua` durchsucht dessen `.lua`/`.vim`-Dateien nach dem
dokumentierten `lhs` bzw. Commandnamen **als String-Literal in Quotes**
(`vim.keymap.set("n", "<leader>iv", ...)`, `composer.verb("Images", ...)`,
`["<leader>iv"] = ...`).

Neue Finding-Arten: `keymap-not-in-repo` / `usercmd-not-in-repo`, mit eigenem
Abschnitt im Bericht.

- **Opt-in, Default aus.** Die drei bestehenden Achsen befragen eine laufende
  Session; diese liest ~30 Repos von der Platte. Gemessen: 940 ms, 2861
  Quelldateien, 28 MiB Zwischenspeicher, der am Ende des Laufs wieder
  freigegeben wird. Kein stiller Kostenfaktor eines Kommandos, das man für
  den üblichen Bericht tippt.
- **Ein Grep, keine API-Abfrage — und im Bericht so gekennzeichnet.** Ein zur
  Laufzeit zusammengesetztes `lhs` (`prefix .. "m"`) ist registriert und
  nicht greppbar. Das ist der bekannte Falschbefund dieser Achse.
- **Case-Regel nach Art des Tokens.** Keymaps case-unabhängig (`<Leader>` und
  `<leader>` sind dieselbe Taste), Commandnamen case-abhängig — sonst trifft
  `:Images` das Wort "images" in jeder zweiten Zeile von images.nvim und die
  Achse meldet nie etwas.
- **Drei Unterdrücker.** Gemeldet wird nur, was in keinem der drei steht: im
  Checkout des Plugins, im `lua/`-Baum dieser Config (der `<leader>`-Einstieg
  eines Personal-Plugins wird sehr oft hier registriert, in einer
  lazy-`keys`-Spec), und in den gerade registrierten Keymaps/Commands.
- **Wer beantwortet wurde, gilt nicht mehr als "skipped".** Ein Plugin ohne
  auflösbaren Checkout, oder eines dessen Checkout keine lesbare Quelle
  enthält, bleibt übersprungen — "nichts gefunden" und "konnte nicht
  nachsehen" bleiben getrennt.
- **Auflösung austauschbar.** `config.repo_dirs()` liefert `{name, dir}` je
  Plugin; Default ist `plugins.personal.export.projects()` (aus dem echten
  Lazy-Spec abgeleitet, nicht aus einer handgepflegten Liste).
  `config.set_repo_dirs(fn)` ersetzt sie — die Tests hängen daran und laufen
  gegen ein Fixture-Repo im Temp-Verzeichnis statt gegen echte
  `C:\repos\*`-Checkouts.
- **Oder ein ganzes Sammelverzeichnis: `root=<dir>`.** `:Bindings check repo
  root=C:/repos` löst nicht über den Lazy-Spec auf, sondern nimmt jedes
  Lua-Projekt direkt unter dem Pfad (`config.repo_dirs_under`) — ein
  Verzeichnis gilt als Projekt, wenn es ein `lua/` oder eine `.lua`-Datei
  obenauf hat, nicht wenn es ein `.git` hat: die Achse liest Quelltext, nicht
  Historie. Nur eine Ebene tief, sonst meldete jeder Checkout sein eigenes
  `lua/` und `tests/` als weitere „Repos". `root=` impliziert `repo`, ist
  positionsunabhängig (`kv`-Argument, `<Tab>` vervollständigt Verzeichnisse)
  und mit einem Plugin-Filter kombinierbar.

  Der Fall, für den das existiert: die Default-Auflösung setzt eine geladene
  `plugins.personal`-Ebene voraus und liefert nur die als Plugin *aktivierten*
  Checkouts. Ein Pfad setzt nichts voraus und deckt alles ab, was dort liegt —
  gemessen an `C:/repos`: 31 Projekte aufgelöst, 30 gegen ihren Checkout
  beantwortet, `skipped` von 38 auf 8. Was dabei zusätzlich abfällt, ist eine
  eigene Berichtszeile wert: **Projekte unter dem Pfad, die dieser Korpus gar
  nicht dokumentiert.** Das ist kein Drift (es gibt keine dokumentierte
  Behauptung, die falsch sein könnte), aber die einzige Aussage, die ein
  Bericht über einen ganzen Pfad machen kann und ein Bericht über eine
  Plugin-Liste strukturell nie.

Erster echter Lauf (headless, alle 30 auflösbaren Plugins künstlich als
ungeladen — der Worst Case, für den die Achse existiert): 30 von 30 Checkouts
beantwortet, 10 Findings. 7 davon sind `debugging.nvim`s zusammengesetzter
`prefix .. "m"` (der dokumentierte Falschbefund), 1 war ein Parser-Artefakt aus
einer Tabellenzelle mit escaptem `\|` — ein vorbestehender Defekt in
`records.lua`s `split_cells`, den dieser Lauf erstmals sichtbar machte und der
seither behoben ist (`472822d8`), womit dieses Finding entfällt —, und 2 echte
Funde:
`cmdlog.nvim`s `ctrl-f`, das in dessen Quelltext nirgends steht, und
`:RATelemetry`, dokumentiert in `Usercmds/lib.nvim.md`, aber registriert in
runtime-analysis.nvim — ein Fund, den die Live-Achse strukturell nie machen
kann, weil das Command ja existiert, nur nicht dort, wo das Cheatsheet es
verortet.

```vim
:Bindings check repo
:Bindings check repo images.nvim
:Bindings check images.nvim repo
:Bindings check repo root=C:/repos
:Bindings check images.nvim root=C:/repos
```

## Bericht als Datei (`:Bindings report`)

`:Bindings report [plugin] [repo] [root=<dir>] [out=<pfad>]`

Derselbe Lauf wie `check`, nur nicht in den Viewer, sondern in eine
Markdown-Datei. Aufbau: Laufkopf (Datum, Neovim-Version, Umfang,
Laufzeit, aufgelöste und beantwortete Checkouts, Übersprungene, Befundzahl),
eine Tabelle der Befunde nach Art, und `drift.describe`s unveränderte Ausgabe
als ```text-Anhang.

**Warum es das gibt.** Der Driftreport vom 2026-09-02
(`docs/ROADMAP/personal/All/BINDINGS-DRIFT-2026-09-02.md`) wurde von Hand aus
einem headless-Lauf zusammengesetzt: `nvim --headless -c "lua ... drift.check"`,
Ausgabe umgeleitet, Kopf und Zahlen davorgetippt. Genau diese Handarbeit macht
`report.lua`.

**Was es nicht macht: bewerten.** Welcher Befund eine echte Doku-Lücke ist und
welcher ein Werkzeugfehler oder ein erwartbarer Effekt (buffer-lokale UI nicht
offen, lazy nicht ausgelöst), entscheidet die Durchsicht — und diese
Einschätzung ist der Teil, für den ein handgeschriebener Bericht sich lohnt.
Erzeugt wird die gemessene Hälfte, damit nur noch die andere zu schreiben ist.
Der Satz, der das im Bericht sagt, steht in jedem Lauf drin, nicht nur im
handgeschriebenen.

**Der Anhang ist ein ```text-Block, keine Markdown-Tabellen.**
`drift.describe` richtet seine Spalten mit `%-22s` aus, und diese Ausrichtung
ist die einzige Struktur, die der rohe Bericht hat. In Tabellen umgesetzt wäre
er länger und schlechter lesbar.

**Zielpfad.** Ohne `out=` schreibt der Bericht nach
`config.report_dir()`/`BINDINGS-DRIFT-<datum>.md`, also in den
Roadmap-Ordner, in dem der Bericht vom 2026-09-02 schon liegt. `out=` nimmt
ein Verzeichnis (dann derselbe Datumsname darin) oder einen Dateinamen (dann
der, mit `.md` ergänzt, falls die Endung fehlt). Typisiert als `PATH`, nicht
`FILE`: `FILE` verlangt eine *lesbare* Datei, und eine Ausgabedatei gibt es
vor dem Lauf per Definition noch nicht.

```vim
:Bindings report
:Bindings report repo
:Bindings report repo out=C:/tmp
:Bindings report images.nvim out=C:/tmp/images.md
```

## Dashboard (`:Bindings status`)

Eine Seite, nach dem Vorbild von `:Reposcope status`:

- **Korpus** — Dateien und Tabellenzeilen je Wurzel und Kategorie, die Summe,
  und wie viele Zeilen aus Korpus-Dateien stammen (`All`/`Collisions`/
  `Overview`, siehe unten) statt aus einem Plugin-Cheatsheet.
- **Live in dieser Session** — globale Keymaps mit Aufteilung nach Modus,
  buffer-lokale Keymaps über die offenen Buffer, Usercmds, Autocmds mit
  Gruppenzahl.
- **Plugins** — wie viele lazy.nvim kennt, wie viele geladen sind, und wie
  viele Checkouts die Repo-Achse auflöst (oder warum keine).
- **Letzter geschriebener Driftbericht** — der jüngste `BINDINGS-DRIFT-*.md`
  in `config.report_dir()`, nach Namen sortiert: der Name trägt das Datum,
  über das der Bericht spricht, und eine später angefasste Datei beschreibt
  immer noch ihren eigenen Tag.
- **Routen** — die Liste aller Subcommands. Der Verb-Baum ist über das
  hinausgewachsen, was die `desc`-Strings in der Completion zeigen; das hier
  ist der `?`-Cheatsheet dazu.

**Läuft keinen Driftcheck.** Der kostet ~650 ms über vier Achsen und erzeugt
einen Bericht — dafür sind `check` und `report` da. Hier ist alles entweder
ein billiger Live-API-Aufruf oder ein Durchgang über den Korpus (~70 ms). Ein
Dashboard, auf das man wartet, öffnet man einmal.

## Was der Scraper nicht mehr falsch liest (2026-09-02)

Der Driftreport vom 2026-09-02 hat aufgeschrieben, welche seiner Befunde
Werkzeugfehler waren. Vier davon sind behoben; gemessen am selben Lauf: 331
Befunde vorher, 262 nachher, kein einziger echter darunter.

| Fix | Wo | Weg |
| --- | --- | ---: |
| Platzhalter in der Key-Spalte (`—`, `*(unset)*`, `*(your lhs)*`) sind keine Taste | `drift.is_placeholder_key` | 3 |
| Korpus-Dateien (`All.md`, `Collisions.md`, `Overview.md`) sind keine Cheatsheets | `records.META_FILES` | 17 |
| `:Name` direkt hinter einem Wortzeichen ist Prosa, kein Command (`path:L1-L2` → `:L1`) | `records.command_names` | 1 |
| Ein im Fließtext dokumentierter Command gilt als dokumentiert | `records.mentions` | 48 |

**Korpus-Dateien werden markiert, nicht verworfen** (`Bindings.Record.meta`).
`browse`/`search` wollen ihre Zeilen, und die Gegenrichtung des Driftchecks
auch: ein in `Overview.md` genannter Command *ist* dokumentiert, er wird dort
nur nicht registriert. Nur die Richtung „dokumentiert, aber nicht live"
überspringt sie — `Collisions.md`s ganzer Punkt ist ja, dass seine Tasten
*doppelt* vergeben sind, was das Gegenteil von fehlend ist.

**Prosa zählt nur in eine Richtung.** Für „live, aber nirgends dokumentiert"
reicht eine Erwähnung, denn die Frage lautet allein, ob der Korpus den Command
überhaupt kennt. Für die Gegenrichtung reicht sie nicht: eine Erwähnung trägt
weder Taste noch Modus noch Fundstelle, gegen die sich etwas prüfen ließe.
