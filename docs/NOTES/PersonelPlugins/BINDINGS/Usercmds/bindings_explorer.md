# bindings-explorer — `:Bindings [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.bindings.usercmd.composer`, wie `:Case`/`:Image`. Bare
`:Bindings` ohne Subcommand ist gleichbedeutend mit `:Bindings search`.

Source: `lua/bindings/usrcmds/bindings_explorer/`
Docs: `lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md`, `:help bindings_explorer`

| Command | Effect |
| --- | --- |
| `:Bindings` | Wie `:Bindings search` |
| `:Bindings search [query]` | Live-Grep über beide BINDINGS-Bäume (Picker-Engine via `pickers.nvim`, sonst Prompt+Liste) |
| `:Bindings search keymaps\|usercmds\|autocmds [query]` | Dieselbe Suche, auf eine Unterkategorie gescopt |
| `:Bindings browse [scope]` | Picker über geparste Tabellenzeilen (alle drei Kategorien) statt Volltext |
| `:Bindings browse keymaps\|usercmds\|autocmds [scope]` | Dieselbe Tabellenzeilen-Suche, auf eine Kategorie gescopt |
| `:Bindings path [personal\|extern]` | BINDINGS-Wurzel(n) in die Zwischenablage kopieren |
| `:Bindings check [plugin]` | Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only) |
| `:Bindings check repo [plugin]` | Derselbe Bericht plus Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum |
| `:Bindings check <plugin> repo` | Dieselbe Achse, Plugin zuerst — identisch zur Zeile darüber |
| `:Bindings check repo root=<dir>` | Dieselbe Achse, aber jedes Lua-Projekt unter `<dir>` statt der Lazy-Spec-Auflösung; `root=` impliziert `repo` |
| `:Bindings check <plugin> root=<dir>` | Dieselbe Pfad-Auflösung, auf ein Plugin gescopt; `root=` ist positionsunabhängig |

`scope` bei `browse` ist `personal`/`extern` (optional, ohne Argument beide).

## Notes

- **Kein `## which-key`**: `bindings_explorer` registriert keine Keymaps —
  bewusst usercommand-only, wie `:Case`/`:Image` auch für ihre
  Argument-tragenden Subcommands entscheiden. Es gibt daher auch keine
  `Keymaps/bindings_explorer.md` in diesem Ordner.
- **`search` vs. `browse`**: `search` durchsucht rohen Zeilentext (findet
  auch Prosa/Notes-Abschnitte), `browse` durchsucht nur geparste
  Tabellenzeilen (strukturierter, aber blind für alles außerhalb einer
  Tabelle). Siehe `docs/FEATURES.md` für die volle Begründung.
- **`check` ist bewusst eingeschränkt** (nur Personal, nur eine Richtung
  bei Keymaps, buffer-lokale/filetype-gescopte Keymaps sind ein bekannter
  False-Positive-Fall, noch nicht geladene Plugins werden übersprungen und
  namentlich gemeldet statt fälschlich als fehlend) — volle Begründung in
  `drift.lua`s Moduldoc, nicht hier dupliziert.
- **`check repo` ist opt-in, nicht Default.** Die drei bestehenden Achsen
  befragen eine laufende Session und kosten nichts Nennenswertes; die
  Checkout-Achse liest ~30 Repos von der Platte (gemessen: 940 ms, 2861
  Quelldateien, 28 MiB, die danach sofort wieder freigegeben werden). Das
  soll kein stiller Kostenfaktor eines Kommandos sein, das man für den
  üblichen Bericht tippt.
- **`:Bindings path` ergänzt, ersetzt nicht** das ältere `:BindingsPath`
  (`lua/bindings/usrcmds/init.lua`) — letzteres bleibt unverändert
  bestehen, zeigt aber weiterhin auf den nie existierenden Pfad
  `docs/NOTES/BINDINGS` statt der beiden echten Wurzeln.

## Changelog

- 2026-08-07: `:Bindings search`/`path` (Phase 1) implementiert.
- 2026-08-07 (2): Live-Grep-in-Picker (`pickers.nvim`-Engine-Schicht) statt
  reinem Prompt+Liste-Fluss, Kategorie-Scoping für `search` ergänzt.
- 2026-08-09: `:Bindings browse` (Phase 2, Tabellenzeilen-Picker) und
  `:Bindings check` (Phase 3, Drift-Bericht) ergänzt. Der ursprüngliche
  Konzept-Entwurf (`docs/ROADMAP/personal/bindings-explorer.nvim.md`) beim
  Aufräumen der Roadmap gelöscht — Feature war zu diesem Zeitpunkt
  vollständig umgesetzt, `docs/FEATURES.md` (im Modul selbst) ist seither
  die aktuelle Doku. Dieses Cheatsheet nachgezogen — fehlte bisher
  komplett, obwohl der Command längst existierte (dasselbe Muster, das
  `:Bindings check` selbst aufdecken soll).

## `:Bindings check` — die dritte Achse: Source (2026-08-15)

`drift.lua` verglich bisher zwei Achsen: **dokumentiert** (die BINDINGS-
Cheatsheets über `records.lua`) gegen **live** (`nvim_get_keymap`/
`nvim_get_commands`). Neu ist **Source** — was dieser Config-Quelltext
tatsächlich registriert, extrahiert von documentation.nvims
`core/bindings.lua` und aus `docs/map/module_map.json` gelesen
(`source.lua`).

**Warum das genau die fehlende Richtung möglich macht.** Die eigene
Einschränkung 1 in `drift.lua` sagt, „live aber undokumentiert" sei nicht
gebaut worden, weil man dafür gegen *jeden* globalen Keymap diffen müsste —
vims Defaults, matchit, jedes Plugin — und der Report damit geflutet wäre.
Dieser Einwand betrifft ausschließlich die **live**-Achse. Die Source-Achse
enthält bauartbedingt nur Registrierungen aus **diesem Repository**, also
exakt die Menge, die die Personal-Cheatsheets abdecken sollen. „Im Source,
nicht in den Docs" ist damit eine saubere, begrenzte Frage, die „live, nicht
in den Docs" nie sein konnte.

Neue Finding-Arten: `keymap-undocumented`, `usercmd-undocumented-source`.
Erster echter Lauf: **194 Findings** (150 Keymaps, 44 Usercmds), jeweils mit
`file:line`.

**Nur eine Richtung.** „Dokumentiert, aber nicht im Source" wird bewusst
*nicht* gemeldet: ein dokumentiertes Binding lebt legitim im Repo eines
Plugins statt hier, und der Fall „dokumentiert, aber wirklich weg" ist
bereits von `keymap-not-live` abgedeckt.

**Liest das Artefakt, scannt nicht.** `module_map.json` ist bereits generiert
und committed, und documentation.nvims Artefakte sind ausdrücklich kalt
lesbar. Ein Scan hier würde ~500 Dateien neu parsen, um Daten herzuleiten,
die auf der Platte liegen.

**Der Preis davon, ausgesprochen statt versteckt:** das Artefakt ist nur so
frisch wie das letzte `:DocMap`. Ein seither hinzugefügtes Binding fehlt in
dieser Achse. Deshalb meldet `source.lua` ein veraltetes oder fehlendes
Artefakt als *Grund* (dritter Rückgabewert von `drift.check`, gerendert von
`describe`) — nie als „keine Bindings gefunden". Die beiden Aussagen sind
verschieden, und ein Report, dem still eine ganze Achse fehlt, liest sich
sonst genau wie einer, in dem diese Achse nichts gefunden hat.

Damit das funktioniert, musste documentation.nvim `bindings` **immer** in
`module_map.json` schreiben (Commit `96eeacf` dort) — ein weggelassenes Feld
und „registriert nichts" wären sonst ununterscheidbar.

## `:Bindings check` — die vierte Achse: Repo (2026-08-30)

`:Bindings check repo [plugin]` (oder `:Bindings check <plugin> repo`).

**Die Lücke, die sie schließt.** `drift.lua`s Einschränkung 4 prüft ein
dokumentiertes Binding nur, wenn lazy.nvim das zugehörige Plugin in *dieser*
Session bereits geladen hat; alles andere wird als „skipped" gemeldet. Das ist
ehrlich, aber leer — in einer normalen Session ist das die Mehrheit der
Personal-Plugins, der Korpus wird also größtenteils von gar nichts geprüft.
Für genau diese Plugins gibt es eine Quelle, die keine laufende Session
braucht: den lokalen Checkout auf der Platte. `repo.lua` durchsucht ihn nach
dem dokumentierten `lhs` bzw. Commandnamen **als String-Literal in Quotes**.

Neue Finding-Arten: `keymap-not-in-repo`, `usercmd-not-in-repo`, eigener
Abschnitt im Report.

**Schwächer als die Live-Achse, und im Report so gekennzeichnet.**
`nvim_get_keymap` beantwortet „ist registriert"; ein Grep beantwortet „steht
so im Quelltext". Ein zur Laufzeit zusammengesetztes `lhs` (`prefix .. "m"`)
ist registriert und nicht greppbar — das ist der bekannte Falschbefund dieser
Achse, siehe den echten Lauf unten.

**Nur `.lua`/`.vim`, nur in Quotes.** Das eigene `doc/`, `README.md` und die
Cheatsheets eines Plugins beschreiben dieselben Bindings wie dieser Korpus;
sie mitzulesen hieße, Doku gegen Doku zu bestätigen. Und die Suche nach dem
blanken Wort war für Commands messbar nutzlos: `:Images` trifft
case-unabhängig „images" in jeder zweiten Zeile von images.nvim. Deshalb
Keymaps case-**un**abhängig (`<Leader>` = `<leader>`), Commandnamen
case-**abhängig**.

**Drei Unterdrücker, damit übrig bleibt, was zu lesen lohnt.** Gemeldet wird
nur, was in keinem der drei steht: im Checkout des Plugins, im `lua/`-Baum
dieser Config (der `<leader>`-Einstieg eines Personal-Plugins wird sehr oft
hier registriert, in einer lazy-`keys`-Spec, nicht dort drüben), und in den
gerade registrierten Keymaps/Commands. Ein Plugin, das die Achse tatsächlich
beantworten konnte, zählt danach nicht mehr als „skipped" — es wurde geprüft,
nur mit einem schwächeren Instrument.

**Auflösung austauschbar, nicht hartkodiert.** `config.repo_dirs()` liefert
`{name, dir}` je Plugin; die Default-Implementierung ruft
`plugins.personal.export.projects()` (das den echten Lazy-Spec auswertet,
nicht eine handgepflegte Markdown-Liste — siehe `plugins/personal/list.lua`s
Moduldoc, warum diese Liste als Quelle aufgegeben wurde).
`config.set_repo_dirs(fn)` ersetzt sie; die Tests hängen daran und laufen
gegen ein Fixture-Repo im Temp-Verzeichnis statt gegen echte
`C:\repos\*`-Checkouts.

**Oder ein ganzes Sammelverzeichnis statt der Plugin-Liste: `root=<dir>`**
(2026-08-30). `:Bindings check repo root=C:/repos` nimmt jedes Lua-Projekt
direkt unter dem Pfad (`config.repo_dirs_under`). Ein Unterverzeichnis zählt
als Projekt, wenn es ein `lua/` oder eine `.lua`-Datei obenauf hat — nicht,
wenn es ein `.git` hat: diese Achse liest Quelltext, nicht Historie, und ein
Checkout ohne eigenes `.git` (Submodul, entpacktes Release) ist genauso
greppbar. Nur eine Ebene tief, sonst meldete jeder Checkout sein eigenes
`lua/` und `tests/` als weitere „Repos".

`root=` ist ein `kv`-Argument, kein dritter Positionswert: ein Pfad und ein
Plugin-Name sind beide freie Strings, und der Composer bindet Positionen der
Reihe nach — `:Bindings check C:/repos` würde den Pfad still als Plugin-Namen
binden. Mit dem Schlüssel davor ist die Zuordnung stellungsunabhängig, `<Tab>`
vervollständigt nach `root=` Verzeichnisse (`type = "DIR"`), und `root=`
impliziert `repo`.

Zwei Dinge kann diese Auflösung, die die Default-Auflösung nicht kann: sie
setzt keine geladene `plugins.personal`-Ebene voraus, und sie deckt jeden
Checkout im Pfad ab statt nur die als Plugin *aktivierten*. Gemessen gegen
`C:/repos`: 31 Projekte aufgelöst, 30 beantwortet, `skipped` von 38 auf 8.
Dazu eine eigene Berichtszeile: **Projekte unter dem Pfad, die dieser Korpus
gar nicht dokumentiert** (hier `buffer-ctx.nvim`, dessen Cheatsheet
`buffer-ctx` heißt). Das ist kein Drift — es gibt keine dokumentierte
Behauptung, die falsch sein könnte —, aber die einzige Aussage, die ein
Bericht über einen ganzen Pfad machen kann und einer über eine Plugin-Liste
strukturell nie.

**Erster echter Lauf** (headless, alle 30 auflösbaren Plugins künstlich als
ungeladen, also der Worst Case, für den die Achse existiert): 940 ms, 30 von
30 Checkouts beantwortet, **10 Findings**. Davon:

- 7× `debugging.nvim` — `<lt>m`/`<lt>n`/… , im Quelltext als
  `prefix .. "m"` gebaut. Genau der oben genannte Falschbefund, kein Bug.
- 1× `markdown.nvim` — `` `]\ `` als „lhs": ein Parser-Artefakt, kein
  Drift. Die Tabellenzelle enthält ein escaptes `\|`, und `records.lua`s
  `split_cells` trennte an jedem `|`, auch am escapten. Vorbestehender
  Defekt des Scrapers, hier nur erstmals sichtbar geworden — **seit
  `472822d8` behoben**, der lhs liest sich jetzt als `]|` und deckt sich mit
  markdown.nvims `keymaps.lua`. Dieser Lauf hat damit 9 Findings, nicht 10.
- 1× `cmdlog.nvim` — `ctrl-f`, in cmdlog.nvims Quelltext nirgends. Echter
  Fund.
- 1× `lib.nvim` — `:RATelemetry`, dokumentiert in `Usercmds/lib.nvim.md`,
  registriert aber in runtime-analysis.nvim. Echter Fund, und einer, den
  die Live-Achse strukturell nie finden kann: sobald beide Plugins geladen
  sind, existiert das Command ja — nur eben nicht dort, wo das Cheatsheet
  es verortet.
