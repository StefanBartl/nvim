# lib.nvim Modul-Audit (docs / @types / Aggregatoren / Feature-Ideen) — 2026-09-07

**Status: 20 kleine/mittlere Module + `ui` + `fs` (zwei der fünf großen
Subsysteme, reduzierte Tiefe) durch. Verbleibend: `bindings`/`cross`/
`buf_win_tab`, der komplette `lib.lua.*`-Namespace und der Glue-Layer.**

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

- **Drei der fünf großen Subsysteme** (`ui` und `fs` sind durch — siehe
  Nachträge oben; je eigene READMEs/@types pro Untermodul laut
  `modules.md`): `bindings` (34 Lua-Dateien), `cross` (42),
  `buf_win_tab` (23). Diese sind de facto eigene Teilprojekte.
  **Neu gelernt bei `fs`**: für jedes der fünf großen Subsysteme existiert
  auch ein `docs/API/<thema>.md` — eine zweite, funktionssignatur-genaue
  Doku-Ebene neben den einzelnen Leaf-READMEs. Die sollte bei `bindings`/
  `cross`/`buf_win_tab` von Anfang an mitgeprüft werden (Vollständigkeit,
  Submodul-Zahl in der Kopfzeile aktuell, "(see README)"-Marker korrekt),
  nicht erst nachträglich entdeckt werden wie bei `fs`.
- **`lib.lua.*`-Namespace** (Lua-nur, kein Neovim-Bezug): `tables`,
  `strings`, `functions`, `time`, `json`, `memo`, `lazy`, `class`,
  `context_manager` — noch **gar nicht** inventarisiert, geschweige denn
  geprüft.
- **Glue-Layer**: `lib/config`, `lib/strategies/*` (4 Aggregator-Strategien:
  metatable/lazy/eager/control), `lib/@types/*` — inkl. der bereits
  gefundenen `Lib.Modules`-Altlast, die dort explizit als offen markiert ist.

`buffer` (das in der ersten Fassung dieser Handover-Datei noch als "Sonderfall
ohne init.lua, zu verifizieren" unter den großen Modulen stand) ist bereits
durch — tatsächlich ein kleines, sauberes Leaf-only-Namespace wie dokumentiert,
kein eigenes Teilprojekt.

## Aufwandsschätzung

Aktualisiert nach jetzt 20 durchgearbeiteten kleinen/mittleren Modulen in
einer Session (inkl. aller Fixes, 6 Commits, Push): das Tempo war höher als
ursprünglich angenommen, weil die allermeisten Module bereits sauber waren
und nur kurze Bestätigungs-Checks brauchten — nur ~6 von 20 brauchten
tatsächliche Fixes.

| Block | Umfang | Geschätzter Aufwand |
|---|---|---|
| `bindings`, `cross`, `buf_win_tab` (`ui`+`fs` bereits durch) | je 23-42 Dateien, viele Unter-READMEs/@types pro Leaf-Modul | **je eine halbe bis ganze eigene Session — macht zusammen 2-3 Sessions** |
| `lib.lua.*` (9 Module) | vermutlich klein wie die meisten `lib.nvim`-Module, aber noch ungeprüft | **~1 Session** |
| Glue-Layer (`config`, `strategies`, Top-`@types`) | klein an Dateizahl, aber hoher Prüfaufwand (Aggregator-Logik, Verweise) — hier liegt schon eine bekannte Altlast (`Lib.Modules`) | **~0.5 Session** |

**Summe: grob 4.5-6.5 weitere Arbeits-Sessions.** Die fünf großen Subsysteme
sind jetzt der klar dominante Rest-Aufwand — jedes davon ist im Umfang
vergleichbar mit allen 20 bisher geprüften Modulen zusammen.

Zwei Stellschrauben, falls das zu lang ist:
- **Tiefe reduzieren** für die fünf großen Subsysteme (nur Top-Level-README
  + Stichproben bei den Leaf-Modulen statt jedes einzelne Leaf-Modul mit
  derselben Sorgfalt) — spart wahrscheinlich 2-3 der 3-5 Sessions dort.
- **Priorisieren**: zuerst die Module, die andere Plugins tatsächlich als
  Dependency nutzen (`lib.nvim.window`, `.ui.kit`, `.fs.*`, `.cross.*`,
  `.progress`, `.deps` — laut [[lib-nvim-dependency]]), Rest später.

## Wie weitermachen

1. `E:/repos/lib.nvim/docs/MODULE_AUDIT.md` öffnen — Pro-Modul-Log zeigt
   alle fertigen Module mit ✅ und den jeweiligen Funden (`ui` und `fs`
   jetzt beide drin).
2. Nächster Schritt: `cross` (42 Dateien) oder `bindings` (34 Dateien) mit
   derselben reduzierten Tiefe wie `ui`/`fs` — laut
   [[lib-nvim-dependency]] wird `cross` von anderen Plugins aktiv genutzt,
   also vermutlich zuerst. Dabei gleich `docs/API/cross-platform.md` bzw.
   `docs/API/commands-and-infra.md` mitprüfen (siehe Nachtrag oben). Danach
   `buf_win_tab`, dann `lib.lua.*` (9 Module, noch nicht inventarisiert),
   zuletzt der Glue-Layer.
3. Jeder Batch: Fixes direkt im Code, Tracking-Datei nachführen, ein Commit
   pro Batch, sofort auf `main` gepusht. Vor dem Push kurz `git log`/
   `git status` gegenchecken — bei der `fs`-Session hat parallel eine
   andere Session/ein anderer Prozess auf demselben Checkout committet
   und eine unfertige Änderung hinterlassen; nicht automatisch annehmen,
   dass der Baum so sauber ist wie beim Sessionstart.
