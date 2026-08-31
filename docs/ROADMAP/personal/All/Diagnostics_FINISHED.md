# Diagnostics -- Erledigt

Aus `docs/ROADMAP/personal/All/Diagnostics.md` herausgenommene Punkte, sobald
sie abgeschlossen sind. Neueste zuerst. Der Report dort bleibt die Quelle fuer
alles, was noch offen ist.

---

## 2026-08-31

### Cluster A: der `assert`-Typ -- und warum der erste Anlauf ins Leere lief

*(war: Diagnostics-Report Abschnitt 4 A, Abschnitt 8 Punkt 1, und der
unverifizierte Nebenbefund aus Abschnitt 7)*

Am 30.08. lagen zwei Dinge vor: die Meta-Datei
`lib.nvim/lua/lib/@types/luassert.lua`, die den globalen `assert` als `luassert`
typisiert, und in vier `.luarc.json` die neue Zeile
`${3rd}/luassert/library`. Nachgemessen hat das zusammen so gut wie nichts
bewirkt:

| Repo | 2026-08-29 | nach den Commits vom 30.08. |
|---|---:|---:|
| lsp.nvim | 1333 | 1333 |
| sandbox.nvim | 223 | 223 |
| dap.nvim | 60 | 60 |
| lib.nvim | 505 | 505 |
| github_stats.nvim | 88 | **60** |

Nur github_stats.nvim hat reagiert -- als einziges der vier fuehrte seine
`.luarc.json` auch `${3rd}/busted/library`, und erst die Meta von busted
verdrahtet `assert` ueberhaupt mit luassert.

#### Die Ursache, jetzt gemessen statt vermutet

Der Nebenbefund vom 29.08. stimmt, und er ist groesser als dort geschaetzt:
**`.luarc.json` ersetzt `workspace.library` vollstaendig**, sie ergaenzt nicht.
Was `lsp.nvim` dem Server mitschickt, kommt nie an.

Nachweis im echten Editor, nicht im Modell: headless nvim, `lua_ls` an
`lsp.nvim/TESTS/lsp/config_spec.lua`. Der Client sendet
`${3rd}/busted/library` mit -- der Server meldet trotzdem
`Undefined global 'describe'` und `'it'`.

Betroffen waren **31 von 33 Workspaces**. Sie alle deklarierten eine eigene
Library-Liste aus ein bis sieben Eintraegen und warfen damit die
43 Eintraege weg, die `build_library.lua` zusammenstellt -- darunter busted,
`$VIMRUNTIME`, saemtliche Plugin-Typen und lib.nvim, also auch die Meta-Datei.
Die erreichte nur `nvim-config` und `runtime-analysis.nvim`, die keine eigene
Liste fuehren.

Bei sandbox.nvim standen in dieser Liste ausserdem vier
`$HOME/.local/share/nvim/lazy/…`-Pfade, die auf dieser Maschine ins Leere
zeigen.

#### Die zweite Ursache: der Workspace als seine eigene Library

`build_library.lua` haengte jeden `runtimepath`-Eintrag an. Die Dev-Repos liegen
auf dem `runtimepath`, also auch das Repo, das gerade offen ist. LuaLS liest
dessen Dateien dann zweimal, und jede `@class` darin meldet
`duplicate-doc-field` gegen sich selbst: **1085 der 1222 Warnungen der
nvim-Config** und 212 in runtime-analysis.nvim.

#### Was gemacht wurde

1. **`workspace.library` aus 20 `.luarc.json` entfernt** -- genau dort, wo die
   Messung eine Verbesserung zeigt. Jede Datei hat nur diesen einen Block
   verloren.
2. **`lsp.nvim/lua/lsp/servers/lua_ls/build_library.lua`**: der
   `runtimepath` wird gefiltert, der Workspace landet nicht mehr in seiner
   eigenen Library.

Die Meta-Datei aus dem ersten Anlauf bleibt unveraendert -- sie war nie das
Problem, sie kam nur nirgends an. Jetzt tut sie, wofuer sie gebaut wurde:
`assert.are.same(...)` loest auf, in lsp.nvim bleiben von 665
`undefined-field` noch 36, davon sieben echte (`has_no`, `are_not` -- Namen,
die die Meta-Datei noch nicht kennt).

#### Ergebnis: 6344 -> 3204

| Repo | vorher | nachher |
|---|---:|---:|
| lsp.nvim | 1333 | 392 |
| nvim-config | 1222 | 137 |
| documentation.nvim | 1048 | 732 |
| runtime-analysis.nvim | 485 | 273 |
| filetree.nvim | 312 | 226 |
| sandbox.nvim | 223 | 44 |
| images.nvim | 150 | 44 |
| open.nvim | 102 | 85 |
| markdown.nvim | 91 | 59 |
| pdfport.nvim | 72 | 62 |
| replacer.nvim | 71 | 60 |
| dap.nvim | 60 | 10 |
| github_stats.nvim | 60 | 52 |
| insights.nvim | 57 | 29 |
| diff.nvim | 50 | 48 |
| pickers.nvim | 43 | 27 |
| cascade.nvim | 38 | 32 |
| recommender.nvim | 23 | 12 |
| reposcope.nvim | 23 | 10 |
| color_my_ascii.nvim | 16 | 8 |
| debugging.nvim | 9 | 8 |
| cmdlog.nvim | 6 | 4 |
| **Summe (alle 33 Workspaces)** | **6344** | **3204** |

Nach Regel: `undefined-field` 1741 -> 562, `duplicate-doc-field` 1235 -> 192,
`undefined-global` 511 -> **0**, `undefined-doc-name` 328 -> 87,
`redundant-parameter` 252 -> 84.

#### Was absichtlich unangetastet blieb

Acht Repos wuerden durch den Fix **schlechter** -- ihre `.luarc.json` behaelt
ihre Library-Liste, und damit bleibt fuer sie auch Fix 2 wirkungslos:
spotlight (+340), mdview (+75), lib (+35), fileops (+15), sessions (+7),
buffer-ctx (+4), neotree-fs-refactor (+4), migrate (+1). Drei weitere aendern
sich gar nicht: emojis, gopath, language.

Dass lib.nvim dabei ist, ist die unangenehme Pointe: das Repo, das die
Meta-Datei traegt, sieht sie selbst nur, weil sie in seinem eigenen Workspace
liegt.

#### Wie gemessen wurde

`lua-language-server --check` pro Workspace, mit einer Config, die die
Injektion aus `build_library.lua` nachbaut und die `.luarc.json` des Repos
darueberlegt -- also genau die Reihenfolge, die auch der Editor herstellt. Zur
Kontrolle wurde die Modell-Library fuer lsp.nvim gegen die **echte**
43-Eintraege-Liste getauscht, die `build_library("E:/repos/lsp.nvim")` im
laufenden nvim zurueckgibt: identisches Ergebnis, 392.

Der Vorher-Lauf hat die Meta-Datei beiseitegelegt und die vier
`luassert`-Zeilen entfernt, statt in der Historie zu blaettern; die Datei kam
per `trap` zurueck, `git status` war danach sauber.

Zwei Sachen, an denen das Skript zuerst gescheitert ist, fuer den naechsten
Anlauf: Windows-Python schreibt die Index-Datei mit CRLF, und das CR haengt am
Pfad; und parallele `lua-language-server`-Instanzen brauchen je einen eigenen
`--metapath`, sonst kommt jeder Lauf leer zurueck.

---

## 2026-08-29

### Cluster C: `missing-fields` -- 518 auf 21, ueber alle 31 Plugins plus Config

*(war: Diagnostics-Report Abschnitt 4 C und Abschnitt 8, Punkt 3)*

Die `@class *.Config`-Klassen deklarierten ihre Felder als Pflicht, obwohl sie
zugleich der Typ dessen waren, was `setup()` entgegennimmt. Jeder partielle
Aufruf -- also die vorgesehene Nutzung -- galt damit als Fehler.

**Ergebnis: 518 -> 21.** Die 21 Reste liegen saemtlich in lib.nvim und sind die
Namespace-Aggregatoren (`---@type Lib` auf einer Tabelle, die per
`LIB.x = ...` gefuellt wird): dieselbe Ursache wie die 108 `inject-field`, und
dort aufzuraeumen, nicht hier.

| Repo | `missing-fields` | Diagnosen gesamt |
|---|---:|---|
| filetree | 90 -> 0 | 315 -> 226 |
| pickers | 78 -> 0 | 121 -> 43 |
| spotlight | 66 -> 0 | 156 -> 90 |
| lib | 37 -> 20 | 533 -> 516 |
| pdfport | 37 -> 0 | 106 -> 62 |
| documentation | 36 -> 0 | 753 -> 717 |
| lsp | 30 -> 0 | 464 -> 441 |
| nvim-config | 25 -> 0 | 185 -> 160 |
| open | 21 -> 0 | 106 -> 85 |
| diff | 14 -> 0 | 62 -> 48 |
| emojis | 14 -> 0 | 28 -> 13 |
| markdown | 12 -> 0 | 71 -> 59 |
| github_stats | 11 -> 0 | 120 -> 109 |
| debugging | 9 -> 0 | 17 -> 8 |
| gopath | 8 -> 0 | 108 -> 100 |
| images | 7 -> 0 | 45 -> 38 |
| language | 6 -> 0 | 40 -> 34 |
| sessions | 5 -> 0 | 23 -> 18 |
| cascade, recommender | 3 -> 0 | 35 -> 32, 15 -> 12 |
| insights, mdview | 2 -> 0 | 31 -> 29, 120 -> 118 |
| dap, runtime-analysis, color_my_ascii | 1 -> 0 | 33 -> 32, 270 -> 269, 20 -> 19 |
| **Summe** | **518 -> 21** | **3777 -> 3278** |

Ohne Befund und unangetastet: sandbox, fileops, buffer-ctx, replacer, migrate,
reposcope, cmdlog.

---

#### Der Fix war nicht ueberall derselbe -- und das liess sich nur messen

Der Report schlug einen Weg vor: Opts von Config trennen. Der billigere --
einfach alle Felder optional stellen -- funktioniert aber in der Mehrzahl der
Repos genauso gut und kostet keine zweite Klassenfamilie. Welcher der richtige
ist, haengt daran, **wie das Plugin seine aufgeloeste Config liest**, und das
sieht man dem Repo nicht an.

Gemessen, jeweils Felder-optional zuerst:

- **spotlight.nvim**: 66 Warnungen weg, *keine* neue. Grund: die Features lesen
  ueber `config.get("section")`-Accessoren, die ohnehin auf die Defaults
  zurueckfallen -- nie direkt in eine gemergte Tabelle hinein.
- **diff.nvim**: 14 weg, **19 neue `need-check-nil` und 2
  `param-type-mismatch`**. Grund: das ganze Plugin liest `cfg.diff.ctxlen` und
  Geschwister direkt.
- **emojis.nvim**: 14 weg, 15 neue. **insights.nvim**: 2 weg, 13 neue.
  **images.nvim**: 7 weg, 12 neue. **sessions.nvim**: 5 weg, 3 neue plus ein
  `return-type-mismatch`. **github_stats.nvim**: 11 weg, 5 neue.

In diesen sechs Repos wurde stattdessen gespalten: eine `*Opts`-Familie mit
lauter optionalen Feldern fuer die Eingabe, die `*Config`-Klassen bleiben
strikt fuer alles nach dem Merge. In den uebrigen 15 genuegte `?`.

**Die Lehre ist die Messung selbst.** Ohne den Vorher/Nachher-Vergleich ueber
*alle* Regeln haette man in sechs Repos 47 Warnungen gegen 54 neue getauscht
und es "erledigt" genannt.

---

#### Was dabei an echten Fehlern herausfiel

Kein einziger davon war der gesuchte Cluster -- alle sind Annotationen, die
etwas anderes behaupteten als der Code daneben tut:

- **`Language.Module.setup` ueberschrieb die eigene Signatur.**
  `language.nvim/@types/init.lua` deklariert `setup` ein zweites Mal als
  `@field setup fun(opts?: LanguageConfig)`, und **diese Deklaration gewinnt
  gegen das `@param` an der Funktion**. Die Umstellung auf `LanguageOpts` kam
  bei keinem Aufrufer an -- gemerkt nur, weil eine Probe *ausserhalb* des Repos
  weiter vier Warnungen zeigte. Wer eine `setup`-Signatur aendert, muss pruefen,
  ob die Modul-Klasse sie nochmal fuehrt (lib, lsp, replacer, reposcope tun das
  auch, dort mit unkritischem Typ).
- **`---@type X` auf einem Modul, das seine Methoden darunter definiert.**
  pdfports 16 Backends und Producer sind Tabellen-Literale mit den Datenfeldern,
  `available`/`extract` folgen als Funktionen. Gegen ein `@type` prueft LuaLS
  nur das Literal und meldet die Methoden als fehlend. `---@class
  PdfPort.Backend.Foo : PdfPort.Backend` macht die spaetere
  `function M.extract(...)` zur Definition des Klassenfeldes. Nebeneffekt:
  `param-type-mismatch` fiel dort von 16 auf 10, weil die Registry jetzt die
  echten Feldtypen sieht statt eines Literals, das sie fuer unvollstaendig hielt.
- **Eine aufgeloeste Config muss weiter als Eingabe taugen.** Nach dem Split
  lehnte LuaLS in images.nvim zwei Specs ab, die eine fertige Config zurueck an
  `setup()` reichen -- voellig legitim. Erst
  `---@class ImagesNvim.Config : ImagesNvim.Opts` macht die Beziehung wahr.
- **filetree `FiletreeBindSpec.rhs`** war Pflicht, obwohl eine Action
  *entweder* `rhs` *oder* per-Modus-`binds` mitbringt (marks' toggle).
- **documentation `IR.duplicates`** -- der eigene Doc-Kommentar sagt "Set by
  `scan_full`, so a bare `scan()` leaves it nil", die Annotation sagte Pflicht.
  Dazu `IR.tag_links` (wird von `tagfiles.lua` nachgestempelt, Leser schreiben
  `ir.tag_links or {}`) und `Node.calls_external` (von `core/calls.lua`).
- **lib.nvim `DirGuard.Opts.on_violation`** -- die Implementierung prueft
  `if opts.on_violation then`; **`Strategies.Registration.keys`** --
  `control.keys()` faellt ohne es auf `pairs()` zurueck, und der Kommentar
  darueber sagt das; **`RootResolverCfg.markers`** -- hat einen Default.
- **lib.nvim `Markdown.Table`**: `render()` verlangte `start_line`/`end_line`,
  liest sie aber nie. Eine im Speicher zusammengesetzte Tabelle hat keine
  Position -- danach zu fragen hiess, den Aufrufer um eine Luege zu bitten.
  Jetzt `Table.Content` (Inhalt) und `Table : Table.Content` (plus Position).
- **language `TranslateHistoryEntry.time`** -- `history.push` stempelt selbst
  (`entry.time = entry.time or os.time()`), alle vier Aufrufer verlassen sich
  darauf.
- **pickers `Smart.Item._rank`** -- wird von `score.rank` nachtraeglich gesetzt;
  ein unrangiertes Item ist ein legaler Zwischenzustand.
- **dap.nvim trug eine Unterdrueckung, die einen falschen Typ verdeckte.**
  `config.setup` hatte ein pauschales `---@diagnostic disable: missing-fields`
  ueber dem Merge. Mit der richtigen Annotation ist beides weg.
- **nvim-config `Lib.Case.BlueprintNode.body`** -- laut eigener Doku nur
  relevant, wenn `template` fehlt; ein `dir`-Knoten hat keines von beidem. Und
  `ui.open_node` nahm einen vollen Blueprint-Knoten, liest davon aber genau
  `key` und `path`; `open_summary` uebergibt entsprechend ein Paar, das gar kein
  Blueprint-Eintrag ist. Jetzt `Lib.Case.NodeRef`.

---

#### Was Pflicht blieb, und warum

Nicht jedes Feld gehoert optional. Belegt statt vermutet:

- **`Pickers.Collection.name` und `.dir`** -- `config.apply` verwirft jeden
  Eintrag ohne sie und sagt das auch ("name+dir required"). Der eine Test, der
  einen namenlosen Eintrag uebergibt, ist jetzt als absichtlich ungueltig
  markiert statt typkonform gemacht.
- **`GHStats`**: vier Felder in `SetupOptions` und zwei in `DashboardConfig`
  sind nach dem Merge garantiert -- deshalb `GHStats.Config` /
  `GHStats.Dashboard.Resolved` fuer `DEFAULTS` und `config.get()`, nicht
  einfach alles optional.
- **`OpenNvim`**: dasselbe umgekehrt entdeckt -- erst als die Felder optional
  waren, meldete die *nvim-Config* einen `param-type-mismatch`, weil sie
  `cfg.default_browser` direkt weiterreicht. `OpenNvim.Config.Resolved` fuer
  `config.get()` loest das an der richtigen Stelle.

---

#### Unterdrueckt, mit Begruendung im Code

Nur zwei Sorten, und beide stehen als Satz an der Stelle:

1. **Upstream-Metas, die zu viel verlangen.** luvs `uv.spawn` deklariert
   *jede* Option als Pflicht (cwd, env, uid, gid, verbatim, detached, hide) --
   lib.nvim, pdfport, mdview. Neovims `vim.api.keyset.command_info` als
   Optionstyp von `nvim_buf_get_commands` (markdown), `lsp.CodeActionContext`
   ohne `diagnostics` (lsp.nvim, java und astro), `vim.lsp.start.Opts` mit
   `cmd` (lsp.nvim, documentation).
2. **Test-Doubles und absichtlich ungueltige Eingaben.** Ein Stub implementiert,
   was der Test aufruft -- ein vollstaendiger `FiletreeAdapter` in einem Unit
   Test ist Rauschen, keine Abdeckung. Und wo ein Test prueft, dass ein
   kaputter Wert abgewiesen wird (spotlights malformed StoredItems, emojis'
   `mode = "nonsense"`, runtime-analysis' Kandidat ohne `fn`), ist die Warnung
   *korrekt* und der Test auch.

---

#### Werkzeug

Drei kleine Skripte, im Scratchpad, wiederverwendbar fuer die naechsten Cluster:

- `scan.sh <repo> <out.json>` -- LuaLS-Check eines Repos mit der Cross-Repo-
  Bibliothek aller *anderen* Repos, plus Kurzauswertung nach Regel.
- `optional.py <Klasse...>` -- macht `@field`-Eintraege der genannten Klassen
  optional, **aber nur die, die LuaLS ueberhaupt als Pflicht zaehlt**: ein Feld,
  dessen Typ schon `|nil` oder `?` traegt, bleibt unangetastet. Richtet die
  Typspalte danach neu aus.
- `mkopts.py <typesfile> <Klasse...> --write` -- erzeugt die `*Opts`-Spiegel-
  familie samt Umbiegen verschachtelter Typen.

**Zwei Fallen, die dabei Zeit gekostet haben:** ein Feld mit Typ `boolean?`
zaehlt fuer LuaLS *nicht* als Pflicht -- ein zusaetzliches `?` am Namen ist
Rauschen. Und `stylua --check` bricht unter Windows bei vielen Diffs mit
`fatal runtime error: I/O error` ab; Ausgabe in eine Datei umlenken.

---

### `lib.nvim.ui.list` -- eine Listen-Senke statt vierzehn

*(war: Diagnostics-Report Abschnitt 9, der delegierbare Teil des
`<leader>wq`-Roadmap-Punkts)*

Neues Modul `lib.nvim/lua/lib/nvim/ui/list/` (`set`, `qf`, `loc`), plus
Spec, README und API-Doku. Alle 20 Aufrufstellen in 12 Repos sind
umgestellt. Gegenprobe danach: in ganz `C:/repos` gibt es unter `lua/` noch
**genau eine** `setqflist`-Zeile, und die steht im Modul selbst.

**Der Report hat die falsche Vorlage benannt.** Er schlug vor, die
`wq`-Logik aus `lsp.nvim/lua/lsp/diagnostics/{quickfix,loclist}.lua` zu
heben. Beim Hinsehen war das die einzige Stelle, die *nicht* passt: die
arbeitet auf `vim.diagnostic.setqflist` -- andere API, eigene
Severity-Behandlung, und eine Signatur, die sich zwischen Neovim 0.10 und
0.11 geaendert hat (lsp.nvim traegt dafuer einen eigenen Arity-Sniffer).
Die anderen 20 Stellen bauen `vim.fn.setqflist`-Items aus eigenen Daten.
Gemeinsam ist ihnen nur der letzte Schritt -- und genau der ist gewandert.
lsp.nvim blieb unangetastet.

**Was die 20 Stellen unterschiedlich machten, ohne dass es jemand
entschieden haette:**

- **Stack-Semantik.** `setqflist(items, "r")` ersetzt die Liste, die der
  Nutzer gerade offen hat; `setqflist({}, " ", {...})` legt eine neue an und
  laesst `:colder` einen Weg zurueck. Fuenf Repos machten das eine, sieben
  das andere, und an keiner Aufrufstelle liest sich das wie eine
  Entscheidung. Jetzt ist `" "` der Default und `"r"` etwas, das ein Aufrufer
  anfordert -- richtig genau dann, wenn er *seine eigene* Liste aktualisiert
  (language.nvims Spell-Refresh, insights' Konflikt-Rescan).
- **Der Titel als zweiter Aufruf.** Die `"r"`-Form kann keinen Titel tragen.
  Deshalb steht in fuenf Repos direkt dahinter ein
  `setqflist({}, "a", { title = ... })` -- ein Append von nichts, nur um
  einen String anzuhaengen. Ein Aufruf macht jetzt beides.
- **Fokus.** `:copen` zieht den Cursor in die Liste. Nur spotlight.nvim gibt
  ihn bewusst zurueck (die gefilterten Zeilen will man *neben* dem Log
  lesen). Der Default bleibt deshalb `"list"` -- ein gemeinsames Modul, das
  elf Plugins still den Cursor woanders hinsetzt, waere schlimmer als die
  Uneinheitlichkeit.
- **Der leere Fall.** `open = "auto"` setzt die Liste trotzdem, oeffnet aber
  kein Fenster auf nichts. Das ist wichtig, weil "keine Treffer" sonst die
  Treffer von gestern stehen laesst, als waeren sie aktuell.
- **Der qf/loc-Zweig.** diff.nvim und replacer.nvim schrieben denselben
  if/else zweimal, obwohl es ein Flag ist. `loclist = <bool|winid>` macht
  daraus einen Wert.

**Nicht mitgewandert, bewusst:** spotlights `max_entries`-Trunkierung (der
Cap greift *waehrend* des Scans, nicht danach -- das muss im Scanner
bleiben) und Filtern/Formatieren/Navigieren.

**Aufwandsehrlichkeit:** Der Gewinn ist Konsistenz, nicht Zeilenzahl. Pro
Aufrufstelle fallen 2-5 Zeilen weg; documentation.nvim war mit 12 Stellen
das groesste Einzelstueck (58 rein, 67 raus). Der eigentliche Wert liegt
darin, dass Stack, Fokus und Leerfall jetzt an einer Stelle entschieden
werden.

Commits: lib.nvim `2fdfcb7`, dann je ein `refactor(qf)`-Commit in
insights, language, emojis, filetree, markdown, replacer, diff, debugging,
runtime-analysis, spotlight, documentation. Alle Test-Suites der
betroffenen Repos laufen gruen (filetree 394, spotlight 453, replacer 188,
lib.nvim vollstaendig).

---

### mdview.nvim formatiert jetzt wie die anderen 30 Repos

*(war: Diagnostics-Report Abschnitt 6, "Zwei Auffaelligkeiten am Rand", Punkt 1
und 2)*

`mdview.nvim/stylua.toml` stand als **einziges** der 31 Repos auf
`indent_type = "Tabs"` mit `indent_width = 4`; alle anderen fahren
`Spaces` / `2`. Umgestellt und das Repo einmal durchformatiert.

Interessant daran:

- **Der Diff ist gross, die Aenderung ist es nicht.** 89 Dateien, ~5600 Zeilen
  -- aber `git diff -w` schrumpft das auf 13 Dateien. Die 13 sind kein
  Sonderfall, sondern eine Folge: mit 2 statt 4 Spalten Einrueckung passen
  Aufrufe wieder in die 120-Spalten-Grenze, die stylua vorher umbrechen musste.
  Semantisch aendert sich nichts.
- **stylua fasst Kommentare nicht an.** Nach dem Lauf war noch genau eine Datei
  tab-eingerueckt: `lua/mdview/helper/normalize.lua`, drei Zeilen im
  `--[[ USAGE: ]]`-Block. Beispielcode in Kommentaren faellt durch jedes
  Formatter-Raster -- wer eine Repo-Konvention umstellt, muss die Kommentare
  separat pruefen (`grep -rlP '^\t' --include='*.lua'`).
- **`stylua --check` stirbt unter Windows an der eigenen Ausgabe.** Bei
  ~90 Diffs bricht der Prozess mit `fatal runtime error: I/O error: operation
  failed to complete synchronously` ab -- ein Pipe-Problem, kein Formatfehler.
  Ausgabe in eine Datei umlenken, dann laeuft es durch.
- Gegenprobe statt Vertrauen: alle 95 Lua-Dateien nach dem Lauf per
  `loadfile()` geprueft, 0 Fehler. `column_width = 120`, `quote_style` und
  `call_parentheses` blieben unveraendert -- angeglichen wurde nur die
  Einrueckung.

Commit: `140dcd2 style: switch stylua to spaces/2, matching the other 30 repos`.

Damit ist auch `docs/templates/usercmds.lua` erledigt, eine der vier
stylua-abweichenden Dateien aus dem Report. Offen bleiben drei:
`emojis.nvim/plugin/{emojis,emojis_autodoc}.lua` und
`gopath.nvim/scripts/ci/headless_tests.lua`.

---

### open.nvim: uebrig gebliebener Claude-Worktree abgeraeumt

*(war: Diagnostics-Report Abschnitt 7, Nebenbefunde, Punkt 1 und 3)*

`.claude/worktrees/cool-benz-a3f6a1` samt Branch `claude/cool-benz-a3f6a1`
hatte den Cleanup vom 2026-08-26 ueberlebt. Entfernt, zusammen mit
`feat/registry-driven-keymaps`.

Vor dem Loeschen geprueft, ob dort etwas liegt, das `main` nicht hat -- das war
der eigentliche Punkt:

- Arbeitsverzeichnis sauber, auch `--ignored` leer. Nichts Uncommittetes.
- Zwei Commits, die `main` nicht kennt, **beide inhaltlich ueberholt**:
  `854e5c6` legt eine `.gitattributes` mit `* text=auto eol=lf` an -- `main`
  traegt seit der repoweiten Line-Ending-Umstellung eine echte Obermenge davon
  (mit `binary`-Regeln). `05bf222` formatiert `check_office_open` in
  `lua/open/health.lua` -- `main` hat exakt dieselbe Formatierung bereits,
  `stylua --check lua/` steht dort auf 0.
- `feat/registry-driven-keymaps` war 0 Commits vor `main`, also vollstaendig
  gemergt.

Die Lehre fuer den naechsten Fund dieser Art: `git log main..<branch>` allein
sagt nur, *dass* etwas fehlt, nicht *ob es fehlt* -- `main` kann denselben
Inhalt ueber einen anderen Commit tragen. Erst der Blick in den Diff der
einzelnen Commits gegen den heutigen Stand entscheidet.

`.claude/` ist dort jetzt gitignored, damit der naechste Worktree nicht wieder
als untracked Repo-Inhalt auftaucht (wie es die nvim-Config schon macht).
Kein LSP-Effekt in beide Richtungen: LuaLS indiziert Punkt-Verzeichnisse
ohnehin nicht.

Commit: `8e235b3 chore: gitignore .claude/ and drop the leftover Claude worktree`.

---
