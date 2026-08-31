# Diagnostics -- Erledigt

Aus `docs/ROADMAP/personal/All/Diagnostics.md` herausgenommene Punkte, sobald
sie abgeschlossen sind. Neueste zuerst. Der Report dort bleibt die Quelle fuer
alles, was noch offen ist.

---

## Table of content

  - [2026-08-31](#2026-08-31)
    - [Cluster F: `inject-field` in lib.nvim -- und die `missing-fields`-Reste daneben](#cluster-f-inject-field-in-libnvim-und-die-missing-fields-reste-daneben)
      - [Die Zombie-Klassen, und was sie verdeckt haben](#die-zombie-klassen-und-was-sie-verdeckt-haben)
      - [Die Annotation stand nur auf der falschen Zeile](#die-annotation-stand-nur-auf-der-falschen-zeile)
      - [Ein Typ, der nicht bloss zu frueh, sondern falsch war](#ein-typ-der-nicht-bloss-zu-frueh-sondern-falsch-war)
      - [Neun Schluessel, die es nur unter einer Strategie gibt](#neun-schluessel-die-es-nur-unter-einer-strategie-gibt)
      - [Der Alias, der eine echte Luecke zugedeckt hat](#der-alias-der-eine-echte-luecke-zugedeckt-hat)
      - [Gemessen](#gemessen)
    - [documentation.nvim: die restlichen 155 -- der erste vertikale Durchgang](#documentationnvim-die-restlichen-155-der-erste-vertikale-durchgang)
      - [Das Muster, das die Haelfte erklaert: der Guard sitzt auf einem Feld](#das-muster-das-die-haelfte-erklaert-der-guard-sitzt-auf-einem-feld)
      - [Die Kinder eines Treesitter-Knotens](#die-kinder-eines-treesitter-knotens)
      - [Ein echter Fehler: zwoelf Advice-Listen, die nie jemand gesehen hat](#ein-echter-fehler-zwoelf-advice-listen-die-nie-jemand-gesehen-hat)
      - [Zwei verwaiste Doc-Bloecke](#zwei-verwaiste-doc-bloecke)
      - [Annotationen, die schlicht falsch waren](#annotationen-die-schlicht-falsch-waren)
      - [Der Overload, der die Zahl verschlechtert hat](#der-overload-der-die-zahl-verschlechtert-hat)
      - [Unterdrueckt, mit der Begruendung daneben](#unterdrueckt-mit-der-begruendung-daneben)
      - [Gemessen](#gemessen-1)
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

## 2026-08-31

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
