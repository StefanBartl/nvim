# Diagnostics -- Erledigt

Aus `docs/ROADMAP/personal/All/Diagnostics.md` herausgenommene Punkte, sobald
sie abgeschlossen sind. Neueste zuerst. Der Report dort bleibt die Quelle fuer
alles, was noch offen ist.

---

## Table of content

  - [2026-09-01](#2026-09-01)
    - [neotree-fs-refactor.nvim -- ausserhalb des Umfangs, versehentlich bearbeitet](#neotree-fs-refactornvim-ausserhalb-des-umfangs-versehentlich-bearbeitet)
    - [Die Sechser-Runde -- fuenf Repos, 126 auf 0](#die-sechser-runde-fuenf-repos-126-auf-0)
      - [fileops: zwei Tastenkuerzel, die nichts gesagt haben](#fileops-zwei-tastenkuerzel-die-nichts-gesagt-haben)
      - [gopath: ein Ergebnis, das gelogen hat](#gopath-ein-ergebnis-das-gelogen-hat)
      - [buffer-ctx: eine API, die seit 0.11 anders heisst](#buffer-ctx-eine-api-die-seit-011-anders-heisst)
      - [Der Rest, und was sich wiederholt](#der-rest-und-was-sich-wiederholt)
    - [runtime-analysis.nvim -- 109 auf 0, und die Hinweise, die niemand sah](#runtime-analysisnvim-109-auf-0-und-die-hinweise-die-niemand-sah)
      - [Derselbe Fehler wie in documentation.nvim](#derselbe-fehler-wie-in-documentationnvim)
      - [`uv_tcp_t` ist kein Typ](#uv_tcp_t-ist-kein-typ)
      - [Zwei Zeilen, die nie geschrieben wurden](#zwei-zeilen-die-nie-geschrieben-wurden)
      - [Der Rest -- zehn kleine Ursachen](#der-rest-zehn-kleine-ursachen)
    - [filetree.nvim -- 80 auf 0, und vier Dinge, die nie liefen](#filetreenvim-80-auf-0-und-vier-dinge-die-nie-liefen)
      - [Der Einstieg war der vorgeschlagene, und er trug 24](#der-einstieg-war-der-vorgeschlagene-und-er-trug-24)
      - [Vier Stellen, die nie gelaufen sein koennen](#vier-stellen-die-nie-gelaufen-sein-koennen)
      - [Cluster E, filetree.nvims ganzer Anteil](#cluster-e-filetreenvims-ganzer-anteil)
      - [Der Rest -- neun kleine Ursachen](#der-rest-neun-kleine-ursachen)
      - [Zweimal die Regel angewandt, die es dafuer gibt](#zweimal-die-regel-angewandt-die-es-dafuer-gibt)
      - [Unterdrueckt, mit Begruendung](#unterdrueckt-mit-begruendung)
      - [Was uebrig ist](#was-uebrig-ist)
    - [filetree.nvim -- 161 auf 80, und fuenf Features, die nie rendern](#filetreenvim-161-auf-80-und-fuenf-features-die-nie-rendern)
      - [`get_node_at_line` ruft niemand auf, weil es niemand hat](#get_node_at_line-ruft-niemand-auf-weil-es-niemand-hat)
      - [Ein Wort: `get_root` gegen `get_root_path`](#ein-wort-get_root-gegen-get_root_path)
      - [Deklariert, nicht implementiert -- und das steht jetzt da](#deklariert-nicht-implementiert-und-das-steht-jetzt-da)
      - [Der Rest](#der-rest)
      - [Was uebrig ist: dieselbe Form wie in lsp.nvim](#was-uebrig-ist-dieselbe-form-wie-in-lspnvim)
    - [lsp.nvim -- 172 auf 35, und die Typen, die es hier nie gab](#lspnvim-172-auf-35-und-die-typen-die-es-hier-nie-gab)
      - [Ein echter Fehler: `:LspLuaLsReload` hat den Server nie benachrichtigt](#ein-echter-fehler-lsplualsreload-hat-den-server-nie-benachrichtigt)
      - [Die drei Typdateien](#die-drei-typdateien)
      - [`LspNvim.Config` sagte das eine und deklarierte das andere](#lspnvimconfig-sagte-das-eine-und-deklarierte-das-andere)
      - [Eine Vermutung, die beim Hinsehen gefallen ist](#eine-vermutung-die-beim-hinsehen-gefallen-ist)
      - [Der Rest](#der-rest-1)
      - [Was uebrig ist: 35, und sie sind einzeln](#was-uebrig-ist-35-und-sie-sind-einzeln)
    - [Die Messgrundlage, zweiter Teil -- luassert, und 180 Befunde, die keinem Repo gehoerten](#die-messgrundlage-zweiter-teil-luassert-und-180-befunde-die-keinem-repo-gehoerten)
      - [Die Hypothese, die die Messung widerlegt hat](#die-hypothese-die-die-messung-widerlegt-hat)
      - [Was es wirklich war: `relatedInformation` fragen statt raten](#was-es-wirklich-war-relatedinformation-fragen-statt-raten)
      - [Der Schluessel war da, er kam nur nirgends an](#der-schluessel-war-da-er-kam-nur-nirgends-an)
      - [Gemessen](#gemessen)
      - [Die +36 sind der eigentliche Ertrag](#die-36-sind-der-eigentliche-ertrag)
      - [Was daraus offen bleibt](#was-daraus-offen-bleibt)
  - [2026-08-31](#2026-08-31)
    - [lib.nvim fertig -- der zweite vertikale Durchgang](#libnvim-fertig-der-zweite-vertikale-durchgang)
      - [Zwei echte Fehler](#zwei-echte-fehler)
      - [Zwei Annotationen, die etwas anderes beschrieben als der Code tut](#zwei-annotationen-die-etwas-anderes-beschrieben-als-der-code-tut)
      - [Das Muster, das ein Drittel erklaert: der Guard sitzt auf dem Feld](#das-muster-das-ein-drittel-erklaert-der-guard-sitzt-auf-dem-feld)
      - [Rueckgaben, die es ganz oder gar nicht gibt](#rueckgaben-die-es-ganz-oder-gar-nicht-gibt)
      - [libuv antwortet mit nil, statt zu werfen](#libuv-antwortet-mit-nil-statt-zu-werfen)
      - [Cluster E, lib.nvims Anteil](#cluster-e-libnvims-anteil)
      - [Typen, die etwas anderes beschrieben haben](#typen-die-etwas-anderes-beschrieben-haben)
      - [Zwei Namen, die der nvim-Config gehoeren](#zwei-namen-die-der-nvim-config-gehoeren)
      - [Die Klammer, die eine Signatur rettet](#die-klammer-die-eine-signatur-rettet)
      - [Unterdrueckt, mit der Begruendung daneben](#unterdrueckt-mit-der-begruendung-daneben)
      - [Was offen bleibt: eine Zeile, und sie gehoert nach lsp.nvim](#was-offen-bleibt-eine-zeile-und-sie-gehoert-nach-lspnvim)
      - [Gemessen](#gemessen-1)
    - [Sechs Repos pruefen wieder gegen Neovims Typen](#sechs-repos-pruefen-wieder-gegen-neovims-typen)
      - [Die Zahl steigt, und das ist der Zweck](#die-zahl-steigt-und-das-ist-der-zweck)
      - [Eine Hypothese, die die Messung widerlegt hat](#eine-hypothese-die-die-messung-widerlegt-hat)
      - [Nebenbefund: das Werkzeug dumpt die falsche Funktion](#nebenbefund-das-werkzeug-dumpt-die-falsche-funktion)
    - [Cluster F: `inject-field` in lib.nvim -- und die `missing-fields`-Reste daneben](#cluster-f-inject-field-in-libnvim-und-die-missing-fields-reste-daneben)
      - [Die Zombie-Klassen, und was sie verdeckt haben](#die-zombie-klassen-und-was-sie-verdeckt-haben)
      - [Die Annotation stand nur auf der falschen Zeile](#die-annotation-stand-nur-auf-der-falschen-zeile)
      - [Ein Typ, der nicht bloss zu frueh, sondern falsch war](#ein-typ-der-nicht-bloss-zu-frueh-sondern-falsch-war)
      - [Neun Schluessel, die es nur unter einer Strategie gibt](#neun-schluessel-die-es-nur-unter-einer-strategie-gibt)
      - [Der Alias, der eine echte Luecke zugedeckt hat](#der-alias-der-eine-echte-luecke-zugedeckt-hat)
      - [Gemessen](#gemessen-2)
    - [documentation.nvim: die restlichen 155 -- der erste vertikale Durchgang](#documentationnvim-die-restlichen-155-der-erste-vertikale-durchgang)
      - [Das Muster, das die Haelfte erklaert: der Guard sitzt auf einem Feld](#das-muster-das-die-haelfte-erklaert-der-guard-sitzt-auf-einem-feld)
      - [Die Kinder eines Treesitter-Knotens](#die-kinder-eines-treesitter-knotens)
      - [Ein echter Fehler: zwoelf Advice-Listen, die nie jemand gesehen hat](#ein-echter-fehler-zwoelf-advice-listen-die-nie-jemand-gesehen-hat)
      - [Zwei verwaiste Doc-Bloecke](#zwei-verwaiste-doc-bloecke)
      - [Annotationen, die schlicht falsch waren](#annotationen-die-schlicht-falsch-waren)
      - [Der Overload, der die Zahl verschlechtert hat](#der-overload-der-die-zahl-verschlechtert-hat)
      - [Unterdrueckt, mit der Begruendung daneben](#unterdrueckt-mit-der-begruendung-daneben-1)
      - [Gemessen](#gemessen-3)
    - [Cluster D: `userdata` statt `TSNode` -- documentation.nvim](#cluster-d-userdata-statt-tsnode-documentationnvim)
      - [Warum `userdata` der teuerste Annotationsfehler ist](#warum-userdata-der-teuerste-annotationsfehler-ist)
      - [Was gemacht wurde -- 154 Annotationen in 18 Dateien](#was-gemacht-wurde-154-annotationen-in-18-dateien)
      - [Zwei Nachbarn derselben Klasse](#zwei-nachbarn-derselben-klasse)
      - [Ergebnis: 383 -> 155](#ergebnis-383-155)
      - [Was von den `undefined-field` uebrig ist](#was-von-den-undefined-field-uebrig-ist)
    - [Cluster B: `need-check-nil` in Tests -- unterdrueckt, nicht auszementiert](#cluster-b-need-check-nil-in-tests-unterdrueckt-nicht-auszementiert)
      - [Der Befund, der die Umsetzung geaendert hat](#der-befund-der-die-umsetzung-geaendert-hat)
      - [Was gemacht wurde -- 19 Repos, 93 Dateien](#was-gemacht-wurde-19-repos-93-dateien)
      - [Ergebnis: 3204 -> 2289](#ergebnis-3204-2289)
      - [Gegenprobe mit dem festen Harness](#gegenprobe-mit-dem-festen-harness)
      - [Zwei Sachen, die beim Messen aufgefallen sind](#zwei-sachen-die-beim-messen-aufgefallen-sind)
      - [Die Messumgebung liegt jetzt fest im Repo](#die-messumgebung-liegt-jetzt-fest-im-repo)
    - [Cluster A: der `assert`-Typ -- und warum der erste Anlauf ins Leere lief](#cluster-a-der-assert-typ-und-warum-der-erste-anlauf-ins-leere-lief)
      - [Die Ursache, jetzt gemessen statt vermutet](#die-ursache-jetzt-gemessen-statt-vermutet)
      - [Die zweite Ursache: der Workspace als seine eigene Library](#die-zweite-ursache-der-workspace-als-seine-eigene-library)
      - [Was gemacht wurde](#was-gemacht-wurde)
      - [Ergebnis: 6344 -> 3204](#ergebnis-6344-3204)
      - [Was absichtlich unangetastet blieb](#was-absichtlich-unangetastet-blieb)
      - [Wie gemessen wurde](#wie-gemessen-wurde)
  - [2026-08-29](#2026-08-29)
    - [Cluster C: `missing-fields` -- 518 auf 21, ueber alle 31 Plugins plus Config](#cluster-c-missing-fields-518-auf-21-ueber-alle-31-plugins-plus-config)
      - [Der Fix war nicht ueberall derselbe -- und das liess sich nur messen](#der-fix-war-nicht-ueberall-derselbe-und-das-liess-sich-nur-messen)
      - [Was dabei an echten Fehlern herausfiel](#was-dabei-an-echten-fehlern-herausfiel)
      - [Was Pflicht blieb, und warum](#was-pflicht-blieb-und-warum)
      - [Unterdrueckt, mit Begruendung im Code](#unterdrueckt-mit-begruendung-im-code)
      - [Werkzeug](#werkzeug)
    - [`lib.nvim.ui.list` -- eine Listen-Senke statt vierzehn](#libnvimuilist-eine-listen-senke-statt-vierzehn)
    - [mdview.nvim formatiert jetzt wie die anderen 30 Repos](#mdviewnvim-formatiert-jetzt-wie-die-anderen-30-repos)
    - [open.nvim: uebrig gebliebener Claude-Worktree abgeraeumt](#opennvim-uebrig-gebliebener-claude-worktree-abgeraeumt)

---

## 2026-09-01

---

### neotree-fs-refactor.nvim -- ausserhalb des Umfangs, versehentlich bearbeitet

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 12)*

> **Dieses Repo gehoert nicht dazu.** Es steht nicht auf der Plugin-Liste in
> Abschnitt 0 des Reports; es hat nur eine `.luarc.json` und wurde deshalb vom
> Scan als Workspace gefuehrt. Der Durchgang unten ist gemacht und gepusht,
> zaehlt aber gegen keine Summe -- und der Offen-Punkt, der ihn ausgeloest hat,
> haette gar nicht dort stehen duerfen. Die Liste in Abschnitt 0 steht seit
> dem 2026-09-01 da, damit das nicht wieder passiert.

Das Repo setzte weiterhin `workspace.library` selbst -- `${3rd}/luv/library`
und `$VIMRUNTIME/lua`, sonst nichts. Der Schluessel **ersetzt** die Injektion
von lsp.nvim, er ergaenzt sie nicht, also war hier jeder Plugin-Typ und auch
luassert unsichtbar. Die 0, die der Report fuer dieses Repo fuehrte, hiess
„nichts wurde geprueft", nicht „nichts ist kaputt". Dieselbe Korrektur wie bei
den sechs Repos im August; dieses war das uebrig gebliebene.

Auf der korrigierten Grundlage: **4**, und beide Ursachen sind Namenskollisionen.

- `LogLevel` kollidiert mit dem Alias, den lib.nvims notify-Modul
  veroeffentlicht -- eine andere Sache (eine Zahl oder ein String, nicht diese
  vier Werte). Namespaced wie die uebrigen Typen des Repos.
- `tests/@types.lua` deklariert eine eigene `Luassert`-Klasse. plenary.nvim
  liefert eine oeffentliche mit denselben drei Container-Feldern, die Kopie ist
  also eine Dopplung und keine Ergaenzung. Sie heisst jetzt wie das, was sie
  ist: ein privater Platzhalter.

**4 -> 0**, `worse: nothing`. Beides sind Annotationen -- ausserhalb von
Kommentaren hat sich nichts geaendert, und das Plugin laedt unveraendert.

Zwei Nebenbefunde, die dabei aufgefallen sind und nicht angefasst wurden:

- **`stylua` ohne `stylua.toml`.** 30 der 32 Repos haben eine;
  `neotree-fs-refactor.nvim` und `learn-cli.nvim` nicht. Ohne Konfiguration
  formatiert stylua mit **Tabs**, die Dateien beider Repos sind aber
  zweispaltig eingerueckt -- ein `stylua .` dort schreibt also das ganze Repo
  um. Beim ersten Versuch genau das passiert und wieder verworfen.
- **`tests/run_tests.sh` meldet „All tests passed" auch dann**, wenn
  `plenary.test_harness` gar nicht geladen werden konnte: nvim beendet sich
  mit 0, und `set -e` sieht keinen Fehler. Die Suite lief hier deshalb nicht --
  `PlenaryBustedDirectory` startet Kind-Prozesse und haengt auf dieser
  Windows-Maschine headless. Nichts in dem Commit ist zur Laufzeit erreichbar,
  darum wurde er trotzdem gemacht.

---

### Die Sechser-Runde -- fuenf Repos, 126 auf 0

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 3)*

`buffer-ctx` (5), `sessions` (6), `emojis` (13), `fileops` (35) und `gopath`
(67): die Repos, deren `.luarc.json` im August die Messgrundlage bekam und die
danach nie durchgegangen wurden. **126 -> 0** ueber alle fuenf,
`worse: nothing`, jede Suite gruen, stylua sauber. Fuenf Commits, einer pro
Repo.

Ein Muster zieht sich durch: **die interessanten Befunde sind Aufrufe, die nie
funktioniert haben koennen** -- dieselbe Familie wie `get_node_at_line` und
`node.line` in filetree.nvim.

---

#### fileops: zwei Tastenkuerzel, die nichts gesagt haben

`<leader>fR` (bulk rename) reichte das Paar `(renamed, err)` von
`bulk.execute` an `notify.report(ok, msg)` weiter. Die Zahl ging als `ok`
hinein, `nil` als Nachricht -- und `report` gibt nichts aus, wenn die Nachricht
nil ist. Das Kuerzel meldete also weder „12 Dateien umbenannt" noch, woran es
gescheitert war; der `:File bulk`-Pfad direkt daneben meldete beides. Jetzt
mit demselben Wortlaut.

Das lockinfo-Kuerzel rief `ops.file.diagnose_lock()` ohne Argumente.
`diagnose_lock` ist asynchron und nimmt den Callback als **erstes, notwendiges**
Argument -- die Taste warf also, statt etwas zu melden. Sie geht jetzt ueber
den oeffentlichen Einstiegspunkt, der den notify-Callback mitbringt.

Und `cfg.bulk` ist kein Konfigurationsabschnitt und war nie einer: beide
Lesestellen im bulk-Kuerzel ergaben immer `{}`. Genau das steht jetzt da, damit
es nicht mehr aussieht wie eine Einstellung, die jemand setzen koennte.

Dazu zwei Annotationen, die nicht geparst haben -- und alles, was darunter
stand:

- `on_before_delete?: fun(path: string): boolean|nil` **innerhalb** eines
  Tabellen-Typs verschluckt den Rest des Literals. LuaLS bleibt bei
  „`}` expected" stehen, und `refresh_explorers`, `git_aware`,
  `git_warn_only`, `git_cmd` und `retry` lesen sich danach als undefinierte
  Felder. Klammern drumherum.
- `---@return string[]  Absolute, canonicalized paths.` liest die Beschreibung
  als zweiten Rueckgabetyp, also musste `list_files` zwei Werte liefern. Der
  Rueckgabewert hat jetzt einen Namen, damit die Prosa Prosa bleibt.

---

#### gopath: ein Ergebnis, das gelogen hat

`make_result` versprach eine Tabelle fuer einen `path`, den `pick_best` bei
leerer Liste als nil beantwortet. Es baute sie trotzdem: `path = nil` neben
`exists = true` -- ein Ergebnis, das behauptet, an nirgendwo liege eine Datei.
Es gibt jetzt nil zurueck, wofuer jeder Aufrufer ohnehin einen Zweig hat. Sechs
Befunde, eine echte Luege.

Zwei Annotationen trugen den groessten Teil des Rests. `---@return
GopathResult|nil, string|nil  result, error` **in einer Zeile** sind fuer LuaLS
nicht zwei Rueckgabewerte -- es las drei, also fehlte elf `return a, b`-Zeilen
in `resolve.lua` je einer, und `error` las sich als undefinierter Typ. Und
`GopathResolveOpts` war zweimal deklariert, einmal in `resolve.lua` und einmal
in `@types/resolvers.lua`.

`providers.treesitter.node_at_cursor` gab `userdata|nil` zurueck -- genau der
Befund, den documentation.nvims eigener Durchgang hatte. Der Typ heisst
`TSNode`, und ohne ihn hatte `node:type()` keine Methode zum Auflaesen.

---

#### buffer-ctx: eine API, die seit 0.11 anders heisst

`get_char_at_pos` rief `vim.str_utfindex` und `vim.str_byteindex` in der
Zwei-Argument-Form von vor 0.11. Seit 0.11 nehmen beide an zweiter Stelle eine
**Kodierung** -- der Byte-Offset landete also dort, wo `"utf-8"` hingehoert.
`vim.str_utf_end` beantwortet die eigentliche Frage (wie viele Bytes bis zum
Ende der Sequenz, zu der dieses Byte gehoert) in einem Aufruf, ab 0.9, ohne
Kodierungsargument. Der `if not char_idx`-Guard, den es ersetzt, war tot:
`str_utfindex` wirft bei einem Index ausserhalb des Strings, statt nil zu
liefern.

---

#### Der Rest, und was sich wiederholt

- **Cluster E, dritte bis fuenfte Wiederholung:** 4 in sessions, 16 in fileops,
  2 in gopath, 1 in emojis (dort lib.nvims Keymap-Modul, eine aufrufbare
  Tabelle -- fuer den Typpruefer kein `function`, auch wenn
  `vim.is_callable` ja sagt).
- **Zwei gestapelte Doc-Bloecke** in `emojis.search.M.run`, ein
  Merge-Ueberbleibsel: `action` und `extra_globs` zweimal deklariert,
  `no_ignore` unter der zweiten Kopie.
- **`AST.parse` gibt `(root, src)` zurueck**, und zwei gopath-Aufrufer prueften
  nur `root` -- elf Aufrufe reichten danach eine Vielleicht-nil-Quelle weiter.
- **Feldverengung traegt nicht in eine frische Lesestelle:**
  `:GopathDebug` pruefte `info.cache_info` und las es danach in ein lokales;
  dreizehn Zeilen lasen sich deshalb als vielleicht-nil. Erst das lokale, dann
  die Pruefung darauf.
- **`LogLevel`** kollidiert auch in gopath mit lib.nvims Alias. Namespaced.

Unterdrueckt, mit Begruendung: `vim.lsp.get_active_clients` in gopaths
health.lua (der Pfad vor 0.10, nur erreichbar wenn `get_clients` fehlt), fuenf
Test-Doubles, und vier absichtlich ungueltige Eingaben, bei denen das
Zurueckweisen genau das ist, was geprueft wird.

---

### runtime-analysis.nvim -- 109 auf 0, und die Hinweise, die niemand sah

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 2)*

Der sechste vertikale Durchgang. **109 -> 0**, `worse: nothing`, alle 25 Specs
gruen, stylua sauber. Das groesste Repo, das seit dem Erstscan unangetastet
war -- und es waren vier Posten mit je einer Ursache statt hundert Einzelfaelle.

---

#### Derselbe Fehler wie in documentation.nvim

`vim.health.info` nimmt eine Nachricht und sonst nichts; `warn` und `error`
sind die, die Hinweise nehmen. Vier `h_info(msg, { ... })`-Aufrufe hier gaben
ein zweites Argument mit, das `:checkhealth` fallen liess: mdviews
Fallback-Notiz, pdfports zwei und die von lib.nvim.progress. Derselbe Wrapper
wie in documentation.nvims `editor/health.lua`, aus demselben Grund.

---

#### `uv_tcp_t` ist kein Typ

Er heisst `uv.uv_tcp_t`. Fuenf Test-Helper annotierten ein Server-Handle mit
dem Namen, der nicht aufloest -- und deshalb las sich jedes `server:close()`
danach als undefiniertes Feld. **Fuenfzehn `close`-Befunde und zehn
Annotationsbefunde waren ein falsches Praefix.** Die Handles selbst sind jetzt
`assert(uv.new_tcp())`: `new_tcp` kann nil liefern, und ein nil-Handle fiel
vorher erst zwei Zeilen spaeter bei `bind` auf.

---

#### Zwei Zeilen, die nie geschrieben wurden

`_cache_opts` und `_snapshot_retention` werden auf jede Telemetrie-Instanz
gesetzt und aus drei Dateien gelesen, und `RA.Telemetry.Instance` deklarierte
keins von beiden. Zwoelf Befunde, ein fehlendes Zeilenpaar.

---

#### Der Rest -- zehn kleine Ursachen

- **Zehn `notify.error(err)`** reichen den zweiten Rueckgabewert eines
  fehlgeschlagenen Aufrufs durch, also ein `string?`. Jeder hat jetzt eine
  Ersatznachricht -- was der Leser auch statt eines leeren Fehler-Popups
  bekommt.
- **`runner`s `(ok, resp)`-Vertrag** -- `resp` ist die Fehlermeldung, wenn
  `ok` falsch ist, und die Antwort, wenn es wahr ist -- stand an zwei Stellen
  in Prosa da und ist jetzt an beiden ein `---@cast`.
- **`flamegraph.svg`** liest `order`, `roots` und `total_ms` und sonst nichts,
  nimmt also `RA.Telemetry.Startup.Drawable` (aus `Startup.Report`
  herausgeloest, das jetzt davon erbt). Ein Aufrufer muss `running` und
  `modules` nicht mehr faelschen fuer eine Funktion, die nie hinsieht.
- **`provenance.inspect`** gab ein zwoelfteiliges Inline-Tabellenliteral
  zurueck, das von `RA.Provenance.Info` abgedriftet war -- `proc_trace` stand
  auf dem Wert und in keinem von beiden.
- **`usage.mode_key`** versprach `string` und lieferte `string|string[]`;
  `record_command` und der Keymap-Wrapper riefen ueber Handles, die ausserhalb
  einer laufenden Sitzung nil sind.
- **`os.date(...)`** ist `string|osdate`; zwei Snapshot-Namen sagen, welches.
- **`inspect`** baut einen Report, indem es `module_id` an einen gelaufenen
  Knoten haengt -- was der Report *ist*: ein `---@cast` statt eines injizierten
  Feldes.
- **`_G.require`** wird vom Startup-Recorder absichtlich ersetzt; das ist der
  ganze Mechanismus, und es ist mit der Begruendung unterdrueckt.
- **Zwei `M.x = local_fn`-Exporte** trugen `---@param`-Zeilen, die an einer
  Zuweisung an nichts andocken. Jetzt `---@type fun(...)`.
- **`export()`s `.pdf`-Zweig** braucht den Callback, den sein eigener Doc-Text
  als notwendig bezeichnet.

Unterdrueckt, mit Begruendung: vier absichtlich ungueltige Eingaben in den
Specs (ein nil-Namespace, eine Nicht-Tabelle als Kandidatenliste, eine nil
Modul-Id, ein Stil ausserhalb des Alias). Zwei Test-Fixtures nehmen `...`, weil
die Aufrufe darunter ihnen Argumente uebergeben.

---

### filetree.nvim -- 80 auf 0, und vier Dinge, die nie liefen

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 1)*

Der fuenfte vertikale Durchgang, und der letzte Rest des Repos. **80 -> 0**,
`worse: nothing`, alle fuenf Suiten gruen (19 + 252 + 15 + 122 + 54 Checks,
0 failed), stylua sauber. Damit ist filetree.nvim das dritte Repo auf Null --
nach documentation.nvim und lib.nvim, und diesmal ohne Sternchen.

---

#### Der Einstieg war der vorgeschlagene, und er trug 24

`FiletreeConfig` markierte alle vierzehn Felder optional, obwohl `setup()`
neun davon aus `config.DEFAULTS` normalisiert. Jeder Leser hinter `setup()`
pruefte damit noch einmal, was `setup()` bereits garantiert hatte. Der Split
ist derselbe wie bei `LspNvim.Config` einen Tag zuvor:

- `FiletreeConfig` -- die **aufgeloeste** Gestalt, wie `config.get()` sie
  zurueckgibt: die neun aus DEFAULTS als Pflichtfelder, die fuenf, die
  niemand fuellt (`keymaps`, `adapter_keymaps`, `command`, `autocmds`,
  `confirmations`), bleiben optional. Das ist die ehrliche Zeile: nicht
  „alles da", sondern „genau das, was DEFAULTS traegt".
- `FiletreeOpts` -- die partielle Gestalt, die ein Aufrufer uebergibt.

Dasselbe fuer `FiletreeCwdModeConfig`/`FiletreeCwdModeOpts`. Dort war die
Wirkung am sichtbarsten: `indicator` als optional zu fuehren machte
`_cfg.indicator` an **fuenf** Stellen innerhalb einer einzigen Funktion
(`badge_text`) zu einem Vielleicht-nil.

Ein Nebenbefund des Splits: `config.get()` gab vor `setup()` `{}` zurueck,
obwohl jedes Feature-Modul es liest, als stuenden die Defaults. Es startet
jetzt auf einer Kopie von DEFAULTS.

Und ein Fehler, den der Split erst erzeugt und dann sichtbar gemacht hat:
`FiletreeCwdModeConfig` liess sich nicht mehr an ein `FiletreeCwdModeOpts?`
zuweisen. Die aufgeloeste Klasse erbt jetzt von der partiellen, was auch die
richtige Aussage ist -- ein aufgeloester Wert *ist* ein zulaessiger Eingabewert.

---

#### Vier Stellen, die nie gelaufen sein koennen

Dieselbe Familie wie `get_node_at_line` im vierten Durchgang: nicht
Annotationen, die hinterherhinken, sondern Code, der auf etwas zeigt, das es
nicht gibt.

- **`find_files`** bewachte sein Reveal mit `_adapter.reveal`. `reveal` ist
  kein Adapter-Member und war nie eines -- die Bedingung war immer falsch.
  `reveal_on_open` steht standardmaessig auf `true` und hat nie etwas
  aufgedeckt. Die Faehigkeit heisst `open_reveal`, und jedes Backend im Repo
  hat sie.
- **`live_search`** las `node.line`. Das Feld heisst `line_number`. Der Guard
  davor (`if not node.path or not node.line then goto continue end`) griff
  also fuer **jeden** Knoten: die Overlay-Suche hat nie etwas hervorgehoben
  und nie etwas abgedunkelt.
- **`preview`s snacks-Backend** rief `snacks.image.open()`. Die Funktion gibt
  es in snacks.nvim nicht (`supports`, `supports_file`, `hover`, `setup` --
  kein `open`). Der Aufruf lief in einem `pcall`, warf bei jedem Bild und fiel
  durch. snacks.image zeichnet einen Bildpuffer, wenn einer angezeigt wird;
  `supports()` ist die oeffentliche Frage danach, und die Datei zu oeffnen ist
  das, was snacks zustaendig macht.
- **`refs`' Provider-Klasse** deklarierte weder `lsp_exempt` noch
  `delete_target` -- die beiden Felder, die der markdown- und der lua-Provider
  setzen und die `refs` liest. Hier war nur die Deklaration unvollstaendig,
  der Code stimmte.

---

#### Cluster E, filetree.nvims ganzer Anteil

Fuenfzehn `pcall(vim.cmd, ...)` sind jetzt Closures. `vim.cmd` ist eine
aufrufbare Tabelle, kein `function` -- dieselbe Form wie in lib.nvim (10) und
lsp.nvim (4). Damit sind von den urspruenglich 60 noch 31 offen, verteilt auf
die uebrigen Repos.

---

#### Der Rest -- neun kleine Ursachen

- **Zehn Debounce-Handles** werden vor `.call()` geprueft. Sie werden in
  `setup()` gebaut; die Aufrufer sind Autocmd-Callbacks, die es ohne `setup()`
  nicht gaebe -- eine Invariante, die LuaLS nicht sehen kann und die ohne
  `setup()` ein echter Laufzeitfehler waere.
- **Fuenf `pcall(require, ...)`-Ergebnisse** pruefen jetzt den Wert statt des
  Flags. Dasselbe Muster wie in lib.nvim, lsp.nvim und im vierten Durchgang,
  hier zum vierten Mal.
- **`FiletreeRootFinder`** war in `cwd_sync` und `path_copy` zweimal von Hand
  deklariert -- eine Kopie von lib.nvims `Lib.Fs.FindRoot`, die inzwischen
  existiert. Beide Kopien sind weg, beide `cast-local-type` damit auch.
- **`_badge` und `_float`**: beide werden im „Fenster hat gewechselt"-Zweig
  gesetzt und danach beschrieben. Ein gescheitertes `attach` verlaesst den
  Zweig aber ohne Segment, also ist die Pruefung danach richtig und nicht nur
  ruhigstellend.
- **`termopen()`** ist seit 0.11 veraltet; `jobstart(cmd, { term = true })`
  tut dasselbe. Der README verspricht 0.8, also steht der alte Aufruf hinter
  einem `has("nvim-0.11")` -- und nur dort unterdrueckt, wo die Veraltung der
  Punkt ist.
- **`pdf_open`s fuenf Keymap-Felder** sagen jetzt `string|false`, weil genau
  das drinsteht: `false` ist im Keymap-Registry die Abschaltung, nicht ein
  falscher Typ. Die Klasse war falsch, nicht der Code.
- **`tree_integrity`** liest nuis internen Knoten-Speicher. nui liefert keine
  Annotationen, also traegt der Speicher jetzt eine eigene Klasse
  (`FiletreeNuiNodeStore`) mit den zwei Feldern, die dieses Feature begeht --
  statt als nacktes `table` gelesen zu werden, an dem `root_ids` dann
  undefiniert ist.
- **Zwei `gsub`-Rueckgaben** in Klammern (`gsub` liefert `(str, count)`), ein
  `@return string|nil`, wo `nil` rein und `nil` raus geht, und zwei Guards
  (`python`s `rest`, `ts_js`' `e`), die ihren zweiten Rueckgabewert nicht
  mitgeprueft haben.

---

#### Zweimal die Regel angewandt, die es dafuer gibt

„Kein Fix, der eine Warnung nur verschiebt": der erste Nachher-Lauf stand bei
8 statt 0. Beides waren eigene Verschiebungen -- ein `---@type string?` auf
`dst` in `move`, das sieben neue `param-type-mismatch` erzeugte (jetzt ein
`skip`-Flag statt `dst = nil`), und eine Enum-Verengung in
`create_from_template`, die LuaLS ueber `==` nicht mitgeht (jetzt ein
`---@cast`). Der zweite Lauf stand bei 0.

---

#### Unterdrueckt, mit Begruendung

Eine Stelle: ein absichtlich ungueltiger Scope in `TESTS/cwd_mode.lua`, wo das
Zurueckweisen genau das ist, was geprueft wird. Die fuenf Test-Doubles geben
stattdessen den Boolean zurueck, den ihre Annotation verspricht -- das ist
kein Zugestaendnis an den Linter, sondern die Signatur, die der echte Adapter
auch hat.

---

#### Was uebrig ist

Nichts in diesem Repo. Was aus dem vierten Durchgang stehen blieb, bleibt
stehen: `get_node_at_line` und die drei anderen Adapter-Faehigkeiten sind
deklariert, von keinem Backend implementiert, und fuenf Features warten
darauf. Das ist eine Designfrage und kein Diagnose-Befund -- Offen-Punkt 4 im
Report.

---

### filetree.nvim -- 161 auf 80, und fuenf Features, die nie rendern

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Der vierte vertikale Durchgang. **161 -> 80**, `worse: nothing`, alle fuenf
Suiten gruen (19 + 252 + 15 + 122 + 54 Checks, 0 failed), stylua sauber.

`undefined-field` war mit 60 der groesste Einzelposten der ganzen Verteilung --
und es war kein Annotationsproblem.

---

#### `get_node_at_line` ruft niemand auf, weil es niemand hat

Fuenf Feature-Module rufen `_adapter.get_node_at_line`. **Kein einziger der
fuenf Adapter implementiert es.** Alle fuenf haben dieselbe Form:

```lua
vim.api.nvim_buf_clear_namespace(bufnr, _ns, 0, -1)
if not _adapter.get_node_at_line then return end   -- immer wahr
```

Also: Namespace leeren, zurueckkehren. Betroffen sind `git_status`,
`lsp_diagnostics`, `copy_move`, `search.filter` und `ui.size_info` -- Git-
Zeichen, Diagnose-Marker und Dateigroessen erscheinen **nie** im Baum. Dreissig
der sechzig Befunde waren dieser eine Aufruf.

Dieselbe Geschichte im selben Feature-Bereich: `org.session` fragt nach
`get_expanded_paths` und `expand_paths`, beide nirgends implementiert -- eine
Session speichert und stellt also keinen Expansionszustand wieder her.

---

#### Ein Wort: `get_root` gegen `get_root_path`

`org.session` schrieb

```lua
local root = _adapter.get_root and _adapter.get_root() or nil
```

Jeder Adapter schreibt die Methode `get_root_path`, und hat das immer getan.
Der kurze Name war also nil, der `and`/`or`-Ausdruck fiel auf `nil` zurueck,
und **jede gespeicherte Session hat `root = nil` aufgezeichnet**. Behoben.

---

#### Deklariert, nicht implementiert -- und das steht jetzt da

Die vier Faehigkeiten (`get_node_at_line`, `get_expanded_paths`,
`expand_paths`, dazu `install_reveal_guard`, das immerhin der neo-tree-Adapter
hat) stehen jetzt im Optional-Abschnitt von `FiletreeAdapter`, mit einem
Vermerk im Kopf: kein Backend hat sie, der aufrufende Code ist geschrieben und
wartet.

**Sie zu implementieren ist ein Feature, kein Diagnose-Fix.** Fuenf Adapter um
eine Zeilen-zu-Knoten-Abbildung zu erweitern ist eine Designfrage (neo-tree
und nvim-tree haben interne Zeilenindizes, oil und netrw parsen ihren eigenen
Puffer), keine Aufraeumarbeit. Das gehoert entschieden, nicht nebenbei
erledigt -- siehe den offenen Punkt im Report.

---

#### Der Rest

- `features.load()` gibt `(ok, mod|nil)` zurueck, und `tree_reset` pruefte
  `ok`, bevor es ein Feld von `mod` las. Der Guard muss auf dem Wert sitzen,
  der danach gelesen wird -- dasselbe Muster wie in lib.nvim und lsp.nvim, hier
  zum dritten Mal.
- Die zwanzig `duplicate-set-field` sind ausnahmslos Test-Doubles: eine
  Stdlib-Funktion, ein `package.loaded`-Eintrag oder eine Plattform-Probe wird
  fuer die Dauer eines Falls ersetzt und direkt danach zurueckgesetzt.
  Unterdrueckt pro Zeile, mit der Begruendung als Kopf-Notiz in jeder der drei
  Dateien statt zwanzigmal wiederholt.
- `file_watcher`s Debounce-Handle ist bis `setup()` nil und wurde ungeprueft
  gelesen. `tree_integrity` laeuft ueber nuis eigenes `root_ids`, das
  upstream keine Annotation traegt.

---

#### Was uebrig ist: dieselbe Form wie in lsp.nvim

80 Befunde, davon `need-check-nil` 33 und `param-type-mismatch` 21. Der
Hauptteil hat eine Ursache, und es ist die, die lsp.nvim gerade hinter sich
hat: `FiletreeCwdModeConfig` und seine Geschwister markieren jedes Feld
optional, obwohl `setup()` sie normalisiert. `cwd_mode` (8) und `config/init`
(5) lesen also garantierte Werte als vielleicht-nil.

Derselbe Split wie bei `LspNvim.Config`: eine aufgeloeste Klasse mit
Pflichtfeldern, eine partielle fuer den Aufrufer. Das ist der naechste Schritt
in diesem Repo.

---

### lsp.nvim -- 172 auf 35, und die Typen, die es hier nie gab

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Der dritte vertikale Durchgang. **172 -> 35**, `worse: nothing`, Suite gruen
(395 Assertions, 0 Failed, 0 Errors), stylua sauber.

Die interessante Haelfte waren Annotationen, die auf Typen zeigten, die es in
diesem Repo nicht gibt. Sie loesten trotzdem auf -- gegen eine Kopie eines
aelteren lsp.nvim, die in einem git-Worktree unter `.claude/` der nvim-Config
lag und auf dem Library-Pfad jedes Workspace stand. `lsp/languages/**` und
`lsp/formatter` wurden also gegen eine Version ihrer selbst geprueft. Mit der
Kopie draussen (siehe den Eintrag darueber) kamen sie als
`undefined-doc-name` heraus.

---

#### Ein echter Fehler: `:LspLuaLsReload` hat den Server nie benachrichtigt

`servers/lua_ls/reload.lua` rief

```lua
client.notify("workspace/didChangeConfiguration", { settings = ... })
```

`notify` ist eine **Methode** -- `Client:notify(method, params)`. Der
Methodenname ging also als `self` hinein, die Params als `method`, und der
Aufruf ist jedes Mal innerhalb von `Client:notify` gescheitert: die
Settings-Tabelle wurde aktualisiert, der Server nie informiert. Zwei Dateien
weiter macht `core/workspace_diagnostics.lua` es zweimal richtig, einmal als
`client:notify(...)` und einmal als `client.notify(client, ...)`.

Gemeldet war das als `missing-parameter` -- "diese Funktion braucht 3
Argumente, bekommt 2". Dritte Regel in dieser Arbeit, die von aussen wie
Kosmetik aussieht und einen kaputten Codepfad verdeckt hat.

---

#### Die drei Typdateien

**`lsp/languages/@types`** deklariert die fuenf
`ConfiguredLangs.Literal.*`-Unions und die zehn `*.Module`-Namen. Alle zehn
Sprachmodule exportieren genau `enable()`, also sind es Aliase auf eine
`ConfiguredLangs.Module` statt zehn Kopien derselben Form. Die Literal-Unions
bleiben literal, weil `enable_all()` aus jedem Eintrag einen `require`-Pfad
baut: ein Tippfehler dort ist ein Modul, das still nie laedt.

**`lsp/formatter/@types`** deklariert `FormatterOptions`, `FormatterState` und
`FormatterApi` -- abgelesen an dem, was `build()` tatsaechlich annimmt,
behaelt und zurueckgibt.

**`@types/vim_lsp.lua` ist geloescht.** Sie deklarierte sieben
`vim.lsp.*`-Klassen als "missing from Neovim's builtin types"; Neovim 0.12
fuehrt alle sieben, also war jedes Feld darin ein Duplikat des echten. Dazu
machten ihre `---@class vim.lsp` und `---@class vim.lsp.buf` die Modultabellen
wieder auf. 30 `duplicate-doc-field`.

---

#### `LspNvim.Config` sagte das eine und deklarierte das andere

Der Klassenkommentar liest sich als "jedes Feld unten ist garantiert vorhanden
und gueltig" -- darunter zwanzig Felder mit `?`. Dasselbe Muster wie
`Composer.DocsOpts` in lib.nvim, nur groesser.

Getrennt: `LspNvim.Config` ist die aufgeloeste Form mit Pflichtfeldern,
`LspNvim.Opts` die partielle, die die beiden `setup()`-Eingaenge nehmen.
`LspNvim.Tools`/`LspNvim.Tool` und `LspNvim.Workspace` tun dasselbe fuer die
zwei verschachtelten Tabellen, die `normalize_switch` beziehungsweise
`normalize_workspace` garantieren und deren Leser sich darauf verlassen.

Und `completion` steht seit dem 2026-08-23 in `DEFAULTS.lua` und stand in
keiner einzigen Klasse -- daher las sich `cfg.completion` an beiden
Aufrufstellen als undefiniertes Feld. Jetzt `LspNvim.CompletionOpts`.

---

#### Eine Vermutung, die beim Hinsehen gefallen ist

Die dreizehn `redundant-parameter` in `TESTS/lsp/completion_spec.lua` sahen
nach der luassert-Luecke aus, die lib.nvims `@types/luassert.lua` beschreibt --
es waren aber gar keine. `with_temp_state` ist als `---@param fn fun()`
annotiert und ruft seinen Callback mit `pcall(fn, fresh, store)`. Ein Blick in
die Funktion statt in die Regel hat das in einer Minute geklaert.

(Die luassert-Luecke gibt es trotzdem: lib.nvim weitet acht Assertion-Namen
auf, lsp.nvim benutzt zusaetzlich `are.equal` 237-mal, `are.same` 97-mal und
`is_string`. Nach der luassert-Zeile in der Injektion fielen davon nur fuenf
`redundant-parameter` weg. Das gehoert nach lib.nvim und steht als
Offen-Punkt.)

---

#### Der Rest

- `has_eslint`/`has_prettier` nehmen laut ihrer eigenen ersten Zeile ein
  `nil`-Root entgegen; die Annotation sagte `string`.
- `usage.load()` gibt die Tabelle jetzt zurueck, statt sie nur in ein Upvalue
  zu schreiben, das kein Aufrufer als gefuellt sehen kann.
- Acht `@param`-Namen hatten den Unterstrich-Praefix des echten Parameters
  nicht mitbekommen (`err` gegen `_err`).
- Vier `pcall(vim.cmd, ...)` sind Closures (Cluster E, lsp.nvims Anteil).
- `handlers.lua` bindet die Payload vor dem Guard statt danach.

Unterdrueckt, mit der Begruendung daneben: acht Stdlib-Doubles in den Specs
(jeweils direkt danach zurueckgesetzt), drei absichtlich kaputte Config-Werte
in `smoke.lua`, und der Zwei-Argument-Zweig von `setloclist`, den zur Laufzeit
ohnehin eine Probe absichert.

---

#### Was uebrig ist: 35, und sie sind einzeln

Keine Regel mehr ueber 12. `param-type-mismatch` 12, `assign-type-mismatch` 7,
je 3 `missing-fields`, `deprecated`, `inject-field`, je 2 `need-check-nil`,
`invisible`, `return-type-mismatch`, 1 `redundant-parameter`.

Zwei Posten lohnen eine eigene Entscheidung:

- **`LspMod.Client` / `LspMod.TextDocumentIdentifier`** in
  `@types/subsystem.lua` sind Parallel-Deklarationen zu Neovims
  `vim.lsp.Client` und `lsp.TextDocumentIdentifier`. Solange `vim_lsp.lua`
  danebenlag, ist das nicht aufgefallen; jetzt kollidieren sie in
  `languages/webdev/typescript.lua` dreimal. Die Frage ist nicht, wie man die
  drei wegannotiert, sondern ob `LspMod.*` ueberhaupt noch etwas beschreibt,
  das Neovim nicht selbst fuehrt.
- **`integrations/trouble.lua`** greift auf
  `vim.treesitter.highlighter._on_win` zu -- privates Upstream-Feld, im Report
  seit dem Erstscan als "bekannt riskant, aber bewusst; gehoert dokumentiert
  statt behoben" vermerkt. Die zwei `invisible` und ein `inject-field` gehoeren
  dorthin.

---

### Die Messgrundlage, zweiter Teil -- luassert, und 180 Befunde, die keinem Repo gehoerten

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Angefangen als Ein-Zeilen-Punkt: `${3rd}/luassert/library` fehlte in
`lsp.nvim`s `build_library.lua`, und deshalb blieb in lib.nvim genau ein
`undefined-doc-name` stehen. Die Zeile ist drin, lib.nvim steht auf **0**, und
lsp.nvim verlor dabei 12 Befunde.

Beim Nachmessen des Rests fiel dann etwas Groesseres auf.

---

#### Die Hypothese, die die Messung widerlegt hat

Zuerst sah es aus wie ein Wiedergaenger von `bb66d37`: `build_library` haengt
ueber `find_type_dirs(root)` und zwei weitere Abschnitte die **eigenen
`@types`-Pfade des Workspace** an die Library -- in lsp.nvims Fall sieben
Eintraege. Ein Workspace, der seine eigene Library ist, wird zweimal gelesen;
genau das hat `bb66d37` fuer die runtimepath-Eintraege behoben und dabei 1085
der 1222 Warnungen der Config erklaert.

Der Ausschluss wurde also verallgemeinert (kein Pfad unterhalb von `root`), die
Library schrumpfte von 44 auf 37 Eintraege -- und die Messung ergab **exakt
null Aenderung**. LuaLS dedupliziert einen Library-Pfad, der innerhalb des
Workspace liegt, offenbar von sich aus. Die Aenderung wurde zurueckgenommen:
was nichts bewirkt, gehoert nicht ins Repo, und wer die Idee spaeter wieder
hat, findet hier, dass sie geprueft ist.

---

#### Was es wirklich war: `relatedInformation` fragen statt raten

Der naechste Schritt war, LuaLS selbst zu fragen, wo die *zweite* Definition
liegt. Die JSON-Ausgabe von `--check` fuehrt sie mit:

```
"message": "Duplicate defined fields `ensure_installing`.",
"relatedInformation": [{ "location": { "uri":
  "file:///c%3A/Users/bartl/AppData/Local/nvim/.claude/worktrees/
   filetree-statusline-modes-c96cc9/lua/lsp/%40types/init.lua" }}]
```

Die nvim-Config haelt **elf git-Worktrees** unter `.claude/worktrees/`, jeder
eine volle Kopie von ihr. Der Config-Root ist fuer jedes Repo ein
Library-Eintrag. Und einer dieser Worktrees stammt aus der Zeit **vor** der
Extraktion von lsp.nvim und traegt noch ein vollstaendiges `lua/lsp/**`.

lua_ls las also eine aeltere Kopie von lsp.nvim neben der echten, und jedes
`@class` darin kollidierte mit sich selbst. Ausgezaehlt ueber alle Befunde mit
`relatedInformation` in einen `.claude`-Worktree:

| Repo | Befunde | davon aus einem `.claude`-Worktree |
|---|---:|---:|
| lsp.nvim | 359 | **180** |
| nvim-config | 128 | 3 |
| lib.nvim | 0 | 0 |

157 `duplicate-doc-field` und 23 `duplicate-set-field`. Die Haelfte des Repos.

---

#### Der Schluessel war da, er kam nur nirgends an

`.claude` steht seit jeher in lib.nvims gemeinsamer Ignore-Liste
(`lib.nvim.fs.ignore.list`), und `lsp.servers.lua_ls.ignore.as_luals_patterns()`
macht daraus 124 Muster fuer `workspace.ignoreDir`. Zwei Stellen haben das
ausgehebelt:

1. **Die Messreihe hat `ignoreDir` nie gesetzt.** `mkcfg.py` modellierte von
   der Injektion nur `library`, `runtime.version`, `diagnostics.globals` und
   `checkThirdParty`. Der Kommentar dort sagte, die uebrigen Defaults wuerden
   von den Repos ohnehin ueberschrieben -- was bei `ignoreDir` gerade der
   Befund ist und nicht die Entwarnung.
2. **`.luarc.json` ersetzt auch diesen Schluessel.** Dieselbe Falle wie bei
   `workspace.library` in Cluster A, nur eine Ebene weiter. lsp.nvims
   `.luarc.json` nannte drei Eintraege -- `.git`, `.deps`, `docs/map` -- und
   warf damit alle 124 weg. Zwei der drei Verzeichnisse existieren in dem Repo
   nicht einmal.

Behoben: `dump_library.lua` holt die Musterliste jetzt genauso aus dem
laufenden nvim wie die Library (`DUMP ignoreDir 124 patterns`), `mkcfg.py`
setzt sie, und lsp.nvims `.luarc.json` nennt den Schluessel nicht mehr.

---

#### Gemessen

| Schritt | lsp.nvim | lib.nvim |
|---|---:|---:|
| Ausgangsstand | 371 | 1 |
| `${3rd}/luassert` | 359 | **0** |
| Workspace-Ausschluss (verworfen) | 359 | 0 |
| `ignoreDir` injiziert | **172** | 0 |

`worse: nothing` in jedem Schritt. lsp.nvims Suite gruen (0 Failed, 0 Errors),
stylua sauber.

Nach Regel, im letzten Schritt:

| Regel | Delta | |
|---|---:|---|
| `duplicate-doc-field` | **-143** | 173 -> 30 |
| `redundant-parameter` | -28 | 43 -> 15 |
| `undefined-field` | -26 | 29 -> 3 |
| `duplicate-set-field` | -21 | 29 -> 8 |
| `duplicate-doc-alias` | -5 | 5 -> 0 |
| `undefined-doc-name` | **+19** | 0 -> 19 |
| `assign-type-mismatch` | +8 | 13 -> 21 |
| `param-type-mismatch` | +5 | 27 -> 32 |
| `inject-field`, `need-check-nil` | +4 | |

---

#### Die +36 sind der eigentliche Ertrag

Wie bei der Library-Korrektur im August ist der Zuwachs kein Rueckschritt --
nur diesmal noch deutlicher, weil die verdeckten Befunde benannt sind:

- `Lsp.Languages.ConfiguredLangs.Go.Module`, `.Lua.Module`, `.C.Module`,
  `.Zig.Module`, `.CSharp.Module`, `.Dart.Module`, `.Java.Module`,
  `.Webdev.Astro.Module` und `.Literal.App`
- `FormatterApi`, `FormatterOptions`, `FormatterState`

Diese Typen werden in lsp.nvim referenziert und sind dort **nirgends
definiert**. Sie loesten die ganze Zeit gegen die veraltete Kopie im Worktree
auf -- also gegen einen Stand von vor der Extraktion, der noch nicht einmal
mehr der Wahrheit entsprechen muss. Das ist der Grund, aus dem sich der
Umweg gelohnt hat: nicht die 180, die verschwinden, sondern die 36, die
sichtbar werden.

---

#### Was daraus offen bleibt

Elf Repos und die Config nennen `workspace.ignoreDir` in ihrer `.luarc.json`
und werfen damit dieselben 124 Muster weg: `cmdlog`, `dap`, `debugging`,
`diff`, `filetree`, `neotree-fs-refactor`, `open`, `pdfport`, `recommender`,
`sandbox`. Was das dort kostet, ist ungemessen -- es gehoert vor den naechsten
Gesamtlauf.

Die elf Worktrees selbst bleiben stehen. Mit dem injizierten `ignoreDir` sind
sie fuer LuaLS unsichtbar, das Problem ist entschaerft; ob die veralteten
aufgeraeumt werden, ist eine Frage an den Autor und keine Messfrage. Eine
Session lief waehrend dieser Arbeit selbst in einem davon.

Und eine Korrektur am Report: Abschnitt 1 behauptete, LuaLS indiziere
Punkt-Verzeichnisse nicht, `.claude/` bleibe also aussen vor -- "im Scan-Log
verifiziert". Das gilt fuer den *Workspace*, nicht fuer die *Library*. Der
Satz steht dort jetzt richtig.

---

## 2026-08-31

---

### lib.nvim fertig -- der zweite vertikale Durchgang

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

**273 -> 1.** Ein Repo, ein Commit
([`197a7c7`](https://github.com/StefanBartl/lib.nvim/commit/197a7c7)), 92
Dateien. Anders als bei Cluster F gab es hier keine eine Ursache -- gut zwanzig
kleine, und zwei davon waren echte Fehler.

| Regel | vorher | nachher |
|---|---:|---:|
| `param-type-mismatch` | 108 | 7 |
| `need-check-nil` | 47 | 2 |
| `undefined-field` | 34 | 0 |
| `assign-type-mismatch` | 26 | 0 |
| `redundant-return-value` | 14 | 1 |
| `duplicate-doc-field` | 13 | 0 |
| `undefined-doc-name` | 11 | 1 |
| `return-type-mismatch` | 11 | 2 |
| Rest (12 Regeln) | 9 | 0 |
| **gesamt** | **273** | **1** |

Die Nachher-Spalte ist die Messung *vor* der letzten Korrekturrunde: sie zaehlt
noch die sieben `param-type-mismatch` und den Rest, die der Bestaetigungslauf
danach auf 1 gebracht hat. `worse: nothing` in beiden Laeufen. Suite gruen (42
Specs), stylua sauber.

---

#### Zwei echte Fehler

**`getbufinfo()` liefert kein `filetype` -- und hat das nie getan.**
`buf_win_tab/buffer_utils.lua`s `count_real_listed_buffers` las `b.filetype`
von den Eintraegen, die diese Funktion zurueckgibt. Vim dokumentiert dort
`bufnr`, `changed`, `hidden`, `lastused`, `listed`, `lnum`, `linecount`,
`loaded`, `name`, `signs`, `variables`, `windows` -- kein `filetype`. `ft` war
also immer `""`, und `DEFAULT_EXCLUDE_FILETYPES` mit seinen neun Eintraegen
(neo-tree, quickfix, TelescopePrompt, help, ...) hat **nie einen Buffer
ausgeschlossen**. Die Funktion lieferte damit dasselbe wie
`count_listed_buffers` direkt daneben. `list_listed_buffers_info` meldete aus
demselben Grund fuer jeden Buffer `filetype = ""`.

Der Befund war ein `undefined-field` auf `b.filetype` -- zwei Zeilen, die
LuaLS seit dem Erstscan gemeldet hat. Behoben wird er, indem beide Stellen die
Option am Buffer lesen, so wie `get_buffer_info` nebenan es die ganze Zeit
schon tut.

**Jede Seite eines PDFs teilte sich einen Hover-Cache-Slot.**
`hover/preview/media.lua`s `page_key` war als `page_key(path)` deklariert und
definiert, wurde aber als `page_key(target.path, page)` aufgerufen -- Lua wirft
das zweite Argument still weg. Der Schluessel war `path .. NUL .. mtime`, fuer
jede Seite derselbe. Folge: Seite 2 rendern speicherte ihr PNG unter Seite 1s
Schluessel und `os.remove`te dabei Seite 1s Datei, und ein spaeterer Hover auf
Seite 1 bekam Seite 2s Bild geliefert.

Der Befund war ein `redundant-parameter` -- eine einzelne Zeile, die aussieht
wie Kosmetik.

---

#### Zwei Annotationen, die etwas anderes beschrieben als der Code tut

`hover/registry.lua` deklarierte `contribution.sources` als **eine** Funktion.
`register()` iteriert das Feld seit jeher mit `ipairs`, und jeder Aufrufer
uebergibt eine Liste -- inklusive vier Faellen in `hover_registry_spec`, die
genau deshalb als `assign-type-mismatch` gemeldet wurden. Die Tests hatten
recht, die Annotation nicht.

Der `ArgType`-Alias des Composers fuehrte `WINDOW` nicht, obwohl `argtypes` den
Typ neben den acht anderen registriert -- und war eine geschlossene Union,
obwohl `composer.register_type(name, def)` oeffentliche API ist: kein
selbstregistrierter Typname konnte sie je erfuellen. Jetzt
`Lib.UserCmd.Composer.ArgTypeBuiltin|string`, mit `WINDOW` in der Liste.

---

#### Das Muster, das ein Drittel erklaert: der Guard sitzt auf dem Feld

Dasselbe wie bei documentation.nvim, nur an anderen Stellen. `parse.dispatch`
prueft `node.route` und liest das Feld drei Aufrufe spaeter erneut in `route`
-- acht `param-type-mismatch` und drei `need-check-nil` aus dieser einen Form.
Dazu `autocmd.docs` (`r.pattern`), `usercmd.create` (`opts.complete`),
`reveal_in_fm` (`opts.command`), `lua_ls.insert.module_annotation`
(`opts.row`).

Bei `proc_trace` ist es nicht einmal pedantisch: die Funktion prueft
`vim.system` und **ersetzt es wenige Zeilen weiter unten selbst**. Der
Re-Read greift dort tatsaechlich auf etwas anderes zu als der Test.

---

#### Rueckgaben, die es ganz oder gar nicht gibt

`selection.chars()` gibt drei Werte zurueck oder keinen, `parse_kv_token` zwei
oder keinen, `vim.ui.select` ein Item mit seinem Index oder nichts,
`parse_raw_response` eine Antwort oder einen Fehler. Zehn Befunde; die
Bedingung prueft jetzt jeweils den Wert statt seinen Partner.

Zwei davon sind eine Spur mehr als Formsache: in `curl` steht die Kopplung
"`err` ist genau dann gesetzt, wenn `response` nil ist" nur in Prosa, nicht in
den zwei Rueckgabe-Slots. Statt ein `nil` als Fehlermeldung weiterzureichen,
haben die vier Aufrufstellen jetzt einen gemeinsamen Fallback-Text.

---

#### libuv antwortet mit nil, statt zu werfen

`uv.new_pipe()` / `uv.new_timer()` sind `|nil` typisiert -- libuv gibt kein
Handle mehr aus, wenn keines mehr zu haben ist -- und wurden ungeprueft
benutzt: in `spawn_capture`, `spawn_stream`, `wait_until`, beiden Debouncern
und drei `ui.kit`-Oberflaechen. 15 `need-check-nil`.

Jede Stelle hat jetzt eine Antwort darauf, und zwar die, die zum Ort passt:

- `spawn_capture`/`spawn_stream` melden es wie einen fehlgeschlagenen Spawn
  -- derselbe Ergebnis-Shape, ein anderer Text. Nebenbei fiel auf, dass
  `spawn_capture`s frueher Ausstieg bei `not handle` seine beiden Pipes offen
  liess; der gemeinsame `fail()` schliesst sie.
- `wait_until` meldet es wie einen erschoepften Poll.
- Die Debouncer rufen die Funktion **undebounced** auf. Den Debounce zu
  verlieren ist schlecht, den Aufruf zu verlieren waere schlimmer.
- Ein Timeout-Timer, den es nicht gibt, heisst schlicht: kein Timeout. Einen
  laufenden Prozess zu killen, weil libuv keine Handles mehr hatte, waere das
  schlechtere von beiden Ergebnissen.

---

#### Cluster E, lib.nvims Anteil

Die zehn `pcall(vim.cmd, "...")` in diesem Repo sind
`pcall(function() vim.cmd(...) end)`, wie im Report vorgeschlagen. Sieben in
`lua/`, drei in `TESTS/`. Der Rest der 60 liegt in anderen Repos und bleibt
offen.

---

#### Typen, die etwas anderes beschrieben haben

- **`Lib.Notify.Notifier`**: alle fuenf Felder optional, obwohl `create()`
  jedes einzelne setzt. Deshalb brauchte `notify().info(...)` in `deps.view`
  an sieben Stellen eine nil-Pruefung. Und `Lib.Notify.Safe` behauptete,
  `create_safe` gebe einen `Notifier` zurueck -- es ist ein `Safe.Notifier`.
- **`Lib.Deps.View.ToolUiState`** war zweimal deklariert, in `@types` und
  noch einmal in `view.lua`. Fuenf `duplicate-doc-field` pro Kopie.
- **`Lib.Cache.SaveOpts`** war eine leere Unterklasse von `Lib.Cache.Opts` --
  nominal also nicht dasselbe, weshalb ein Aufrufer mit dem Basistyp sie nicht
  uebergeben konnte. `deps.first_run` reicht genau eine Options-Tabelle an
  `load` *und* `save` weiter. Jetzt ein Alias.
- **`Composer.DocsOpts`** machte zwei Jobs: die partielle Ueberschreibung, die
  ein Aufrufer `setup()` gibt, und die aufgeloesten Defaults, die
  `registry.docs` haelt. Getrennt in `DocsOpts` und `DocsDefaults`.
- **`Lib.Deps.ManagerOpts`** ersetzt das fuenfmal ausgeschriebene
  `{ manager?: Lib.Deps.Manager }`. LuaLS normalisiert einen Inline-Tabellentyp
  an einer Deklaration anders als an einer Aufrufstelle -- dieselbe
  Schreibweise passte irgendwann nicht mehr auf sich selbst.
- **`Lib.System.ProcTrace.Saved`** ersetzt `table<string, function>` auf einer
  Tabelle, die auch das offene Log-Handle haelt. Und `uv_hrtime` war ein
  Typname, den es nie gegeben hat; `uv.hrtime()` gibt eine Zahl zurueck.
- **Tabpage-Handles** in `tabs_utils` waren `userdata`. Sie sind Integer, in
  beiden Richtungen der API -- dieselbe Klasse Fehler wie Cluster D, nur fuenf
  Befunde statt 154.
- **`Lib.Frecency`** wurde von der `Lib`-Fassade referenziert und war nirgends
  deklariert. **`Lib.Logger.Instance`** fehlten `level` und `file`, die
  `:checkhealth` von einer Instanz liest. **`Route.run`** und `Spec.default`
  waren als "gibt nichts zurueck" deklariert, obwohl `dispatch` genau das
  zurueckgibt, was sie liefern.
- Ein `@param`/`@return`-Paar stand auf `M.is_ike = M.is_like` -- einer
  schlichten Zuweisung ohne Funktion, an die es binden koennte.

---

#### Zwei Namen, die der nvim-Config gehoeren

`LogLevel`/`LogLevelNumber` und `AutoCmds.General.MD.GotoFile.Cfg` deklariert
die Config des Autors ebenfalls global, und zwei globale Deklarationen eines
Namens sind in **beiden** Dateien ein `duplicate-doc-alias` beziehungsweise
`duplicate-doc-field`. Diese Library nennt ihre jetzt `Lib.Notify.LogLevel*`
und `Lib.Fs.Open.Url.SystemOpener.Cfg`.

Damit ist der Kandidat aus Abschnitt 5 des Reports ("einmal in lib.nvim
definieren, ueberall referenzieren") von der anderen Seite geloest: nicht
gemeinsam definieren, sondern getrennt benennen. Was lib.nvim gehoert, heisst
`Lib.*`; was die Config global braucht, behaelt seinen Namen.

---

#### Die Klammer, die eine Signatur rettet

Ein inneres `fun(): X` frisst in einer Signatur alles, was danach kommt:

```lua
---@field create fun(cmd: string|fun(): string, exclude_filetypes?: string[], lhs?: string): function
```

LuaLS liest das als "innere Funktion gibt `string` und `exclude_filetypes`
zurueck" und scheitert dann an der schliessenden Klammer -- `luadoc-miss-symbol`
plus zwei `undefined-doc-name` auf Parameternamen, die es als Typen liest. Die
Annotation existiert danach gar nicht.

Vier Vorkommen: `resize_guarded`, `cross`, `cross.fs.mutate` -- und
`Lib.AutoCmd.create`, wo es beim Fix erst entstanden ist. Dort hat es `create`
still auf zwei Parameter reduziert, was vier `redundant-parameter` im
Dispatcher ausgeloest hat, der die Funktion mit dreien aufruft. Der
Zwischenscan hat das gefangen; Klammern drum, weg.

Das ist die Lehre daraus: ein Fix in einer `@types`-Datei kann eine Signatur
kaputtmachen, ohne dass die Datei selbst einen Befund bekommt.

---

#### Unterdrueckt, mit der Begruendung daneben

`nvim_buf_get_option` und `vim.tbl_islist` sind Kompatibilitaetszweige, deren
ganzer Sinn ihre Veraltetheit ist -- beide laufen nur, wenn der moderne Weg
davor schon gescheitert ist. `proc_trace`, das `vim.system` und
`vim.fn.jobstart` ersetzt, *ist* Monkey-Patching; das war schon im Report
(Abschnitt 5, `duplicate-set-field`) so vermutet.

In den Specs: sieben absichtlich ungueltige Argumente (ein unbekannter
chdir-Scope, ein Nicht-Tabellen-Submenu, ein malformter Frecency-Eintrag, eine
Nicht-Funktion als Sink, zwei unbekannte Format-Styles, ein nicht-numerisches
Buffer-Handle) und zwei `vim.notify`-Doubles.

Und eine in `docs/EXAMPLES/composer-flags-and-kv.lua`: `require("diff")` meint
diff.nvim, loest innerhalb *dieses* Workspace aber auf `lib.lua.diff` auf. Fuer
einen Leser mit installiertem diff.nvim ist die Zeile richtig.

---

#### Was offen bleibt: eine Zeile, und sie gehoert nach lsp.nvim

Der eine verbliebene Befund ist `undefined-doc-name` auf `luassert` in
`lua/lib/@types/luassert.lua:83`. Die Datei sagt selbst, warum: der Typ loest
nur auf, wo `${3rd}/luassert/library` auf dem Library-Pfad liegt, und
`lsp.nvim`s `build_library.lua` haengt `${3rd}/busted/library` und
`${3rd}/luv/library` an -- luassert nicht.

Aus lib.nvim ist das nicht zu schliessen. Eine eigene `workspace.library` in
der `.luarc.json` waere genau der Fehler, den `dd40880` einen Tag vorher
behoben hat: die Liste **ersetzt** die Injektion, statt sie zu ergaenzen. Der
Fix ist eine Zeile in lsp.nvim und wirkt auf alle 31 Repos mit Testsuite --
deshalb steht er dort und nicht hier.

---

#### Gemessen

```
scripts/luals-scan/scan.sh before lib.nvim
# ... 92 Dateien ...
scripts/luals-scan/scan.sh after lib.nvim
python scripts/luals-scan/compare.py before after
```

Drei Laeufe statt zwei: einer nach dem `lua/`-Durchgang (273 -> 91, `worse:
nothing`), einer nach `TESTS/` (273 -> 8), einer nach der Korrektur der vier
`redundant-parameter`, die der zweite aufgedeckt hatte (273 -> 1). Der
Zwischenlauf hat sich bezahlt gemacht: ohne ihn waere die kaputte
`create`-Signatur mit committet worden.

---

### Sechs Repos pruefen wieder gegen Neovims Typen

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

`buffer-ctx`, `emojis`, `fileops`, `gopath`, `lib` und `sessions` nannten in
ihrer `.luarc.json` ein eigenes `workspace.library` -- und weil eine
`.luarc.json` jeden Schluessel, den sie nennt, **ersetzt** statt ihn zu
ergaenzen, warf das die Liste weg, die `lsp.nvim` mitschickt:

```json
"diagnostics.globals": ["vim"],
"workspace.library": ["${3rd}/luv/library"]
```

Uebrig blieb luv. Kein `$VIMRUNTIME/lua`, keine Plugin-Typen, kein lib.nvim.
`vim` war in diesen sechs Repos ein deklariertes Global vom Typ `any`:
`vim.fn.expand(...)` gab `any` zurueck, `vim.api.*` wurde nicht geprueft, und
`vim.SystemCompleted` existierte nicht -- obwohl Neovim 0.12 die Klasse in
`$VIMRUNTIME/lua/vim/_core/system.lua` fuehrt. Die niedrige Warnungszahl kam
daher, dass nicht geprueft wurde.

Das ist derselbe Mechanismus wie Cluster A, und dort wurde die Zeile schon aus
20 `.luarc.json` entfernt -- **aber nur dort, wo die Messung sofort eine
Verbesserung zeigte**. Genau deshalb blieben diese sechs zurueck: bei ihnen
stieg die Zahl. Ohne die Zeile sind ihre `.luarc.json` jetzt identisch zu
documentation.nvim, dem Repo, das auf 0 steht.

---

#### Die Zahl steigt, und das ist der Zweck

| Repo | vorher | nachher |
|---|---:|---:|
| lib.nvim | 244 | 273 |
| gopath.nvim | 67 | 67 |
| fileops.nvim | 20 | 35 |
| sessions.nvim | 8 | 15 |
| emojis.nvim | 13 | 13 |
| buffer-ctx.nvim | 4 | 8 |
| **Summe** | **356** | **411** |

Nach Regel, und daran liest sich, was passiert ist:

| Regel | Delta | warum |
|---|---:|---|
| `undefined-doc-name` | **-37** | `vim.SystemCompleted` / `vim.SystemObj` loesen auf |
| `undefined-field` | **-23** | dito, auf `vim.*`-Feldern |
| `param-type-mismatch` | +57 | typisierte `vim.fn.*`-Rueckgaben, meist `\|nil` |
| `need-check-nil` | +28 | dieselbe Ursache, andere Regel |
| `assign-type-mismatch` | +11 | |
| `deprecated` | +5 | veraltete Neovim-APIs, vorher unsichtbar |
| Rest | +14 | `duplicate-*`, `cast-*`, `return-type-mismatch` |

60 Befunde verschwinden, 119 kommen dazu. Die neuen liegen ausnahmslos an
Stellen, die vorher **niemand** geprueft hat.

Die fuenf `deprecated` sind der beste Beleg dafuer, dass hier nichts kaputt
gemacht, sondern etwas wieder sichtbar wurde: `nvim_buf_get_option` in
`lib.nvim/buf_win_tab/get_option/init.lua:24` steht seit dem Erstscan vom
29.08. in Abschnitt 5 des Reports -- und war in der gesamten laufenden
Messreihe unsichtbar.

Und ein Beispiel aus fileops.nvim, das zeigt, dass es nicht nur um `vim.*`
geht: `bindings/keymaps.lua:110` reicht `bulk.execute(...)` direkt in
`notify.report(...)` weiter und uebergibt dabei ein `integer` an einen
`boolean`-Parameter. Sichtbar erst jetzt -- lib.nvim war vorher gar nicht in
fileops' Library.

---

#### Eine Hypothese, die die Messung widerlegt hat

Der erste Nachher-Lauf brachte drei `duplicate-doc-alias` und drei zusaetzliche
`duplicate-doc-field` mit, und die Vermutung lag nahe: `build_library` sammelt
ueber `find_type_dirs(root)` die `@types/`-Verzeichnisse **des gemessenen
Workspace** ein -- bei lib.nvim 110 von 146 Eintraegen -- also liest LuaLS
diese Dateien zweimal und meldet jede `@class` gegen sich selbst. Das waere
Cluster As zweite Ursache eine Ebene tiefer gewesen.

Ein Filter im Dump, ein zweiter kompletter Lauf: **exakt dieselben 411**, Regel
fuer Regel. Die Hypothese ist falsch -- LuaLS indiziert einen Pfad, der im
Workspace liegt, ohnehin als Workspace-Datei, und die Library-Nennung aendert
daran nichts. Der Filter ist deshalb wieder draussen; eine Aenderung ohne
messbare Wirkung gehoert nicht ins Werkzeug.

Die `duplicate-doc-field` in `lib.nvim/deps/` sind stattdessen echt:
`view.lua:49` und `@types/init.lua:99` deklarieren beide
`Lib.Deps.View.ToolUiState`. Dasselbe in gopath zwischen
`@types/resolvers.lua` und `resolve.lua`.

---

#### Nebenbefund: das Werkzeug dumpt die falsche Funktion

Beim Nachsehen ist aufgefallen, dass `scripts/luals-scan/dump_library.lua`
`build_library(root)` aufruft -- 37 bis 146 Eintraege --, waehrend der
Attach-Pfad des Editors `library_profiles.build_runtime_library()` benutzt und
damit **drei**: `${3rd}/luv/library`, `${3rd}/busted/library`,
`$VIMRUNTIME/lua`. `build_library` erreicht den laufenden Server nur ueber
`:LuaLsReloadLibrary` von Hand; lsp.nvims eigener Kommentar in
`lua_ls/init.lua` haelt fest, dass die fruehere Verdrahtung ueber
`on_new_config` toter Code war.

Der Unterschied ist nicht folgenlos: das Werkzeug ersetzt damit faktisch
lazydev, das im Editor die Plugin-Typen bei Bedarf nachzieht. Das ist eine
brauchbare Annaeherung -- aber der README von `luals-scan` beschreibt sie als
das, was der Editor tut, und das stimmt so nicht. Steht als offener Punkt im
Report.

---

### Cluster F: `inject-field` in lib.nvim -- und die `missing-fields`-Reste daneben

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Beide Regeln, 108 und 22, hingen an **einer** Schreibweise:

```lua
---@type LibStringsCore
local S = {}

function S.trim(s) ... end   -- 21x: "Fields cannot be injected into
                             --       the reference of `LibStringsCore`"
```

`---@type` sagt „diese Tabelle *ist* bereits jene Klasse“. Alles, was danach
hineingeschrieben wird, ist fuer LuaLS eine Injektion in eine geschlossene
Referenz -- und das leere Literal davor eine Klasse, der ihre Felder fehlen.
Dieselbe Zeile erzeugt also je nach Klasse `inject-field` oder
`missing-fields`; welche von beiden, haengt nur daran, ob die Klasse Felder
deklariert.

**381 -> 244**, ein Commit (`e42235d`). Keine andere Regel hat sich
verschlechtert, Suite gruen, `stylua --check` sauber.

---

#### Die Zombie-Klassen, und was sie verdeckt haben

`lua/lib/lua/tables/@types/init.lua` endete so:

```lua
return {}

---@class LibTablesSafe

---@class TablesSet

---@class LibTablesFn
```

Acht leere Klassendeklarationen, hinter dem `return`, ueber zwei Dateien
(`tables` und `strings`) -- und genau auf die zeigten die acht
Implementierungen. Die echten, gefuellten Klassen lagen daneben:
`Lib.Tables.Core`, `Lib.Strings.Core` und so weiter, je eine Datei pro Modul.

Die Annotation trug damit **keine** Typinformation. Sie schaltete nur die
Ableitung ab, die ohne sie das Richtige getan haette -- und produzierte 99 der
108 `inject-field`.

**Der teure Teil stand woanders.** `lua/lib/@types/all_functions.lua`, die
Beschreibung von `require("lib")`, routete vier Namespaces durch dieselben
Leichen:

```lua
---@field array TablesArray      -- leer
---@field core LibTablesCore     -- leer
---@field dict TablesDict        -- leer
---@field functional LibTablesFn -- leer
```

`lib.core.deep_copy(...)` bot im Editor also gar nichts an: keine Completion,
keine Signatur, keine Pruefung. Vier von rund dreissig Namespaces der
Hauptfassade, still.

Die Fassade nennt jetzt die echten Klassen. Vorher gegengeprueft, Feld fuer
Feld, ueber alle acht Paare: `---@field`-Liste und
`function M.<name>`-Definitionen sind deckungsgleich, in beide Richtungen. Die
Umstellung kostet also keine Zeile Dokumentation. Der tote Block ist weg, die
Implementierungen annotieren nicht mehr -- so, wie es `case.lua`, `wrap.lua`,
`links.lua` und `distance.lua` in demselben Verzeichnis schon immer gemacht
haben.

---

#### Die Annotation stand nur auf der falschen Zeile

Fuer die Module, deren Klasse echt gefuellt ist, lag der Fix bereits im Repo
vor -- `cache/init.lua` und `store/init.lua` schreiben ihn hin:

```lua
local M = {}
M.disk = require("lib.nvim.cache.disk")
M.memory = require("lib.nvim.cache.memory")

---@type Lib.Cache
return M
```

Am `return` ist die Tabelle vollstaendig, dort prueft LuaLS sie gegen die
Klasse, und die Klasse bleibt erhalten. Elf weitere Module ziehen jetzt nach
(`dump`, `error`, `uuid`, `yaml`, `diff/lines`, `diff/myers`,
`numeral/roman`, `numeral/alpha`, `time/format`, `time/presets`,
`parser_policy`). `diff/init.lua` und `numeral/init.lua` bauen ihr Aggregat
stattdessen als ein Literal -- zwei `require`s, die ohnehin nebeneinander
standen.

Dieselbe Bewegung bei den drei lokalen Kontext-Tabellen: in
`buffer/context` und `window/context` steht die Klasse bereits am `---@return`
der Funktion, und die Methoden werden erst unter dem Literal angehaengt. Die
zweite Annotation auf dem Literal war schlicht zu frueh.

---

#### Ein Typ, der nicht bloss zu frueh, sondern falsch war

`bindings/autocmd/dispatcher/init.lua` fuehrt eine Liste jedes erzeugten
Dispatchers:

```lua
---@type Lib.Autocmd.Dispatcher.Entry[]
local live = {}
```

`Entry` ist aber, was `M.registry()` daraus **baut** -- mit `attached`, `mode`
und `handlers`. Was `live` haelt, ist die Rohregistrierung: `name`, `events`,
`group` und ein `handle`, von dem jene drei Felder erst zur Abfragezeit
gelesen werden. `handle` kennt `Entry` gar nicht.

Die Liste hat jetzt ihre eigene Klasse, `Lib.Autocmd.Dispatcher.LiveEntry`.
Das raeumt neben der `missing-fields` auch sechs `undefined-field` auf
`entry.handle` ab -- an sechs Stellen, an denen der Editor bisher auf einem
Feld, das es wirklich gibt, nichts anzubieten hatte.

---

#### Neun Schluessel, die es nur unter einer Strategie gibt

Die restlichen neun `inject-field` lagen in `strategies/lazy.lua` -- und die
waren kein Annotationsfehler, sondern ein Befund: `lazy` exportiert
`augroup`, `augroup_create_clear`, `unique`, `unique_by`, `is_unique` und drei
`json_*`, die `Lib` nicht kennt. Die **Standard**strategie (`metatable`)
registriert sie ebenfalls nicht; ihr `__index` wirft dort
`lib: unknown key '<name>'`.

Sie einfach auf `Lib` nachzutragen haette eine injizierte Warnung gegen eine
Phantom-Zusage getauscht: die Fassade haette unter der Voreinstellung etwas
versprochen, das nicht existiert. Sie stehen deshalb auf einer Unterklasse,
`---@class Lib.Strategy.Lazy : Lib`, die nur `lazy.lua` an seinem `return`
fuehrt. Wer die Strategie waehlt, bekommt die Typen; wer sie nicht waehlt,
bekommt keine Zusage.

`deps` war der eine Schluessel, den beide Strategien fuehren und nur die
Fassade nicht kannte -- der steht jetzt auf `Lib` selbst.

Das dahinterliegende Problem bleibt offen und ist im Report notiert: die drei
Strategien haben drei verschiedene Oberflaechen, `eager.lua` nennt `augroup`
sogar `autogroup`. Der Kommentar bei `noop`/`identity` in `metatable.lua`
beschreibt genau denselben Fall, einmal schon behoben.

---

#### Der Alias, der eine echte Luecke zugedeckt hat

Im geloeschten Zombie-Block stand, ganz am Ende, `---@alias K any`. Mit ihm
verschwanden fuenf `undefined-doc-name` -- die der erste Nachher-Lauf prompt
gemeldet hat, und ohne den waeren sie unbemerkt in die Zahl gewandert.

Vier davon sind eine bekannte Grenze von LuaLS: ein `---@type table<K, ...>`
*im Rumpf* einer Funktion loest deren Typparameter nicht auf. Da `K` durch den
Alias ohnehin `any` war, steht dort jetzt `any` -- gleiche Bedeutung, ehrlich
benannt; die Signatur typisiert weiter, und die sieht der Aufrufer.

Die fuenfte war ein echter Fehler:

```lua
---@generic T            -- K fehlt
---@param key fun(item:T):K
---@return table<K, T[]>
function M.group_by(list, key)
```

`count_by`, dreissig Zeilen darunter, macht es richtig (`---@generic T,K`).
`group_by` hat `K` nie deklariert -- die Zusage `table<K, T[]>` war seit jeher
`table<any, any[]>`, nur hat es niemand gesehen.

Und noch eine Unterdrueckung, die eine Zeile zu hoch sass: in
`TESTS/frecency_spec.lua` stand `---@diagnostic disable-next-line:
missing-fields` ueber `eq(`, waehrend der Befund auf dem `pcall`-Argument in
der Zeile darunter lag. Sie deckt jetzt die Zeile, die sie meinen sollte.

---

#### Gemessen

`scripts/luals-scan`, ein Lauf vor und einer nach der Aenderung, gleiche
Arbeitskopie.

| Regel | vorher | nachher |
|---|---:|---:|
| `inject-field` | 108 | **0** |
| `missing-fields` | 22 | **0** |
| `undefined-field` | 58 | 52 |
| `undefined-doc-name` | 35 | 34 |
| `assign-type-mismatch` | 27 | 26 |
| **lib.nvim gesamt** | **381** | **244** |

`compare.py` meldet `worse: nothing`. Was in lib.nvim bleibt, hat keine
gemeinsame Ursache mehr: `param-type-mismatch` 71, `undefined-field` 52
(davon 12 in `bindings/audit.lua`, alle aus einem Union-Rueckgabetyp:
`keymap.registered()` gibt `table<string, Registered[]>|Registered[]` zurueck,
je nach Argument, und in `pairs(buckets)` kann LuaLS dann nicht entscheiden,
welcher der beiden Zweige vorliegt), `undefined-doc-name` 34 -- **19 davon**
`vim.SystemCompleted` / `vim.SystemObj`, die Neovims Meta unter diesen Namen
nicht fuehrt.

---

### documentation.nvim: die restlichen 155 -- der erste vertikale Durchgang

*(war: Diagnostics-Report Abschnitt 0, "documentation.nvim zu Ende bringen")*

Nach Cluster D standen in dem Repo noch 155 Befunde, und sie hatten keine
gemeinsame Ursache mehr: dreizehn Regeln, verteilt ueber 44 Dateien. Genau
dafuer ist der vertikale Modus gedacht -- der Overhead (Scan davor, Scan
danach, Testsuite, Commit) faellt einmal an, nicht einmal pro Regel.

**155 -> 0.** Zwei Commits: `9f128bb` fuer den einen echten Fehler,
`9e81344` fuer den Rest.

---

#### Das Muster, das die Haelfte erklaert: der Guard sitzt auf einem Feld

```lua
if e.pin then
  local p = e.pin   -- p ist trotzdem `Pin?`
  go(st, { mode = p.mode, ... })
```

Die Pruefung engt nur den Ausdruck ein, den sie prueft. Die zweite Lesung
desselben Feldes ist fuer den Typpruefer ein neuer Ausdruck, und der ist wieder
nil-behaftet. An acht Stellen zuerst an eine Lokale gebunden und dann geprueft
-- in `browse/init.lua`, `browse/view.lua`, `core/docs.lua`,
`bindings/usrcmds/bindings.lua` und `mcp/tools.lua`.

Wo das Feld eine Invariante der Datenstruktur ist -- eine `kind="endpoint"`-Zeile
*hat* ihr `spec` --, steht jetzt ein `assert` statt eines erfundenen Fallbacks:
es benennt die Invariante und kracht, wenn sie je verletzt wird.

---

#### Die Kinder eines Treesitter-Knotens

`node:child(i)` ist `TSNode?`. Innerhalb von `0 .. child_count()-1` kann es
nicht nil sein, aber das weiss der Typpruefer nicht, und ein Guard, der nie
zuschlagen kann, waere gelogener Code. Die Index-Schleifen in
`core/lang/ecma.lua` laufen deshalb ueber `iter_children()`: liefert `TSNode`
ohne nil und besucht exakt dieselben Kinder.

**Und dann hat ein Gate des Repos zugeschlagen.** `TESTS/shim_contract_spec.lua`
verlangt, dass jede Treesitter-Methode, die `core/` aufruft, im Standalone-Shim
klassifiziert ist. Der erste Anlauf benutzte `named_children()` -- eine
Neovim-Bequemlichkeit, die die `lua-tree-sitter`-Bindung des Standalone-Builds
nicht hat. Im Editor waere das nie aufgefallen; der Build waere gescheitert.
Dort steht jetzt wieder `named_child(i)`, mit `assert` fuer die Index-Invariante.

---

#### Ein echter Fehler: zwoelf Advice-Listen, die nie jemand gesehen hat

`vim.health.info(msg)` nimmt eine Nachricht und sonst nichts -- anders als
`warn` und `error` hat es **keinen** Advice-Parameter. Zwoelf Aufrufe in
`editor/health.lua` haben trotzdem eine Liste mitgegeben:

```lua
h_info("lua-language-server not on PATH", {
  "Only :DocMap full needs it; a plain :DocMap never calls it.",
  "In Neovim: :Mason, then install lua-language-server.",
})
```

Lua nimmt das entgegen und wirft es weg. Keine dieser Zeilen stand je in einem
`:checkhealth`. LuaLS hat es als `redundant-parameter` gemeldet -- eine Meldung,
die wie eine Stilnote klingt und ein fehlendes Feature ist. Der lokale Shim
rendert die Hinweise jetzt in die Nachricht, in derselben Form, die
`vim.health` der Advice einer Warnung gibt.

---

#### Zwei verwaiste Doc-Bloecke

In `core/check.lua` und in `scripts/ci.lua` stand je ein Kommentarblock einer
frueheren Fassung ueber der falschen Funktion -- ohne Leerzeile dazwischen, also
verschmolzen mit dem naechsten. Folgen: `check_require_cycles` galt als
undokumentiert (seine Beschreibung klebte 350 Zeilen weiter oben an
`check_binding_conflicts`), und `puc_lua` schien drei Rueckgabewerte zu
deklarieren, weshalb die Meldung "Rueckgabewert #2 ist `string?`" sich auf die
Annotation der Vorgaengerversion bezog. Beide zusammengefuehrt.

---

#### Annotationen, die schlicht falsch waren

Jede davon eine Aussage ueber diesen Code, keine Typ-Kosmetik:

- `core/lang/ocaml.lua`: `doc_blocks` gibt zwei Tabellen zurueck, deklariert war
  eine -- beide Aufrufer benutzen beide.
- `editor/callhierarchy.lua`: `make_client` baut einen
  `vim.lsp.rpc.PublicClient` (die vier Methoden, die `vim.lsp.start` verlangt),
  deklariert war `Client`.
- `config.sources`: auf `Documentation.Opts` annotiert, obwohl der eigene Header
  sagt, dass **jeder** Konsument hier durchgeht. Der Browser reichte seine
  eigene Opts-Klasse hinein -- richtig, und trotzdem gemeldet.
- `Documentation.Browse.KeyAction` kannte `send_request` nicht: wer `gs` ueber
  `opts.keys` umbinden wollte, war fuer den Typ ein Fehler und fuer den Code
  nicht.
- `Documentation.Browse.Entry` deklarierte kein `spec`, obwohl jede
  `kind="endpoint"`-Zeile eines traegt.
- `Documentation.Config` deklarierte kein `git` -- den Host-Hook, den
  `core/api.lua` seit jeher aufruft und beide Hosts setzen.

---

#### Der Overload, der die Zahl verschlechtert hat

Fuenf `missing-return` kamen daher, dass die Haelfte der Scan-Stages nichts
zurueckgibt, `timing.measure`s `fun(): T` aber von jedem Rueckruf einen Wert
verlangt. Erster Versuch: die void-Form als `@overload` deklarieren. Gemessen:
**aus 5 Befunden wurden 13.** Mit der Ueberladung wird der Rueckgabewert *jedes*
`measure`-Aufrufs nil-behaftet, also war `ir` ploetzlich `Documentation.IR|nil`
und jede Weitergabe davon ein neuer Befund.

Genau der Fall, wegen dem vorher *und* nachher gemessen wird. Stattdessen
`timing.stage(t, name, fn)`: dieselbe Messung ohne Wert. Warum der Overload
nicht geht, steht jetzt in der Doku der Funktion -- sonst probiert es der
naechste noch einmal.

---

#### Unterdrueckt, mit der Begruendung daneben

Nur dort, wo der Befund die Absicht des Codes meldet:

- `scripts/bundle_manifest.lua` ersetzt `os.exit`, `scripts/mcp_server.lua`
  ersetzt `vim.notify` -- beides der Zweck der jeweiligen Datei.
- Test-Doubles, die pro Fall einen eigenen Stub ueber dasselbe Feld legen
  (`docmap_browse_spec`, `usrcmds_generate_all_spec`).
- Teil-Fixturen, die nur die Felder tragen, die die gepruefte Einheit liest
  (`call_path_spec`, `scopes_spec`).
- Aufrufe, die absichtlich `nil` oder `42` hineinreichen, weil die Abweisung
  das Testobjekt ist (`docmap_spec`, `tags_spec`, `check_policy_spec`).

Wo der Test selbst schon prueft (`ok(x ~= nil, ...)`), steht ein `---@cast`
statt einer Unterdrueckung: er sagt dem Typpruefer, was die Zeile darueber
bereits behauptet.

---

#### Gemessen

`155 -> 0`, mit `scripts/luals-scan` vor und nach jeder Runde. Gates vor dem
Commit: **96 Spec-Dateien gruen**, `stylua --check .` sauber, luacheck 0
Warnungen / 0 Fehler ueber 244 Dateien.

Der Zuschnitt der beiden Durchgaenge ist der Unterschied, den der Arbeitsmodus
in Abschnitt 0 beschreibt: Cluster D war **eine** Ursache, 154-mal angewendet;
diese Runde waren **dreizehn** Ursachen ueber 44 Dateien, jede einzeln zu lesen
und einzeln zu entscheiden. Die zweite Sorte laesst sich nicht horizontal
abarbeiten -- deshalb steht sie hinter dem Repo, nicht hinter der Regel.

---

### Cluster D: `userdata` statt `TSNode` -- documentation.nvim

*(war: Diagnostics-Report Abschnitt 4 D und Abschnitt 8, Punkt 2)*

Der erste vertikale Durchgang, und er faengt beim groessten Einzelposten der
ganzen Liste an: 237 `undefined-field` in einem Repo, davon 211 auf vier
Methodennamen -- `iter_children` 92, `start` 65, `end_` 28, `type` 26.

---

#### Warum `userdata` der teuerste Annotationsfehler ist

`---@param node userdata` sieht aus wie "ein Objekt, das die Sprache nicht
naeher beschreibt". LuaLS liest es strenger: `userdata` ist ein Typ **ohne
Felder**, also ist jeder Zugriff darauf ein Befund. Eine einzige Annotation,
ueber 17 Sprachmodule wiederholt, erzeugt so ein Vielfaches an Warnungen --
eine pro Aufrufstelle, nicht eine pro Deklaration.

Der Typ, der gemeint war, liegt die ganze Zeit im Runtime:
`$VIMRUNTIME/lua/vim/treesitter/_meta/tsnode.lua` deklariert `TSNode` mit genau
diesen Methoden. Es war also nichts nachzubauen und nichts zu unterdruecken,
sondern nur der richtige Name einzusetzen.

---

#### Was gemacht wurde -- 154 Annotationen in 18 Dateien

`userdata` -> `TSNode` in jeder `@param`/`@return`/`@type`-Zeile der 17
Sprachmodule und in `core/plugins.lua`. Prosa blieb unangetastet: in
`core/artifact.lua` und im Lua-Glossar steht das Wort als Fliesstext ueber Luas
`type()`, und dort ist es richtig.

Kein Zeichen Code geaendert, nur Annotationen.

---

#### Zwei Nachbarn derselben Klasse

Die Messung hat zwei weitere Stellen mitgezeigt, an denen `userdata` einen
vorhandenen Typ verdeckt hat:

- **`editor/serve.lua`** (11 Befunde): die Client-Handles kommen aus
  `uv.new_tcp()` und sind `uv.uv_tcp_t`. Die luv-Meta kennt `write`, `close`,
  `is_closing`, `read_start` und `read_stop`; `---@param client userdata` hat
  genau das weggeworfen, was der Server benutzt.
- **`standalone/treesitter.lua`** (2 Befunde): hier waere `TSNode` **falsch**.
  Die Datei uebersetzt `lua-tree-sitter` auf Neovims Oberflaeche, und die
  Knoten der Bindung tragen die Byte-Offsets der C-API (`start_byte`,
  `end_byte`) statt `start()`/`end_()` -- das ist eine der sechs Luecken, die
  die Datei ueberhaupt erst schliesst. Ihre Knoten haben deshalb eine eigene,
  benannte Klasse bekommen, mit dem Grund darueber, statt Neovims Typ
  aufgedrueckt zu bekommen.

Das ist der Unterschied zwischen "die Warnung ist weg" und "der Typ stimmt":
`TSNode` haette dort ebenfalls 2 Befunde beseitigt und dafuer eine Behauptung
aufgestellt, die beim naechsten Leser als Tatsache durchgeht.

---

#### Ergebnis: 383 -> 155

| Regel | vorher | nachher |
|---|---:|---:|
| `undefined-field` | 237 | **9** |
| `param-type-mismatch` | 47 | 47 |
| `need-check-nil` | 44 | 44 |
| `duplicate-set-field` | 13 | 13 |
| `redundant-parameter` | 13 | 13 |
| `assign-type-mismatch` | 8 | 8 |
| **gesamt** | **383** | **155** |

**Keine andere Regel hat sich um einen einzigen Zaehler bewegt.** Das war die
Frage, wegen der ueberhaupt vor *und* nach der Aenderung gemessen wird: ein
echter Typ kann anderswo neue Befunde ausloesen (ein `TSNode?`, das an ein
`TSNode` gereicht wird), und dann waere der Fix nur eine Verschiebung gewesen.

Gates vor dem Commit: 96 Spec-Dateien gruen, `stylua --check .` sauber,
luacheck 0 Warnungen / 0 Fehler ueber 135 Dateien. Ein Commit, `c98ea46`,
gepusht.

---

#### Was von den `undefined-field` uebrig ist

Neun, und sie haben eine andere Ursache -- fehlende Feld-Deklarationen, keine
falschen Typen:

- `Documentation.Browse.Entry` fuehrt kein `spec`, obwohl
  `kind="endpoint"`-Zeilen eines tragen: 2 in `lua/`, 4 im Spec dazu.
- `TESTS/mcp_spec.lua` greift auf `text`, `commits` und `last_commit` eines
  MCP-Ergebnisses zu, die der Typ nicht nennt.

Beides sind Ein-Zeilen-Nachtraege am jeweiligen `@class` und gehoeren in den
naechsten Durchgang durch dieses Repo, nicht zu Cluster D.

---

### Cluster B: `need-check-nil` in Tests -- unterdrueckt, nicht auszementiert

*(war: Diagnostics-Report Abschnitt 4 B und Abschnitt 8, Punkt 5)*

Der Report hatte die Wahl offen gelassen, weil sie keine Arbeit ist, sondern
eine Entscheidung: die 920 `need-check-nil` aus `TESTS/` und `scripts/`
entweder mit `assert(mod)` auszementieren, oder dort abschalten, wo der Befund
invertiert ist. Entschieden wurde das Abschalten.

Der Grund ist der Zweck der Dateien. Kommt in einem Test etwas als `nil`
zurueck -- ein `pcall(require, ...)`, ein Fixture-Read, ein uv-Handle --, dann
*soll* die Datei krachen und das `nil` benennen. Die Nil-Pruefung, die LuaLS
verlangt, wuerde genau den Fehlschlag verstecken, fuer dessen Meldung der Test
existiert. Ein `assert(mod)` davor waere 920-mal Code, der eine Pruefung
nachbaut, die der Test ohnehin ist.

---

#### Der Befund, der die Umsetzung geaendert hat

Geplant war eine `TESTS/.luarc.json` pro Repo: Verzeichnisebene statt
Dateiebene, 19 Eintraege statt 93. **Das geht nicht.** LuaLS liest
ausschliesslich die `.luarc.json` im Wurzelverzeichnis des Workspace; eine in
einem Unterverzeichnis wird nicht etwa daruebergelegt, sondern ignoriert.

Zweimal gegengeprueft, weil eine Verneinung sonst nur eine Vermutung bleibt:
einmal per `lua-language-server --check` mit einer probeweise angelegten
`TESTS/.luarc.json`, einmal gegen einen laufenden Server im Editor
(`runtime-analysis.nvim/TESTS/telemetry_spec.lua` -- 52 Befunde vorher wie
nachher).

Dateiebene ist damit die feinste Granularitaet, die der Server anbietet. Sie
erfuellt nebenbei die stehende Regel *"Unterdrueckung braucht eine Begruendung
im Code"* besser als der urspruengliche Plan: die Begruendung steht ueber dem
Code, den sie betrifft, statt in einer JSON-Datei ein Verzeichnis hoeher.

---

#### Was gemacht wurde -- 19 Repos, 93 Dateien

19 Repos, 93 Testdateien, je vier Zeilen am Dateikopf:

```lua
-- Test code: when something here comes back nil -- a `pcall(require, ...)`,
-- a fixture read, a uv handle -- this file must crash and name it. The nil
-- guards LuaLS asks for below would hide the very failure it exists to report.
---@diagnostic disable: need-check-nil
```

Verteilung der 93 Dateien: documentation 40, lib 11, markdown 8,
runtime-analysis 8, spotlight 7, filetree 3, open 3, diff 2, und je eine in
fileops, github_stats, gopath, images, lsp, mdview, pickers, replacer,
reposcope, sandbox, sessions.

**Kein Zeichen Code geaendert** -- ueber alle 19 Commits sind saemtliche
hinzugefuegten Zeilen Kommentarzeilen, geloescht wurde nichts. Ein Commit pro
Repo, alle auf `main` gepusht: diff `ca102cf`, documentation `430ed61`, fileops
`2e68761`, filetree `63b88f2`, github_stats `66487dc`, gopath `4aaad96`, images
`59395b4`, lib `a0232a0`, lsp `fde2de3`, markdown `fae1b92`, mdview `ec3c7a7`,
open `1d5ecde`, pickers `c9fd4fe`, replacer `deb279b`, reposcope `2bb7c69`,
runtime-analysis `5be8414`, sandbox `283af24`, sessions `9394c52`, spotlight
`01dca91`.

---

#### Ergebnis: 3204 -> 2289

Messreihe vom 31.08., dieselbe Config-Herstellung wie bei Cluster A.
Aufgefuehrt sind die Repos, fuer die beide Messungen vorliegen; die Summe geht
ueber alle 33 Workspaces.

| Repo | vorher | nachher |
|---|---:|---:|
| documentation.nvim | 732 | 383 |
| lib.nvim | 505 | 381 |
| lsp.nvim | 392 | 379 |
| runtime-analysis.nvim | 273 | 119 |
| filetree.nvim | 226 | 167 |
| nvim-config | 137 | 137 |
| **Summe (alle 33 Workspaces)** | **3204** | **2289** |

`need-check-nil` selbst: **1128 -> 208**, also genau die 920 aus `TESTS/` und
`scripts/`. Die 208 Reste liegen in `lua/` und sind echt -- dort wird ein
`string|nil` ungeprueft weitergereicht, das ist keine Testabsicht, sondern eine
offene Stelle. Nach Repo: documentation 44, filetree 43, lib 18, lsp 15,
gopath 14, nvim-config 11, github_stats 10, mdview 10, der Rest verteilt.

Die Rangfolge der Regeln danach: `undefined-field` 562,
`param-type-mismatch` 458, `need-check-nil` 208, `duplicate-doc-field` 192,
`duplicate-set-field` 160, `assign-type-mismatch` 135, `inject-field` 118,
`undefined-doc-name` 87, `redundant-parameter` 84.

---

#### Gegenprobe mit dem festen Harness

Dieselbe Messung ein zweites Mal, mit `scripts/luals-scan` statt der
Ad-hoc-Umgebung: **2285** statt 2289. Vier Zaehler ueber 33 Workspaces -- genau
das Rauschen, das unten beschrieben ist, und kein Repo, das sich anders
verhaelt als gemeldet. Repoweise identisch bis auf den Zaehler:
documentation 383, lib 381, lsp 379, filetree 167, runtime-analysis 119. Auch
`need-check-nil` kommt wieder auf 208, davon 197 in den 32 Plugin-Workspaces
und 11 in der Config -- und **kein einziger mehr in `TESTS/` oder `scripts/`**,
was die Unterdrueckung an genau der beabsichtigten Stelle bestaetigt.

Die Gegenprobe zeigt nebenbei, wo die zwei Repos gelandet sind, die aus der
100er-Tabelle in Abschnitt 0 des Reports gefallen sind: spotlight.nvim
105 -> 49, gopath.nvim 101 -> 67.

---

#### Zwei Sachen, die beim Messen aufgefallen sind

**Die Messung rauscht.** `param-type-mismatch` schwankt zwischen zwei Laeufen
ueber denselben unveraenderten Stand um einige Zaehler -- pdfport.nvim, in
dieser Runde nicht angefasst, kam einmal mit -7 und einmal mit +7 zurueck. Ein
Delta unter etwa 10 in einem einzelnen Repo ist ohne Gegenprobe nicht
belastbar, und zwar in beide Richtungen: ein Minus als Erfolg zu lesen waere
derselbe Fehler wie ein Plus als Regression.

**`diff.nvim/plugin/diff.lua` hat CRLF-Zeilenenden** und faellt deshalb bei
`stylua --check` durch. Nicht von dieser Arbeit verursacht -- die Datei wurde
hier nicht angefasst, die Zeilenenden stammen aus `4cb35d4` vom 2026-08-06.
Damit stimmt Abschnitt 6 des Reports nicht mehr, der stylua ueber alle 31 Repos
sauber meldet; der Punkt steht dort jetzt wieder offen.

---

#### Die Messumgebung liegt jetzt fest im Repo

Nach zwei weggeworfenen Ad-hoc-Varianten steht sie als
[`scripts/luals-scan/`](../../../../scripts/luals-scan/README.md) im
Config-Repo: `scan.sh <pass> [repo ...]`, dann
`compare.py <vorher> <nachher>`. Die injizierte `workspace.library` wird darin
nicht mehr nachmodelliert, sondern per `build_library(root)` aus einem
laufenden nvim geholt -- damit entfaellt die Frage, ob das Modell dem Editor
entspricht. `compare.py` markiert Deltas unterhalb der Rauschgrenze, statt sie
als Ergebnis zu melden.

Zwei Fallen, die je einen Anlauf gekostet haben und in der README stehen:
`pwd` antwortet in Git Bash mit `/c/Users/…`, was das Windows-`nvim` nicht
findet -- headless nvim wartet dann stumm bis zum Timeout, statt zu scheitern
(dieselbe Klasse Haenger wie ein fehlendes `PLENARY_PATH` in der lsp.nvim-Suite).
Und `| tail` oder `| grep` puffern die Ausgabe, wodurch ein laufender Scan wie
ein haengender aussieht.

Beim Nachmessen fuer diesen Eintrag kam eine dritte dazu: der volle Lauf ohne
Repo-Argumente bricht ab, wenn er aus einem Worktree gestartet wird -- die
Config landet im Dump unter dem Ordnernamen des Worktrees, `scan.sh` sucht
`nvim-config.json` und findet nichts. Aus dem Haupt-Checkout tritt das nicht
auf, deshalb war es beim Bauen nicht aufgefallen. Behoben am 2026-08-31 in
`8e3d7ef4`.

---

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

---

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

---

#### Die zweite Ursache: der Workspace als seine eigene Library

`build_library.lua` haengte jeden `runtimepath`-Eintrag an. Die Dev-Repos liegen
auf dem `runtimepath`, also auch das Repo, das gerade offen ist. LuaLS liest
dessen Dateien dann zweimal, und jede `@class` darin meldet
`duplicate-doc-field` gegen sich selbst: **1085 der 1222 Warnungen der
nvim-Config** und 212 in runtime-analysis.nvim.

---

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

---

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

---

#### Was absichtlich unangetastet blieb

Acht Repos wuerden durch den Fix **schlechter** -- ihre `.luarc.json` behaelt
ihre Library-Liste, und damit bleibt fuer sie auch Fix 2 wirkungslos:
spotlight (+340), mdview (+75), lib (+35), fileops (+15), sessions (+7),
buffer-ctx (+4), neotree-fs-refactor (+4), migrate (+1). Drei weitere aendern
sich gar nicht: emojis, gopath, language.

Dass lib.nvim dabei ist, ist die unangenehme Pointe: das Repo, das die
Meta-Datei traegt, sieht sie selbst nur, weil sie in seinem eigenen Workspace
liegt.

---

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

---

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
