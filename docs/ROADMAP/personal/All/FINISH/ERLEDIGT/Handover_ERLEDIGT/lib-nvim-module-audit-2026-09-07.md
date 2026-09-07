# lib.nvim Modul-Audit (docs / @types / Aggregatoren / Feature-Ideen) — 2026-09-07

**Status: ABGESCHLOSSEN. Das gesamte `lib.nvim`-Modul-Audit ist fertig —
20 kleine/mittlere Module, alle fünf großen Subsysteme, der komplette
`lib.lua.*`-Namespace und der komplette Glue-Layer inkl. des letzten
offenen Punkts (der `all_functions.lua`-Cross-Check). Letzter gepushter
Stand: `lib.nvim@ca2660c`. Die vollständige Abschluss-Zusammenfassung
steht am Ende von `E:/repos/lib.nvim/docs/MODULE_AUDIT.md`.**

> **Lektionen zurückgeschrieben** nach `WKDBooks` (Commit `32d1093`):
> - `wkdbook-Lua/Checklists/regeln/LUA_NVIM.md` — `LLS-45` (`---@type ClassX`
>   auf `return M` wird nicht gegen die echte Form geprüft; falsche Klasse =
>   aktiv falsche Completions, kein Befund) + `LLS-46` (Phantom-`@field`;
>   Namens-Drift zwischen Backends *einer* Oberfläche).
> - `wkdbook-Lua/Checklists/luals/DIAGNOSEN.md` — neuer Abschnitt „Wenn
>   *keine* Meldung kommt" (Scan-Tool-Blindfleck).
> - `wkdbook-Lua/Checklists/luals/README.md § 8` + `gates/REVIEW.md § 5`.
> - `wkdbook-myplugins/ALL/Module-Audit-Findings.md` — die wiederkehrenden
>   Fund-Typen nach Ergiebigkeit, als Checkliste für den nächsten
>   docs/`@types`-Durchgang an *irgendeinem* Plugin.
> - `wkdbook-Neovim/.../96_lua-in-nvim/Packages-und-Modules/Aggregator-Module-Strategien.md`
>   — das metatable/lazy/eager-Muster + der `---@type`-Blindfleck.

> **Nachtrag 2026-09-07 (neunte Fortsetzung — LETZTER PUNKT, Audit
> abgeschlossen).** Der Cross-Check von `all_functions.lua`s `Lib`-Klasse
> gegen die drei Strategien (`metatable`/`eager`/`lazy`) — mit exakt der
> Methode, die bei `lib.lua.strings`/`tables` den größten Bug fand: jedes
> `---@field` gegen das, was die Strategien real zuweisen, jede Abweichung
> in den Quelltext verfolgt. **Sechs echte Funde, alle gefixt**
> (`lib.nvim@ca2660c`), verifiziert per `TESTS/run.lua` (grün) +
> Drei-Strategien-Runtime-Smoke-Test:
> 1. **`Lib.set`** war als Highlight-Setter `fun(group, opts, ns)` typisiert
>    — alle drei Strategien exportieren aber `lib.lua.tables.set` (die
>    generische `Set<T>`-Datenstruktur). Gleiche „aktiv falsche Completions"-
>    Bug-Klasse wie `Lib.Strings`. → `Lib.Tables.Set`, hoch in den
>    Namespace-Block.
> 2. **`Lib.safe`** war `Lib.Notify.Safe` — Strategien exportieren
>    `lib.lua.tables.safe` (defensive Table-Mutatoren). → `Lib.Tables.Safe`.
>    `notify.safe`/`hl.set` bleiben über `lib.notify`/`lib.hl` erreichbar.
> 3. **`globbable`** war ein Phantom-Feld: auf der Klasse seit `9265c34`,
>    aber in **keiner** Strategie verdrahtet — `lib.globbable(...)` warf
>    unter der Default-Strategie „unknown key". In alle drei verdrahtet.
> 4. **`count_lines`** fehlte in der `lazy`-Strategie (auf der Klasse, in
>    metatable + eager vorhanden). Ergänzt.
> 5. **`json_decode_to_string_array`** fehlte in `eager` + `lazy` (auf der
>    Basis-Klasse, in metatable vorhanden). In beiden ergänzt.
> 6. **`eager.lua`** nannte den Key `autogroup`/`autogroup_create_clear` —
>    überall sonst (+ `Lib.Strategy.Lazy`) heißt er `augroup`/…. In
>    `eager.lua` umbenannt.
>
> `lazy`s Extra-Keys decken sich jetzt exakt mit `Lib.Strategy.Lazy`.
> `eager`s Extras (`augroup*`, rohes `json`-Handle) sind als bewusst in
> einem Header-Kommentar in `eager.lua` dokumentiert. `configuration.md`s
> „All strategies expose the same surface" entschärft (widersprach der
> `Lib.Strategy.Lazy`-Klasse). `luassert.lua` gesichtet — vorbildlich
> selbst-dokumentiert, nichts zu fixen. `Lib.Modules` bewusst nicht
> angefasst (self-flagged). **Damit ist das komplette Audit durch.**

> **Nachtrag 2026-09-07 (achte Fortsetzung — Glue-Layer begonnen, wenig
> Budget übrig).** `lib.config` (setup/get/strategy_module),
> `lib.strategies.control` (register/active/keys/reset_cache) und
> `.telemetry_wrap` (setup/teardown) hatten alle drei keine Modul-
> Oberflächenklasse trotz vollständiger, realer Funktionen — gleiches
> mechanisches Muster wie im ganzen restlichen Audit. Ergänzt und
> verdrahtet, `lib.nvim@e77c981`. `lib.strategies.{eager,lazy,metatable}`
> (die drei echten Aggregator-Strategien) hatten bereits korrektes
> `---@type Lib`/`Lib.Strategy.Lazy`.
>
> **Nachtrag 2026-09-07 (siebte Fortsetzung — `lib.lua.*` durch, größter
> Einzelfund der ganzen Session).** `lib.lua.*` (16 Module, 90 Dateien,
> editor-unabhängiges reines Lua) durchgearbeitet — `strings`/`tables`
> (38 Dateien zusammen) an einen Sub-Agenten delegiert, jeder Fund selbst
> verifiziert, Rest (14 kleine Module) direkt geprüft.
>
> **Der größte Einzelfund der ganzen Session**: `Lib.Strings` und
> `Lib.Tables` (die beiden Top-Level-Aggregat-Klassen) beschrieben die
> **falsche** Form — ein echter Bug, keine Lücke. Beide `@types/init.lua`
> trugen seit jeher zwei Klassen: eine fiktive (auch `Lib.Strings`/
> `Lib.Tables` genannt), die eine verschachtelte Form beschrieb
> (`strings.core.trim`), die `init.lua` nie zurückgibt, und eine zweite
> (`Lib.Strings.ALL`/`Lib.Tables.All`), die korrekt die echte flache Form
> beschrieb (`strings.trim`) — aber nirgends referenziert wurde. Beide
> `init.lua`s eigenes `---@type Lib.Strings`/`Lib.Tables` zeigte die ganze
> Zeit auf die falsche (fiktive) Klasse: LuaLS gab **aktiv falsche**
> Vervollständigungen für `require("lib.lua.strings")`/`.tables` — nicht
> nur fehlende. Zusammengeführt. Beim Cross-Check jedes echten `M.<feld>`
> gegen die (jetzt echte) Klasse kamen noch drei weitere echte Lücken
> zutage: `strings.width` (das ganze Submodul, nicht nur seine 3
> geflatteten Funktionen), `strings.strip_ansi`, `tables.with` — alle real
> und fehlend. `tables.functional`/`.unique_table` sind bewusst nicht in
> `tables/init.lua` verdrahtet (Namens-/Argumentreihenfolge-Kollision mit
> den bereits geflatteten Array-Ops), aber nirgends stand das — README
> ergänzt. `strings.hex_to_string` war real und versprochen, aber nie
> verdrahtet — nachgezogen (kein Kollisionsrisiko, anders als bei
> `tables.functional`). Dazu 16 weitere mechanische `---@type`-Lücken
> (10× strings, 6× tables) plus `time.diff`. `modules.md`s `lib.lua.*`-
> Tabelle fehlten 7 von 16 Modulen komplett (`config`, `diff`, `dump`,
> `error`, `numeral`, `uuid`, `yaml`); `docs/API/foundations-lua.md`
> fehlten `class`/`context_manager`/`config`. Alle gefixt,
> `lib.nvim@a77df61`.
>
> **Nachtrag 2026-09-07 (sechste Fortsetzung — letztes großes Subsystem
> durch).** `buf_win_tab` (23 Dateien: buffer_utils/windows_utils/
> tabs_utils + capture/get_option/move_buffer_to_tab/normal_buffer/
> resize_guarded/safe_adjacent_buffer/selection/word_under_cursor)
> durchgearbeitet — bei weitem das kleinste und sauberste der fünf großen
> Subsysteme. `docs/API/ui-windows-buffers.md` war bereits vollständig
> korrekt (gute Bestätigung der `fs`/`cross`/`bindings`-Lehre, dass dieser
> Doku-Layer mitgeprüft werden muss — hier gab's nichts zu fixen). Echte
> Funde: `windows_utils.collect_win_report()` fehlte in `Command-List.md`
> (dem README-Ersatz für die drei losen Top-Level-Dateien) obwohl in
> `@types` und der API-Referenz bereits korrekt erfasst; `modules.md`s
> `buf_win_tab`-Zeile hatte überhaupt keine Links; `resize_guarded/README.md`
> nannte einen veralteten, falschen Dateipfad. Zwei niedrig-priorisierte
> Funde (unbenutzte, aber exakt passende `@types`-Aliase neben bereits
> selbst-typisierten `return function(...)`) bewusst NICHT gefixt — LuaLS
> typisiert in beiden Fällen bereits identisch, reine Kosmetik ohne
> funktionalen Nutzen, dasselbe Nicht-Bug-Muster wie `resolve_style.lua`
> aus einer früheren Runde. Alle gefixt, `lib.nvim@5b96ce5`.
>
> **Damit sind alle fünf großen Subsysteme durch.** Verbleibend:
> `lib.lua.*` (9 Module, noch nicht inventarisiert) und der Glue-Layer
> (`lib/config`, `lib/strategies/*`, Top-`@types`) — geschätzt noch
> ~1.5 Sessions.
>
> **Nachtrag 2026-09-07 (fünfte Fortsetzung).** `bindings` (34 Dateien:
> keymap/autocmd/usercmd + composer/dispatcher/modifier/portability/audit)
> durchgearbeitet. Alle Aggregator-`return`s hatten bereits korrektes
> `---@type` (anders als `cross` — dieses Subsystem war schon gut in
> Schuss). `composer` — laut eigener Doku "meistgenutzte Komponente der
> Library, 30+ konsumierende Plugins" — bekam einen dedizierten Tiefen-Pass
> (405-Zeilen-README gegen jede interne Datei gegengelesen): **komplett
> sauber**, kein einziger Fund. Echte Funde: `keymap.portability` hatte
> keine Modul-Oberflächen-Klasse, ihr `Tier`-Alias stand inline im Code
> statt unter `@types/`; `autocmd.docs`/`bindings.audit` hatten ihre
> `@types`-Klassen ebenfalls inline statt unter `@types/`; `autocmd.docs.
> write_all()` (ein fertiges Multi-Repo-Batch-Feature) fehlte komplett im
> README; `bindings.audit` hatte gleich **drei** komplett undokumentierte
> Lint-Features (`naming_candidates`, `prefix_ambiguities`,
> `checklist_lines`) obwohl `create_usercmd()` bereits alle sechs
> zugehörigen Commands registrierte; `docs/API/commands-and-infra.md`
> fehlten `keymap.modifier`/`keymap.portability` komplett sowie
> `registered`/`delete`/`docs` in den `autocmd`/`usercmd`-Abschnitten.
> Alle gefixt, `lib.nvim@9deb1e2`.
>
> **Nachtrag 2026-09-07 (vierte Fortsetzung).** `cross` (~28 Leaf-Module,
> 42 Dateien) durchgearbeitet, gleiche reduzierte Tiefe. Größter Fund im
> ganzen Audit bisher: `cross/init.lua` — der Root-Aggregator, der
> meistgenutzte Require im ganzen Subsystem — hatte trotz vollständig
> korrekter `Lib.Cross`-Klasse kein `---@type`. Anders als `fs`/`ui`
> (reine Leaf-Namespaces ohne echten Aggregator) hat `cross` einen
> waschechten, funktionierenden `init.lua`-Aggregator — das macht diesen
> Fix den bisher wirkungsvollsten der ganzen Session. Weitere Funde:
> `cross.executable` hatte gar keine Modul-Oberflächen-Klasse (gleiches
> Muster wie `fs.path`) und `clear(name?)` war nirgends dokumentiert;
> `run_argv.run_async_captured` (eine fertige, gegen UI-Freezes gebaute
> Async-Funktion) fehlte in README und API-Referenz; `fs.mutate`/`run.env`
> hatten das übliche fehlende `---@type`, dazu fehlten `symlink`/
> `hardlink` bzw. `array()` in `docs/API/cross-platform.md`;
> `uv.spawn_capture`s `opts.stdin` (Credential-Handoff ohne argv-Leck) war
> ebenfalls nirgends dokumentiert. `modules.md`s `lib.nvim.cross`-Zeile
> verlinkte fälschlich auf `fs/separators/README.md` statt die eigene
> Root-README. Alle gefixt, `lib.nvim@0d21f7d`.
>
> **Nachtrag 2026-09-07 (zweite Fortsetzung).** `fs` (29 Leaf-Submodule,
> 52 Dateien) durchgearbeitet, gleiche reduzierte Tiefe wie bei `ui`.
> Dabei entdeckt: `docs/API/*.md` ist eine ganze zweite, detailliertere
> Doku-Ebene (ein File pro großem Subsystem), die die bisherige Methode
> nicht auf dem Schirm hatte — `modules.md`s Zeile pro Modul ist bewusst
> nur ein Einzeiler, der dorthin verweist (steht explizit so in
> `docs/API/README.md`). Echte Funde: `fs.path` und `fs.ignore.list`
> hatten beide gar keine Modul-Oberflächen-Klasse (dasselbe Muster wie
> `harvest`); `fs.relpath`/`fs.path_shorten` hatten reale READMEs, waren
> aber in `modules.md` unverlinkt und `filesystem.md` sagte fälschlich
> "(no README)" für `relpath`; `fs.polymorphic_rootresolver` hatte drei
> Doku-Drifts (undokumentiertes `cfg.resolve`-Feld, falscher Modul-Pfad +
> falsches Call-Pattern im Setup-Beispiel, irreführendes Flow-Diagram).
> Alle gefixt, `lib.nvim@88432e1`. Nebenbef: eine andere Session/ein
> anderer Prozess hat parallel auf demselben `lib.nvim`-Checkout
> gearbeitet (ein fremder Commit `bb063e5` lag zwischen Sessionstart und
> meinem Push; eine unfertige, in sich widersprüchliche Änderung in
> `lua/lib/@types/init.lua` lag uncommittet im Baum) — bewusst nicht
> angefasst/committet, gehört nicht zu diesem Audit.
>
> **Nachtrag 2026-09-07 (dritte Fortsetzung).** `bb063e5` war dieser
> Chat/dieses Fenster — der Regressions-Fix aus der `ui`-Runde vorhin,
> von CI selbst gefangen (siehe Chat-Verlauf). Für `fs` selbst kein
> weiterer Handlungsbedarf mehr: eigene Verifikation (unabhängig, gleiche
> Methode) kommt zu denselben Ergebnissen wie oben — die 25 übrigen
> Leaf-Module sind sauber, das Bare-Function-Return-Muster ohne
> `---@type` ist bei allen korrekt (jeweils eigene `---@param`/`---@return`
> direkt an der Funktion, kein Bug). Die oben erwähnte liegengebliebene
> `lua/lib/@types/init.lua`-Änderung war tatsächlich in sich
> widersprüchlich (Kommentar sagte "narrowed to `table`", das Feld blieb
> aber `Lib.Nvim`) — fertiggestellt, `lib.nvim@e5aa97c`. Kein Teil des
> großen Subsystem-Sweeps, nur ein Fundstück, das sonst für die spätere
> Glue-Layer-Runde verwirrend im Baum gelegen hätte.
>
> **Nachtrag 2026-09-07 (Fortsetzung).** `ui` (29 Dateien: kit/list/
> statusline/hl/nerd_font) durchgearbeitet, reduzierte Tiefe wie unten unter
> "Zwei Stellschrauben" vorgeschlagen — Top-Level-README/`@types`/
> `modules.md`-Wiring pro Leaf geprüft, volle Funktions-für-Funktion-
> README-Diffs nur wo etwas auffiel (nicht für alle 20 `kit`-Dateien
> einzeln). Zwei echte Funde: `nerd_font` komplett undokumentiert
> (dieselbe "vergessenes Submodul"-Form wie `image_preview`/
> `notify.resolve_log_level`), `kit.compare` (eine ganze fertige Feature —
> Zwei-Items-vergleichen-Flow) hatte null README-Abdeckung. Beide gefixt,
> `lib.nvim@9143f01`. Details im Pro-Modul-Log der Tracking-Datei.

Auslöser (Chat, Repo `lib.nvim` in einem Worktree, nicht nvim-config selbst):

> lib.nvim - alle module durcgehen und checken, ob docs, @types, als auch
> aggregatoren noch korrekt sind. Die lib.nvim ist für mich umso mehr wert,
> umso besser die docs sind. Dabei auch gleich feature ideen einbringen,
> sprich bei jedem modul am ende auch checken "fehlt etwass sinnvolles?"

Tracking-Datei **im lib.nvim-Repo selbst** (nicht hier), lebt fort über
Sessions hinweg: [`E:/repos/lib.nvim/docs/MODULE_AUDIT.md`](file:///E:/repos/lib.nvim/docs/MODULE_AUDIT.md) —
dort steht die vollständige Inventar-Tabelle aller Top-Level-Module
(init/README/@types-Vorhandensein) plus das Pro-Modul-Log mit jedem Fund.
Diese Handover-Datei hier ist nur die Kurzfassung + Aufwandsschätzung.

---

## Table of contents

- [Methode](#methode)
- [Bisheriger Fortschritt](#bisheriger-fortschritt)
- [Bisherige Funde](#bisherige-funde)
- [Was noch aussteht](#was-noch-aussteht)
- [Aufwandsschätzung](#aufwandsschätzung)
- [Wie weitermachen](#wie-weitermachen)

---

## Methode

Pro Modul (Granularität: die Namespace-Tabellen in
[`docs/modules.md`](file:///E:/repos/lib.nvim/docs/modules.md)):

1. `init.lua` (echte API) gegen `README.md` (dokumentierte API) gegenlesen —
   fehlende/überzählige/falsch beschriebene Funktionen.
2. `@types/*.lua` gegen die tatsächlichen Parameter/Rückgaben gegenlesen;
   prüfen ob die Modul-Oberfläche selbst eine `@class` hat und ob `return M`
   ein `---@type` trägt (Konvention laut
   [`docs/conventions.md`](file:///E:/repos/lib.nvim/docs/conventions.md)).
3. Wiring prüfen: Zeile in `docs/modules.md`s Namespace-Tabelle + Per-Module-
   Doc-Bullet; bei `:help`-würdigen Modulen auch `doc/lib.nvim-<modul>.txt` +
   Hub-Zeile in `doc/lib.nvim.txt`.
4. Feature-Idee-Check: "fehlt etwas Sinnvolles?" — notiert, nicht automatisch
   gebaut (das ist eine Design-Entscheidung, keine Audit-Aufgabe).

Gefundene Bugs/Lücken werden direkt gefixt, committet und auf `main`
gepusht (kein Co-Author), in Batches von ca. 4-6 Modulen.

## Bisheriger Fortschritt

**20 von ~37 Top-Level-Modulen unter `lib.nvim.*` durch**, alle "klein bis
mittel" (2-15 Dateien): `core`, `async`, `contextmenu`, `count`, `debounce`,
`dotrepeat`, `git`, `json`, `lastcmd`, `notify`, `require`, `safe_api`,
`selection`, `store`, `terminal`, `token`, `health`, `harvest`, `cache`,
`deps`, `logger`, `progress`, `window`, `normalize`, `system`, `dev`,
`image_preview`, `lua_ls`, `markdown`, `neotree`, `net`, `treesitter`,
`buffer` (das sind schon mehr als 20 Namen, weil manche als "ein Modul" in
der ursprünglichen Zählung liefen, aber mehrere Unterdateien mitbrachten —
die Inventar-Tabelle in `MODULE_AUDIT.md` ist die genaue Quelle).

Sechs Commits gepusht (`cc08fad` … `8f46452`), insgesamt ~15 echte Fixes.

`lib.nvim_usrcmds` (eigener Namespace neben `lib.nvim`, nicht in dessen
Baum) stichprobenartig geprüft — sauber dokumentiert (README, root-README,
`docs/BINDINGS.md`), bewusst nicht in `modules.md` gelistet, da andere
Kategorie (Opt-in-Usercmds für Nutzer der Library, nicht Library-API für
andere Plugins).

## Bisherige Funde

Details im Pro-Modul-Log der Tracking-Datei. Die wiederkehrenden Muster:

**Mechanisch, über viele Module verteilt** (je ~5-6× gefunden, immer
gefixt): `return M` ohne `---@type`-Annotation trotz vorhandener/fehlender
Modul-Oberflächen-Klasse (`debounce`, `git`, `window.tag`, `neotree.node`,
`neotree.watch`, `net.curl`, `dev.duplicates`) — LuaLS gab für
`require(...)` dieser Module schlicht keine Typisierung.

**"Vergessenes Submodul beim Aggregieren"** (echtes, fertiges, aktiv
genutztes Submodul existiert, ist aber nirgends verdrahtet/dokumentiert):
- `notify.resolve_log_level` — von `lib.nvim.logger` aktiv genutzt, aber
  nicht auf `notify`s `M` gehängt, nicht im README, nicht typisiert.
- `window.find_by_filetype` — komplett generisch nutzbar, aber nicht
  aggregiert, nicht in `@types`, nicht in der Modulstruktur des READMEs.
- **`image_preview` — der größte Einzelfund**: komplettes, fertiges
  3-Provider-Modul (images.nvim/snacks/image.nvim) mit **null** der drei
  Pflicht-Doku-Ebenen (kein README, kein `@types`, kein Eintrag in
  `modules.md`), obwohl es schon einen Einzeiler im `doc/lib.nvim.txt`-Hub
  hatte — also bekannt, aber nie fertiggestellt. Komplett nachgezogen.
- `harvest`: keines der 4 Files (`init`/`scope`/`render`/`sink`) hatte auch
  nur eine Modul-Oberflächen-Klasse — nur die Daten-Shape-Typen existierten.
  LuaLS gab vorher **null** Signatur-Hilfe für jeden `harvest.*`-Aufruf.

**Ein echter Tippfehler-Bug**: `lua_ls.insert.module_annnotation` (das
Verzeichnis trägt selbst einen Tippfehler, dreifaches n) — dessen eigenes
README hatte in **allen vier** Code-Beispielen den falsch geschriebenen,
nicht existierenden Pfad (`module_annotation`, doppeltes n). Copy-paste des
READMEs hätte einen `require`-Fehler geworfen. Auch zwei `notify.warn`-Präfixe
im Modul selbst und der Link-Text in `modules.md` trugen den falschen Namen.
Gefixt auf den echten (tippfehlerhaften) Pfad; das Verzeichnis selbst nicht
umbenannt (wäre ein Breaking Change für jeden externen Konsumenten, der schon
den Tippfehler-Pfad nutzt — das ist eine Entscheidung für dich, nicht für
einen Audit-Sweep).

**README-Lücken bei bereits korrekt typisierten Funktionen** (mehrfach):
`logger` (`count`/`counters`/`add_sink`/`loggers()` fehlten komplett in der
Prosa), `window` (vier bereits aggregierte Funktionen fehlten in der
Funktions-Prosa), `neotree.watch` (`installed()`/`clear()`), `net.curl`
(`is_secret_header`/`config_quote` nur implizit erwähnt).

Insgesamt: die meisten Module sind **sehr sauber** — README/@types/Code
decken sich exakt, teils vorbildlich (z. B. `normalize`, `cache`, `deps`,
`store`). Kein einziger Fall von grob falscher/veralteter Fach-Dokumentation
gefunden — jeder Fund war entweder mechanisch (fehlende Typ-Annotation) oder
"etwas Fertiges wurde nie zu Ende verdrahtet".

## Was noch aussteht

**Nichts. Das Audit ist vollständig abgeschlossen** — alle fünf großen
Subsysteme, der komplette `lib.lua.*`-Namespace UND der komplette
Glue-Layer (`lib/config`, alle vier Strategien, `lib/@types/*` inkl. des
`all_functions.lua`-Cross-Checks). `Lib.Modules` bleibt als einziger Punkt
bewusst unangetastet — self-flagged als „pending external-consumer check",
das ist keine offene Audit-Aufgabe, sondern eine bewusste Design-/
Breaking-Change-Entscheidung für den Repo-Eigentümer.

**Über den ganzen Audit gelernte, wiederkehrende Muster** (falls später
ein ähnlicher Sweep über ein anderes Plugin ansteht):
- Bei Subsystemen/Modulen mit einem **echten** `init.lua`-Aggregator
  zuerst prüfen, ob dessen `return M` ein `---@type` trägt, UND ob diese
  Klasse tatsächlich die reale Rückgabeform beschreibt. Bei `cross` fehlte
  die Annotation ganz (größter Einzelfund unter den fünf Subsystemen); bei
  `lib.lua.strings`/`tables` war die Annotation vorhanden, zeigte aber auf
  eine **falsche** Klasse (eine fiktive, nie referenzierte zweite Klasse
  beschrieb fälschlich eine verschachtelte statt der echten flachen Form)
  — größter Einzelfund der ganzen Session, weil LuaLS dadurch aktiv
  falsche statt nur fehlender Typinfo lieferte. Beim Glue-Layer (der
  bereits bekannte `Lib.Modules`-Altfall) also nicht nur auf Vorhandensein
  prüfen, sondern jedes `M.<feld>` gegen die Klasse cross-checken
  (`grep -oE "^M\.[a-zA-Z_0-9]+" <init.lua>` vs. die `@field`-Liste).
- Inline-`@class`-Definitionen direkt im Modul-Code statt unter `@types/`
  (Convention-Verstoß): `grep -rn "^---@class" <modul-pfad> | grep -v
  '@types/'` findet sie zuverlässig — tauchte bei `bindings` dreimal auf,
  bei `lib.lua.strings.location` einmal.
- Ein `docs/API/<thema>.md`-Layer existiert für jedes der fünf Subsysteme
  UND für `lib.lua.*` (`foundations-lua.md`) — von Anfang an mitprüfen.
  Bei `foundations-lua.md` fehlten `class`/`context_manager`/`config`
  komplett, obwohl 13 von 16 Modulen bereits abgedeckt waren.
- Ein fertiges, korrekt typisiertes Feature, das schlicht nie ins README
  geschrieben wurde ("vergessenes Feature") tauchte in JEDEM Block
  mindestens einmal auf (`ui.kit.compare`, `fs.path`,
  `cross.run_argv.run_async_captured`, `bindings.audit`s drei Lints,
  `buf_win_tab.windows_utils.collect_win_report`,
  `strings.hex_to_string`) — der ergiebigste einzelne Fund-Typ dieses
  ganzen Audits, quer durch alle Blöcke.
- Nicht jeder fehlende `---@type` ist ein Fund: ein bare `return
  function(...)` mit vollständigen eigenen `---@param`/`---@return` ist
  bereits selbst-typisiert (LuaLS braucht dafür keine separate Klasse).
  Etabliertes Nicht-Bug-Muster seit `resolve_style.lua`/`is_dir` aus der
  ersten Session.
- Ein Modul, das absichtlich NICHT in einen Aggregator verdrahtet ist
  (Namens-/Signatur-Kollision mit bereits verdrahteten Funktionen), muss
  das trotzdem irgendwo sagen — sonst sieht es wie eine vergessene Lücke
  aus. `strings.transform` hatte das schon vorbildlich dokumentiert;
  `tables.functional`/`.unique_table` (gleiche Kollisionsursache) hatten
  es nirgends erwähnt.

`buffer` (das in der ersten Fassung dieser Handover-Datei noch als "Sonderfall
ohne init.lua, zu verifizieren" unter den großen Modulen stand) ist bereits
durch — tatsächlich ein kleines, sauberes Leaf-only-Namespace wie dokumentiert,
kein eigenes Teilprojekt.

## Aufwandsschätzung

Erledigt. Keine offene Arbeit mehr an diesem Audit.

## Ergebnis

Das gesamte `lib.nvim`-Modul-Audit ist abgeschlossen. Die vollständige
Abschluss-Zusammenfassung (alle wiederkehrenden Fund-Typen, alle bewusst
nicht angefassten Punkte) steht am Ende von
`E:/repos/lib.nvim/docs/MODULE_AUDIT.md` unter „Audit complete —
2026-09-07". Letzter gepushter Stand: `lib.nvim@ca2660c`.

Falls doch noch einmal etwas nachzuziehen ist: `Lib.Modules` /
`Lib.Fs` / `Lib.Cross.ALL` / `Lib.BufWinTab` (fiktive Aggregator-Klassen,
alle self-flagged) und der `module_annnotation`-Tippfehler im
Verzeichnisnamen sind bewusst offen gelassene Breaking-Change-
Entscheidungen — kein Audit-Nachholbedarf, sondern Sache des Repo-
Eigentümers.
