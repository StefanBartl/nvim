# P5 — Die fünf Wiederholungsläufe, Stand 2026-09-05

Begleitet [`LAST_CDX_TASKS.md` §8](LAST_CDX_TASKS.md#8-die-fünf-wiederholungsläufe).
Vier der fünf Läufe sind durch; der fünfte (8.2, Diagnostics) ist in zwei
Hälften zerfallen — **8.2a (die 12 Repos + lsp.nvim mechanisch auf 0) ist
jetzt ebenfalls durch, siehe der neue Abschnitt am Ende.** 8.2b (die sieben/acht
übrigen Regel-Familien, ~250 Punkte, Handprüfung) ist **angelaufen** — die
`SEC-*`-Welle (24 Regeln) läuft über 22 von 32 Repos, siehe der Abschnitt
„8.2b — SEC-* Welle" am Ende. Die übrigen sieben Familien und die
verbleibenden 9 Repos sind weiterhin offen.

Alle vier Werkzeuge liefen **nicht** über die Usercmds aus dem Standard
(`:LibDuplicateScan`, `:LibBindingsAudit`, `:LibBindingsAuditGaps`) — diese
sind zwar in `lib.nvim` implementiert (`M.create_usercmd()`), aber **in
keiner Config jemals aufgerufen worden**. Die zugrunde liegenden Lua-Module
sind aber direkt aufrufbar und wurden so verwendet.

---

## 8.1 — lib.nvim-Nutzung im neuen Code

**Werkzeug:** `require("lib.nvim.dev.duplicates").lines("E:/repos")`,
headless mit nur `lib.nvim` auf dem `rtp` (kein voller Config-Start nötig).

**6 Gruppen gefunden, 5 davon erwartet** (deckungsgleich mit der in §8.1
genannten Ausnahmeliste):

| Gruppe | Repos | Status |
|---|---|---|
| `M.get` (config-Modul) | dap, debugging, diff, emojis, lsp, recommender | erwartet (`config.M.get`) |
| `M.augroup` | cascade, spotlight | erwartet |
| `resolve` (notify) | buffer-ctx, fileops | erwartet (`notify.resolve`) |
| `try_require` | cascade, spotlight | erwartet |
| `try_require` | emojis, recommender | **neue Instanz derselben Ausnahme** — selbe Soft-Dependency-Begründung, andere Plugin-Paarung |
| `h_info` (Health-Formatierung) | documentation.nvim, runtime-analysis.nvim | **neu, nicht in der Ausnahmeliste** |

**Der eine echte Fund:** `h_info(msg, advice)` — eine 4-Zeilen-Funktion, die
eine Health-Zeile um einen `ADVICE:`-Block erweitert — ist in
`documentation.nvim/lua/documentation/editor/health.lua` und
`runtime-analysis.nvim/lua/runtime-analysis/health.lua` wortgleich. Der
Kommentar in `runtime-analysis.nvim` sagt es sogar selbst: *"as
documentation.nvim's `editor/health.lua`"* — bewusst kopiert, nicht zufällig
gleich. Ob das eine Extraktion nach `lib.nvim` rechtfertigt (4 Zeilen, laut
`duplicates.lua`s eigener `MIN_LINES`-Schwelle gerade noch meldenswert) oder
als akzeptierte Kleinst-Duplikation bleibt, ist eine Autorenentscheidung —
nicht automatisch behoben.

---

## 8.3 — Magic Numbers erneut geprüft

**Werkzeug:** `require("insights.smells").magic_numbers(root)`, einmal pro
Repo aufgerufen (nicht über `E:/repos` als Ganzes — das Modul ist laut
eigenem Kopf für *ein* Projekt gedacht, und ein blinder Lauf über alle 52
Ordner unter `E:/repos` dauerte im Test mehrere Minuten statt Sekunden).

**220 Treffer** (`.p5_8_3_magic_v2.txt` im Session-Arbeitsverzeichnis) —
gegenüber 43 beim letzten Lauf eine deutliche Zunahme, aber erwartbar: das
ist neuer Code aus mehreren Wochen aktiver Arbeit, nicht ein Regressionswert.

| Art | Treffer |
|---|---|
| `wait` (`vim.wait(N, …)`, N > 50ms — die Unter-50ms-Filterregel steckt schon im Werkzeug selbst, `TICK_MAX`) | 169 |
| `frac_cols` (`vim.o.columns * 0.X`) | 19 |
| `frac_lines` (`vim.o.lines * 0.X`) | 16 |
| `timeout` | 12 |
| `defer` | 3 |

**Der eine Befund, den §8.3 explizit vorhersagt, ist eingetreten.** Die
gemeinsame Hilfsfunktion für Float-Größen aus dem letzten Durchgang (26
Fälle in 9 Plugins, damals gelöst) hat **35 neue, von Hand geschriebene
`vim.o.columns * 0.X` / `vim.o.lines * 0.X`-Stellen** in **9 Plugins**
bekommen: `filetree.nvim`, `hover.nvim`, `images.nvim`, `insights.nvim`,
`language.nvim` (×3), `lib.nvim` selbst, `lsp.nvim` (×3), `reposcope.nvim`
(×4), `runtime-analysis.nvim`. Eine Suche nach einer aktuell existierenden,
*öffentlichen* Sammel-Funktion dafür in `lib.nvim.ui.kit` blieb erfolglos —
`layout.lua`s `resolve_size` ist `@internal` und Teil eines anderen,
schwereren Mechanismus (Mehrfenster-Layout), keine Ein-Zeiler-Ersatz. Zwei
Möglichkeiten, beide eine Autorenentscheidung: entweder gab es nie eine
*öffentliche* Helper-Funktion (nur individuelle Fixes pro Aufrufstelle beim
letzten Mal), oder eine existierende wurde seither entfernt/umbenannt.

Die 169 `wait`-Treffer und die übrigen sind nicht einzeln bewertet — bei
dieser Menge ist eine Verdikt-pro-Zeile-Prüfung kein Wiederholungslauf mehr,
sondern eine eigene mehrstündige Aufgabe. Die Rohliste liegt vor, für einen
gezielten Blick.

---

## 8.4 — Keymap↔Usercmd-Parität

**Werkzeug:** `lib.nvim.bindings.audit` (`.lines()`, `.gap_lines()`),
aufgerufen in einer **echten, vollen Session** — die Registrierung passiert
erst, wenn jedes Plugin sein `setup()` tatsächlich durchlaufen hat, und die
meisten sind `ft`/`event`-lazy. Alle 30 personal Plugins per
`lazy.core.loader.load(name)` zwangsweise geladen, danach `audit.lines()`
gegen die jetzt volle Registry.

**Ein Stolperstein unterwegs:** `reposcope.nvim`s Lazy-Spec trägt
`name = "reposcope"` (Zeile 622 in `plugins/personal/init.lua`) — der erste
Versuch, es unter seinem Repo-Namen `"reposcope.nvim"` zu laden, schlug mit
"Plugin reposcope.nvim not found" fehl und hätte seine 2 zusätzlichen
Keymap-Aktionen sonst stillschweigend aus der Prüfung gelassen.

**Ergebnis: 345 Keymap-Aktionen, 2 Kandidaten ohne Kommando-Gegenstück —
beide keine echten Befunde:**

```
bindings.<leader>dv    [Diffview] Open
bindings.<leader>fth   [FzfLua] Colorschemes
```

Beides Fremdplugin-Keymaps (Diffview, fzf-lua), die über die generische
Registry mitlaufen, nicht Teil irgendeines der 32 eigenen Plugins. **Letzter
Stand „keine Lücke über 29 Plugins" bestätigt sich unverändert für jetzt 30.**

---

## 8.5 — Konfigurierbarkeit

**Werkzeug:** `require("insights.smells").hardcoded_constants(root)`, gleiche
Methode wie 8.3.

**38 Treffer** (`.p5_8_5_const_v2.txt`), gegenüber dem letzten Lauf spürbar
mehr. Die weit überwiegende Mehrheit sieht nach legitimer interner
Implementierungsgrenze aus (Puffergrößen, Timeouts, Spaltenbreiten für
Text-UI) — keine `DEFAULT_`-Präfixe wurden automatisch abgezogen, weil keiner
davon einen trägt.

**Ein Fund lohnt einen zweiten Blick, aus derselben Familie wie 8.1:**
`reposcope.nvim` hat `UNAVAILABLE_MSG = "README from this repository
couldn't be fetched."` **wortgleich in drei Dateien** —
`providers/codeberg/readme/readme_manager.lua`,
`providers/github/readme/readme_manager.lua`,
`providers/gitlab/readme/readme_manager.lua`. Kein Cross-Repo-Duplikat (das
hätte 8.1 gefunden), sondern ein **Cross-Provider-Duplikat innerhalb
desselben Repos** — dieselbe Konstante dreimal statt einmal geteilt. Keine
Config-Frage (Nachrichtentext, keine Verhaltensoption), aber eine
DRY-Beobachtung, die keiner der beiden Scanner als solche benennt, weil
keiner nach *interner* String-Duplikation über Dateien hinweg sucht.

Restliche 35 Konstanten: Rohliste liegt vor, keine Einzelbewertung — gleiche
Größenordnungs-Begründung wie bei 8.3.

---

## 8.2 — Diagnostics erneut anwenden — **bewusst nur angerissen**

**Umfang laut Standard:** 34 `LLS`-Regeln + 11 `NEW`-Gate-Punkte aus
`$REPOS_DIR\WKDBooks\Development\wkdbook-Lua\Checklists\`, dazu (über die
`LLS`-Teilmenge hinaus) weitere sieben Regel-Präfixe
(`PRIN-`, `LUA-`, `ERR-`, `SEC-`, `UI-`, `TS-`, `DEP-`, `PERF-`) — macht
insgesamt weit mehr als 43 Einzelregeln über 32 Repos.

**Eine harte Tatsache, verifiziert statt behauptet:** `git log --grep
"fix(luals)"` zeigt, dass **20 der 32 Repos** einen frischen,
eigenständigen „auf 0 Diagnosen" Durchgang bereits hinter sich haben —
teils mit echten Fehlern dabei gefunden (`gopath.nvim`: „ein Ergebnis, das
log"; `images.nvim`: „ein Vergleich, der abstürzen konnte";
`mdview.nvim`: „ein `assert`, das seinen Wert verschluckt hat"). Das ist
exakt das, was `LLS-01`…`LLS-43` prüfen sollen — und es ist **bereits
gemacht**, in einem separaten, aktuelleren Durchgang als dieser hier.

| Status | Repos |
|---|---|
| Frisch auf 0 (verifiziert per Commit) | buffer-ctx, cmdlog, dap, debugging, diff, emojis, fileops, filetree, gopath, images, lib.nvim, mdview, open, pdfport, recommender, runtime-analysis, sandbox, sessions, spotlight — **19** |
| In Arbeit (172 → 35, nicht 0) | lsp.nvim |
| Kein solcher Commit gefunden | cascade, casedesk, color_my_ascii, documentation, github_stats, hover, insights, language, markdown, pickers, replacer, reposcope — **12** |

**Warum hier trotzdem nicht weitergemacht wurde:** Die verbleibende
Diagnostics-Arbeit zerfällt in zwei sehr unterschiedliche Aufgaben —

1. Die 12 Repos ohne frischen LuaLS-Nulldurchgang (plus `lsp.nvim`s Rest)
   nachziehen — mechanisch, pro Repo einige Runden, wie die anderen 20 auch.
2. Die **sieben übrigen Regel-Präfixe** (`PRIN-`/`LUA-`/`ERR-`/`SEC-`/`UI-`/
   `TS-`/`DEP-`/`PERF-`) sind reine Handprüfung gegen Quelltext — keines der
   fünf Wiederholungslauf-Werkzeuge deckt sie ab. Das ist keine
   Fortsetzung von ein paar Minuten, sondern strukturell ein eigener,
   mehrstündiger bis mehrtägiger Durchgang über 32 Repos × 8 Regel-Familien.

→ **Autorenentscheidung, mit welcher der beiden Hälften weitergemacht
werden soll** — beide sind gemacht, keine ist stillschweigend übersprungen.

**Entscheidung des Autors (2026-09-05): voller Regel-Katalog als Pilot an
einem Repo**, um den Aufwand realistisch einzuschätzen, bevor 32 Repos
angefasst werden. Ergebnis unten.

---

### Pilot: buffer-ctx.nvim gegen die 8 übrigen Regel-Familien

**Gewählt, weil aus dem P4-Durchgang bereits gut bekannt** (45 Lua-Dateien,
`docs/architecture.md` frisch geschrieben) — spart die
Struktur-Einarbeitung, die bei einem fremden Repo zusätzlich anfiele.

**Vorgehen:** die vollständigen Regeltexte gelesen (`PRINCIPLES.md`,
`LUA_NVIM.md` ohne den `LLS-*`-Abschnitt, `PERFORMANCE.md` — zusammen ~1.480
Zeilen), danach gezielt gegen die Stellen gehalten, an denen eine Regel am
ehesten greift: `ops/git.lua` (`SEC-01`/`02`, Prozessaufrufe), `config/init.lua`
(`ERR-50`…`53`, Merge-Sicherheit), `commands.lua`/`bindings/usrcmds.lua`
(`UI-21`…`23`, Compound-Command + Completion), ein `grep` über `ops/` auf
`notify\.` (`ERR-04`, Low-Level darf nicht selbst benachrichtigen), ein
`grep` über den ganzen Baum auf die sieben `DEP-*`-Muster.

**Befund: überwiegend bereits konform.**

| Regel | Ergebnis |
|---|---|
| `SEC-01`/`SEC-02` | `ops/git.lua` — Argv-Array, `-C` explizit gesetzt. Konform |
| `ERR-51` | `config/init.lua` — `vim.tbl_deep_extend("force", DEFAULTS, user_opts or {})`, mutiert `DEFAULTS` nicht. Konform, genau das im Regeltext gezeigte Muster |
| `ERR-04` | Zwei `notify.`-Treffer in `ops/` — beide falsch positiv: ein Kommentar, eine Template-**Textzeile**, die der Boilerplate-Generator ausgibt, kein echter Aufruf. Konform |
| `UI-21`/`UI-22`/`UI-23` | `:Insert`/`:Copy`/`:Format`/`:Mark` über `lib.nvim.usercmd.composer`; `boilerplate`/`snippet`/`env` completen live aus `list_keys()`/`list_names()`, nicht aus einer bei `setup()` eingefrorenen Liste. Konform |
| `DEP-01`…`07` | Ein Treffer, `vim.fn.sign_define()` in `mark/init.lua` — laut `DEP-05` explizit **kein** Verstoß: die Ausnahme gilt für eigene Plugin-Signs, nur `DiagnosticSign*` ist deprecated |

**Ein echter Fund:** `:Format clear` (`format/misc.lua:146-150`) leert den
kompletten Buffer über `nvim_buf_set_lines(0, -1, ...)` **ohne jede
Bestätigung** — `notify.info("Buffer cleared")` danach ist die einzige
Rückmeldung. `UI-01` verlangt für destruktive Aktionen genau eine Bestätigung.
Gegenargument, das die Regel nicht automatisch aussticht: Vim-Undo (`u`)
stellt den Inhalt vollständig wieder her, und einige native Vim-Operationen
(`:%d`) sind ebenso bestätigungslos — ob das hier reicht, ist eine
Autorenentscheidung, kein eindeutiger Bug. **Nicht behoben**, nur gefunden.

**Aufwand, gemessen statt geschätzt:** Regeltexte lesen + sieben
gezielte Datei-/Grep-Prüfungen für **einen** Bruchteil der ~250 einzelnen
Regelpunkte (grob 15–20 %, konzentriert auf die Stellen mit der höchsten
Trefferwahrscheinlichkeit) haben bereits diesen Umfang gebraucht — TS-*
(keine Treesitter-Nutzung im Repo, also 0 Aufwand dort), die restlichen
`SEC-*`/`UI-*`/`PERF-*`-Punkte systematisch **nicht** einzeln geprüft.

**Hochrechnung:** eine wirklich vollständige Prüfung aller ~250 Regelpunkte
gegen **ein** mittelgroßes Repo ist realistisch eine mehrstündige Aufgabe;
gegen alle 32 Repos (von 12 wie `emojis.nvim` bis 125 wie `filetree.nvim`)
ein mehrtägiges bis mehrwöchiges Vorhaben — deutlich außerhalb dessen, was
ein einzelner Wiederholungslauf-Termin leisten kann. Die belastbare
Verkürzung, die die `Belege`-Spalten in `LUA_NVIM.md`/`PERFORMANCE.md`
selbst schon zeigen: die meisten Regeln sind **bereits einmal** an einem
Referenz-Repo verifiziert (Erhebung 2026-08-08) — der eigentlich offene
Aufwand ist nicht „250 Regeln neu ableiten", sondern „250 Referenzen gegen
den *aktuellen* Stand ihres jeweiligen Repos erneut verifizieren, plus
neuer Code seit dem 08.08. gegen dieselben Regeln halten" — kleiner als der
erste Durchgang, aber immer noch groß.

→ **Empfehlung:** 8.2 nicht als einen Block behandeln, sondern in der
gleichen Wellen-Logik wie P4 aufteilen — z. B. eine Regel-Familie
(`SEC-*` zuerst, sicherheitsrelevant) über alle 32 Repos, dann die nächste
Familie, statt ein Repo komplett gegen alle acht Familien auf einmal.

---

## 8.2a — Nachtrag 2026-09-05 (später am Tag): die 12 Repos + lsp.nvim

**Alle 13 sind jetzt bei 0 gemessenen Befunden.** Baseline-Scan über genau
diese 13 (`scripts/luals-scan/scan.sh before <13 Namen>`):

| Repo | Vorher | Nachher | Was |
|---|---|---|---|
| cascade.nvim | 0 | — | bereits sauber |
| casedesk.nvim | 0 | — | bereits sauber |
| color_my_ascii.nvim | 0 | — | bereits sauber |
| github_stats.nvim | 0 | — | bereits sauber |
| language.nvim | 0 | — | bereits sauber |
| replacer.nvim | 0 | — | bereits sauber |
| **lsp.nvim** | 0 | — | **fertig geworden seit diesem Dokument (§8.2 oben notierte noch 172→35, „in Arbeit")** |
| documentation.nvim | 1 | 0 | `opts.hover` ungenutzt annotiert — Feld fehlte auf `Documentation.Opts`. Ein-Zeiler |
| hover.nvim | 1 | 0 | `vim.deepcopy(raw.auto_hover)`: das Feld ist `table\|boolean\|string[]`, `true`/`false` sind gültige Werte, `deepcopy` will eine Tabelle. Nur die Tabellenform kopiert |
| insights.nvim | 2 | 0 | dieselbe Lücke wie documentation.nvim, auf zwei Klassen (`InsightsConfig`/`InsightsOpts`) |
| pickers.nvim | 1 | 0 | Test prüft *bewusst* die Abwesenheit von `search_dirs` (fzf-lua kennt das Feld nicht) — Unterdrückung mit Begründung, kein Bug |
| reposcope.nvim | 1 | 0 | `config.get_option("hover")` — `"hover"` fehlte im `ConfigOptionKey`-Enum |
| **markdown.nvim** | **35** | **35 gemeldet, 0 real** | siehe unten — Messartefakt, nicht behoben, weil nichts zu beheben ist |

Fünf echte Ein-Zeiler-Funde, alle aus derselben Familie: ein Plugin bietet die
weiche `hover.nvim`-Integration an (`opts.hover ~= false` /
`cfg.get_option("hover")`), aber das Feld fehlte in der eigenen Typdeklaration
— nicht überraschend, `hover.nvim` ist als eigenständiges Repo erst seit
2026-09-01 alt und diese Integration ist frisch. `worse: nothing` in allen
fünf Nachher-Läufen.

### markdown.nvim — 35 gemeldete Befunde, alle Messartefakt

Alle 35 laufen auf denselben Grund zurück: `lua/markdown/@types/init.lua`
deklariert drei Aliase auf `Hover.*`-Typen
(`---@alias Mkdn.HoverConfig Hover.Config` usw.) — die Typen selbst leben seit
der Extraktion in `hover.nvim`s eigenem `@types`, nicht mehr in markdown.nvim
oder lib.nvim. Der Scan-Tool-Library-Dump für den markdown.nvim-Workspace
enthielt `hover.nvim`s `lua/`-Verzeichnis **nicht** (geprüft: 37
Library-Einträge, keiner davon `hover.nvim`) — exakt der Fall, den `LLS-01`
beschreibt: „ohne Library-Injektion ist jeder Cross-Repo-Typ undefined".

**Gegenprobe im laufenden Editor** (wie die Methode selbst für einen harten
Befund verlangt): `lua/markdown/hover/section.lua` in einer echten Session
geöffnet, auf den LSP-Anlauf gewartet, `vim.diagnostic.get(0)` ausgezählt —
**0**. Der reale Editor löst `Hover.Config` über `lazydev`s Bedarfs-Injektion
korrekt auf; nur der Scan-Dump (der `lazydev` laut eigenem README ersetzen
soll) tut es hier nicht.

**Keine Code-Änderung** — markdown.nvims eigener Code ist korrekt, die 35
sind ein Loch im Scan-Werkzeug (welche Repos als „transitiv gebraucht" für den
Library-Dump zählen), nicht im Plugin. Für `scripts/luals-scan` selbst
vorgemerkt, nicht in diesem Durchgang behoben — außerhalb des Umfangs von
8.2a, das die **Repos** auf 0 bringen soll, nicht das Messwerkzeug härten.

---

## Rohdaten dieses Laufs

Liegen unter
`$REPOS_DIR\WKDBooks\Development\wkdbook-myplugins\_P5-Rohdaten-2026-09-05\`
(`8_3_magic_numbers.txt`, `8_5_hardcoded_constants.txt`,
`8_4_bindings_audit.txt`, `8_4_gaps.txt`) — nicht committet, wie der Rest
von `wkdbook-myplugins` in diesem Durchgang.

---

## 8.2b — SEC-* Welle, Zwischenstand 2026-09-05 (Abend)

**Autorenentscheidung:** volle `SEC-*`-Welle (24 Regeln, `SEC-01`…`SEC-45`)
über alle 32 Repos, alphabetisch in Runden zu 3 (feste Vorgabe: max. 3
parallele Agenten). Jeder Agent bekam den vollständigen Regelkatalog, prüfte
Anwendbarkeit pro Regel (kein erzwungener Befund, wo keine Angriffsfläche
existiert), verifizierte gegen den **aktuellen** Quelltext (nicht gegen den
08-08-Belege-Snapshot), behob echte Ein-Zeiler-Funde selbst und committete
pro Repo einzeln (`fix(sec): …`).

**Runden 1–6 (18 Repos) liefen zu 3 parallelen Agenten; Runde 7 (`lib.nvim`,
`lsp.nvim`, `markdown.nvim`) ebenso und noch fertig geworden — Runde 8
(`mdview.nvim`/`open.nvim`/`pdfport.nvim`) scheiterte am Sitzungslimit, bevor
etwas geschrieben wurde. Ab da: ein Repo pro Durchgang, siehe „Was bleibt"
unten.** Alle Fixes sind committet **und gepusht** auf `main` der jeweiligen
Repos.

### Ergebnis je Repo (Runden 1–7)

| Repo | Befunde | Commit |
|---|---|---|
| buffer-ctx.nvim | 0 | — |
| cascade.nvim | 0 (praktisch keine SEC-Angriffsfläche — reines lokales Buffer-Editing) | — |
| casedesk.nvim | 1 — SEC-02, fehlendes `cwd` auf `export.lua`s zwei `vim.system`-Aufrufen | `b932688` |
| cmdlog.nvim | 0 (bestätigt: die im 08-08-Snapshot offen vermerkte SEC-11/12/13-Lücke ist inzwischen durch `redact_patterns` geschlossen) | — |
| color_my_ascii.nvim | 1 — SEC-02, `:Fence run`/`format` ohne `cwd` | `5a8e6a0` |
| dap.nvim | 1 — SEC-02, `zig.lua`s `zig build`-Spawn (ein bereits vorhandener, nie verdrahteter `workspace_root()`-Helper) | `1064d43` |
| debugging.nvim | 1 — SEC-03, `inline_debug.lua`s Statuszeile spleißte Filetype/Colorscheme ungeschützt in einen Vimscript-`echo`-String (der Kommentar behauptete Escaping, das nie stattfand) | `0606d5074` |
| diff.nvim | 1 — SEC-21, `http(s)://`-Fetch hatte Timeout, aber kein Byte-Limit | `3a383c3` |
| documentation.nvim | 1 — SEC-33, `trail_store.lua`s `normalize()` prüfte nur die Top-Level-Form, nicht die Feldtypen persistierter Pins — eine verunstaltete `trails.json` konnte `:DocBrowse` abstürzen lassen | `c38e8003f` |
| emojis.nvim | 0 | — |
| fileops.nvim | 0 | — |
| filetree.nvim | 0 (inkl. verifizierter PowerShell-/AppleScript-Pfad-Escaping gegen adversarielle Eingaben) | — |
| github_stats.nvim | **2, davon 1 gravierend** — SEC-01/03/10: `:checkhealth`s API-Sync-Test baute einen Shell-String **mit dem GitHub-Token direkt hineininterpoliert**, ausgeführt über `fn.system(string)` — der Token war für die Laufzeit des Aufrufs im Prozess-Argv sichtbar (`ps`/Win32_Process). Zusätzlich SEC-21: `fetch_json` hatte **gar keinen** Timeout (schlimmer als die im 08-08-Snapshot vermerkte Lücke „kein Byte-Limit") | `dc8efa9` |
| gopath.nvim | 3 — SEC-30 ×2 (`symbol_locator.lua`/`table_locator.lua` bauten Lua-Patterns aus Treesitter-extrahierten Kettengliedern ohne Escaping), SEC-33 ×1 (`truncated/cache.lua`s `load_from_disk()` übernahm persistiertes JSON ungeprüft in den Live-State) | `74ddf7e19d4` |
| hover.nvim | 0 (Erstdurchlauf — Repo ist neu, kein 08-08-Belege-Snapshot vorhanden; durchgehend defensiv: Argv-only, Netzwerk-Features per Default aus, Timeout+Byte-Limit+Cache-Sweep, typgeprüftes Parsen) | — |
| images.nvim | **1, gravierend** — SEC-01/03: die Linux-Clipboard-Paste (`wl-paste`/`xclip`) baute einen Shell-String mit dem aufgelösten Zielpfad in einfachen Anführungszeichen; `:Image replace` kann diesen Pfad aus einem Markdown-Link/der Cursorposition ableiten — ein Pfad mit `'` oder Shell-Metazeichen hätte die Quotierung gebrochen. Echte Command-Injection-Fläche, nicht nur theoretisch | `89a6b6f` |
| insights.nvim | 1 — SEC-02, `conflicts/init.lua` und `symbols/rg_index.lua` setzten bei sequentiellen `git`/`rg`-Aufrufen kein explizites `cwd` | `5fe0733` |
| language.nvim | 1 — SEC-01/03: `add_to_dict` spleißte das von `cspell`/`codespell`/`typos` gemeldete Wort in einen `:spellgood!`-Vimscript-String; das Wort kann aus fremden gescannten Dateien stammen, nicht nur aus Nutzereingabe | `7792e60806f` |
| lib.nvim | 2 — SEC-02, `cross.uv.spawn_shell_command` hatte kein `cwd` (Geschwister `spawn_command` schon); dazu ein Docstring-Hinweis, dass beide Shell-String-Spawner nicht für ungeprüfte Eingaben gedacht sind (SEC-01/03, additiv, keine Verhaltensänderung). SEC-21, `curl.download`/`download_blocking` ließen bei einem fehlgeschlagenen Transfer die abgeschnittene Zieldatei liegen statt sie zu entfernen | `fbfa956`, `60b75a7` |
| lsp.nvim | 1 — SEC-02, `prettier_format` spawnte ohne `cwd` (Geschwister `eslint_fix` löste die Projekt-Root schon auf und übergab sie) — erbte damit stillschweigend das globale Editor-cwd statt des Puffer-Projekts | `2a71561` |
| markdown.nvim | 0 | — |
| mdview.nvim | 1 — SEC-20/21, `install.lua`s `curl_download()` (Release-Binary + Client-Bundle) hatte weder `--max-time` noch `--max-filesize` (blockiert den Main-Loop, kann Platte füllen), und ließ bei einem Fehlschlag die abgeschnittene Datei liegen — `ensure_asset()`s „existiert schon"-Schnellpfad hätte eine so beschädigte Binary beim nächsten `:MDView start` **ungeprüft als Server-Prozess gestartet**, ohne je die Checksumme zu ziehen | `E:\repos\mdview.nvim` |
| open.nvim | 0 im Repo selbst — **aber 1 im mitbenutzten `lib.nvim`-Code**: `reveal_in_fm`s `win_reveal.ps1` (geteilt mit filetree.nvim, dort ist es `<leader>fm`) baute das `-ArgumentList` für `explorer.exe` per Hand aus einem manuell gequoteten String. Ein natives Windows-Pfad kann kein `"` enthalten, aber ein per `wslpath -w` übersetzter WSL-Pfad schon — Linux erlaubt es in Dateinamen, und `wslpath` filtert nichts. Ein `"` im Pfad hätte das selbstgebaute Anführungszeichen vorzeitig geschlossen und den Rest des Dateinamens als zusätzliche `explorer.exe`-Argumente einschmuggeln können. Fail-closed statt fragilem Escaping (`explorer.exe`s Quote-Konvention ist nicht robust genug dokumentiert) | `E:\repos\lib.nvim` |

**15 von 22 geprüften Repos hatten mindestens einen echten Fund**, alle
behoben, committet und gepusht. Zwei Funde sind keine Kosmetik, sondern
reale Schwachstellen: der GitHub-Token-Leak über Prozess-Argv
(`github_stats.nvim`) und die Shell-Injection über den Clipboard-Zielpfad
(`images.nvim`).

Vollständige Einzel-Reports (welche Regeln geprüft, welche N/A mit
Begründung, welche bewusst nicht behoben) liegen in den Session-Transkripten
der beauftragten Agenten — hier nur die Verdichtung.

### Was bleibt

**Ab jetzt ein Repo pro Durchgang, nicht mehr parallel** — Autorenentscheidung
2026-09-05 (Abend): mehrere gleichzeitige Agenten kosten zu viele Token und
lassen sich zwischendurch nicht von Hand nachhalten. Runde 8 (`mdview.nvim`,
`open.nvim`, `pdfport.nvim` gleichzeitig) ist am Sitzungslimit gescheitert,
**bevor** irgendein Agent etwas geschrieben hat — alle drei Repos standen
danach mit sauberem Working Tree da, nichts zu retten, nichts verloren.

**9 Repos noch nicht geprüft:** `pdfport.nvim`,
`pickers.nvim`, `recommender.nvim`, `replacer.nvim`, `reposcope.nvim`,
`runtime-analysis.nvim`, `sandbox.nvim`, `sessions.nvim`, `spotlight.nvim` —
weiter alphabetisch, ein Repo je Durchgang, voller SEC-*-Katalog pro Repo.

**Danach:** die übrigen sieben Regel-Familien (`PRIN-`/`LUA-`/`ERR-`/`UI-`/
`TS-`/`DEP-`/`PERF-`) über alle 32 Repos — `SEC-*` war nur die erste von acht
Wellen laut Piloten-Empfehlung (Pilot: `buffer-ctx.nvim`, siehe oben).
