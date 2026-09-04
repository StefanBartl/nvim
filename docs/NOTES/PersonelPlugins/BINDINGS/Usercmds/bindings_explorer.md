# bindings-explorer — `:Bindings [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.bindings.usercmd.composer`, wie `:Case`/`:Image`. Bare
`:Bindings` ohne Subcommand ist gleichbedeutend mit `:Bindings search`.

Source: `lua/bindings/usrcmds/bindings_explorer/`
Docs: `lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md`, `:help bindings_explorer`

| Command | Effect |
| --- | --- |
| `:Bindings` | Wie `:Bindings search` |
| `:Bindings search [plugin] [query]` | Live-Grep über beide BINDINGS-Bäume (Picker-Engine via `pickers.nvim`, sonst Prompt+Liste) |
| `:Bindings search keymaps\|usercmds\|autocmds [plugin] [query]` | Dieselbe Suche, auf eine Unterkategorie gescopt |
| `:Bindings search keymaps hover.nvim` | Nur hover.nvims Keymaps-Sheet — Plugin-Scope statt Query |
| `:Bindings search keymaps plugin=<stamm> [query]` | Derselbe Scope ausgeschrieben; löst auch Präfixe auf (`plugin=documentat`) |
| `:Bindings browse [plugin] [scope]` | Picker über geparste Tabellenzeilen (alle drei Kategorien) statt Volltext |
| `:Bindings browse keymaps\|usercmds\|autocmds [plugin] [scope]` | Dieselbe Tabellenzeilen-Suche, auf eine Kategorie gescopt |
| `:Bindings path [personal\|extern]` | BINDINGS-Wurzel(n) in die Zwischenablage kopieren |
| `:Bindings check [plugin]` | Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only) |
| `:Bindings check extern [plugin]` | Derselbe Bericht über den Extern-Korpus: `ExternPlugins/Bindings` gegen live, plus die fremden Commands ohne Cheatsheet |
| `:Bindings check all [plugin]` | Beide Korpora zusammen — das Verhalten vor der Scope-Trennung |
| `:Bindings check repo [plugin]` | Derselbe Bericht plus Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum |
| `:Bindings check <plugin> repo` | Dieselbe Achse, Plugin zuerst — identisch zur Zeile darüber |
| `:Bindings check repo root=<dir>` | Dieselbe Achse, aber jedes Lua-Projekt unter `<dir>` statt der Lazy-Spec-Auflösung; `root=` impliziert `repo` |
| `:Bindings check <plugin> root=<dir>` | Dieselbe Pfad-Auflösung, auf ein Plugin gescopt; `root=` ist positionsunabhängig |
| `:Bindings report [plugin]` | Derselbe Bericht als Markdown-Datei nach `docs/ROADMAP/personal/All/BINDINGS-DRIFT-<datum>.md` |
| `:Bindings report repo [plugin]` | Dasselbe mit der Checkout-Achse; `root=<dir>` wie bei `check` |
| `:Bindings report out=<pfad>` | Zielpfad überschreiben — ein Verzeichnis bekommt den Datumsnamen, ein Dateiname wird genommen wie er ist |
| `:Bindings status` | Dashboard: Korpus-, Live- und Plugin-Zahlen, letzter Bericht, Routenliste |

`scope` bei `browse` ist `personal`/`extern` (optional, ohne Argument beide).
`plugin` ist ein Cheatsheet-Stamm — der Dateiname ohne `.md`, also `hover.nvim`,
`Gitsigns`, `nvim-config`. `<Tab>` listet die Stämme der bereits getippten
Kategorie.

## Notes

- **Plugin-Scope (2026-09-03)**: `search`, `browse`, `check` und `report`
  nehmen den Stamm auch verkürzt (`hover` → `hover.nvim`, `neotree` →
  `NeoTree`) — dieselbe Normalisierung, mit der `check` Cheatsheet-Stämme auf
  lazy.nvim-Namen abbildet (`plugin_scope.normalize`, von `drift.lua`
  mitbenutzt). Bei `search` teilt sich der Scope den Platz mit der Query,
  deshalb gilt dort **nur** der ausgeschriebene oder normalisierte Stamm als
  Scope: `:Bindings search keymaps redact` ist weiterhin eine Textsuche.
  Präfixe (`documentat`) löst nur die Form `plugin=documentat` auf, und ein
  Präfix, das mehrere Stämme trifft, wird als mehrdeutig gemeldet statt auf
  einen davon geraten. `:Bindings search keymaps hover.nvim zoom` und
  `:Bindings search keymaps zoom hover.nvim` sind dasselbe — es zählt, welches
  Token ein Sheet benennt, nicht die Stellung. Ein Token, das ein Sheet
  benennt, wird als Scope gelesen; wer den Namen als **Text** sucht, tippt ihn
  in den Picker statt in die Kommandozeile.

- **Dokumentierte Unterrouten werden seit 2026-09-03 mitgeprüft**, und vorher
  gar nicht. `nvim_get_commands` kennt nur oberste Namen; ein Plugin auf
  `usercmd.composer` registriert genau eines, und alle Routenzeilen fallen
  darauf zusammen. Sechzehn Zeilen, ein Name, den es gibt — beide Richtungen
  bestanden trivial, und der Check sah aus, als decke er diese Tabellen ab.
  Gemessen: eine erfundene Route erzeugte kein Finding.

  Geprüft wird über die **Completion des Kommandos**, Ebene für Ebene. Ein
  Kommando ohne Completion wird übersprungen statt geraten. Neue Finding-Art:
  `usercmd-subroute-not-live`.


- **Kein `## which-key`**: `bindings_explorer` registriert keine Keymaps —
  bewusst usercommand-only, wie `:Case`/`:Image` auch für ihre
  Argument-tragenden Subcommands entscheiden. Es gibt daher auch keine
  `Keymaps/bindings_explorer.md` in diesem Ordner.
- **`search` vs. `browse`**: `search` durchsucht rohen Zeilentext (findet
  auch Prosa/Notes-Abschnitte), `browse` durchsucht nur geparste
  Tabellenzeilen (strukturierter, aber blind für alles außerhalb einer
  Tabelle). Siehe `docs/FEATURES.md` für die volle Begründung.
- **`check` ist bewusst eingeschränkt** (nur Personal, nur eine Richtung
  bei Keymaps, noch nicht geladene Plugins werden übersprungen und
  namentlich gemeldet statt fälschlich als fehlend) — volle Begründung in
  `drift.lua`s Moduldoc, nicht hier dupliziert. Buffer-lokale und
  filetype-gescopte Keymaps waren der dominante False-Positive-Fall und sind
  es seit dem Quelltext-Fallback nicht mehr, siehe unten.
## Scope: eigen und fremd sind zwei Fragen (2026-09-02)

`:Bindings check` prüft per Default **nur die eigenen** Bindings, und das ist
seit diesem Datum eine ausgesprochene Regel statt eines Zufalls.

| Route | Dokumentierte Seite | Live-Commands ohne Cheatsheet |
| --- | --- | --- |
| `:Bindings check` | `PersonelPlugins/BINDINGS` | nur eigene |
| `:Bindings check extern` | `ExternPlugins/Bindings` | nur fremde |
| `:Bindings check all` | beide Bäume | beide |

`report` spiegelt alle drei (`:Bindings report extern`, `… all`).

**Warum der Default eng ist.** Ein fremdes Command ohne Cheatsheet ist keine
Drift — es ist ein Korpus, den diese Config nie zu decken behauptet hat.
Gemessen am 2026-09-02: von 107 Befunden waren 54 genau das, und alle 54
gehörten Fremdplugins (git-conflict 9, noice 4, treesitter 3, Mason,
Vimscript-Plugins, Neovims eigene). Mit dem Default bleiben 53, und jeder
davon ist eine Aussage über etwas, das dieses Repo selbst registriert.

**Warum es trotzdem eine Route gibt.** `extern` ist kein Abfallprodukt: der
Extern-Korpus (552 Keymap- und 107 Usercmd-Zeilen) wurde von diesem Prüfer
noch nie gegen die Realität gehalten. Der erste Lauf meldet 379 Befunde — das
ist keine Regression, sondern eine Achse, die vorher gar nicht existierte.

**Woran „eigen" hängt.** An `config.repo_dirs()`, also an der aus dem
Lazy-Spec abgeleiteten Liste der Personal-Plugins, plus `nvim-config` selbst
— keine handgepflegte Namensliste. Lässt sie sich nicht auflösen, wird
*nicht* gefiltert: der Bericht zeigt dann alles und sagt im Kopf, dass der
Scope nicht angewandt werden konnte. Eine Trennung, die im Zweifel Befunde
verschluckt, wäre schlimmer als keine.

**`search` und `browse` sind ausgenommen** und bleiben es. Wer eine Taste
sucht, sucht sie unabhängig davon, wer sie registriert — beide Routen lesen
weiterhin beide Bäume, in jedem Scope.

- **`check repo` ist opt-in, nicht Default.** Die drei bestehenden Achsen
  befragen eine laufende Session und kosten nichts Nennenswertes; die
  Checkout-Achse liest ~30 Repos von der Platte (gemessen: 940 ms, 2861
  Quelldateien, 28 MiB, die danach sofort wieder freigegeben werden). Das
  soll kein stiller Kostenfaktor eines Kommandos sein, das man für den
  üblichen Bericht tippt.
- **`:Bindings path` hat `:BindingsPath` ersetzt** (2026-09-04). Das ältere
  Kommando in `lua/bindings/usrcmds/init.lua` zeigte auf den nie
  existierenden Pfad `docs/NOTES/BINDINGS` statt auf die beiden echten
  Wurzeln und trug seit dem ersten Tag ein `TEMP`. Es ist entfernt;
  `<leader>BI` läuft jetzt auf `:Bindings path`, weil die Telemetrie die
  Taste als häufig gedrückt ausweist — die Taste bleibt, nur ihr Ziel
  stimmt jetzt.

## Der Quelltext-Fallback (2026-09-02)

Findet die Live-Achse eine dokumentierte Taste nicht, wird sie im Quelltext
gesucht, bevor daraus ein `keymap-not-live` wird — im Checkout des Plugins und
im `lua/`-Baum dieser Config. **Kein Schalter, das läuft in jedem Lauf.**

| Route | `keymap-not-live` vorher | nachher | im Quelltext bestätigt |
| --- | ---: | ---: | ---: |
| `:Bindings check` | 52 | **1** | 51 |
| `:Bindings check extern` | 309 | **84** | 225 |

Der eine Übriggebliebene ist `cmdlog.nvim`s `ctrl-f` — fzf-lua-Notation in
einem Korpus, der sonst Vim-Notation schreibt.

**Warum nicht einfach die buffer-lokalen Tasten ausgliedern?** Weil
`keymap-not-live` kein Kollisionscheck ist: dort wird nie buffer-lokal gegen
global verglichen, die Achse fragt nur „das Cheatsheet dokumentiert diese Taste
— gibt es sie?". Eine ganze Klasse davon auszunehmen hieße, dass eine
buffer-lokale Taste, die ihr Plugin inzwischen umbenannt hat, nie wieder
auffiele. Der Fallback behält die Frage und beantwortet sie besser.

**Was das mit `check repo` zu tun hat: nichts.** Die Achse darüber liest den
Checkout jedes *ungeladenen* Plugins, zweiunddreißig Bäume auf Verdacht — sie
bleibt opt-in. Der Fallback fasst einen Checkout erst an, nachdem eine Taste
gefehlt hat, in einem Default-Lauf also eine Handvoll. Gemessene Kosten: `check`
~150 ms ohne, ~550 ms mit.

**Der bekannte Preis.** Ein Grep unterdrückt gelegentlich auch einen echten
Fund: `cmdlog.nvim`s `ctrl-t` steht in keiner Zeile von cmdlog.nvim, wohl aber
in `lua/config/fzf/init.lua` dieser Config, wo dasselbe Literal etwas ganz
anderes bindet. Dieselbe Haltung wie überall in `repo.lua`: ein verpasster Fund
ist billiger als ein falscher.

**Der Bericht sagt die Zahl.** Laufkopf-Zeile „Quelltext-Fallback" und ein
eigener Abschnitt „Confirmed by source instead of by the session (n)" — sonst
verschwinden zwischen zwei Läufen desselben Kommandos 51 Befunde, und das ist
die Form eines Bugs, nicht die einer Verbesserung.

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
- 2026-09-02: `:Bindings report` (Bericht als Datei) und `:Bindings status`
  (Dashboard) ergänzt, dazu vier Fixes am Scraper — siehe den Abschnitt
  ganz unten.
- 2026-09-02 (2): `check`/`report` nennen den Eigentümer jedes
  undokumentierten Live-Commands statt „owner not recorded" — siehe den
  letzten Abschnitt.
- 2026-09-02 (3): Quelltext-Fallback im Default — eine dokumentierte Taste,
  die nicht live ist, wird im Quelltext gesucht, bevor sie ein Befund wird.
  `keymap-not-live` 52 → 1. Siehe den Abschnitt darüber.
- 2026-09-03: **Plugin-Scope** für `search` und `browse`
  (`:Bindings search keymaps hover.nvim`), neues Modul `plugin_scope.lua`.
  `check`/`report` hatten das Argument schon, nehmen es jetzt aber auch
  verkürzt. `<Tab>` schlägt in jedem dieser Slots die Cheatsheet-Stämme der
  getippten Kategorie vor. Siehe die Notes oben.

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

## `:Bindings report` und `:Bindings status`, plus vier Scraper-Fixes (2026-09-02)

Aus dem Driftreport vom 2026-09-02
(`docs/ROADMAP/personal/All/BINDINGS-DRIFT-2026-09-02.md`). Der wurde von Hand
aus einem headless-Lauf zusammengesetzt und hat dabei aufgeschrieben, welche
seiner 266 Befunde gar keine Befunde waren. Beides ist hier eingebaut.

**`:Bindings report [plugin] [repo] [root=<dir>] [out=<pfad>]`** — derselbe
Lauf wie `check`, aber als Markdown-Datei statt in den Viewer: Laufkopf
(Datum, Neovim-Version, Umfang, Laufzeit, aufgelöste Checkouts), eine Tabelle
der Befunde nach Art, und `drift.describe`s unveränderte Ausgabe als
```text-Anhang. Ohne `out=` landet er als `BINDINGS-DRIFT-<datum>.md` in
`docs/ROADMAP/personal/All/` (`config.report_dir()`); `out=` darf ein
Verzeichnis oder ein Dateiname sein. `out` ist als `PATH` typisiert und nicht
als `FILE` — `FILE` verlangt eine *lesbare* Datei, und eine Ausgabedatei gibt
es vor dem Lauf per Definition noch nicht.

Was `report` bewusst **nicht** tut: die Befunde bewerten. Welcher davon eine
echte Doku-Lücke ist und welcher ein Werkzeugfehler oder ein erwartbarer
Effekt, bleibt die Durchsicht — und genau diese Einschätzung ist der Teil,
für den ein handgeschriebener Bericht sich lohnt. Erzeugt wird die gemessene
Hälfte, damit nur noch die andere zu schreiben ist.

**`:Bindings status`** — eine Seite: Dateien und Tabellenzeilen je Wurzel und
Kategorie, die Live-Zahlen dieser Session (globale Keymaps nach Modus,
buffer-lokale, Usercmds, Autocmds mit Gruppenzahl), wie viele Plugins lazy
kennt und wie viele geladen sind, wie viele Checkouts die Repo-Achse auflöst,
der zuletzt geschriebene Bericht, und die Routenliste. Läuft **keinen**
Driftcheck (~70 ms statt ~650 ms) — ein Dashboard, auf das man wartet, öffnet
man einmal.

**Vier Fixes am Scraper**, gemessen am selben Lauf: 331 Befunde vor, 262 nach
den Fixes, und keiner der 69 entfernten war ein echter.

| Fix | Wo | Weg |
| --- | --- | ---: |
| Platzhalter in der Key-Spalte (`—`, `*(unset)*`, `*(your lhs)*`) zählen nicht als Taste | `drift.is_placeholder_key` | 3 |
| Korpus-Dateien (`All.md`, `Collisions.md`, `Overview.md`) sind keine Cheatsheets | `records.META_FILES` | 17 |
| Ein Commandname direkt hinter einem Wortzeichen ist Prosa (`path:L1-L2` wurde als fehlendes Kommando gemeldet) | `records.command_names` | 1 |
| Ein im Fließtext dokumentierter Command gilt als dokumentiert | `records.mentions` | 48 |

Die Korpus-Dateien werden **markiert, nicht verworfen**: `browse`/`search`
wollen ihre Zeilen, und die Gegenrichtung des Driftchecks auch — ein in
`Overview.md` genannter Command *ist* dokumentiert, er wird dort nur nicht
registriert. Nur die Richtung „dokumentiert, aber nicht live" überspringt sie.

Dasselbe Prinzip bei der Prosa: für „live, aber nirgends dokumentiert" reicht
eine Erwähnung, denn die Frage lautet nur, ob der Korpus den Command
überhaupt kennt. Für die Gegenrichtung reicht sie nicht — eine Erwähnung
trägt weder Taste noch Modus noch Fundstelle, gegen die sich etwas prüfen
ließe.

## `:Bindings check` sagt jetzt, wem ein Command gehört (2026-09-02)

Der größte Posten des Driftreports war die Zeile *„88 live commands, origin:
via lib.nvim usercmd helpers — owner not recorded"*. Der Befund hinter dem
Befund war anders als dort vermutet: **die Information fehlte nie.** lib.nvims
Registry hält den Aufrufort fest (`Lib.UserCommand.Record.src`). Nur haben
zwei Stellen ihn nicht benutzt:

* `drift.lua` fragte die Registry gar nicht, sondern las
  `debug.getinfo(def.callback)` — die pcall-Hülle, die `usercmd.create` um
  jeden Callback legt. Die ist in lib.nvim definiert, also meldete jedes über
  die Helfer angelegte Command lib.nvim als Quelle.
* `composer.verb` reichte `create`s `src`-Option nie durch, obwohl deren Doku
  genau diesen Fall beschreibt. Alle zwölf Verben einer Session lagen auf
  einer Zeile von `composer/init.lua`. Behoben in lib.nvim `bfa09e5`; danach
  nennen 136 von 139 Registry-Einträgen einen echten Eigentümer, und die drei
  übrigen (`:KitPreview`, `:Lib`, `:SystemInfo`) sind lib.nvims eigene.

Im Bericht sieht man das an der Herkunftsspalte: **0 unbekannte Eigentümer**,
53 der 109 undokumentierten Live-Commands sind eigene mit `file:line`, 56 sind
fremde. Ein Eintrag mit Fundstelle ist einer, für den eine Cheatsheet-Zeile
fehlt; ein blanker Pluginname ist Fremdinfrastruktur, die dieser Korpus nie
abgedeckt hat. Die alte, entschuldigende Note unter der Überschrift ist genau
dadurch ersetzt worden.

Nebeneffekt, der die weitere Doku-Arbeit lenkt: die 23 von pickers.nvim
erzeugten Scope-Commands teilen sich eine Generatorzeile und stehen deshalb
als ein Block im Bericht — sichtbar als das, was sie sind, und damit als
Argument für „den Generator dokumentieren, nicht seine 23 Ergebnisse".
