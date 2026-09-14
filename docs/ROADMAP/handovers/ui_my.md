# ui.nvim / my.nvim
## Notes

Roadmap und Handover files findest du hier:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ui.nvim`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/my.nvim`

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / ../README-New/README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit)
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- code der implementiert wurde muss luacheck / stylua grün sein

---

## Handover Notes

**2026-09-13/14, ui.nvim-Session (Worktree `busy-bassi-c01118`), gestoppt auf
Nutzeranfrage mitten in der Umsetzung:**

Bereits fertig, getestet, direkt nach `origin/main` gepusht (Commits
`cd58c8d`, `f8c7757`, `f0b5795`):
- **Deferred-Close-Bug** (`ui.tabline.utils.close_buffer`/`close_all_bufs`):
  der `vim.defer_fn`-Callback war nicht `pcall`'d, ein ungültig gewordener
  Buffer konnte unabgefangen aus dem Timer-Callback werfen. Gefixt + Test.
- **"1 ohne Icon"-Bug**: sechs Icon-Glyphen in
  `ui.statusline.utils.primitives` (Git added/changed/removed/branch,
  LSP-Error/Warning, LSP-Client-Label) waren komplett verschwunden (bloße
  ASCII-Leerzeichen statt Glyph) — Byte-für-Byte-Vergleich mit
  `nvchad/stl/utils.lua` bestätigt, wiederhergestellt als `\xEE`/`\xEF`-Escapes.
- **Tabline-Style-Preset-System**: `ui.tabline.styles` (Registry, analog zu
  `ui.config.variants`) + `:UI tabline-style`/`:UI tabline-styles`, volle
  Laufzeit-Parität zur Statusline-Variantenauswahl.

**Statusline-Ideen-Sichtung**: alle offenen Punkte aus `IDEEN-statusline.md`
durchgegangen, Nutzer hat 16 von ~18 zur Umsetzung ausgewählt — explizit
**als eigenständige, opt-in Preset-Module**, nicht in Shipped-Defaults oder
die persönliche Config verdrahtet (wie `undo_depth`/`search_count` schon).
Vereinbarte Reihenfolge: Klick-Layer zuerst, dann alles Klickbare darauf.

**Nachgeholt 2026-09-14 (neue Session, Worktree `strange-shamir-7a4175`):**
der oben geplante Klick-Layer war nie committet — der Arbeitsbaum von
`busy-bassi-c01118` war beim Wiederaufnehmen bereits recycelt, alle fünf
geplanten Dateien nicht mehr auf der Platte. Neu gebaut nach genau dieser
Spezifikation — `clickable.lua`, `diagnostics_clickable`, `git_clickable`,
`variant`, Katalog + Doku, den `%`-Escape-Fix in `primitives.git()` gleich
mit —, nicht identisch im Code, gleichwertig im Verhalten, inklusive Tests.
Gepusht als `ui.nvim@73f36a4` + `ui.nvim@0551cb8`.

Zwei echte Lua/Neovim-Fallstricke beim Testen gefunden: `require()`
reduziert das Ergebnis eines Moduls immer auf einen Wert, egal wie viele das
Modul zurückgibt (die Klick-Id kann deshalb nicht über einen zweiten
`require()`-Rückgabewert an einen Test durchgereicht werden — geparst aus
dem gerenderten `%id@UiSlClick@...%X`-Text stattdessen); `vim.v.shell_error`
ist auch über `vim.api.nvim_set_vvar()` schreibgeschützt. Volle Suite grün
(217 Tests), `luacheck`/`stylua` clean. Details: `$REPOS_DIR/WKDBooks/
Development/wkdbook-myplugins/ui.nvim/handovers/ERLEDIGT/
statusline-click-layer.md`.

Bewusst nicht gemacht: keine Live-Verdrahtung in die persönliche Statusline
(alle drei Module bleiben `used_by = {}`, opt-in, wie `undo_depth`/
`search_count` vor ihrer eigenen Verdrahtungsrunde) und kein manueller
Maus-Klick-Test im echten Host (keine GUI in dieser Sandbox) — nur headless
verifiziert.

**Nebenbei entdeckt:** der `custom_menu`-Roadmap-Eintrag (die deklarative
Menu-Entry-API-Idee), am 2026-09-08 in dieser Datei dokumentiert und nach
`nvim-config@main` gepusht, ist im aktuellen `main` nicht mehr vorhanden —
vermutlich durch einen späteren Force-Push von `main` verloren gegangen
(erwartetes Risiko, siehe `nvim-config-main-gets-force-pushed`-Memory).
Nicht selbstständig wiederhergestellt, da unklar ist, ob das absichtlich
raus ist oder nur beim Force-Push mitgerissen wurde — beim Nutzer
nachgefragt.

**2026-09-14, direkt danach: Statusline-Vordergrund vereinheitlicht + vier
der elf Module (`ui.nvim@63bd747`…`240e890`).**

**Live-Feedback zwischendurch:** "Statusline-Schrift ist nicht durchgehend —
sollte alles weiß sein, außer der Mode-Chip." `St_gitIcons`/`St_LspMsg`/
`St_Lsp`/`St_cwd_icon`/`St_cwd_text`/`St_LspProgress` lasen eine gedimmte,
`"Comment"`-abgeleitete Farbe, während `St_file`/`St_pos_icon`/`St_pos_text`
die normale Vordergrundfarbe lasen — ohne inhaltlichen Grund unterschiedlich.
Vereinheitlicht; Mode-Chip und der `blocks`-Preset-Cursor-Chip unverändert
(sitzen auf einem gefüllten Akzent-Hintergrund, nicht der schlichten
Statusline-Fläche); Diagnostics-Farben (Error/Warning/Hint/Info) bewusst
nicht angefasst, die sind bedeutungstragend.

Der Reihe nach umgesetzt, wie unten gelistet:
1. `diagnostics_sparkline` — 20-Glyph-Dichte-Zeile, `cursor_ctl.renderer
   .pct_bar` dafür öffentlich gemacht statt dupliziert.
2. `macro_counter` — Live-Tastendruckzähler während Makro-Aufnahme, über
   `vim.on_key()` geklammert von `RecordingEnter`/`RecordingLeave`.
3. `time_in_buffer` — "12m" seit dem ersten `BufEnter` dieser Session,
   bewusst ohne die `sessions.nvim`-Cross-Session-Erweiterung.
4. `github_stats_badge` — "👁 42 diese Woche" fürs aktuelle Repo, nur
   sichtbar innerhalb eines getrackten Repos.

Zwei echte Bugs beim Bauen gefunden: `macro_counter`s erster Entwurf nutzte
`string.format`, dessen literales `%` aus `%#Group#` Lua selbst als
ungültige Format-Direktive las (auf Konkatenation umgestellt);
`github_stats_badge`s erster `owner/repo`-Regex schloss Punkte aus dem
Repo-Namen aus und kürzte deshalb jedes `*.nvim`-Repo dieses Ökosystems
("ui.nvim" → "ui") — vom eigenen Test gefunden.

**Ein Idee-Punkt hielt der Realität nicht stand — geklärt 2026-09-14:**
"Recommender-Badge" beschrieb `recommender.nvim` als Perf-/Security-Scanner
mit einem `:RecommenderCheck`-Befehl — beides existiert im tatsächlichen
Repo nicht. `recommender.nvim` findet stattdessen wiederholte Dotted-Chains,
die sich als Alias lohnen würden (siehe dessen README). Nutzer hat sich für
"Idee anpassen" entschieden — `IDEEN-statusline.md`s Recommender-Badge-Eintrag
korrigiert (Badge zeigt künftig: "N Alias-Vorschläge für diese Datei offen"),
noch nicht implementiert.

20 neue Tests seit der letzten Runde. Volle Suite grün (235 Tests),
`luacheck`/`stylua` clean. Details: `$REPOS_DIR/WKDBooks/Development/
wkdbook-myplugins/ui.nvim/NOTES.md`s achtzehnte Runde.

**2026-09-14, neue Session (Worktree `ui-nvim-tabline-0ca9d3`):**
`runtime_analysis_ampel` gebaut — 🟢/🟡/🔴-Ampel für "hat heute irgendeine
runtime-analysis.nvim-instrumentierte Funktion einen Fehler geworfen oder
lief auffällig langsam" (Grenzwert: Ø-Aufrufzeit > 50ms). Nutzt nur die
öffentliche `runtime-analysis.telemetry`-Fassade (`known_namespaces`, `get`,
`load`), nicht deren interne `.store`/`.report`-Submodule — degradiert
sauber über Versionswechsel des Fremdplugins hinweg, wie jede andere weiche
Abhängigkeit hier auch. Rendert leer, wenn `runtime-analysis.nvim` nicht
installiert ist oder noch nie eine Telemetrie-Instanz gewrappt wurde.

**Ehrlichkeitslimit bewusst dokumentiert:** "gerade" heißt hier "heute
aktiv (`Data.days[today]`) UND lebenslang mind. 1 Fehler bzw. Ø-Zeit über
dem Grenzwert" — die Telemetrie zeitstempelt keinen einzelnen Aufruf, nur
Tages-Buckets, das ist der ehrlichste Näherungswert, den die Daten
hergeben. Ein Fehler von vor Monaten macht die Ampel nicht rot, wenn die
Funktion seither nicht mehr aufgerufen wurde.

8 neue Tests (`TESTS/runtime_analysis_ampel_spec.lua`), Katalog- +
Doku-Eintrag ergänzt (`lua/ui/statusline/catalog.lua`,
`docs/modules.md`). `luacheck`/`stylua` clean. Nicht in einem Preset
verdrahtet (`used_by = {}`), wie die anderen Ideen-Module vor ihrer eigenen
Verdrahtungsrunde. Details: NOTES.md's neunzehnte Runde.

**Nebenbei entdeckt, nicht selbst gefixt:** `TESTS/github_stats_badge_spec.lua`s
"renders empty when the tracked repo has zero views"-Test ist
laufreihenfolge-abhängig — der `views_this_week`-Cache in
`github_stats_badge/init.lua` ist nur nach Slug geschlüsselt (60s TTL), und
zwei Tests teilen sich denselben Slug `"StefanBartl/ui.nvim"`, wodurch der
zweite Test den gecachten Wert (42) statt seines eigenen Mocks (0) sieht.
Auf `main` reproduziert, unabhängig von dieser Session. Als eigenständige
Aufgabe geflaggt (Chip), nicht hier mit erledigt.

---

**2026-09-14, neue Session (Worktree `nvim-ui-handover-521045`):**
`recommender_badge` gebaut — "N Alias-Vorschläge für diese Datei offen"
für den aktuellen Buffer, ohne `:Recommender` tippen oder den Float öffnen
zu müssen. Ruft direkt den von `recommender.config.get().analyzer`
gewählten Analyzer mit dessen eigenem `threshold`/`custom_aliases`/
`blacklist` auf — dieselbe Quelle, die `:Recommender` selbst benutzt, keine
separate Config. Ergebnis pro Buffer über `nvim_buf_get_changedtick`
gecacht. 6 neue Tests, Katalog- + Doku-Eintrag ergänzt, `luacheck`/`stylua`
über das gesamte Projekt (89 Dateien) clean, volle Suite grün. Nicht in
einem Preset verdrahtet (`used_by = {}`), wie der Rest der Auswahl vor
ihrer eigenen Verdrahtungsrunde. Gepusht als `ui.nvim@8ba9ab2`.

**2026-09-14, dieselbe Session, vier weitere Runden — komplette
Statusline-Ideen-Auswahl abgeschlossen:**
- **Casedesk-SLA-Countdown**: Badge existierte schon (`casedesk.nvim`s
  eigenes SLA.md §6C), nur einfarbig — jetzt zweistufig (Gelb solange
  dringend, Rot sobald überfällig). Idee entsprechend korrigiert. 9 neue
  Tests (gab vorher gar keine für dieses Modul). `ui.nvim@d37b1f4`.
- **Filetree-Verlaufspunkte**: `opts.history = true` an
  `filetree_cwd_mode` — bis zu 3 kleine Punkte (aktuell gefüllt, ältere
  hohl), geschlüsselt nach Modus UND Root (sonst wäre "zwischen zwei
  Cases hin- und herspringen" unsichtbar geblieben, da beide denselben
  Modusnamen tragen können). `ui.nvim@fe5d277`.
- **Idle-Erweiterung**: neue Primitive `ui.statusline.utils.idle`
  (`is_idle()`/`wrap()`, auf `CursorHold`/`CursorHoldI`) + erstes Payload
  `idle_clock` (Uhrzeit, verschwindet beim nächsten Tastendruck).
  Mini-Git-Log/mehr Breadcrumb-Platz bleiben offen, können dieselbe
  Primitive ohne eigene Verdrahtung nutzen. `ui.nvim@b5a37ca`.
- **Seit-letztem-Save-Indikator**: `since_last_save` — Dauer seit
  ungespeicherter Änderung, eskalierend gedämpft → `DiagnosticWarn` →
  `DiagnosticError`, Uhr setzt sich beim Speichern zurück.
  `ui.nvim@91f575c`.
- **Adaptive Segmentauswahl nach Fensterbreite**: `Ui.Statusline.Config.
  responsive = true` + generisches `essential`-Tag im Katalog
  (`mode`/`file`/`diagnostics`/`cursor` sind "das Nötigste", alles andere
  droppable) statt einer zweiten, parallel gepflegten `order`-Liste — genau
  nach der unten skizzierten Spezifikation. `ui.nvim@03cfa43`.

Jede Runde: eigene Tests, `luacheck`/`stylua` clean, Katalog + `docs/
modules.md` aktualisiert, direkt nach `main` gepusht. Details je Runde:
`NOTES.md`s 21.–25. Runde.

**2026-09-14, dieselbe Session, Rechtsklick-Menü-Migration begonnen
(`PLAN-ui-kit-migration.md`, Schritt 3 von 6):**

Vor dem Start drei offene Architekturfragen aus dem Plan vorgelegt, alle
drei mit der jeweils empfohlenen Option beantwortet:
- `contextmenu` (Datenbauer) wandert zusammen mit `ui.kit` (Renderer)
  nach `ui.nvim`, keine Modulgrenze zwischen beiden.
- `menu = false` heißt künftig "Datenbauer immer da, nur Renderer/Trigger
  am Schalter" — **entschieden, aber noch nicht verdrahtet.**
- Umfang dieser Runde: **nur Schritt 3** (kopieren + Prefix-Rename +
  Tests). Kein Shim in `lib.nvim`, keine der ~30/~11 Konsumenten-Repos
  umgestellt — das bleibt für spätere Runden.

Mechanischer Prefix-Umzug: `lib.nvim.ui.kit` → `lua/ui/kit/` (21 Dateien),
`lib.nvim.contextmenu` → `lua/ui/contextmenu/`, `Lib.UI.Kit.*` →
`Ui.Kit.*`, `Lib.ContextMenu.*` → `Ui.ContextMenu.*` überall. Jeder
andere `lib.nvim.*`-Require bleibt unangetastet (`lib.nvim` bleibt echte
Abhängigkeit). `lib.nvim`s eigene Testsuite nutzt einen komplett anderen
Custom-Harness (`return function(H) ... end`, `H.eq`/`H.ok`) statt
`describe`/`it`/`assert.*` — statt ~230 Einzel-Assertions über ~1763
Zeilen von Hand umzuschreiben (Risiko, irgendwo leise die Bedeutung einer
Prüfung zu verändern), einen kleinen `H.eq`/`H.ok`-Shim über `assert.*`
gebaut und den originalen Testkörper fast wortwörtlich gewrappt.

Nebenbei drei tote relative Markdown-Links in den mitkopierten READMEs
gefunden und repariert (neue Verzeichnistiefe zwei Ebenen flacher).
`docs/scope.md` neue "UI Kit"-Zeile. Volle Suite grün (32 Dateien),
`luacheck`/`stylua` clean (123 Dateien). `PLAN-ui-kit-migration.md`
entsprechend fortgeschrieben. Details: `NOTES.md`s 26. Runde. Gepusht als
`ui.nvim@5fba540`.

**2026-09-14, neue Session (Worktree `busy-bassi-c01118`, nach Sync auf den
oben beschriebenen Stand): `menu = true/false`-Toggle verdrahtet.**

War als eigener Punkt in "Offene Tasks" gelistet. `ui.contextmenu` bekam
einen internen `enabled`-Flag (Default `true` — opt-out, nicht opt-in, da
Renderer/Trigger schon heute ohne jeden Setup-Aufruf funktionieren) plus
`set_enabled(bool)`/`is_enabled()`; `M.open()` ist das einzige Gate —
deckt `bind_buffer` automatisch mit ab, da dessen Trigger auf `open`
delegiert, `entry`/`group`/`submenu` bleiben komplett unangetastet.
Erreichbar über `require("ui").setup({ menu = false })`, neben den
bestehenden `keymaps`/`usrcmds`-Flags (nicht `ui.config.setup()`, wie im
Plan ursprünglich vermutet — passt besser zu `ui.setup()`s bestehender
"welche Submodule sind aktiv"-Rolle).

Ende-zu-Ende gegen ein echtes headless Neovim verifiziert (Default an,
`open()` liefert eine echte Surface; nach `menu = false` liefert `open()`
`nil`), plus neue Tests in `TESTS/config_spec.lua`. Volle Suite grün,
`luacheck`/`stylua` clean (126 Dateien). `PLAN-ui-kit-migration.md`
entsprechend fortgeschrieben (§2, §5). Gepusht als `ui.nvim@9acf77d`.

**2026-09-14, parallel dazu (Worktree `nvim-ui-handover-521045`):
Tabline-Bug behoben — erster Buffer-Chip verlor Icon + Namensanfang.**

Per Screenshot gemeldet. Root Cause messbar gefunden (kein Terminal-Font-
Raten): `ui.tabline.utils.style_buf()`s Padding konnte bei schmalen
`bufwidth`-Werten (viele offene Buffer) auf einen Sicherheits-Floor
zurückfallen, der 1-2 Spalten mehr rendert als angefordert — der
summierte Overflow über alle Chips ist das, was Neovims eigene Tabline-
Kürzung dann vom linken Rand abschneidet. Fix: Icon- und Close-Button-
Breite real gemessen statt angenommen, Name aufs übrige Budget
zugeschnitten. Headless gegen `nvim_eval_statusline` verifiziert (Sweep +
Ende-zu-Ende mit 7 Buffern bei mehreren Terminalbreiten) — Tabline trifft
jetzt exakt `vim.o.columns`, nie mehr darüber. Beim Push mit der obigen
Session kollidiert (unterschiedliche Dateien, sauber rebased). Volle
Suite grün, `luacheck`/`stylua` clean. Details: `NOTES.md`. Gepusht als
`ui.nvim@4bffa02`.

**Nachtrag, nach Neustart per Live-Feedback: Bug bestand weiter, zweite
Ursache gefunden.** Präzisiert: tritt erst bei dynamischer
Breitenberechnung auf, verschlimmert sich mit mehr Tabs (erst Icon weg,
dann auch Text abgeschnitten) — zeigt eine zweite, unabhängige Ursache,
die reine interne Konsistenz nicht fangen konnte: ein echtes
Terminal/eine echte Schrift kann ein Nerd-Font-Glyph breiter zeichnen, als
Neovims eigene Breitentabellen glauben — keine Lua-Messung kann das sehen,
sie fragt immer nur Neovims eigenes Modell. Fix: `ui.tabline.modules.
buffers()` reserviert jetzt 2 Spalten Puffer PRO sichtbarem Chip in der
"passt er noch rein"-Entscheidung (nicht im Rendering selbst) — passt zum
beobachteten Wachstumsmuster. Drei Tests neu kalibriert. Volle Suite grün.
Gepusht als `ui.nvim@9e5639f`.

---

## Offene Tasks

Statusline-Ideen-Auswahl (`IDEEN-statusline.md`, 16 von ~18 Punkten) ist
seit 2026-09-14 **komplett abgearbeitet** — nichts mehr offen aus dieser
Liste.

**2026-09-14, Worktree `busy-bassi-c01118`, Schritt 5 (Konsumenten
umstellen) begonnen — 4 von 30 Repos fertig:**

Reihenfolge wie im Plan (Nutzungstiefe zuerst): `filetree.nvim` (23
Lua+7 MD, hart), `sandbox.nvim` (13 Lua, hart), `replacer.nvim` (11 Lua+1
MD, hart), `lsp.nvim` (11 Lua, weich), `language.nvim` (9 Lua+1 MD, weich),
`dap.nvim` (9 Lua+3 MD, hart — war schon vorher implizit als Pflicht
dokumentiert). Jedes: mechanischer Prefix-Rename, verwaiste "update
lib.nvim"-Textstellen korrigiert, Dependency-Doku (hart vs. weich je nach
tatsächlichem Require-Verhalten geprüft, nicht angenommen), Test-Infra
(rtp-Bootstrap je Repo-Eigenart erweitert, oder — wenn die Suite `ui.kit`
komplett stubt wie bei dap.nvim — bewusst NICHT erweitert), volle Suite +
`luacheck`/`stylua` grün (bei lsp.nvim zusätzlich CI abgewartet, da ein
Smoke-Test lokal nicht nachstellbar war), gepusht, persönliche
Installations-Spec nachgezogen wo nötig, Plan-Doku aktualisiert.

**Nebenbei gefunden:** die primäre `ui.nvim`-Checkout unter
`E:\repos\ui.nvim` hing auf einem alten Commit (vor Schritt 3) — ohne
`git pull` dort hätte weder die Tests noch dein echtes Neovim-Setup
`ui.kit`/`ui.contextmenu` gefunden. Gepullt.

**Handwerks-Fallstrick, mehrfach getroffen:** `vim.opt.rtp:prepend()`
inkl. manuellem `package.path`-Fallback funktioniert auf dieser Maschine
nur zuverlässig, wenn der Basispfad durchgehend im selben Trennzeichen-Stil
geschrieben ist (`E:\repos\ui.nvim`, Backslash) — ein Forward-Slash-Pfad
(`E:/repos/ui.nvim`) plus Luas eigene Punkt-zu-Trennzeichen-Ersetzung für
`require("ui.kit")` erzeugt einen GEMISCHTEN Pfad (`.../ui\kit.lua`), den
der Loader nicht findet. Betraf nur eigene Verifikations-Skripte, nicht
die eigentlichen Testrunner (deren `vim.fn.fnamemodify`-basierte Pfade sind
schon durchgehend Windows-nativ).

Danach 4 weitere: diff.nvim (7, weich), reposcope.nvim (6, **hart** — noch
eagerer als filetree/sandbox/replacer: `init.lua`s eigenes
Modul-Top-Level-`require` zieht `ui.kit` schon vor `setup()` nach),
pickers.nvim (6, weich, komplett lazy mit `vim.ui.select`-Fallback in 3
von 5 Stellen), images.nvim (7, gespalten — manche Aufrufe fallen
zurück, `:Image compare` nicht).

**Wichtiger Fund bei images.nvim, rückwirkend auf alle vorherigen Repos
angewandt:** der reine `sed` auf den literalen Require-String
(`lib.nvim.ui.kit` → `ui.kit`) fängt KEINE Prosa-Erwähnungen ("lib.nvim's
UI kit") und KEINE GitHub-Blob-Links auf den alten Pfad
(`lib.nvim/blob/.../lua/lib/nvim/ui/kit/...`). Nachträglicher Grep über
alle 9 bis dahin fertigen Repos gefunden: 2 Stellen in filetree.nvim, 2 in
sandbox.nvim (Testkommentare mit altem Pfad), 1 in replacer.nvim (toter
Link) — je in einem eigenen kleinen Nachbesserungs-Commit gefixt und
gepusht. **Für die restlichen 20 Repos gehört dieser zweite Grep-Durchgang
jetzt zum Standardvorgehen**, nicht erst am Ende.

**2026-09-14, dieselbe Session, Schritt 5 fortgesetzt bis 19/30:**
documentation.nvim (9, weich — `editor/browse/init.lua`s eigenes
Modul-Top-Level-Require zwingt die Testsuite trotzdem zu einem echten
`ui.nvim`-Checkout in CI; CI-Analyse ergab drei separate Jobs, von denen
nur `tests` überhaupt betroffen ist), gopath.nvim (5, weich, Healthcheck +
mehrere Docs schrieben `ui.kit.confirm`/`.select` fälschlich `lib.nvim`
zu — nicht nur der Require-String war falsch, sondern die Paketzuordnung
selbst), fileops.nvim (5, weich trotz fehlendem `vim.ui.select`-Fallback
an den meisten Stellen — Klassifikation läuft nach Lade-Zeitpunkt, nicht
nach Fallback-Vorhandensein), emojis.nvim (8, weich, aber CI brauchte
einen echten `ui.nvim`-Checkout: zwei Specs treiben `ui.kit.select`/den
Overlay tatsächlich, nicht nur gestubbt), runtime-analysis.nvim
(10, weich, nachgeholt aus der ursprünglichen 6-Datei-Stufe — beim ersten
Durchgang übersprungen), buffer-ctx.nvim (6, weich), markdown.nvim
(6, weich — CI dort seit 4 Commits VOR dieser Migration wegen fehlendem
`rg` im Runner rot, unabhängig verifiziert und als Task geflaggt statt
selbst gefixt), insights.nvim (8, gemischt — Scratch-Buffer weich,
Dev-Server-Prompt effektiv hart weil `devserver.prompt` standardmäßig an
ist und es keinen Fallback gibt → `ui.nvim` in die persönliche Config),
spotlight.nvim (9, **hart** — `ui.kit.select` IST die Spotlight-Liste,
`health.lua` markierte das schon vorher `required = true` → ebenfalls
`ui.nvim` in die persönliche Config).

**Neues wiederkehrendes Muster ab insights.nvim:** wenn `ui.kit` in einer
`health.lua` bisher unter einer "lib.nvim"-Sektion mitlief, wird das jetzt
in eine eigene "ui.nvim"-Sektion mit korrektem Install-Hinweis
herausgelöst, statt den falschen Hinweistext ("Update lib.nvim") einfach
nur umzubenennen — sonst zeigt `:checkhealth` bei fehlendem `ui.nvim`
weiterhin auf das falsche Repo.

**Noch offen: 11 der 30 Konsumenten-Repos**, nächste laut Reihenfolge:
pdfport/open/color_my_ascii (3 Dateien), recommender/cmdlog/casedesk
(2), sessions/hover/github_stats/cascade (1) — die letzte Gruppe sind
Ein-Datei-Konsumenten, laut Plan bewusst zuletzt.

Rechtsklick-Menü-Migration (`PLAN-ui-kit-migration.md`) — Schritt 3 von 6
und der `menu`-Toggle sind erledigt, Schritt 5 zu 19/30 (s. o.), noch offen:
- Schritt 5: die restlichen 11 Konsumenten-Repos
- Schritt 6: Shim löschen, `lib.nvim`-Docs nachziehen (kein `lib.nvim`-Shim
  gebaut — bewusst übersprungen, direkt mit Schritt 5 weitergemacht)

**Nebenbei als eigenständige Aufgaben geflaggt (Chips), nicht selbst
gefixt:**
- `emojis.nvim`s `picker.lua`: Moduldoku behauptet einen
  `vim.ui.select`-Fallback, den `select_fallback()` tatsächlich nicht hat
  (`task_5d14fa46`).
- `markdown.nvim`s CI (`tests`-Job): seit mind. 4 Commits rot wegen
  fehlendem `rg` im Runner-Image, unabhängig von dieser Migration
  (`task_2295ae16`).

Aus der ursprünglichen Roadmap, noch nicht angegangen:
- rules.nvim-Pass über ui.nvim (nachrangig zu my.nvim)
- Kreuzfeature-Check gegen die ~30 Schwesterplugins

---
