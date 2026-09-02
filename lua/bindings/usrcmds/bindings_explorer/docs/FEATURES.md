# bindings-explorer — Features

`:Bindings` — Picker über die eigenen BINDINGS-Cheatsheets
(`docs/NOTES/PersonelPlugins/BINDINGS/` + `docs/NOTES/ExternPlugins/Bindings/`,
160 Dateien, drei Kategorien: Keymaps/Usercmds/Autocmds).
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

**Zahlen kommen aus [MEASURING.md](./MEASURING.md)**, nicht von hier: dort
stehen die gemessenen Stände mit Datum, die sechs Fallen, die eine
headless-Messung still falsch machen, und die drei Klassen von Befund, die
korrekt gemeldet werden und trotzdem kein Problem sind. Wer eine Zahl aus
dieser Datei nachprüfen will, liest zuerst dort die Vorkehrungen.

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

Gegen den echten Bestand verifiziert. Am 2026-08-30 lieferte
`records.list()` 1940 Datensätze über den ganzen Korpus, davon 561 für
`Keymaps personal`, und in keinem einzigen wich die Zellenzahl von der
Spaltenzahl seiner Kopfzeile ab.

Nachgemessen am **2026-09-02**: **2333** Datensätze (Keymaps 1230, Usercmds
811, Autocmds 292), davon 678 für `Keymaps personal`. Der Korpus ist seither
also um gut ein Fünftel gewachsen.

**Und die Null stimmt nicht mehr: neun Zeilen weichen ab**, alle im
Personal-Korpus — acht in `Usercmds/documentation.nvim.md` (Z. 99–106) und
eine in `Usercmds/lib.nvim.md` (Z. 15). Alle neun haben eine dreispaltige
Kopfzeile und nur zwei Zellen: die dritte Spalte (bei `:DocMap` die
„schreibt?"-Spalte) fehlt schlicht. Für die Prüfung ist das folgenlos — die
Achsen greifen über den Header-Index auf die Command-Spalte zu, und die ist
vorhanden —, aber die Behauptung „keine einzige" darf nicht stehenbleiben.
Was in die fehlende Spalte gehört, sagt nur die jeweilige Quelle; geraten
wird hier nichts.

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
- **Buffer-lokale/filetype-gescopte Keymaps waren der dominante
  False-Positive-Fall** — `nvim_get_keymap` sieht nur globale Maps, UI-Plugins
  mit eigenem Buffer (filetree.nvim, github_stats.nvim, pickers.nvim, ...)
  tauchten deshalb systematisch als "missing" auf. Drei Dinge adressieren das,
  keines davon durch Wegwerfen von Befunden: `live_keymaps` liest auch
  `nvim_buf_get_keymap` jedes offenen Buffers, der Quelltext-Fallback (unten)
  greift die Taste im Plugin selbst ab, und was danach übrig bleibt, bekommt
  das Pro-Tabellen-Verdikt „not verifiable from here" statt N Einzelbefunde.
  Gemessen ist von 52 solchen Meldungen genau eine übrig.
- **Noch nicht geladene Plugins werden übersprungen, nicht fälschlich als
  fehlend gemeldet**: `records.lua`s `plugin`-Feld wird über `stem_plugin`
  (siehe „Wie ein Cheatsheet-Stamm zu seinem Plugin findet") auf den
  lazy.nvim-Namen aufgelöst und dessen `._.loaded` geprüft; ein Plugin, das
  lazy.nvim in dieser Session noch nicht geladen hat, wird namentlich als
  "skipped" aufgeführt statt Falschalarme zu erzeugen. Empirisch wichtig: in
  einer frisch gestarteten Session war das kein Randfall — die Mehrheit der
  Personal-Keymaps-Plugins war noch ungeladen, und seit der Auflösung gilt
  dasselbe für 17 der 24 Extern-Stämme. Der Bericht nennt deshalb neben der
  übersprungenen Plugin-Liste auch, **wie viele dokumentierte Zeilen** an ihr
  hängen.
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
`Usercmds/dap.nvimMERGE.md`s bereits in `BINDINGS-FORMAT.md` §7 (dem
Retrofit-Abschnitt) als
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

### Der Quelltext-Fallback (immer an, seit 2026-09-02)

Die vierte Achse oben beantwortet Plugins, die **nie geladen** wurden. Der
Fallback beantwortet eine andere Frage für die, die **geladen sind**: findet
die Live-Achse eine dokumentierte Taste nicht, wird sie im Quelltext gesucht,
bevor daraus ein `keymap-not-live` wird. Dasselbe Werkzeug (`repo.mentions`),
dieselben zwei Bäume, umgekehrter Default — und der Grund für den umgekehrten
Default ist die Messung:

| Route | `keymap-not-live` vorher | nachher | im Quelltext bestätigt |
| --- | ---: | ---: | ---: |
| `:Bindings check` | 52 | **1** | 51 |
| `:Bindings check extern` | 309 | **84** | 225 |

Der eine Übriggebliebene ist `cmdlog.nvim`s `ctrl-f`: fzf-lua-Notation in
einem Korpus, der sonst Vim-Notation schreibt. **Ein Befund aus 52.** Ein
Abschnitt, der zu 98 % Rauschen ist, wird nicht gelesen; die Achse, die das
Rauschen entfernt, kostet einen Grep.

- **Warum nicht einfach die buffer-lokalen Tasten ausgliedern?** Weil
  `keymap-not-live` kein Kollisionscheck ist: dort wird nie buffer-lokal gegen
  global verglichen, die Achse fragt nur „das Cheatsheet dokumentiert diese
  Taste — gibt es sie?". Eine ganze Klasse von dieser Frage auszunehmen hieße,
  dass eine buffer-lokale Taste, die ihr Plugin inzwischen umbenannt oder
  entfernt hat, nie wieder auffiele — still. Der Fallback behält die Frage und
  beantwortet sie besser.
- **`extern` profitiert aus einem anderen Grund.** Ein fremder
  Cheatsheet-Stamm hat keinen lokalen Checkout; der Baum, der dort antwortet,
  ist der `lua/`-Baum dieser Config — genau die Stelle, an der diese Tasten
  gebunden werden (lazy-`keys`-Spec). Deshalb sagt die Abschnittsnotiz „any
  source that could be read" und nicht „im Quelltext des Plugins".
- **Kosten, gemessen.** `check` läuft ~150 ms ohne, ~550 ms mit Fallback. Ein
  Checkout wird erst indiziert, wenn eine Taste dieses Plugins tatsächlich
  gefehlt hat — in einem Default-Lauf eine Handvoll, nicht alle 32. Die
  Entscheidung dafür ist mit dieser Zahl vor Augen gefallen.
- **Der bekannte Preis: ein Grep unterdrückt gelegentlich auch zu Recht
  Gemeldetes.** `cmdlog.nvim`s `ctrl-t` steht in keiner Zeile von cmdlog.nvim
  — wohl aber in `lua/config/fzf/init.lua` dieser Config, wo dasselbe Literal
  eine völlig andere Aktion bindet. Das genügt, der Fund entfällt. Dieselbe
  Haltung wie in `repo.lua`s Moduldoc: ein verpasster Fund ist billiger als
  ein falscher.
- **Die Zahl steht im Bericht.** Laufkopf-Zeile „Quelltext-Fallback" und ein
  eigener Abschnitt „Confirmed by source instead of by the session (n)" —
  sonst verschwinden zwischen zwei Läufen desselben Kommandos 51 Befunde, und
  das ist die Form eines Bugs, nicht die einer Verbesserung.
- **Zwei getrennte Schalter, absichtlich.** `repo` indiziert den Checkout
  jedes ungeladenen Plugins, zweiunddreißig Bäume, ob mit ihnen etwas nicht
  stimmt oder nicht. Der Fallback fasst einen Checkout erst an, nachdem eine
  Taste gefehlt hat. Deshalb ist das eine opt-in und das andere nicht.

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
| Ein Commandname direkt hinter einem Wortzeichen ist Prosa (`path:L1-L2` wurde als fehlendes Kommando gemeldet) | `records.command_names` | 1 |
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

## Wer hat dieses Command registriert (2026-09-02)

Der Abschnitt „Live commands with no cheatsheet, by origin" trug für 88 seiner
166 Zeilen die Herkunft *„via lib.nvim usercmd helpers — owner not recorded"*,
darunter eine Note, die sich für Fremdinfrastruktur entschuldigte. Beides war
falsch: es waren fast ausschließlich eigene Commands.

**Die Ursache war nicht, dass die Information fehlte.** lib.nvims Registry
hält den Aufrufort seit jeher fest (`Lib.UserCommand.Record.src`). Zwei
Stellen haben ihn nur nie erreicht:

* `drift.lua` hat die Registry nie gefragt, sondern
  `debug.getinfo(def.callback)` gelesen — und das ist die pcall-Hülle, die
  `usercmd.create` um jeden Callback legt. Sie ist in lib.nvim definiert, also
  meldete *jedes* über die Helfer angelegte Command lib.nvim als Quelle.
* `composer.verb` hat `create`s `src`-Option nie durchgereicht, obwohl deren
  Doku genau diesen Fall beschreibt („a wrapper creating a command on a
  caller's behalf"). Alle zwölf Verben einer Session lagen damit auf einer
  Zeile von `composer/init.lua` (behoben in lib.nvim `bfa09e5`).

`command_owner` fragt jetzt vier Quellen, absteigend nach Direktheit: lazys
`cmd`-Spec für Lazy-Stubs, **lib.nvims Registry**, `debug.getinfo` für
Plugins, die selbst registrieren, und die `script_id` für Vimscript.
`owner_of_path` macht aus einem Pfad einen Eigentümer — Lazy-Install,
Checkout unter `<laufwerk>:/repos/`, dieser Config-Baum (`nvim-config`) oder
Neovims Runtime — und hängt die Fundstelle innerhalb dessen an.

### Die vierte Quelle druckte eine Zahl, die zwischen zwei Läufen wechselte

Sie tat es zunächst wörtlich: `vimscript script_id=%d`. Die `script_id` ist
aber sitzungsabhängig, und drei aufgezeichnete Läufe derselben Config
widersprechen sich vollständig — `:StartupTime` stand auf `10`, dann `9`,
dann `25`, `:TodoLocList` auf `13`, dann `25`, dann `12`. **11 der 54
undokumentierten Commands** trugen ein Label, das nichts identifiziert und
beim nächsten Aufruf anders lautet.

`vim.fn.getscriptinfo({ sid = N })` gibt den Pfad zurück, und der ist genau
die Form, die `owner_of_path` für Lua-Quellen ohnehin schon einordnet. Alle
elf tragen seither einen Namen:

| Vorher | Jetzt |
| --- | --- |
| `vimscript script_id=19` | `todo-comments.nvim` (2×) |
| `vimscript script_id=12`/`13` | `vim-matchup` (4×) |
| `vimscript script_id=10` | `vim-matchup` — `:DoMatchParen`/`:NoMatchParen`, das Plugin ersetzt Neovims eigenes `matchparen` |
| `vimscript script_id=17` | `plenary.nvim` (2×) |
| `vimscript script_id=25` | `vim-startuptime` |

Die Befundzahlen bewegt das nicht (9 / 158 / 167 vor und nach der Änderung),
und das ist das erwartete Ergebnis: alle elf gehören Fremdplugins und bleiben
damit im selben Scope. Bewegt hat sich, was in der Spalte steht — und
`owner_plugin` kann die Zeilen jetzt überhaupt erst einordnen, statt sie
pauschal als „third-party by construction" abzuweisen. Die alte Form bleibt
als letzter Rückfall bestehen, für den Fall, dass `getscriptinfo` die id nicht
auflösen kann; sie bedeutet dann „Vimscript, Herkunft ungeklärt" und nicht
mehr eine Herkunft.

Zwei der elf haben damit ein Cheatsheet-Ziel, das es gibt: `:TodoFzfLua` und
`:TodoLocList` gehören zu `todo-comments.nvim`, und `TodoComments` ist einer
der Stämme des Extern-Korpus.

Gemessen an einem echten Lauf: **0 unbekannte Eigentümer**, 53 der 109
Befunde sind eigene mit `file:line`, 56 sind fremde. Die Note unter der
Überschrift sagt jetzt, wie die Spalte zu lesen ist, statt zu raten, was in
ihr steht.

**Der Nebeneffekt, der die Doku-Arbeit lenkt:** die 23 von pickers.nvim
erzeugten Scope-Commands (`:NotesFiles`, `:WkdbooksGrep`, …) landen alle auf
*derselben* Generatorzeile (`lua/pickers/bindings/util.lua:33`) und stehen im
Bericht damit als ein Block untereinander. Genau die Aussage, die der
Driftreport von Hand getroffen hat: hier ist der Generator zu dokumentieren,
nicht seine 23 Ergebnisse.

## Der Quelltext-Fallback gilt jetzt auch für Commands (2026-09-02)

Eine dokumentierte Taste, die der Live-Test nicht findet, wird seit jeher
erst im Quelltext gesucht, bevor sie ein Befund wird — zwei Bäume, der des
Plugins und der `lua/`-Baum dieser Config. Ein dokumentiertes **Command**
wurde das nie. Das war eine Auslassung, keine Entscheidung.

Ein Unterschied ist nötig, und er ist derselbe, den die opt-in-Repo-Achse
schon macht: **case-sensitiv**. Die Keymap-Seite faltet Groß- und
Kleinschreibung, weil der Korpus `<Leader>` schreibt, wo die Quelle
`<leader>` schreibt. Ein Commandname hat diese Varianz nicht — dafür trifft
`:Images` case-insensitiv das Wort „images" in jeder zweiten Zeile von
images.nvims eigener Quelle, und jedes Command würde als aufgeschrieben
gelten.

Was er strukturell nicht sehen kann: `repo.mentions` findet nur
Quoted-Literals, und ein Vimscript-`com! -bang UnicodeDownload …` ist
unquoted. `:UnicodeDownload` und `:DigraphNew` bleiben also gemeldet, egal
wie geladen ihr Plugin ist. Das ist eine Grenze, die man benennt, keine
Lücke, die man schließt.

**Gemessen:** `usercmd-not-live` fällt in allen drei Scopes auf **0** (8/46/54
→ 7/45/52). Die zwei betroffenen Zeilen sind beide bestätigte Nicht-Befunde:
`:MasonInstallAll` steht in der lokalen `nvchad/au.lua`-Kopie dieser Config,
`:LibLogger` in lib.nvims `logger/command.lua` — beide registrieren lazy.

Eine ältere Notiz in MEASURING.md behauptete, `LibLogger` stehe in lib.nvim
nirgends als Quoted-Literal, der Fallback würde diesen Befund also stehen
lassen. Das war falsch gemessen; die Korrektur steht dort.

## Eine Tabelle, die gar nichts über diese Session sagt (2026-09-02)

Die Keymap-Achse fragt: ist diese dokumentierte Taste jetzt registriert? Drei
Sorten Tabelle im Korpus beantworten diese Frage nicht — ein abgeschalteter
Plugin-Default, eine Taste im LazyGit-TUI, eine Verweistabelle auf andere
Blätter. Sie melden sich trotzdem, weil der Scraper ihre Key-Spalte findet.

Sie können es jetzt sagen: eine Zeile `**Nicht live:**` direkt unter der
Überschrift markiert alle Tabellen dieses Abschnitts als unprüfbar
(`records.lua`s `NOT_LIVE_MARKER`, Format in
[`BINDINGS-FORMAT.md`](../../../../../docs/NOTES/BINDINGS-FORMAT.md) §6).
Nur die Live-Richtung ehrt ihn; die Zeilen bleiben in `browse` und zählen als
Dokumentation — dieselbe Trennung wie bei `META_FILES`.

**Warum ein Marker und keine Header-Umbenennung.** `normalize_header` wirft
eine Klammer-Gruppe absichtlich weg, damit `Default-Mapping (Plugin)` und
`Taste (in LazyGit)` als lhs-Spalte erkannt werden — der Korpus schreibt
diese Spalte in einem Dutzend Varianten, und die Toleranz ist der Grund, warum
der Scraper überhaupt funktioniert. Einen Header umzubenennen, damit der
Parser wegschaut, wäre eine versteckte Kopplung zwischen Prosa und
Parser-Interna.

**Gemessen** (alle Extern-Plugins geladen): `keymap-not-live` 16 → **10**.
Die fünf markierten Zeilen sind drei abgeschaltete VisualMulti-Defaults, eine
LazyGit-TUI-Taste und ein Verweis auf ein Astro-Keymap; die sechste war ein
echter Notationsfehler (siehe unten). Der Bericht druckt die Zahl der
markierten Zeilen mit, damit ein Opt-out nicht unsichtbar wird — aktuell 16.

### Der sechste war kein Opt-out, sondern ein Fehler

`Keymaps/Fugitive.md` dokumentierte `["x]y<C-G>`. Das ist keine Taste, sondern
`fugitive.txt`s Schreibweise für „optionales Register, dann `y<C-G>`". Live
geprüft: die Map heißt `y<C-G>` (Normal-Modus,
`setreg(v:register, fugitive#Object(@%))`), und das Register-Präfix wirkt wie
überall in Vim. Korrigiert; die Zeile ist seither live und ein Befund weniger.

## Wie ein Cheatsheet-Stamm zu seinem Plugin findet (2026-09-02)

Zwei Fragen des Prüfers hängen daran, und beide wurden für den ganzen
Extern-Korpus falsch beantwortet: **ist dieses Plugin geladen** (sonst ist
eine fehlende Registrierung keine Aussage) und **wo liegt sein Quelltext**
(für den Fallback und die Repo-Achse).

Beide fragten `lazy_config.plugins[stamm]`, und **kein einziger der 24
Extern-Stämme ist so geschrieben, wie lazy.nvim seine Tabelle schlüsselt**:

```
Diffview -> diffview.nvim      Fugitive  -> vim-fugitive
Telescope -> telescope.nvim    NeoTree   -> neo-tree.nvim
VisualMulti -> vim-visual-multi
```

Jeder Lookup ging daneben, und ein danebengegangener Lookup hieß „kein
Plugin, also immer geladen". `skipped` stand im Extern-Scope folglich auf
**0**, und jede dokumentierte Zeile wurde gegen eine Session geprüft, die
ihr Plugin womöglich nie geladen hatte.

### Drei Schritte, keiner davon rät

1. **Die `**Repo:**`-Zeile des Blattes**, wenn es eine hat. Sie gewinnt immer.
2. **Der Stamm wörtlich**, für ein Blatt, das schon nach seinem Repo heißt.
3. **Der eindeutige normalisierte Treffer**: klein, ohne die
   `nvim`/`vim`-Affixe und ohne `-`, `_`, `.`. `NeoTree` und `neo-tree.nvim`
   werden beide zu `neotree`.

Mehrdeutigkeit wird **verworfen, nicht aufgelöst**: `dap.nvim` und `nvim-dap`
normalisieren beide auf `dap`, und eine Münze zu werfen und das Ergebnis als
Tatsache zu drucken ist schlimmer als nichts zu sagen. Solche Blätter sagen
es selbst (Schritt 1).

**Kein Teilstring-Rückfall.** Der naheliegende „längster passender
Teilstring" liegt über dem echten Korpus zweimal daneben, und zwar still:
`Telescope` → `telescope-file-browser.nvim`, `NeoTree` →
`neo-tree-tests-source.nvim`. Der kürzeste Treffer verschiebt nur, welche
Paare er falsch macht. Gemessen lösen die drei Schritte 21 der 24 Stämme
allein auf; die verbleibenden drei — `Blink` → `blink.cmp`, `Dap` →
`dap.nvim`, `NvChadUI` → `ui` — tragen ihre `**Repo:**`-Zeile. Damit kauft
das Raten nichts und kostet Korrektheit.

### Was die Auflösung an den Zahlen getan hat

| | vorher | nachher |
| --- | ---: | ---: |
| `keymap-not-live` (extern) | 84 | **0** |
| `usercmd-not-live` (all) | 31 | **2** |
| `autocmd-not-live` (all) | 12 | 11 |
| übersprungene Stämme (extern) | 0 | **17** |

**Das ist kein sauberer Korpus, sondern eine ehrliche Messung.** Die 84
verschwundenen Keymap-Befunde sind nicht geprüft und für gut befunden worden
— sie gehören zu Plugins, die diese Session nie geladen hat, und über die
kann der Live-Zustand nichts sagen. Deshalb druckt der Bericht jetzt eine
zweite Zahl unter der übersprungenen Liste: **wie viele dokumentierte Zeilen**
an ihr hängen (extern 541, insgesamt 1377). Ohne sie liest sich „54 Befunde"
wie ein Urteil über den Korpus statt wie eine Tatsache über die Session.

Der eine `autocmd-not-live` weniger ist ein Personal-Blatt: `buffer-ctx`
heißt so, sein Repo `buffer-ctx.nvim`. Auch der Personal-Korpus hatte also
Stämme, die nicht trafen — nur weniger auffällig.

### Wo die 84 wirklich landen

Auf der opt-in-Achse, die sie jetzt zum ersten Mal prüfen *kann*:
`:Bindings check repo extern` findet die Checkouts der 17 übersprungenen
Stämme und meldet **18 `keymap-not-in-repo`** statt 84 (1146 ms). Davon sind
13 die bekannten Notationsdifferenzen — Telescope schreibt `<A-c>`, die
Quelle `<M-c>`; VisualMulti trägt den Leader `\\` im Key —, plus
`["x]y<C-G>`, das keine Taste ist, sondern eine Register-Notation. Übrig
bleiben eine Handvoll echter Kandidaten.

Dazu 15 `usercmd-not-in-repo`, von denen 13 ein dokumentierter Falschbefund
sind: noice **generiert** seine Einzelcommands zur Laufzeit, im Quelltext
steht `stats` und nie `NoiceStats`. Dieselbe Klasse wie debugging.nvims
`prefix .. "m"` — der Preis dafür, dass diese Achse ein Grep ist.

## Die Autocmds-Achse (2026-09-02)

`:Bindings check` verglich Keymaps und Usercmds gegen die laufende Session.
Die dritte Kategorie wurde nur *gelesen* — `records.mentions()` holt sich
Commandnamen auch aus `Autocmds/*.md` —, aber keine Autocmd-Zeile wurde je
gegen `nvim_get_autocmds` gehalten. **241 dokumentierte Zeilen in 33 Dateien
standen damit außerhalb jeder Zahl, die dieser Bericht gedruckt hat.**

**Der Anlass war ein Beleg, keine Vermutung.** lsp.nvims `b260fc8` hat zwei
Autocmds auf der Roh-API registriert und damit zwei ausdrückliche Aussagen von
`Autocmds/lsp.nvim.md` falsch gemacht — die Kopfzahl und den Satz „kein
einziger auf der Roh-API". Gefunden hat das ein Mensch, kein Prüfer.

### Zwei Richtungen, und warum die zweite hier geht

**Dokumentiert, nicht registriert** (`autocmd-not-live`): jede Zeile mit einer
Augroup und mindestens einem Event, das Neovim kennt, wird gegen
`nvim_get_autocmds({})` geprüft. Ein Befund pro **Zeile**, nicht pro Event —
die Zeile ist die dokumentierte Behauptung, und ein Handler, der zwei seiner
vier Events verloren hat, ist eine Stelle zum Nachsehen, nicht zwei.

**Registriert, nicht dokumentiert** (`autocmd-undocumented`): hier liefert
`lib.nvim.bindings.autocmd.registered()` die Antwort, und zwar präzise.
Einschränkung 1 des Moduldocs verbietet diese Richtung für Keymaps, weil man
gegen *jeden* globalen Keymap diffen müsste. Die Registry enthält
bauartbedingt nur Registrierungen, die durch die Helfer gelaufen sind —
Neovims eigene und die eines Fremdplugins sind darin unsichtbar. Dieselbe
Eigenschaft, die auf der Usercmd-Seite aus „owner not recorded" eine Datei mit
Zeilennummer gemacht hat.

Ein Detail, das dort nötig war: `Lib.Autocmd.Record.group` trägt nur dann
einen Namen, wenn die Augroup über lib.nvim angelegt wurde. Die Hälfte dieser
Config benutzt `vim.api.nvim_create_augroup` und übergibt eine Zahl, für die
lib.nvim keinen Namen kennt. `nvim_get_autocmds` kennt ihn immer, also schließt
die Autocmd-`id` die Lücke exakt, statt zu raten.

### Die Zählfalle, die umgangen statt gelöst wird

Der Korpus zählt **Aufrufstellen** (`Autocmds/lsp.nvim.md` sagt das
ausdrücklich), `nvim_get_autocmds` zählt **Event-Registrierungen** — ein
Handler auf vier Events erscheint dort viermal. Nichts hier vergleicht Zahlen:
beide Seiten werden zu `(Augroup, Event)`-Paaren flachgeklopft, ein
Vier-Event-Handler liefert auf beiden Seiten vier Paare, und die zwei
Zählweisen begegnen sich nie.

### Was die Achse nicht erreicht, und was sie stattdessen tut

* **Zeilen ohne Augroup-Spalte.** Acht Sheets dokumentieren ihre Autocmds,
  ohne je eine Gruppe in einer eigenen Spalte zu nennen. Ein Event allein ist
  nicht prüfbar — jedes Plugin registriert `BufEnter`. Diese Zeilen werden
  **gezählt und im Bericht genannt**, nicht als Befund gemeldet.
* **Die Prosa-Rückfallebene.** `Autocmds/sessions.nvim.md` nennt seine Augroup
  in einem Satz über der Tabelle („Single augroup `SessionsNvim`") und hat gar
  keine Augroup-Spalte. Für die Undokumentiert-Richtung zählt deshalb auch
  eine Nennung im **eigenen Sheet des Plugins** (`records.sheet_text`) —
  derselbe Grundsatz wie bei `records.mentions` für Commands, und aus
  demselben Grund nur in diese eine Richtung. Auf das eigene Sheet begrenzt,
  weil eine Augroup, die wie ihr Plugin heißt (`pickers.nvim` ist eine), sonst
  irgendwo in 33 Dateien träfe und „dokumentiert" aufhörte, etwas zu bedeuten.
* **Ein Zellentext, der „keine" sagt.** `Autocmds/reposcope.nvim.md` schreibt
  in die Augroup-Spalte „**none** — registered directly via
  `nvim_create_autocmd`, id tracked manually …". `first_token` nahm brav den
  ersten Backtick-Ausdruck dieses Satzes, und die Achse meldete eine fehlende
  Augroup namens `nvim_create_autocmd`. Eine Zelle, die mit einem
  Keine-Wort *beginnt*, beantwortet „welche Augroup" mit „gar keine".
* **Nur diese Session.** Die Registry kennt, was tatsächlich registriert
  wurde. Welche Plugins das waren, hängt am Lazy-Loading — zwei headless-Läufe
  unterschieden sich um vier `ra_telemetry_<plugin>`-Gruppen, weil zwei
  Plugins im einen Lauf nie geladen haben.

### Erster echter Lauf

| Scope | Befunde | davon Autocmds |
| --- | ---: | --- |
| `personal` | 56 | 8 nicht registriert, 47 nicht dokumentiert |
| `extern` | 158 | 4 nicht registriert |
| `all` | 214 | 12 / 47 |

102 dokumentierte Zeilen sind nicht prüfbar, 116 Registrierungen waren
zuzuordnen — beides steht als eigene Zeile unter dem Bericht, damit eine
kleine Befundzahl nicht mit einer gründlichen Prüfung verwechselt wird.

**Der strukturelle Fund des ersten Laufs:** 35 der 47 undokumentierten
Autocmds gehören `nvim-config` selbst, und es gibt **kein**
`Autocmds/nvim-config.md`. Dieselbe Lücke, die die Usercmd-Seite mit den
`:MyOpt*`-Commands hatte — dort existierte das Blatt immerhin. 15 weitere sind
runtime-analysis.nvims `ra_telemetry_<plugin>`-Gruppen, also eine generierte
Familie: derselbe Fall wie pickers.nvims Scope-Commands, und derselbe
Vorschlag — den Generator dokumentieren, nicht seine Ergebnisse.

### Familien, auch für Augroups (2026-09-02)

Nach dem Blatt für nvim-config blieben 16 undokumentierte Autocmds, davon 15
generiert: `ra_telemetry_<plugin>`, eine Augroup je telemetriefähigem Plugin,
aus einer Schleife in runtime-analysis.nvim. Derselbe Fall wie pickers.nvims
23 Scope-Commands — und dieselbe Antwort: der Korpus dokumentiert den
Generator, und der Prüfer akzeptiert, was der Generator macht.

**Die Notation stand schon da.** Für Commands schreibt der Korpus `:*Files`.
Für Augroups schrieb er längst `ra_telemetry_<namespace>`
(`runtime-analysis.nvim.md`) und `LspSignaturePopup_<winid>`
(`lsp.nvim.md`) — ein Platzhalter, der *benennt*, was variiert, und damit die
bessere Dokumentation. `records.wildcard_pattern` versteht beide Formen;
für Augroups ist `<name>` die zu schreibende.

**Zwei Zeichenklassen, nicht eine.** Commandnamen sind
Lua-Bezeichner-förmig, `[%w_]` ist ihr ganzes Alphabet. Augroupnamen sind es
nicht: diese Config betreibt `ra_telemetry_lib.nvim` und
`ra_telemetry_runtime-analysis.nvim`, beide nach einem Plugin benannt, Punkt
und Bindestrich inklusive. Eine gemeinsame Klasse würde entweder diese
verfehlen oder eine Command-Familie über einen `.` greifen lassen, über den
sie nichts zu suchen hat.

**Gebunden wie die Command-Familien:** an eine Tabellenzeile (nie Fließtext)
und an den Eigentümer. `ra_telemetry_<namespace>` aus
`runtime-analysis.nvim.md` deckt die Augroups dieses Plugins ab und die von
niemandem sonst — geprüft über `command_owner`s Antwort, dieselbe
Eigentümerspalte wie überall.

**Nur in die Undokumentiert-Richtung.** Eine Familie trägt keinen konkreten
Namen, gegen den sich Liveness prüfen ließe; `extract_augroup` weist einen
Platzhalter-Token deshalb weiterhin ab, und die Zeile zählt für die
Vorwärtsrichtung als „nicht prüfbar". Dieselbe Asymmetrie wie bei
`records.mentions`, aus demselben Grund.

**Ein Fehler beim Bauen, weil er lehrreich war.** Die Zeichenklassen gehen
durch `gsub`s *Ersatz*-Argument, in dem `%` ein Escape ist. Als sie aus dem
Inline-Code in eine benannte Tabelle wanderten, verloren sie ihre doppelten
Prozentzeichen — und der Schaden war lautlos auf die schlechteste Art: nicht
ein Fehler, sondern **18 Befunde, die zwei Tage lang korrekt unterdrückt
waren, kamen zurück**. Gemessen aufgefallen, nicht gelesen.

### Stand nach den Familien

| Scope | vor dem Blatt | nach dem Blatt | nach den Familien |
| --- | ---: | ---: | ---: |
| `personal` | 56 | 25 | **9** |
| `all` | 214 | 183 | **167** |

`autocmd-undocumented` steht damit auf **0**. Übrig bleiben 8
`autocmd-not-live` (feature-gated oder lazy, siehe oben) und `:LibLogger`.

> Zeitpunkt-Stand. Danach haben die Stamm-Auflösung und der
> Usercmd-Fallback ihn weiterbewegt — aktuell **7 / 45 / 52**, `:LibLogger`
> ist weg. Die Reihe steht in MEASURING.md, „Gemessene Stände".

Zwei echte Funde hat der Weg dorthin noch abgeworfen, beide von der Achse
gefunden und beide nachgetragen: runtime-analysis.nvims
`runtime_analysis_telemetry_extra` stand in keinem Blatt (das Sheet kannte nur
`…_lazyload`), und lib.nvims `LibNvimUsrCmdsHelptags` ebenso wenig.
