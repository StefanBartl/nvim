# Plugin-Roadmaps — Erledigtes

Gegenstueck zu [`PLUGIN_ROADMAPS.md`](PLUGIN_ROADMAPS.md), das nur noch offene
Arbeit fuehrt. Hierher wandert ein Punkt, sobald er gebaut, dokumentiert,
committet und gepusht ist — mit den Notizen, die beim Bauen angefallen sind.

Die Notizen sind der eigentliche Wert dieser Datei. Ein erledigter Punkt ohne
sie waere eine Zeile in `git log`; was ihn hier aufhebenswert macht, sind die
Stellen, an denen die urspruengliche Beschreibung nicht ganz stimmte, die
Nebenbefunde, und die Entscheidungen, die im Auftrag nicht standen.

Nummerierung und Titel bleiben die aus `PLUGIN_ROADMAPS.md`, damit ein
Querverweis von aussen weiter aufgeht.

Seit dem 2026-08-30 fuehrt die Datei **zwei** Sorten geschlossener Punkte. Das
Erledigte steht oben, am Ende ein Abschnitt
[Zurueckgestellt](#zurueckgestellt) fuer Punkte, die aus
`PLUGIN_ROADMAPS.md` heraus sind, ohne gebaut worden zu sein. (Am 2026-08-31
sortiert: zwei erledigte Punkte — M5 und die Call-Hierarchy-Resthaelfte —
waren hinter der Trennlinie gelandet und sahen damit aus wie zurueckgestellte.
Nur verschoben, kein Wort geaendert.) Sie stehen hier
und nicht dort, weil sie keine offene Arbeit mehr sind — und sie sind nicht
geloescht, weil ein stillschweigend verschwundener Punkt in einem halben Jahr
als neue Idee wiederkommt. Zu jedem gehoert, **warum** er zurueckgestellt ist
und **was ihn wieder aufmachen wuerde**.

---

## Table of content

  - [QW3 · `lsp.nvim` — Inlay-Hints-Toggle](#qw3-lspnvim-inlay-hints-toggle)
  - [QW4 · `lsp.nvim` — Diagnostics-Debounce auf `publishDiagnostics`](#qw4-lspnvim-diagnostics-debounce-auf-publishdiagnostics)
  - [QW6 · `lsp.nvim` — `formatter_priority` verkabeln oder als report-only festschreiben](#qw6-lspnvim-formatter_priority-verkabeln-oder-als-report-only-festschreiben)
  - [QW7 · `lsp.nvim` — "installed vs. attached"-Zeile in `:checkhealth lsp`](#qw7-lspnvim-installed-vs-attached-zeile-in-checkhealth-lsp)
  - [QW9 · `images.nvim` — Trial-Run für die `reposcope.nvim`-Kreuzung](#qw9-imagesnvim-trial-run-fr-die-reposcopenvim-kreuzung)
  - [A · `nvim-config` — die Source-Achse von `:Bindings check` abarbeiten](#a-nvim-config-die-source-achse-von-bindings-check-abarbeiten)
  - [B · Die verbliebenen Audit-Zeilen prüfen](#b-die-verbliebenen-audit-zeilen-prfen)
  - [QW1 · `mdview.nvim` — `any_file` in echtem Neovim durchtesten](#qw1-mdviewnvim-any_file-in-echtem-neovim-durchtesten)
  - [QW10 · `mdview.nvim` — auf Windows startet kein lokal gebauter Relay](#qw10-mdviewnvim-auf-windows-startet-kein-lokal-gebauter-relay)
  - [QW8 · `lsp.nvim` — Multi-Root-/Monorepo-Workspace-Switcher](#qw8-lspnvim-multi-root-monorepo-workspace-switcher)
  - [M6 + M7 · `lsp.nvim` — Profile-Presets und Per-Projekt-Override](#m6--m7-lspnvim-profile-presets-und-per-projekt-override)
  - [M17/M7 · `documentation.nvim` — Phase-0-IR: der besitzende Scope](#m17m7-documentationnvim-phase-0-ir-der-besitzende-scope)
  - [QW5 · `lsp.nvim` — Hover-Cache über `lib.lua.memo`](#qw5-lspnvim-hover-cache-ber-libluamemo)
  - [M1 · `lsp.nvim` — Fehler provozieren als Testhilfe (`:LspDoctor probe`)](#m1-lspnvim-fehler-provozieren-als-testhilfe-lspdoctor-probe)
  - [M16 · `lib.nvim` — `deps.health`-Migrationen](#m16-libnvim-depshealth-migrationen)
  - [M2 · `lsp.nvim` — Code-Action-Indikator](#m2-lspnvim-code-action-indikator)
  - [M3 · `lsp.nvim` — Auto-Restart mit Backoff bei Client-Crash](#m3-lspnvim-auto-restart-mit-backoff-bei-client-crash)
  - [M4a · `lsp.nvim` — ein Picker-Backend statt zwei](#m4a-lspnvim-ein-picker-backend-statt-zwei)
  - [M17/M13 · `documentation.nvim`-Verbund — ein `ECOSYSTEM.md`, fünf Repos erreichen es](#m17m13-documentationnvim-verbund-ein-ecosystemmd-fnf-repos-erreichen-es)
  - [M17/M8 · `documentation.nvim` — `:DocMap impact`, gewichtet nach Runtime-Reichweite](#m17m8-documentationnvim-docmap-impact-gewichtet-nach-runtime-reichweite)
  - [M17/M9 · `documentation.nvim` — `:DocMap why` × Call-Trees](#m17m9-documentationnvim-docmap-why--call-trees)
  - [M17/M14 · `documentation.nvim` — Cross-Repo-Doku-Verweise, per CI geprueft](#m17m14-documentationnvim--cross-repo-doku-verweise-per-ci-geprueft)
  - [M17/M7c · `documentation.nvim` — der Befund statt des Umbaus](#m17m7c-documentationnvim--der-befund-statt-des-umbaus)
  - [M5 · `nvim-config` — Sprung zur umschliessenden Struktur (ehemals `<leader>gtt`)](#m5-nvim-config-sprung-zur-umschliessenden-struktur-ehemals-leadergtt)
  - [Call Hierarchy · `lsp.nvim` — die Resthaelfte von M4](#call-hierarchy-lspnvim-die-resthaelfte-von-m4)
  - [M9 · `gopath.nvim` + `pickers.nvim` + `lib.nvim` — Frecency fuer Alternate-Vorschlaege](#m9-gopathnvim--pickersnvim--libnvim--frecency-fuer-alternate-vorschlaege)
  - [M17/M10 · `documentation.nvim` + `runtime-analysis.nvim` — Laufzeit-Evidenz als Check-Input](#m17m10-documentationnvim--runtime-analysisnvim--laufzeit-evidenz-als-check-input)
  - [M11 · `images.nvim` + casedesk — OCR, und wofuer sie eigentlich da ist](#m11-imagesnvim--casedesk--ocr-und-wofuer-sie-eigentlich-da-ist)
  - [M13 · `images.nvim` — Bildoperationen als Dateioperationen](#m13-imagesnvim--bildoperationen-als-dateioperationen)
  - [M17/QW6 · `documentation.nvim` — Fenced Blocks auf der generierten Seite](#m17qw6-documentationnvim--fenced-blocks-auf-der-generierten-seite)
  - [M12 · `runtime-analysis.nvim` + `images.nvim` — Flamegraphs als Bild](#m12-runtime-analysisnvim--imagesnvim--flamegraphs-als-bild)
  - [Zurueckgestellt](#zurueckgestellt)
    - [M4b · `lsp.nvim` — der Picker-Adapter (Roadmap-Abschnitt 7)](#m4b-lspnvim-der-picker-adapter-roadmap-abschnitt-7)
    - [M17/M12 · `documentation.nvim`-Verbund — Runtime-Tab im ausgelieferten Artefakt](#m17m12-documentationnvim-verbund-runtime-tab-im-ausgelieferten-artefakt)
    - [M17/M7b · `documentation.nvim` — ein Scope ist kein Knoten](#m17m7b-documentationnvim--ein-scope-ist-kein-knoten)

---

### QW3 · `lsp.nvim` — Inlay-Hints-Toggle

**Erledigt am 2026-08-29. `lua/lsp/core/inlay_hints.lua`, 14 neue Specs.**

Ursprünglich: `vim.lsp.inlay_hint` ist seit Neovim 0.10 nativ und war in
`lua/lsp/` nirgends referenziert; global plus pro Filetype schaltbar, an den
`:Lsp`-Composer und den Keymap-Katalog angehängt.

Gebaut wurde genau das, mit einer Entscheidung, die im Auftrag nicht stand:
**die Filetype-Ebene ist eine Map, keine Liste.** Zwei Ebenen funktionieren
nur, wenn "keine Meinung" und "hier ausdrücklich aus" verschiedene Zustände
sind — `filetypes = { lua = false }` gegen ein globales `enable = true` heißt
"überall außer Lua", ein fehlender Schlüssel erbt. Eine Liste
(`filetypes = { "lua" }`) type-checkt als Tabelle, löst jeden Lookup zu `nil`
auf und würde schweigend gar nichts überschreiben; `config/init.lua` weist sie
deshalb mit einer Warnung zurück, statt sie anzunehmen.

*Oberfläche*: `inlay_hints = { enable, filetypes }` in den DEFAULTS,
`:Lsp hints [toggle|on|off|status|clear] [filetype]` mit Tab-Completion über
beide Argumente, `<leader>th` (global) und `<leader>tH` (dieser Filetype) im
Katalog — damit auch in `docs/BINDINGS.md`, das aus dem Katalog generiert wird.
`clear` gibt einen Filetype an den globalen Default zurück; das ist die eine
Aktion ohne globale Bedeutung und verlangt deshalb ein Argument.

*Zwei Details, die Zeit kosten würden*: der `LspAttach`-Handler liegt in einem
**eigenen** Augroup (`lsp_nvim_inlay_hints`), nicht in `lsp_nvim` — der wird
bei `keymaps.enable = false` geleert, und Hints sind keine Keymap-Sache.
Und gefragt werden nur Clients mit `inlayHintProvider`: sonst meldet `status`
"an" für Buffer, die nie einen Hint zeigen werden.

*Verifiziert*: 199 Specs grün (14 davon neu), Smoke-Test grün, `stylua` und
der `gen_bindings --check` sauber, und `:Lsp hints` in einem echten headless
Neovim durchgespielt — Routing, Override, `clear`, Completion.

---

### QW4 · `lsp.nvim` — Diagnostics-Debounce auf `publishDiagnostics`

**Erledigt am 2026-08-29. `lua/lsp/core/handlers.lua`, 18 neue Specs — und
ein Defekt im Dedup darunter, der dabei aufgefallen ist.**

Ursprünglich: `core/handlers.lua` dedupliziert, debounct aber nicht; ein Timer
pro `(client, bufnr)`, Intervall konfigurierbar.

*Gebaut*: `diagnostics.debounce_ms`, Default 150ms, `0` schaltet ab. Das
Fenster ist **leading-edge**, und das ist die eigentliche Entscheidung: ein
reines trailing debounce würde ausgerechnet den Push verzögern, auf den man
wartet — den direkt nach dem Aufhören zu tippen. Der erste Push eines Bursts
geht sofort durch, nur was innerhalb des Fensters ankommt wird zusammengelegt.
Zusammenlegen heißt *neuester gewinnt*, nie Merge: eine Diagnostics-Liste
ersetzt die Datei komplett, ein Merge würde gerade gelöschte Einträge
wiederbeleben. Fenster pro `(Client, Datei)` — pro Client allein würde ein
lauter Buffer einen ruhigen mitdrosseln, pro Datei allein würden sich zwei
Server auf derselben Datei gegenseitig ausbremsen.

*Der Nebenbefund, der wichtiger ist als der Punkt selbst*: `filter.dedup` lief
auf dem **rohen** LSP-Payload, und der trägt `range`, nicht `lnum`/`col`. Die
Funktion las nur das zweite Paar, verglich also jeden Eintrag auf Position
`(0,0)` — und warf von zwei echten Diagnostics mit gleichem Text ("unused
variable" zweimal in einer Datei) die zweite weg. Sie wurde nie gerendert, hat
nie geloggt und sah aus wie "der Server hat sie nicht geschickt". Behoben:
`dedup` liest die Position jetzt aus beiden Formen. Das saß in genau der
Funktion, die QW4 anfasst — eine Drosselung obendrauf hätte den Fehler nur
schwerer auffindbar gemacht.

*Zwei Härtungen dazu*: `setup()` weigert sich, den Handler ein zweites Mal zu
umwickeln (sonst sieht der zweite Wrapper die Ausgabe des ersten statt die des
Servers), und ein Nachzügler wird verworfen, wenn sein Client inzwischen weg
ist — sonst kommen Diagnostics eines beendeten Servers zurück, *nachdem*
Neovim sie gelöscht hat, und nichts entfernt sie mehr.

*Verifiziert*: 217 Specs grün (18 davon neu), Smoke-Test grün, `stylua` und
`gen_bindings --check` sauber.

---

### QW6 · `lsp.nvim` — `formatter_priority` verkabeln oder als report-only festschreiben

**Erledigt am 2026-08-29 als report-only. Der Punkt war anders gelagert, als die
Beschreibung annahm — in beide Richtungen.**

Urspruenglich: `formatter_priority` wird nur von `lspdoctor/inspect.lua:161`
gelesen, also nur berichtet; zwei Wege, entweder conform ordnet
`formatters_by_ft` danach, oder der Key wird als reine Report-Option
dokumentiert. „Der zweite ist eine Zeile, der erste die ehrlichere Semantik."

**Der erste Weg geht nicht.** `formatters_by_ft` enthaelt Werkzeugnamen
(`stylua`, `prettier`, `shfmt`), `formatter_priority` enthaelt
**LSP-Client-Namen** (`lua_ls`, `eslint`, `null-ls`). Die zwei Namensraeume
beruehren sich nicht — der Vorschlag ist ein Kategorienfehler, keine
Verkabelung.

**Und der Key liegt bereits richtig.** Er heisst `lspdoctor.formatter_priority`,
sitzt also schon im Report-Namensraum. Report-only war damit kein Rueckzug,
sondern das, was sein Pfad ohnehin sagt; *Durchsetzen* waere die Aenderung
gewesen, die ihn nach `formatter.*` zwingt — ein Config-Bruch.

**Der eigentliche Defekt war die Report-Ausgabe, nicht die Semantik.** Auf
einer Lua-Datei stand dort:

```
Candidates: lua_ls
Winner: **lua_ls**
Policy: priority list
```

Formatiert wird die Datei von **stylua**. Auf `.ts` haette es `eslint` genannt,
waehrend `prettierd` laeuft. Grund: `lsp.formatter` laesst conforms Kette
laufen und faellt nur auf LSP zurueck, wenn conform fuer das Filetype nichts
hat — und conform deckt `lua`, `ts`, `js`, `json`, `css`, `html`, `cs`,
`markdown`, `sh` ab. Genau dort, wo zwei LSP-Clients streiten koennten,
gewinnt conform vorher. Uebrig bleibt `go` (nur gopls) und die
auskommentierten `c`/`cpp`/`zig`. Der Filter, den die „ehrliche Semantik"
gebaut haette, laeuft also praktisch nie.

*Gebaut*: der Report fragt jetzt **conform selbst**
(`list_formatters_to_run`, das `stop_after_first` und die Fallback-Logik
beruecksichtigt) statt ein zweites Mal zu entscheiden — eine zweite Meinung,
die der Realitaet widerspricht, ist schlimmer als keine. `Runs:` steht zuerst,
das Ranking der LSP-Clients darunter, ausdruecklich als report-only markiert.
Dazu DEFAULTS-Kommentar, `@types.lua`, Helpdoc, `configuration.md`,
`FEATURES.md`.

*Verifiziert*: in der echten Config gerendert, `lua` und `markdown`:

```
### Formatter
Runs: **stylua** (conform)

LSP clients able to format: lua_ls
Preferred among them: **lua_ls** (priority list)
*Report only.* ...
```

228 Specs gruen, Smoke-Test gruen, `stylua` und `gen_bindings --check` sauber.

---

### QW7 · `lsp.nvim` — "installed vs. attached"-Zeile in `:checkhealth lsp`

**Erledigt am 2026-08-29. `lua/lsp/health.lua`, 11 neue Specs.**

Ursprünglich: die attached-Seite steht (*configured: N*, *set up N von M*, pro
Client eine Zeile mit `%d buffer(s)`); es fehlten die **installed**-Seite, das
„davon in diesem Buffer: K", und die Warnung bei schwerem Server über vielen
Buffern.

*Alle drei gebaut.* Die Sektion läuft jetzt über vier Zahlen: installed →
configured → set up → attached, plus welche der laufenden Clients den Buffer
bedienen.

*Der Punkt, an dem es beinahe falsch geworden wäre*: „in diesem Buffer" kann
nicht `nvim_get_current_buf()` sein. Neovim legt den `health://`-Buffer an und
macht ihn zum aktuellen, **bevor** ein einziger Check läuft
(`runtime/lua/vim/health.lua`) — der Report hätte über sich selbst berichtet.
Am Filetype ist es auch nicht erkennbar, das wird erst *nach* den Checks
gesetzt. Der Buffer von vorher ist der Alternate (`#`); empirisch geprüft, nicht
angenommen. Gibt es keinen echten Datei-Buffer, sagt die Zeile das, statt eine
Null zu drucken, die wie ein Defekt aussieht.

*Die installed-Seite mit einer Einschränkung, die dokumentiert ist*:
Mason-Paketnamen sind keine lspconfig-Servernamen (`lua-language-server` gegen
`lua_ls`), und die Übersetzung liegt in `mason-lspconfig`, von dem das Plugin
bewusst nicht abhängt. Also werden Masons Namen berichtet und das dazugesagt —
eine falsche „installiert aber nicht eingerichtet"-Liste wäre schlechter als
keine. Zusatzfall, der sonst gelogen hätte: sind Pakete da, aber keins
kategorisiert, ist Masons Registry noch nicht geladen; die Zeile meldet dann
„unbekannt", nicht „0 LSP-Pakete" neben 73 vorhandenen.

*Die Warnung* springt nur bei der Kombination an: `ts_ls`, `pyright`, `jdtls`,
`omnisharp` über mindestens 20 Buffern, mit Buffer- und Zeilenzahl im Text.
Nie über eine Zahl allein — fünf Buffer auf `ts_ls` sind ein Arbeitsset, und
eine Warnung darüber erzieht dazu, die Sektion zu überspringen.

*Nebenbefund*: `vim.health.info()` nimmt keine Advice-Zeilen, nur `warn` und
`error` tun das. Ein zweites Argument wird stillschweigend verworfen. Der
Hinweis zur Namensgebung steht deshalb im Meldungstext.

*Verifiziert*: 228 Specs grün (11 davon neu), Smoke-Test grün, `stylua` und
`gen_bindings --check` sauber, und `:checkhealth lsp` mit geladenem Mason in
einem echten headless Neovim durchgespielt — 38 installierte LSP-Pakete gegen
8 konfigurierte.

---

### QW9 · `images.nvim` — Trial-Run für die `reposcope.nvim`-Kreuzung

**Erledigt am 2026-08-29. Die Messung hat eine Frage in zwei geteilt.**

Ursprünglich: Social-Preview-Card bzw. README-Bilder in der Repo-Vorschau,
mit dem Auftrag, vor dem Bauen zu messen, wie stark `:Reposcope`s
Reaktionszeit leidet. Gemessen wurde über 25 Repos (20 verbreitete
nvim-Plugins, 5 eigene). Vollständiges Protokoll:
`wkdbook-myplugins/images.nvim/ROADMAP/CROSS-PLUGIN.md`.

**Card: endgültig abgelehnt** — und nicht wegen der Reaktionszeit.
`opengraph.githubassets.com` limitiert hart und unauthentifiziert pro IP:
`X-RateLimit-Limit: 100`, danach `Retry-After: 900`. Vier von zwölf Cards
kamen in einem einzigen sequentiellen Lauf als 429 zurück. In dieses Budget
passt ein Repo-Browser nicht: `readme_precache_count` allein verbraucht 5 pro
Suche. Ein Cache rettet es auch nicht — reposcope existiert, um *unbekannte*
Repos zu finden, der Cache hilft beim zweiten Blick, und genau da ist die
Card am wenigsten wert. Nebenzahlen: 49–130 kB gegen 3–31 kB README, Mittel
617 ms gegen 220–514 ms.

**README-Bild: offen, und billiger als es aussieht.** 8 von 25 Repos haben
ein echtes Bild (Badges herausgerechnet), 17 keins — darunter alle fünf
eigenen. Mittlere Ladezeit 883 ms, mittlere Größe 232 kB. Entscheidend ist
aber die Zahl, die nicht in der Tabelle steht: **die Erkennung ist gratis.**
reposcope hat den README-Text ohnehin im eigenen Cache, also kostet
„hat dieses Repo überhaupt ein Bild?" einen Pattern-Match im RAM — kein
Request. Der häufige Fall (zwei Drittel) kostet damit *nichts* und bietet
korrekt gar keinen Hover statt eines leeren.

**README-Bild: gebaut am 2026-08-29**, als `reposcope.ui.preview.preview_image`
mit `<C-p>` im Prompt. In images.nvim war dafür nichts nötig:
`images.browse.draw_in_window()` zeichnet in ein fremdes Fenster,
`images.remote.fetch` lädt asynchron in einen SHA256-Cache. Dazu Docs in
reposcope (BINDINGS, COMMANDS, CONFIGURATION, FEATURES, FEATURES/UI, vimdoc),
ein Health-Abschnitt und ein Spec für die reine Erkennungsfunktion.

**Zwei der vier vorab notierten Bedingungen sind beim Bauen gefallen**, und
das ist der lehrreiche Teil des Punkts:

- Der **Negativ-Cache** war rückwärts gedacht. „Dieses Repo hat kein Bild"
  wird zwar bei jedem Neustart neu hergeleitet — aber aus einem README, das
  ohnehin in reposcopes Dateicache liegt, per Pattern-Match, in Mikrosekunden,
  ohne Request. Der Cache hätte etwas gespart, das bereits gratis ist. Was
  ihn hätte rechtfertigen können, wäre ein *fehlgeschlagener* Download — und
  selbst der gehört wiederholt, weil die übliche Ursache ein transienter
  Netzfehler ist und ein zweiter Tastendruck genau die Bitte ist, es nochmal
  zu versuchen.
- Das **Größenlimit** lässt sich auf der reposcope-Seite nicht durchsetzen:
  der Transfer passiert in `images.remote.fetch`, das `max_bytes` aus
  images.nvims eigener Config liest. Ein Limit danach würde nur das Zeichnen
  von Bytes verweigern, die längst bezahlt sind. Stattdessen meldet
  `:checkhealth reposcope` den effektiven Wert und benennt, wo er zu ändern
  ist — die ehrliche Fassung eines Limits, das es nicht erzwingen kann.

Die beiden Bedingungen, die hielten, betrafen **Verhalten**: auf Anforderung
statt automatisch, und kein unaufgeforderter Hover ohne Bild. Bei der zweiten
kam beim Schreiben eine Unterscheidung dazu, die vorher nicht sichtbar war:
die Regel gilt für *unaufgeforderte* UI. Auf ein ausdrückliches `<C-p>` hat
der Nutzer eine Frage gestellt, und jeder Fehlerpfad antwortet — „README noch
nicht geladen", „dieses README hat kein Bild", oder images.remotes eigene
Meldung, die den abgeschalteten Schalter benennt. Schweigen wäre dort ein
Bug, kein Prinzip.

Die zwei, die fielen, betrafen **Mechanik** — und beide unterstellten Kosten,
die die vorhandenen Caches längst beseitigt hatten.

---

### A · `nvim-config` — die Source-Achse von `:Bindings check` abarbeiten

**Erledigt am 2026-08-30. nvim-config `42fed783`, `726a3887`, `f834a02c`,
`84a6557d`, `3cc32cb8`.**

Ursprünglich: „111 Keymaps und 39 Usercmds, die in der Config existieren und
nirgends im Notes-Baum stehen", davon 82 in `lua/bindings/mappings` — Aufwand
M, Nutzen hoch. Die Stichproben dazu (`<F1>`, `<leader>dt`) waren echt.

**Die Zahl war es nicht.** Von 150 Befunden blieben 51 echte übrig; die
anderen 99 waren zwei Werkzeugfehler und ein veraltetes Artefakt. Das ist der
eigentliche Fund dieses Punktes, und er wäre ohne den Versuch, die Liste
abzuarbeiten, nicht aufgefallen:

| | Befunde | Ursache |
| --- | ---: | --- |
| Ausgangslage | 150 | |
| Veraltete Karte | −49 | `docs/map/module_map.json` war sechs Tage alt und beschrieb noch `lua/lsp/`, das längst nach `lsp.nvim` ausgezogen ist. 44 Befunde zeigten auf gelöschte Dateien |
| `LHS_HEADERS` englisch-only | −50 | Der Korpus ist zweisprachig: `ExternPlugins/Bindings/*` schreibt `Taste`, `Mapping`, `Taste(n)`. **601 Tabellenzeilen** waren dadurch für *beide* Achsen unsichtbar — eine Zeile ohne lesbaren Spaltenkopf liefert kein `lhs` und wird kommentarlos verworfen. `<leader>gb` steht wörtlich in `Snacks.md`s Git-Tabelle und wurde trotzdem als undokumentiert gemeldet |
| Echte Doku-Lücke | **51** | dokumentiert |

*Ein zweiter Werkzeugfehler, gefunden erst beim Gegenprüfen der eigenen
Arbeit*: die neuen Cheatsheets meldeten 81 Keymaps als „dokumentiert, nicht
live". Davon waren 58 ein Messfehler — die Keymaps werden in der
`UIReady`-Phase registriert (VimEnter + `vim.schedule`), ein
`nvim --headless -c luafile` läuft davor. Die verbliebenen 23 waren echt und
alle Ctrl-Akkorde: `nvim_get_keymap` liefert `<C-a>` modifier-erhaltend als
`{128,252,4,65}`, `nvim_replace_termcodes` kollabiert dasselbe zum Steuerbyte
`{1}`. `is_live` verglich beide auf Gleichheit, also meldete **jede
dokumentierte Ctrl-Kombination im ganzen Korpus** „nicht live". `key_forms()`
schickt jetzt beide Seiten durch dieselbe Normalform — zusätzlich zum
Rohschlüssel indiziert, damit nichts, was vorher traf, aufhören kann zu
treffen. `keytrans` allein reichte nicht: Byte 10 rendert als `<NL>` von der
einen und `<C-J>` von der anderen Seite, daher die dritte Form über den
Rückweg durch `nvim_replace_termcodes`.

*Gebaut*: die beiden Fixes in `drift.lua`, jeweils mit der Messung im
Kommentar; `Keymaps/nvim-config.md` und `Usercmds/nvim-config.md` als neue
Cheatsheets (der Baum kannte nur „Personal-Plugin" und „Extern-Plugin", nicht
„die Config selbst" — obwohl `Usercmds/` mit `MyPlugins.md`, `WhoLocks.md`
und `bindings_explorer.md` das Muster längst hatte); `Keymaps/dap.nvim.md`,
dessen Tabelle durch dazwischenliegende Prosa ihre Kopfzeile verloren hatte,
sodass der Parser die erste Datenzeile als Header las und zehn Keymaps
verwarf.

*Vier deutsche Spaltennamen bewusst nicht aufgenommen*, weil ihre Zellen keine
Tasten enthalten und sie sonst Fremdtext als „Dokumentation" gelten ließen:
`Eintrag` (nvzone/menu-Labels), `Tab` (search.nvim-Tabnamen), `Modul`
(Modulnamen), `Vorschlag (README)` (Tasten, die upstream *vorschlägt* und
diese Config nicht bindet — die würden einen echten Befund unterdrücken).

*Zwei echte Defekte nebenbei*, beide behoben: `:WKDDiffProfile` war definiert,
aber `register_diff_profile()` hatte keinen Aufrufer — der Command existierte
in keiner laufenden Sitzung, und **nur beide Achsen zusammen** konnten das
finden (in der Quelle vorhanden, in `nvim_get_commands` nicht). Und
`terminal.lua`s `<C-j>` trug `desc = "[Terminal Down"` mit offener Klammer,
was das Cheatsheet zunächst wörtlich reproduzieren musste, weil `is_live` den
`desc` verbatim vergleicht.

*Verifiziert*: `:Bindings check` meldet **260 statt 680** Befunde, die
Source-Achse null. `:WKDDiffProfile` in echtem Neovim durchgespielt — alle
vier Profile schreiben `diffopt` wie ihre Tabelle es sagt, Completion liefert
`context`/`minimal`/`review`/`strict`, ein unbekannter Name lässt `diffopt`
unangetastet. `stylua` sauber auf allen geänderten Dateien (die 58
Beanstandungen in `lua/@types/` sind vorbestehend).

*Was das im täglichen Gebrauch ändert*: wer eine Taste nachschlägt, findet
sie. Vorher standen 40 Keymaps und 11 Commands ausschließlich im Code.

---

### B · Die verbliebenen Audit-Zeilen prüfen

**Erledigt am 2026-08-30. WKDBooks `482f707`.**

Ursprünglich: „die ~14 echten Audit-Zeilen abräumen", Aufwand XS, Nutzen
mittel — mit der ausdrücklichen Ansage, dass sich **im täglichen Gebrauch gar
nichts** ändert und danach nur die Beschreibung stimmt. Genau das ist
eingetreten.

Vorab die Zählung, weil die Ausgangszahl irreführend war: von 179
`🟡`-Markierungen sind **114 Phantome** — 109 in `gopath.nvim`s Checkliste,
einer wörtlichen Kopie der *generischen* Vorlage, wo `🟡` „EMPFOHLEN" heißt
und keinen Befund über gopath macht; vier sind `spotlight.nvim`s
Prioritätsspalte; eine ist in `migrate.nvim` als `n/a` gekennzeichnet.

*`color_my_ascii.nvim`*: „kein automatisiertes Test-Framework" war **komplett**
überholt, nicht halb — mein erster Blick auf `lint.yml` sah nur `stylua` und
`luacheck` und schloss auf „Specs ja, Automatisierung nein". Falsch: die Datei
hat einen dritten Job `tests (headless)`, und `TESTS/` enthält 14 `_spec.lua`
plus einen repo-eigenen Runner (`run.lua` + `harness.lua`). Die
`@types`-Ordner-Zeile ist nachgeprüft und unverändert zutreffend.

*`markdown.nvim`*: das Dokument widersprach **sich selbst**. Der Durchgang vom
2026-08-29 hatte §5 auf „A3 done" korrigiert, aber zwei `🟡`-Zeilen
stehengelassen, die dieselbe Lücke weiter behaupteten — genau der Fehler, den
die Konvention dieser Audits verbietet. Beide korrigiert. Dazu **A2**
beantwortet, das als offene Frage formuliert war („confirm every deferred
callback re-validates"): `tableview/renderer.lua` enthält gar kein
`vim.schedule`/`defer_fn`, es gibt also keinen verzögerten Callback, dessen
Handle veralten könnte — und jede Handle-Nutzung ist ohnehin durch
`nvim_win_is_valid`/`nvim_buf_is_valid` abgesichert, an zehn Stellen.

*`github_stats.nvim`*: drei Stellen führten den *gefixten* Global-Leak in
`dashboard/init.lua` weiter als Teilerfüllung. Auf ✅ korrigiert, mit der
Historie als Notiz und `luacheck` im CI als dem, was den Zustand hält. Die
übrigen `🟡` sind geprüft und bleiben zu Recht stehen: Type Guards nur
punktuell, keine echte Dependency Injection, Import-Reihenfolge konsistent
aber nicht normiert, keine Tabellen-Vorreservierung (`table.new` kommt im
ganzen Repo nicht vor).

*Was jetzt anders ist*: die vier Dateien sind lesbar, ohne jede Zeile
nachzuschlagen — auch dort, wo der Befund stehen bleibt, steht jetzt daneben,
dass er geprüft wurde. Teil 3.1 ist damit vollständig abgeschlossen statt zu
neun Zehnteln.

---

### QW1 · `mdview.nvim` — `any_file` in echtem Neovim durchtesten

**Erledigt am 2026-08-30. `mdview.nvim` `6a12aa5` (Freigabe) und `8f24847`
(Nebenbefund), beide auf `main` gepusht.**

Ursprünglich: `experimental.any_file` war seit 2026-08-24 gebaut und über den
Lua-Harness (55 Tests), das Client-vitest (95 Tests) und einen Browser-Check im
Standalone-`--watch` verifiziert — nur nicht durch Neovims Autocmd-Kette, und
genau die ändert das Flag. Fünf Fälle in `TESTS/CHECK.md` sollten entscheiden,
ob es ausgeliefert werden kann.

**Ergebnis: alle fünf bestanden. Der Schlüssel heißt jetzt `any_file`,
ohne `experimental`,** und ist in `configuration.md`, `FEATURES.md`,
`WORKFLOW.md` und `doc/mdview.txt` als unterstützt dokumentiert.
`experimental.any_file` bleibt als veralteter Alias funktionsfähig — DEFAULTS
führt ihn nicht mehr, er ist also nur wahr, wenn ihn jemand übergeben hat, und
ein ausdrückliches `any_file = false` im selben `setup()` gewinnt.

*Wie „echtes Neovim" hier aussah*, weil der Punkt als „braucht dich"
eingestuft war: `nvim --headless --listen 127.0.0.1:6789`, gesteuert über
`--remote-expr` — also ein laufender Prozess mit normaler Event-Loop, in dem
jedes Autocmd echt feuert, nicht ein Harness, der Funktionen direkt aufruft.
Auf dem rtp lagen nur mdview.nvim und lib.nvim, der Relay war der lokal
gebaute, der Client `dist/client`, und der Preview-Tab wurde von Hand auf
**die URL** gestellt, die der Produktions-Launcher gebaut hat.

*Die fünf Ergebnisse*:

1. **Rendern**: `.lua`, `.py` und `.sh` erscheinen als hervorgehobener Code.
   Die als Überschrift geformten `#`-Zeilen in den Python- und Shell-Fixtures
   bleiben Kommentare — der Markdown-Renderer läuft nicht mit.
2. **Scroll-Sync**: proportional, wie versprochen. Cursor auf Zeile 35 von 70
   ergab Scroll-Ratio 0.486, Zeile 70 ergab 0.985; auf dem Code-Pfad kein
   `.mdview-cursor-bar` und null `[data-sourcepos]`-Knoten, auf `control.md`
   dagegen ein sichtbarer Balken und 20 Knoten.
3. **Breadcrumbs**: `.py` und `.sh` liefern ausschließlich `(top)`, auch nach
   einem Lauf über jede überschriftförmige Kommentarzeile — und `control.md`
   sammelt in derselben Sitzung seine vier echten Überschriften ein. Das Gate
   ist damit ein Gate und kein toter Zweig. Der Export schreibt dasselbe.
4. **Ausschlüsse**: `:terminal`, `:help`, `:copen` und mdviews eigener
   Log-Buffer liefern alle `previewable.is() == false`, die Vorschau blieb
   durchgehend auf `sample.lua`, und der Log-Ring stand danach bei 7 Zeilen —
   die befürchtete Rückkopplung über den Log-Buffer gibt es nicht.
5. **Flag aus**: `control.md` behält Sourcepos und Cursor-Balken; in
   `sample.lua` ist `previewable.is()` falsch, und eine ungespeicherte
   Probe-Änderung samt Cursor-Bewegung erreicht den Browser nie. Die eine
   Erwartung, die dort „aus dem Code hergeleitet, nicht gemessen" markiert war,
   stimmt also wie aufgeschrieben.

*Was offen bleibt und nicht delegierbar ist*: ob die proportionale
Scroll-Verzögerung sich **gut anfühlt**. Gemessen ist sie, beurteilt nicht —
das braucht jemanden, der scrollt. Steht so in `CHECK.md`.

*Nebenbefund, eigener Commit*: `ft_pattern`s erster Eintrag war `.markdown`
statt `*.markdown`. Ein Autocmd-Pattern ohne `/` wird gegen den Dateinamen
gematcht, dieser eine traf also nur eine Datei, die **`.markdown` heißt** — und
weil die anderen beiden `*.md` und `*.mdx` sind, deckte kein Default
`notes.markdown` ab. Der Fehler war still: `:MDView start` schiebt den aktuellen
Buffer unabhängig vom Filetype, die Vorschau kam also korrekt hoch und
aktualisierte sich danach nie wieder. Vorher und nachher mit identischem
Ablauf reproduziert. Gefunden hat ihn Fall 5, der genau danach fragt, was
`ft_pattern` bei ausgeschaltetem Flag enthält.

*Zweiter Nebenbefund, nicht behoben — siehe `PLUGIN_ROADMAPS.md`, QW10*: auf
Windows lässt sich ein lokal gebauter Relay gar nicht starten. `npm run
build:go` schreibt `mdview-server` ohne `.exe`, `vim.fn.executable()` sagt dazu
`1`, `uv.spawn()` scheitert mit `ENOENT` — `:MDView start` meldet nur „failed
to start server process". Für diesen Testlauf mit einer Kopie als `.exe`
umgangen.

*Verifiziert*: 62 Lua/nvim-Specs grün (7 neu in `TESTS/nvim/config_spec.lua`,
darunter der Alias und ein Regressionstest gegen jedes nackte
Extension-Pattern), 95 vitest grün, `tsc --noEmit` und `stylua` sauber, dazu
der komplette Fünf-Fall-Durchlauf oben — und ein zweiter Durchlauf mit dem
alten `experimental.any_file`, der belegt, dass der Alias in echtem Neovim
trägt.

*Bindings-Zettel*: `docs/NOTES/PersonelPlugins/BINDINGS/Autocmds/mdview.nvim.md`
nennt in jeder Zeile `defaults.ft_pattern` symbolisch, driftete durch den Fix
also nicht — hat aber nirgends gesagt, was dahinter steht. Steht jetzt dort,
samt der Rolle von `any_file` und dem Glob-Fehler.

---

### QW10 · `mdview.nvim` — auf Windows startet kein lokal gebauter Relay

**Erledigt am 2026-08-30. `mdview.nvim` `7a92aeb`, auf `main` gepusht.**

Ursprünglich: aus dem QW1-Durchlauf mitgenommen, dort umgangen statt behoben.
`npm run build:go` war `go build -o mdview-server .`, Go nimmt den Namen
wörtlich, auf Windows entstand eine Datei ohne `.exe`.

*Warum das überhaupt scheitert* — der Teil, der beim Aufschreiben noch fehlte:
libuv löst ein Kommando **ohne** Endung auf, indem es jeden `PATHEXT`-Eintrag
anhängt, und probiert den nackten Namen nie. `vim.fn.executable()` sagt zu der
Datei trotzdem `1`. Die beiden Fragen sind also verschieden, und der Code hat
sie als dieselbe behandelt — deshalb `ENOENT` auf eine Datei, die genau dort
liegt, wo hingezeigt wurde.

*Getroffen hat es mehr als gedacht*: nicht nur die Zero-Config-Erkennung eines
lokalen Builds, sondern auch jedes `dev.binary_path`, jedes
`$MDVIEW_DEV_BINARY` und jedes `standalone.binary_path`, das auf den Namen
zeigte, den `build:go` selbst geschrieben hatte. Wer den Relay unter Windows
aus dem Quelltext baute, konnte ihn mit dem Plugin nicht starten — auf keinem
der vier Wege.

*Gebaut wurde*:

- `scripts/build-go.mjs` fragt `go env GOEXE` und baut unter diesem Namen.
  Ein Skript, weil npm auf Windows über `cmd.exe` startet, wo `$(...)` nichts
  bedeutet. Es löscht außerdem einen übrig gebliebenen endungslosen Build —
  genau die Datei, über die der Resolver stolperte.
- `server_args.spawnable()` ersetzt die nackten `executable()`-Prüfungen: auf
  Windows löst ein endungsloser Pfad auf das `.exe` daneben auf, sonst auf
  nichts. Benutzt von der Local-Build-Suche, von `dev.binary_path` und von
  `standalone.binary_path` — ein Override, der gegen den alten Namen
  geschrieben wurde, funktioniert also weiter. Das war die Entscheidung, die
  im Auftrag nicht stand: eine Fehlermeldung hätte auch gereicht, aber der
  alte Name steht in der eigenen Doku und in fremden Configs.
- Ein Checkout, der vor dem Fix gebaut wurde, hält die alte Datei noch. Die
  Local-Build-Suche nennt sie jetzt beim Namen und verweist auf
  `npm run build:go`, statt in den `ENOENT` zu laufen.

*Verifiziert auf Windows, beide Richtungen*: `npm run build:go`, dann
`:MDView start` in echtem headless Neovim **ohne jede Env-Variable und ohne
Dev-Override** — genau der Pfad, der vorher scheiterte, jetzt grün. Danach nur
die endungslose Datei hingelegt: die Warnung nennt den Neubau, die
Local-Build-Suche liefert `nil` und faellt damit sauber auf den Release
zurueck, statt zu scheitern; der Neubau raeumt die Datei weg. Dazu 67
Lua-Specs (5 neu in `TESTS/nvim/server_args_spec.lua`), 95 vitest,
`go test ./...`, `tsc --noEmit`, `stylua` und `eslint` gruen.

*Was an der Doku falsch war*: `development.md`, `installation.md`, die
DEFAULTS-Kommentare und `minimal_init.lua` führten die fehlende Endung als
Eigenschaft der Welt („no `.exe` suffix, also on Windows — the `-o` name is
literal"), nicht als Fehler. `docs/server/Testanweisugen.md` trug die
Handarbeit-Umgehung `go build -o mdview-server.exe .` als Anleitung. Alles
korrigiert; die Stellen sagen jetzt, was gilt und was bis 2026-08-30 galt.

---

### QW8 · `lsp.nvim` — Multi-Root-/Monorepo-Workspace-Switcher

**Erledigt am 2026-08-30. `lsp.nvim` `860cd44`, auf `main` gepusht. Zwei neue
Module, 24 neue Specs, ein Nebenbefund in der Config-Normalisierung.**

Ursprünglich: *„Formalisiert, was in `root_scope_picker` halb existiert. Kein
neues Konzept, nur ein sauberer Einstiegspunkt."* Aufwand S, Nutzen mittel.

**Die Beschreibung stimmte nicht ganz, und das ist der wichtigste Teil dieser
Notiz.** Der naheliegende Zuschnitt wäre eine vierte `root_scope`-Strategie
gewesen — `cwd`/`git`/`path` plus ein gepinntes Verzeichnis. Der hätte
ausgerechnet dort nichts getan, wo man ihn braucht: `root_scope` wird nur von
Resolvern gelesen, die als *Funktion* an `root_dir` hängen, und das sind in
diesem Repo genau zwei — `lua_ls` und `marksman`. `gopls`, `ts_ls`, `clangd`
und `csharp` deklarieren `root_markers`, die Neovim selbst auflöst; dort gibt
es keinen Haken, an dem eine Strategie greifen könnte. Ein Pin hätte also
lautlos die Server verfehlt, für die ein Monorepo-Switcher überhaupt existiert.

*Gebaut wurde stattdessen LSPs echter Multi-Root-Mechanismus*: ein laufender
Client führt eine **Liste** von Workspace-Foldern und nimmt
`workspace/didChangeWorkspaceFolders` entgegen, um sie zur Laufzeit zu ändern.
Das erreicht jeden Server, der die Notification ankündigt — `root_markers`-Server
eingeschlossen — und wirkt **ohne Neustart**.

*Konkrete Auswirkung*: `gopls` steht in `packages/api`; `<leader>lsw`, in der
Liste `packages/web` wählen — Go-to-Definition über die Paketgrenze löst auf.
Kein Client-Neustart, kein Re-Index des ganzen Repos.

*Oberfläche*: `:Lsp root` bekommt `add`, `remove` und `list` neben `pick` und
`show`; `<leader>lsw` öffnet den Add-Picker. Neue Module
`lua/lsp/core/workspace_folders.lua` (redet mit den Clients) und
`lua/lsp/core/workspace_picker.lua` (die zwei Chooser) — getrennt, damit das
erste ohne UI testbar bleibt. Neue Config-Keys `workspace.markers` und
`workspace.containers`.

*Die Kandidatensuche ist die eigentliche Arbeit.* Aufwärts von der Datei jedes
Verzeichnis mit einem Marker — das findet das eigene Paket und das Repo-Root.
Danach liest sie die Kinder des **äußersten** gefundenen Projekts und steigt
genau **eine** Ebene durch `containers` (`packages`, `apps`, `services`, …) ab.
Ohne diesen zweiten Teil taugt die Funktion für Monorepos nichts: von
`packages/api` aus liegt `packages/web` niemals *über* einem, ein reiner
Aufwärtslauf sieht es nie. Begrenzt ist er trotzdem — ein `readdir` pro
Container-Name, sonst würde ein Picker ein ganzes Repository durchstaten.

*Drei Dinge, die Neovims eigene `add`/`remove`/`list_workspace_folders` nicht
tun und die den Wrapper rechtfertigen*:

1. **Capability-Gate.** Die LSP-Spec trennt zwei Fragen, die Neovim als eine
   behandelt: `workspaceFolders.supported` heißt „der Server versteht Folder
   beim Initialize", `changeNotifications` heißt „er will zur Laufzeit davon
   hören". Nur die zweite lizenziert, was dieses Modul tut. Ein Client, der sie
   nicht ankündigt, wird übersprungen und mit Grund im Report genannt, statt
   eine Notification zu bekommen, um die er nie gebeten hat.
2. **Client-Zuordnung.** `list_workspace_folders()` wirft die Folder aller
   Clients in eine namenlose Liste. Welcher Client welchen hält, ist genau die
   Frage, mit der man ankommt, wenn ein Sprung nicht auflöst.
3. **Ehrliche Rückmeldung.** `Client:_add_workspace_folder` antwortet auf ein
   Duplikat mit einem nackten `print()`; `vim.lsp.buf.remove_workspace_folder`
   meldet *„is not currently part of the workspace"* **bedingungslos** — auch
   im Erfolgsfall, und mit fehlendem Leerzeichen. Duplikate und unbekannte
   Folder werden deshalb hier aufgelöst, bevor die Builtins erreicht werden.

*Ein Detail, das sonst Zeit gekostet hätte*: `Client:_remove_workspace_folder`
vergleicht `folder.name == dir` **wörtlich**. Übergibt man die normalisierte
Schreibweise, geht die Notification an den Server raus und der Eintrag bleibt
lokal trotzdem stehen. `M.folders()` führt deshalb `path` (normalisiert, für
Anzeige und Vergleich) und `raw` (die Schreibweise des Clients, fürs Entfernen)
nebeneinander.

*Zwei Änderungen über das Feature hinaus.* `:Lsp root` ohne Argument macht
jetzt `show` statt `pick` — ein blankes Verb, das einen modalen Picker öffnet,
war der überraschendere Default, und `show` ist inzwischen der volle Report:
Scope, plus pro Client der aufgelöste Root, seine Folder und ob er
Laufzeitänderungen annimmt. Der Scope allein sagt nie, *wo* er die Server
hingesetzt hat, und das ist die Frage, mit der man ankommt.

*Nebenbefund, im selben Commit behoben*: `servers` wurde aus der
**gemergten** Tabelle gelesen. `vim.tbl_deep_extend` verschmilzt Arrays
indexweise, also kam `servers = { "lua_ls" }` als `{ "lua_ls", "gopls",
"marksman", "html", … }` heraus — jeder Default ab Index zwei überlebte. Die
Server-Liste einzuschränken tat also fast nichts und sagte nichts darüber.
Beide neuen Listen-Optionen hätten denselben Fehler geerbt; sie und `servers`
lesen jetzt die rohe User-Tabelle. **Das ist eine Verhaltensänderung**: eine
Config, die Server nennt, bekommt ab jetzt genau diese.

*Verifiziert*: 261 Specs grün (24 neu — 16 in `workspace_folders_spec.lua`, 8
in `config_spec.lua`), Smoke-Test grün, `stylua`, `luacheck` und
`gen_bindings --check` sauber. Dazu ein Durchlauf in echtem Neovim gegen einen
angelegten Monorepo-Baum: Routen und Completion, Kandidatensuche inklusive
Geschwister-Paket und markerlosem Verzeichnis, das Capability-Skip mit Grund,
der Duplikat-Guard, der Report und `:Lsp root list` in den Scratch-Split.

*Zahlendreher in der Commit-Message*: `860cd44` sagt „27 of them new (16 …, 11
in config_spec)". Es sind 24 (16 + 8). Die Gesamtzahl 261 stimmt.

*Bindings-Zettel*: `Keymaps/lsp.nvim.md` und `Usercmds/lsp.nvim.md` tragen den
neuen Eintrag samt der Begründung, warum `<leader>lsp` und `<leader>lsw`
nebeneinander liegen, aber verschiedene Dinge bewegen — und warum `remove`
bewusst *keine* Taste bekommt.


---

### M6 + M7 · `lsp.nvim` — Profile-Presets und Per-Projekt-Override

**Erledigt am 2026-08-30. `lsp.nvim` `80b858b`, auf `main` gepusht. Zwei neue
Module, 25 neue Specs, sechs Doku-Dateien.**

Ursprünglich zwei Zeilen: M6 *„Ein Schalter statt 20 Einzeloptionen für
‚schlank auf schwacher Maschine'"* (Aufwand M, Nutzen mittel), M7 *„Server X in
Projekt Y abschalten, ohne die globale Config anzufassen"* (Aufwand M–L, Nutzen
mittel).

**Die Kopplung hat gehalten, und zwar genau an der vorhergesagten Stelle.**
`config/init.lua` hatte *eine* Merge-Ebene; jetzt sind es vier — `DEFAULTS`,
das Preset, die `setup()`-Optionen, die `.nvim-lsp.json`. Was einzeln zweimal
zu schreiben gewesen wäre, ist die Ebenen-Zuordnung: die Listen-Optionen müssen
aus der Ebene gelesen werden, die sie geliefert hat (nicht aus der gemergten
Tabelle), und jede Warnung muss sagen, aus welcher Ebene der beanstandete Wert
kam. Beides ist derselbe Mechanismus (`_layers` als Daten, `source_of()`
darüber), einmal geschrieben.

*Konkrete Auswirkung, M7*: eine `.nvim-lsp.json` mit `{"servers":["lua_ls"]}`
im Repo-Root — und in **diesem** Checkout laufen `ts_ls` und `gopls` nicht mehr,
während die globale Config unangetastet bleibt. `:Lsp status` und
`:checkhealth lsp` nennen die Datei beim Namen.

*Konkrete Auswirkung, M6*: `preset = "lean"` ersetzt rund zwanzig Felder durch
ein Wort — Virtual Text aus, `signatureHelp` aus, Workspace-Scan beim Attach
aus, Debounce 400 statt 150ms, `keymaps.preset = "minimal"`, die ~25 Legacy-
Kommandos weg.

**Vier Entscheidungen, die im Auftrag nicht standen:**

1. **Die Reihenfolge der Ebenen ist das eigentliche Argument.** Das Preset
   liegt *unter* den User-Optionen, die Projektdatei *darüber*. Anders herum
   wäre beides sinnlos: ein Preset, das explizite Optionen überstimmt, macht
   `preset = "lean", inlay_hints = { enable = true }` unlesbar; eine
   Projektdatei, die es nicht tut, ist keine Projektdatei.
2. **JSON statt Lua, und das ist die Sicherheitsgrenze selbst.** Eine
   Projektdatei schreibt, wer das Repository geschrieben hat, und Neovim liest
   sie, weil man ein Verzeichnis geöffnet hat. Lua hieße: ein `git clone`
   genügt, um fremden Code auszuführen. JSON kann keine Funktion ausdrücken —
   es gibt nichts zu exekutieren, ohne dass man sich auf eine Konvention
   verlassen müsste.
3. **Allowlist statt Filter, und die Trennlinie ist nicht „was könnte kaputt
   gehen".** Erlaubt sind `servers`, `diagnostics`, `formatter`,
   `inlay_hints`, `attach`, `workspace`, `tools`, `languages` — die acht
   Fragen, die das *Repository* beantworten kann. `keymaps`, `usrcmds`,
   `which_key`, `menu` gehören dem Benutzer; ein Checkout verschiebt keine
   Taste. `mason` installiert Software. `preset` ist eine Eigenschaft der
   Maschine, nicht des Repos. Alles andere fliegt mit einer Warnung raus.
4. **Kein Preset setzt jemals `mason.ensure_install` oder
   `formatter.on_save`.** Das eine installiert Software, das andere schreibt
   Dateien. Ein Profil ist ein Leistungsregler, keine Einwilligung — genau das
   macht `preset = "full"` gefahrlos wählbar, ohne vorher `PRESETS.lua` zu
   lesen.

**Zwei Details, die sonst Zeit gekostet hätten:**

*Zweistufige Auflösung.* `project.enable` und `project.file` kommen aus den
Ebenen 1–3, also müssen die zuerst gemergt werden. Eine Projektdatei kann
dadurch nicht entscheiden, ob Projektdateien gelesen werden — und ihren eigenen
Nachfolger nicht umbenennen. Ohne die Trennung wäre das ein Henne-Ei-Problem
mit stiller Auflösung.

*Eine defekte Liste stoppt die Suche, statt die Ebene darunter einspringen zu
lassen.* `"servers": "lua_ls"` (String statt Liste) in der Projektdatei
degradiert auf die Defaults und warnt — es greift **nicht** auf die
`setup()`-Liste darunter zurück. Sonst wäre der Tippfehler unsichtbar, und
unsichtbar ist die einzige Variante, die wirklich Zeit kostet.

*`preset = "default"` ist eine leere Tabelle*, keine Kopie der Defaults. Eine
Kopie wäre eine zweite Stelle zum Ändern und die erste Gelegenheit für beide,
sich zu widersprechen.

*JSON `null`* wird als „keine Meinung" gelesen (`luanil`), nicht als
`vim.NIL` — sonst läge ein Sentinel-Userdata dort, wo jeder Konsument einen
Wert erwartet.

*Namenskollision, bewusst in Kauf genommen*: `preset` und `keymaps.preset` sind
zwei verschiedene Dinge. Der Roadmap-Wortlaut gab `preset` vor; die Doku sagt
an drei Stellen, dass das eine Tasten wählt und das andere Optionen — und dass
eine der Optionen `keymaps.preset` ist.

*Sichtbarkeit*: `:Lsp status` bekommt zwei Zeilen (`preset`, `project
override`), `:checkhealth lsp` zwei Info-Zeilen **vor** den Warnungen — in
dieser Reihenfolge, weil „(from .nvim-lsp.json)" erst dann etwas nützt, wenn
man weiß, dass überhaupt eine Projektdatei gefunden wurde und welche.

*Neue Module*: `lua/lsp/config/PRESETS.lua` (die drei Profile),
`lua/lsp/config/project.lua` (Suche, Dekodierung, Allowlist). Neue Config-Keys
`preset` und `project.{enable,file}`.

*Verifiziert*: 286 Specs grün (25 neu in `config_layers_spec.lua`), Smoke-Test
grün (5 neue Zeilen), `stylua`, `luacheck` und `gen_bindings --check` sauber.
Dazu ein Durchlauf in echtem Neovim: `.nvim-lsp.json` in einem Temp-Verzeichnis
mit `preset = "lean"` und einer abgewiesenen `keymaps`-Sektion — die Serverliste
kam aus der Datei, `keymaps.enable` blieb `true`, die Warnung nannte Datei und
Allowlist.

*Bindings-Zettel*: nicht berührt. Der Punkt fügt weder Keymap noch Usercmd noch
Autocmd hinzu; `:Lsp status` gibt nur zwei Zeilen mehr aus.

*Nachtrag `e050778`*: die Projektdatei-Specs laden `lsp.config` jetzt **vor**
dem `chdir` ins Temp-Verzeichnis. Ein `require` aus einem fremden
Arbeitsverzeichnis heraus hängt davon ab, wie der jeweilige Test-Runner die
`runtimepath` gesetzt hat — lokal mit `PlenaryBustedFile` schlug es fehl, mit
`PlenaryBustedDirectory` (was die CI benutzt) nicht. Nur `setup()` muss aus dem
Projekt heraus laufen; das `require` gehört nicht zum Testgegenstand.

---

### M17/M7 · `documentation.nvim` — Phase-0-IR: der besitzende Scope

**Erledigt am 2026-08-30. `documentation.nvim` [`ffc24a5`](https://github.com/StefanBartl/documentation.nvim/commit/ffc24a5),
`docmap-desktop` `b303bc0`, `WKDBooks` `f15aa52`.**

Ursprünglich: „Phase-0-IR: besitzender Scope, eine Datei / viele Module" — der
einzige Punkt der Liste, der etwas anderes aufhielt, weil
`Documentation.FunctionInfo` keinen besitzenden Scope kannte und Python-Klassen
und Rust-`impl`-Blöcke damit keinen Ort hatten.

**Was gebaut wurde**: zwei Felder auf `Documentation.FunctionInfo` — `owner`
(die Klasse, der `impl`-Block, das Trait, der Receiver-Typ oder das Inline-Modul)
und `owner_kind` daneben, gesetzt vom jeweiligen Backend genau dort, wo der
Parse-Baum noch existiert. Schema 6. Vierzehn der zwanzig Backend-Dateien
setzen sie.

*Konkrete Auswirkung, und sie ist genau die versprochene*: eine Python-Datei mit
zwei Klassen liest sich im Detail-Panel jetzt als `Functions (6, 2 scopes)` —
drei Methoden unter `class Widget`, zwei unter `class Gadget`, die freie
Funktion darüber. Eine Rust-Datei trennt `impl Widget`, `trait Doer` und
`module inner`. Vorher waren das zwölf gleichrangige Zeilen neben einem
Klassennamen, der nichts besaß. `:DocMap` gibt zusätzlich eine Zeile aus („3
scopes owning 12 of 15 functions") — und für einen Lua- oder C-Baum
**gar keine**, weil eine dauerhafte „0 scopes"-Zeile wie ein Defekt aussieht
statt wie eine Spracheigenschaft.

**Die Entscheidung, die im Auftrag nicht stand: ein Feld statt eines besseren
Strings.** Jedes Backend kannte den Besitzer längst und gab ihn im Namen aus
(`Class.method`, `Widget::new`, `Doer::go`). Der Name ist richtig und war nie
die ganze Auskunft — er lässt sich nicht rückwärts lesen:

- `Class.helper` auf Modulebene und `helper` innerhalb von `class Class`
  ergeben denselben `name`.
- Luas eigenes `function M.foo()` ist gepunktet, weil `M` die Modultabelle ist
  — ein Präfix-Match würde in *jeder* Lua-Datei einen Scope namens `M`
  erfinden.
- Ruby schreibt `Class#method` und `Class.method`, PHP und Rust `::`. Eine
  Frage, vier Trennzeichen.

`TESTS/scopes_spec.lua` prüft genau diese drei Fälle — sie sind der einzige
Grund, warum die IR ein Feld bekommen hat und nicht eine Namenskonvention.

**Was das Bauen gelehrt hat und in keiner Beschreibung stand: die *Art* des
Scopes wiegt schwerer als sein Name.** Rust hat es erzwungen — `Widget::new`,
`Doer::go` und `inner::helper` sind identisch geschrieben und sind eine
inhärente Methode, eine Trait-Methode und die Funktion eines Inline-Moduls. Ein
normalisiertes „type" hätte alle drei zu „class" verflacht und damit das eine
weggeworfen, wonach man in dieser Datei sucht. `Documentation.ScopeKind` behält
deshalb das Konstrukt so, wie die Sprache es nennt — inklusive `receiver` für
Go, das gar keinen umschließenden Block hat.

**Abgeleitet, nie serialisiert.** `Documentation.ScopeInfo` ist Gruppierung,
keine Daten: `core/scopes.lua` für die Lua-Seite, dieselbe Gruppierung in
JavaScript auf der Seite. Bewusst die umgekehrte Entscheidung zu
`ir.duplicates` — dessen eigene Begründung (die Seite hat keinen Parse-Baum,
um `fn.shape` nachzurechnen) trägt hier nicht: `fn.owner` liegt ihr vor.

*Verifiziert an echten Parses der beiden Sprachen, um die es ging.* Python- und
Rust-Grammatiken waren vorhanden, also prüfen `lang_python_spec.lua` und
`lang_rust_spec.lua` Besitzer und Art an echten Bäumen; dazu wurde ein
polyglottes Wegwerf-Repo generiert und **durch die tatsächliche Seite**
zurückgelesen, nicht nur über Unit-Assertions. Alle fünf CI-Gates grün
(`stylua`, `luacheck`, Tests, `map --check`; `standalone` lokal übersprungen).

*Drei Backends könnten einen Besitzer setzen und tun es nicht* — Haskells
`class`/`instance`, OCamls `module X = struct … end`, Zigs
`const S = struct { … }`. Jedes bräuchte Walk-Verkabelung, die es nicht gibt,
und keines ließ sich auf dieser Maschine an einem echten Parse prüfen. In
`docs/LANGUAGES.md` ausdrücklich als **Lücken** geführt, nicht als
Spracheigenschaften — sonst liest sich ein Defizit wie eine Tatsache.

**Was offen bleibt, und der Punkt wurde nicht stillschweigend eingedampft**:
die zweite Hälfte des ursprünglichen Titels, „eine Datei / viele Module". Ein
Scope ist **kein** Knoten — keine Summary, keine Coverage, keine Kanten, keine
id. Ein Rust-`mod x { … }` wird weiterhin als Teil seiner Datei gelesen; Elixir
ist der zweite Fall und kommt von der anderen Seite (eine `.ex`-Datei hält
regelmäßig mehrere `defmodule`). Das ist eine falsche *Identität*, keine
fehlenden Daten — der Grund, warum es bis heute nicht weh getan hat. Es läuft
ab sofort als eigener Punkt **M17/M7b** in `docmap-desktop/docs/PLAN.md`, samt
der Bedingung, unter der es aufhört, kosmetisch zu sein.

*Bindings-Zettel*: nicht berührt. Der Punkt fügt weder Keymap noch Usercmd noch
Autocmd hinzu; `:DocMap` gibt eine Zeile mehr aus, wenn der Baum überhaupt
Scopes hat.


---

### QW5 · `lsp.nvim` — Hover-Cache über `lib.lua.memo`

**Erledigt am 2026-08-30. `lua/lsp/tools/lsp_signature/show_hover.lua`,
6 neue Specs in `TESTS/lsp/hover_cache_spec.lua`.**

Ursprünglich: wiederholter Hover auf derselben Position bei gleicher
Buffer-Version spart einen Roundtrip, Schlüssel `(bufnr, changedtick, row,
col)`.

*Gebaut*: genau das, mit einer LRU (Kapazität 32) aus `lib.lua.memo`.
Gecacht werden die **anzeigefertigen Zeilen**, also hinter dem Request *und*
hinter `format_hover` — die Formatierung ist deterministisch aus demselben
Ergebnis, und sie zweimal zu rechnen, um dann dasselbe anzuzeigen, wäre die
halbe Ersparnis weggeworfen.

**Der Schlüssel hat ein fünftes Feld bekommen, und das ist die Entscheidung,
die im Auftrag nicht stand: die Client-IDs.** Die ersten vier Felder sagen,
was die Antwort *ist*; die IDs sagen, wann sie *falsch* wird. Ein
`:Lsp restart` lässt den Buffer unberührt — `changedtick` stimmt danach
weiterhin, der Cache würde also die Antwort des toten Servers weiterreichen.
Ein neu gestarteter Client trägt eine neue ID, damit wandert der Schlüssel von
selbst und der alte Eintrag wird schlicht nie wieder gefragt. Das ist billiger
als ein Invalidierungs-Autocmd und kann nicht gegenüber einem aus dem Tritt
geraten.

Zweite Entscheidung: ein Request **ohne** Position wird gar nicht gecacht,
statt auf einen geratenen Schlüssel gelegt zu werden. Zwei verschiedene Fragen
auf eine Antwort zu falten wäre ein Hover-Popup, das die falsche Stelle
erklärt — schlimmer als der Roundtrip, den es spart.

*Konkrete Auswirkung*: `<C-b>` ist ein Toggle, „nochmal draufschauen" heißt
also zu, auf, warten. Beim zweiten Mal auf unverändertem Buffer erscheint das
Popup jetzt sofort und ohne Anfrage an den Server. Bei `lua_ls`/`gopls` sind
das die im Report genannten 10–50 ms, bei `jdtls`/`omnisharp` spürbar mehr —
und genau deshalb stand der Punkt in der Empfehlung an letzter Stelle. Er ist
gebaut worden, weil er erledigt sein sollte, nicht weil er dringend war.

*Die Specs prüfen überwiegend die Fehlschläge*, nicht den Treffer: Edit,
andere Position, ersetzter Client und geleerter Cache müssen jeweils wieder an
die Leitung gehen. Ein Cache, der zu oft trifft, ist der Fehlermodus, der
Schaden anrichtet; einer, der zu selten trifft, kostet nur, was vorher auch
gekostet hat.

*Verifiziert*: 298 Specs grün (6 davon neu), Smoke-Test grün, `stylua` sauber.

*Bindings-Zettel*: nicht berührt — der Punkt ändert weder Keymap noch Usercmd
noch Autocmd. `<C-b>` bleibt, was es war, nur schneller beim zweiten Mal.

---

### M1 · `lsp.nvim` — Fehler provozieren als Testhilfe (`:LspDoctor probe`)

**Erledigt am 2026-08-30. Neu: `lua/lsp/lspdoctor/probe.lua`, 7 neue Specs,
neue Option `lspdoctor.probe_timeout`.**

Ursprünglich unter dem Namen `:LspDoctor deep` geführt. **Den gibt es so nicht
mehr**: die Report-Namen wurden am 2026-08-29 umbenannt, `deep` heißt heute
`capabilities` und beantwortet eine ganz andere Frage (was können die Server
hier). Der Punkt ist deshalb ein **sechster Report** geworden und kein Modus
eines bestehenden. Er heißt `probe`, weil er als einziger etwas *tut*, statt
Zustand zu lesen — die anderen fünf tragen den Namen ihrer Frage, dieser den
seiner Methode, und der Unterschied ist genau das, was man vorher wissen will.

*Gebaut*: `:LspDoctor probe` legt einen Buffer mit Inhalt an, den der Server
dieses Filetypes nicht akzeptieren kann (`local x =`, `const x =`, ein offenes
`func main()`), benennt ihn nach einer Datei, die es **nicht gibt**, im
Verzeichnis des aktuellen Buffers, hängt die dort ohnehin schon attachten
Clients an und wartet `probe_timeout` (Default 5000 ms) auf Diagnostics — pro
Client, mit Dauer und erster Meldung.

**Nie wird etwas auf die Platte geschrieben.** Das Dokument existiert nur als
der Inhalt, den der Client über die Leitung geschickt hat; der Buffer wird
gelöscht, bevor der Report gerendert wird, damit die Diagnostics des Probes
nicht in globalen Listen liegen bleiben. Der Pfad zeigt trotzdem ins
Projektverzeichnis, weil `root_dir` sonst anders auflöst als bei echter Arbeit
— und „gopls hat eine Datei ignoriert, die nicht in deinem Modul liegt" wäre
die Antwort auf eine Frage, die niemand gestellt hat.

**Drei Entscheidungen, die im Auftrag nicht standen.**

*Erstens: keine Server werden gestartet.* Gefragt sind die Clients, die hier
schon hängen. Einen zu starten würde eine andere Frage beantworten, und zwar
langsam.

*Zweitens: `probe` ist nicht Teil von `all`.* Die anderen fünf lesen Zustand
und sind sofort da; dieser legt einen Buffer an, redet mit Servern und
blockiert bis zu fünf Sekunden. Ihn in den Default zu falten hieße, den
Report, den man zuerst aufruft, langsam und nebenwirkungsbehaftet zu machen
für eine Frage, die man gar nicht gestellt hat.

*Drittens: pro Filetype ein Snippet statt eines Generators.* Zwanzig Stück
(`c`, `cpp`, `cs`, `css`, `go`, `java`, `javascript`, `javascriptreact`,
`json`, `jsonc`, `lua`, `python`, `rust`, `sh`, `bash`, `toml`, `typescript`,
`typescriptreact`, `yaml`, `zig`), jedes ein *Syntax*-Fehler und kein Typ-
oder Lint-Fehler: Syntax ist, was ein Server prüft, bevor er irgendetwas
auflöst, also bleibt der Probe auch in einem Verzeichnis ehrlich, das der
Server noch nicht durchindiziert hat. Bei jedem anderen Filetype sagt der
Report das und nennt die abgedeckten — geraten würde riskieren, eine tote
Kette zu melden, wo die Datei nur akzeptabel war.

**Was der Report nicht kann, steht im Report.** Ein Server, der synthetische
Dateien außerhalb seines Projekts ablehnt (gopls ohne Modul, tsserver ohne
tsconfig), sieht von hier aus genauso aus wie ein kaputter. Beide Fälle werden
als Hinweis ausgegeben, statt den einen als den anderen zu verkaufen — ein
Diagnosewerkzeug, das den falschen Schuldigen nennt, ist das eine, was ein
Diagnosewerkzeug nicht tun darf.

*Konkrete Auswirkung, und sie ist die versprochene*: `:LspDoctor probe` auf
einer Lua-Datei sagt jetzt

```
Summary: 1/1 client(s) delivered diagnostics within 5000ms
**lua_ls**
  Diagnostics: ✅ 1 after 21ms
  First: `<exp> expected.` (ERROR)
```

und bei einer toten Kette `❌ none within 5000ms` samt zwei Hinweisen, wo man
nachsieht. Vorher waren „diese Datei ist sauber" und „hier kommt nichts mehr
an" auf dem Bildschirm nicht zu unterscheiden, und jeder zustandslesende Check
sagte über beide dasselbe.

*Verifiziert an einem echten `lua_ls`*, zweimal in derselben Sitzung: eine
Diagnostic in ~20 ms, keine Datei auf der Platte, kein Buffer übrig, und
nichts vom Probe mehr in `vim.diagnostic.get()`. Dazu 299 Specs grün (7 davon
neu), Smoke-Test grün, `stylua` sauber, und die Completion von `:LspDoctor`
bietet `probe` an (`startup, resolve, buffer, capabilities, probe, all`),
während `:LspDoctor deep` weiterhin auf `capabilities` zeigt.

*Nebenbefund, nicht mitgemacht*: `lua/lsp/lspdoctor/doc/help.txt` und
`doc/lspdoctor.txt` beschreiben beide noch das Modul von **vor** der Migration
(`:LspDoctor export`, `run()`, `quick`/`deep`) und beanspruchen beide denselben
Helptag `*lspdoctor.txt*` — dabei liegen sie unter `lua/`, wo Neovim
Hilfedateien gar nicht indiziert. Das ist zwei tote Dateien, kein veralteter
Absatz; sie im Vorbeigehen um eine Report-Zeile zu ergänzen hätte den Rest
falsch gelassen. Als eigener Aufräumpunkt vermerkt, nicht hier miterledigt.

*Bindings-Zettel*: `docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/lsp.nvim.md`
nachgezogen — sechs statt fünf Reports, ein eigener Abschnitt zu `probe`
inklusive der Grenze, die er nicht sehen kann, und ein Changelog-Eintrag mit
der Notiz, dass die Roadmap ihn unter dem alten Namen `deep` führte.


---

### M16 · `lib.nvim` — `deps.health`-Migrationen

**Erledigt am 2026-08-30. `lib.nvim` (neu: `lua/lib/nvim/deps/detect.lua`),
`pdfport.nvim` (`docs/install.json`, `lua/pdfport/health.lua`, neuer Spec-Test).
Zwei Repos, beide gepusht.**

Ursprünglich: „`images.nvim` und `language.nvim` rufen bereits
`deps.health.report_for`. Offen ist allein `pdfport.nvim`, das `check_exe` noch
selbst rollt — acht Aufrufstellen."

**Die Prämisse trug nicht, und das ist der eigentliche Ertrag dieses Punktes.**
Im Quelltext nachgesehen, bevor gebaut wurde:

- `pdfport.nvim` ruft `deps.health.report_for` **längst**
  (`lua/pdfport/health.lua:373`) — genau wie die beiden „erledigten" Repos.
- Sein `check_exe` rollt **keine eigene Erkennung**: `platform.has` delegiert an
  `lib.nvim.core.has_exec`, `platform.first_available` an
  `lib.nvim.core.first_available`. Lokal ist nur der *Wortlaut* der drei
  Health-Zeilen.
- `language.nvim` — eines der zwei als erledigt geführten Repos — hat sein
  eigenes `vim.fn.executable(bin) == 1` in `health.lua:15`. Nach dem Kriterium
  des Punktes wäre es genauso offen wie pdfport.
- Und die Doppelmeldung ist **Absicht**: der Kommentar in `images.nvim` sagt es
  selbst — *„the same tools `check_imagemagick()`/`check_clipboard()` already
  cover, but with the declared `why`"*. Die Deps-Sektion ist ein Inventar
  **neben** den Fähigkeitsprüfungen, kein Ersatz für sie. Die handgerollte
  Hälfte wegzuräumen hätte genau die Zeilen gekostet, für die
  `:checkhealth pdfport` da ist („pandoc gefunden, aber keine PDF-Engine",
  „ollama-Daemon läuft nicht", „tesseract braucht auch pdftoppm").

Migriert war also alles. Was **wirklich** offen war, waren drei Stellen, an
denen ein einziger `:checkhealth`-Lauf sich selbst widersprach — und das ist
das eine, was ein Diagnosewerkzeug nicht tun darf.

**1. `curl` war „required" und „optional" zugleich.** `check_exe("curl", true)`
meldete einen **Fehler**, `docs/install.json` deklarierte `required: false`.
Die Spec hatte recht: curl brauchen nur der claude-Backend und der
ollama-Daemon-Check, beide optional, und `backends/claude.lua` gibt in
`available()` ohnehin `false` zurück, wenn curl fehlt.

**2. Ghostscript heißt auf Windows anders.** Der Producer prüfte
`gs`/`gswin64c`/`gswin32c` und meldete „ghostscript producer: ready (exe:
gswin64c)"; die Deklarations-Sektion kannte nur `gs` und meldete es als
fehlend — auf demselben Rechner, im selben Lauf. Das war **nicht** in
`pdfport` zu reparieren: `Lib.Deps.Tool` hatte genau ein `bin`.

*Dafür hat `lib.nvim` ein Feld bekommen: `bin_alternatives`.* Andere
Schreibweisen **desselben** Programms, nur für die Erkennung; `bin` bleibt
kanonisch für Identität, Anzeigename, Install-Ziel und `pkg`-Schlüssel. Die
Meldung nennt die Schreibweise, die geantwortet hat — `gs found (as gswin64c)`,
weil „gs found" auf einem Rechner ohne `gs` wahr und irreführend in derselben
Zeile ist.

**Drei Entscheidungen dazu, die im Auftrag nicht standen.**

*Erstens: Erkennung wandert in ein eigenes Modul* (`deps.detect`) statt dreimal
inline zu stehen. Alle drei Stellen, die „ist es da" fragen, gehen darüber:
die Health-Zeile, `install.plan` (sonst würde ein unter seinem Windows-Namen
vorhandenes Tool zur Installation eingeplant) und die
„schon-installiert"-Absage in `view`. `forget` löscht den gemerkten
PATH-Befund für **jeden** Namen — nach einer Installation ist es womöglich die
Alternative, die aufgetaucht ist.

*Zweitens: ein blanker String wird abgewiesen, nicht angenommen.*
`bin_alternatives = "gswin64c"` ist die naheliegende Art, das Feld falsch zu
schreiben, und die einzige, die sonst still durchginge: ein String iteriert als
leere Liste, die Alternative würde nie geprüft, und das Tool meldete weiter
„fehlt" — auf genau der Plattform, für die das Feld eingeführt wurde.

*Drittens: es ist keine Liste von Ersatzprogrammen.* Ein anderes Programm, das
die Aufgabe auch erledigt, ist ein eigenes Tool mit eigenem `why` und eigenem
`pkg`. `qpdf` und `pdftk` mergen beide PDFs und bleiben zwei Einträge. Der Test
ist, ob **eine** `pkg`-Zuordnung für alle ehrlich wäre.

**3. Zwei geprüfte Tools fehlten im Inventar, ohne dass irgendwo stand warum.**
Hier ist das Ergebnis ein anderes als die Ankündigung, und zwar in beide
Richtungen:

- `ueberzugpp` ist jetzt deklariert — mit `pacman` und **sonst nichts**. Es
  liegt in Arch' `extra`-Repo; auf Debian, Ubuntu, Fedora und openSUSE
  existiert es nur in einem Fremd-Repository, das man erst hinzufügen muss.
  Ein `apt`- oder `brew`-Schlüssel hätte ein Install-Kommando gebaut, das
  fehlschlägt. Ein fehlender Schlüssel heißt „kein bekanntes Paket für diesen
  Manager", und genau das ist hier wahr.
- `marker_single` bleibt **nicht** deklariert, sagt aber jetzt warum:
  `marker-pdf` kommt aus `pip`, kein OS-Paketmanager führt es, und ein Eintrag
  bräuchte eine `pkg`-Map, die er nicht ehrlich füllen kann. Dieselbe Grenze,
  die schon um `pdfplumber` und `docling` lag — geprüft, nirgends deklariert,
  bis jetzt ohne Begründung.

**Neu: ein Test für die Spec-Datei selbst** (`TESTS/install_spec_spec.lua`).
`docs/install.json` ist Daten, die sonst niemand liest: kein Modul requiret
sie, `luacheck` sieht sie nicht, und ein abgewiesener Eintrag wird still aus
`tools` fallen gelassen. Ein Tippfehler zeigt sich also nur als ein Tool, das
leise aus dem Report verschwindet — und das sieht genauso aus wie ein Tool, das
nie jemand deklariert hat. Der Test parst die echte Datei mit dem echten Parser
und besteht auf **null** Fehlern.

*Verifiziert an einem echten `:checkhealth pdfport`*, inklusive eines
simulierten Rechners ohne `gs` und ohne `curl` (die eine PATH-Abfrage, durch
die alles läuft, lügt über genau zwei Namen — sonst ist nichts gestubbt):
`⚠️ curl NOT found (optional)` in **beiden** Sektionen statt Fehler hier und
Warnung dort, und `gs found (as gswin64c)` neben „ghostscript producer: ready
(exe: gswin64c)". Dazu: lib.nvim-Suite grün (neue Fälle für `detect`, den
Parser in beiden Formaten und die Install-Planung), `luacheck` 0/0 über 341
Dateien; pdfport-Suite grün mit dem neuen Spec-Test, `luacheck` 0/0 über 60
Dateien, `stylua` in beiden Repos sauber.

*Bindings-Zettel*: nicht berührt. Der Punkt fügt weder Keymap noch Usercmd noch
Autocmd hinzu; `:checkhealth pdfport` und `:Lib deps show pdfport.nvim` sagen
dasselbe wie vorher, nur ohne sich zu widersprechen.


---

### M2 · `lsp.nvim` — Code-Action-Indikator

**Erledigt am 2026-08-30. `lua/lsp/core/lightbulb.lua`, 29 neue Specs.**

Ursprünglich: „Sign oder Virtual Text, wenn `textDocument/codeAction` etwas
zurückgibt. Sichtbarkeit statt blindem `lsa`." Die Beschreibung stimmte —
zum ersten Mal seit drei Punkten hat das Nachsehen im Quelltext nichts
widerlegt. `code_action` kam in `lua/lsp/` nur dreimal vor: als Keymap `lsa`,
als marksman-Handler-Wrapper und im TypeScript-Organize-Imports-Pfad. Nichts
davon war ein Indikator.

**Die Entscheidung, die im Auftrag nicht stand, ist die Kind-Allowlist — und
sie ist nicht eine Verfeinerung des Punktes, sie ist der Punkt.** Ungefiltert
leuchtet eine Code-Action-Lampe unter genau den Servern, die dieses Plugin
konfiguriert, permanent: `ts_ls` bietet „Move to a new file" auf fast jeder
Top-Level-Zeile an, `gopls` ist mit Refactorings ähnlich freigiebig. Eine
Lampe, die immer leuchtet, trägt keine Information — das ist der Grund, aus
dem die naive Umsetzung dieses Features in der Praxis wieder abgeschaltet
wird. `lightbulb.kinds` ist deshalb eine Allowlist von CodeActionKind-Präfixen
und steht per Default auf `quickfix` und `source`: die Markierung heißt
**„hier ist etwas kaputt und behebbar"**, nicht „hier wäre ein Refactoring
denkbar". Erst damit ist `enable = true` als Default vertretbar.

Zwei Regeln, die daran hängen und beide falsch sein könnten, ohne dass es
auffiele:

- **Ein Präfix matcht exakt oder als gepunktetes Kind.** `source` deckt
  `source.organizeImports` ab, `quickfix` deckt `quickfixed` nicht ab. Reines
  String-Prefixing hätte das zweite durchgelassen.
- **Eine Action *ohne* `kind` zählt immer.** `kind` ist im Protokoll optional
  und ein blankes `Command` hat nie eines. Hätte man die weggeworfen, wäre
  jede Action jedes Servers unsichtbar geworden, der nicht klassifiziert — und
  zwar als Lampe, die nie leuchtet, also ununterscheidbar von einer, die
  funktioniert.

**Was der Punkt nicht erwähnte und die eigentliche Designfrage war: es gibt
keinen freien Platz.** Die Signspalte trägt bereits die Diagnostic-Signs, und
`virtual_text` steht am Zeilenende — beide naheliegenden Orte sind besetzt.
`render = "sign"` leiht sich deshalb die Signspalte **nur auf der
Cursorzeile** und mit einer Priorität *über* den Diagnostic-Signs (20 gegen
`vim.diagnostic`s 10): auf der einen Zeile, die man gerade ansieht, ist die
handlungsrelevante Markierung die wichtigere. `render = "virtual_text"`
zeichnet stattdessen `right_align` am Fensterrand, wo die Diagnostic-Meldung
am `eol` nicht kollidieren kann.

*Kosten*: ein `textDocument/codeAction` pro Cursorposition, debounced
(`debounce_ms`, Default 150), nur an Clients mit `codeActionProvider`, mit
`triggerKind = 2` (Automatic) — Server, die das unterscheiden (gopls,
rust-analyzer), beantworten eine automatische Anfrage billiger als die hinter
einem Tastendruck. Im Insert-Modus wird gar nicht gefragt, und eine
überholte Anfrage wird storniert statt nur ignoriert. `preset = "lean"`
schaltet das Ganze ab, `preset = "full"` schaltet die Allowlist ab.

*Oberfläche*: `lightbulb = { enable, filetypes, kinds, render, text,
debounce_ms, priority }` in den DEFAULTS und in der Projekt-Allowlist,
`:Lsp lightbulb [toggle|on|off|status|clear] [filetype]`, `<leader>tl`
(global) und `<leader>tL` (dieses Filetype) im Katalog — damit auch im
generierten `docs/BINDINGS.md`. Die Filetype-Ebene ist dieselbe Map-statt-Liste
wie bei QW3, weil es derselbe Schaltertyp ist.

**Drei Nebenbefunde, alle beim Bauen aufgefallen:**

1. **Ein von `setup()` eingeplanter Refresh konnte sein eigenes `detach()`
   überleben.** `vim.schedule` lässt sich nicht zurücknehmen; lief der
   Callback nach einem `detach()` oder einem zweiten `setup()`, zeichnete er
   eine Markierung, die danach kein Refresh mehr kannte und also niemand mehr
   wegnahm. Gefunden hat ihn die Spec-Suite, nicht die Theorie: drei
   Modulinstanzen aus früheren Testfällen zeichneten gleichzeitig.
2. **Eine synchrone Antwort löschte die gerade gesetzte Markierung wieder.**
   Der Zweig „alle Requests wurden abgelehnt" feuerte auch dann, wenn der
   Handler synchron schon gelaufen war. Mit einem echten Server fällt das nie
   auf — mit einem gecachten Ergebnis oder einem Stub sofort.
3. **Der Autocmds-Zettel rechnete nicht auf.** Er stand auf „26 Autocmds über
   21 Augroups", während seine eigene Aufschlüsselung daneben 22 ergab.
   Nachgezählt: 29 über 23. Dass er Aufrufstellen zählt und nicht
   Event-Registrierungen — der Lightbulb-Aufruf horcht auf vier Events —
   steht jetzt dabei.

*Aufgeräumt*: die Filetype-Map-Normalisierung liegt jetzt einmal statt zweimal
in `config/init.lua` (`normalize_filetype_map`, geteilt mit `inlay_hints`) —
die beiden lösen ihre Overrides nach derselben Regel auf, also müssen sie
dieselben Fehler zurückweisen. Und die `LSP_FILETYPE`-Completion liest jetzt
die Overrides *beider* Features: ein Override für ein Filetype, das gerade in
keinem Buffer offen ist, war sonst nicht completebar, und genau den wieder
loszuwerden ist `clear`s Aufgabe.

*Verifiziert an einem echten `lua_ls`* auf einer Datei mit zwei Diagnostics
(unused local, undefined global): Zeile 4 und 5 tragen den Indikator, Zeile 1
(`local M = {}`) und Zeile 9 (`return M`) nicht — also genau der Zuschnitt, den
die Allowlist verspricht. Dazu: lsp.nvim-Suite grün über 19 Spec-Dateien
(darunter 29 neue, davon fünf für den Zeichenpfad mit gestubbtem Client),
Smoke-Test grün, `luacheck` 0/0 über 197 Dateien, `stylua` sauber,
`gen_bindings.lua --check` sagt „current".

*Bindings-Zettel*: alle drei berührt. `Keymaps/lsp.nvim.md` (neuer Abschnitt,
plus Korrektur der Preset-Zeile, die noch auf 44/28 stand und seit QW3 falsch
war — jetzt 47/31), `Usercmds/lsp.nvim.md` (neuer Abschnitt) und
`Autocmds/lsp.nvim.md` (neue Augroup `lsp_nvim_lightbulb` plus die Kopfzahl
oben).


---

### M3 · `lsp.nvim` — Auto-Restart mit Backoff bei Client-Crash

**Erledigt am 2026-08-30. `lua/lsp/core/supervisor.lua`, 22 neue Specs.**

Ursprünglich: „`core/attach.lua` hat heute keine Crash-Behandlung." Stimmte —
79 Zeilen, keine Zeile davon über Exits. Der Punkt hat auch die richtige
Reihenfolge vorgegeben: `usercmds/recovery.lua` führte bereits einen
Versuchszähler, und darauf aufzusetzen statt danebenzubauen war die
Vorbedingung, damit nicht zwei Stellen unabhängig mitzählen und sich im Report
widersprechen.

**Die eigentliche Schwierigkeit ist Absturz gegen Absicht, und sie ist nicht
aus dem Exit-Code lösbar.** `vim.lsp.stop_client(id, true)` schickt SIGTERM —
ein gewolltes `:Lsp restart` sieht am `on_exit` **exakt** aus wie ein Server,
den der OOM-Killer erwischt hat. Beide Richtungen des Fehlers sind schlimm: rät
man auf „Absturz", startet das Plugin neu, was man gerade gestoppt hat; rät man
auf „Absicht", verpasst es genau den Fall, für den es existiert. Also wird
Absicht **deklariert**: jeder gewollte Stopp im Plugin ruft vorher
`expect_stop(id)`, und ein markierter Exit ist kein Absturz. Das betrifft
`usercmds/stop.lua` (beide Pfade — der Graceful-Shutdown endet mit 0, der
Force-Fallback mit SIGTERM), `usercmds/restart.lua` (beide Zweige) und
`recovery.force_restart`.

Drei weitere Exits zählen bewusst nicht als Absturz, jeder aus eigenem Grund:

- **Ein sauberer Exit, den niemand verlangt hat** (`code == 0`, kein Signal).
  Konstruktionsbedingt mehrdeutig; ein Neustart riskiert eine Schleife gegen
  einen Server, der von sich aus fertig ist.
- **Ein Exit während `:qa`.** `vim.v.exiting` ist erst gesetzt, wenn Neovim
  schon abbaut — Clients sterben eine Spur davor. Deshalb zusätzlich ein
  `VimLeavePre`-Flag.
- **Ein Client, der starb, bevor er je attachte.** Es gibt keinen Namen und
  keinen Buffer, in den er zurückgehörte — und ein Server, der *beim Start*
  abstürzt, ist genau der Fall, in dem eine automatische Retry-Schleife
  gefährlich ist. Der hat schon einen Besitzer: `:Lsp recover`.

**Der Zähler wird durch Überleben zurückgesetzt, nicht durch Erfolg.** Ein neu
gestarteter Client, der `reset_after_ms` später noch läuft, löscht ihn. Beim
Attach zurückzusetzen wäre das Naheliegende und wäre falsch: ein Server, der
zwei Sekunden nach jedem Attach abstürzt, würde ewig neu starten, weil jeder
Attach den vorigen Absturz verzeiht.

*Aufhängung*: `on_exit` einmal über `vim.lsp.config("*", …)` statt in jedem
Servermodul — `"*"` wird in jede benannte Config gemergt, und die Auflösung ist
lazy (auf 0.12.2 nachgemessen: auch eine *danach* registrierte Config bekommt
den Hook). Ein Server, der morgen dazukommt, ist damit ohne Zutun überwacht.
`on_exit` läuft im Fast-Event — ebenfalls nachgemessen — dort wird also nur
eingesammelt und per `vim.schedule` entschieden.

*Oberfläche*: `auto_restart = { enable, max_attempts, initial_delay_ms,
max_delay_ms, reset_after_ms }` in den DEFAULTS, `:Lsp autorestart
[toggle|on|off|status]`. **Kein Keymap** — anders als die Hint- und
Indikator-Schalter wird der einmal gesetzt und nicht mehr angefasst; eine Taste
dafür wäre eine Taste, die man nie drückt. `preset = "lean"` lässt ihn an, mit
Begründung im Preset: er kostet nichts, solange nichts abstürzt, und eine
schwache Maschine ist gerade die, auf der ein Server OOM-gekillt wird.

**Zwei Bugs, beide in der Maschinerie, auf der das aufsetzt:**

1. **`:Lsp restart <server>` hat noch nie etwas neu gestartet.** Die
   Config-Suche lief über `vim.lsp.config.get()` — das gibt es auf Neovim 0.12
   nicht (gegen 0.12.2 geprüft). Der Aufruf löste zu `nil` auf, der Lookup fiel
   auf eine leere Tabelle durch, und das Kommando stoppte seinen Client und
   meldete danach ein Scheitern, das von einem echten nicht zu unterscheiden
   war. Läuft jetzt über `vim.lsp.config[name]`, und zwar in **einer**
   Implementierung für Kommando und Supervisor.
2. **`:LspDoctor startup` meldete immer „Attempts: 0".** Er las den Zähler aus
   `lsp.usercmds.state` — ein Modul, das es in diesem Plugin nie gab. Der
   `pcall` schlug also bei jedem Aufruf still fehl, während
   `usercmds/recovery.lua` in eine Tabelle zählte, die niemand las, und der
   Hinweis „Start failed — check `:LspLog`", den die Zahl freischaltet, konnte
   nie erscheinen. Der Supervisor besitzt den Zähler jetzt für beide Seiten —
   die verlangten Starts und die automatischen — und der Report liest daraus.

*Verifiziert an einem echten abstürzenden Serverprozess*: ein minimaler
stdio-LSP-Server (Node), der den `initialize`-Handshake beantwortet und beim
ersten Lauf 1,2 s nach `initialized` mit Code 3 stirbt. Beobachtet: Client 1
(PID 20084) attacht, stirbt, 400 ms später wird ein **zweiter Prozess** (PID
37688) gestartet, Client 2 attacht, der Zähler fällt nach dem Überlebensfenster
auf 0 zurück — und ein anschließend *deklarierter* Stopp desselben Clients
(Exit 1, Signal 15, also die absturzähnlichste Variante) führt zu **keinem**
Neustart und **keinem** Zähler. Der `:Lsp restart`-Fix separat am selben Server
geprüft: id 1 → id 2, zwei Prozesse im Log, nicht als Absturz gezählt. Dazu:
Suite grün über 20 Spec-Dateien, Smoke grün, `luacheck` 0/0 über 199 Dateien,
`stylua` sauber, `gen_bindings.lua --check` sagt „current".

*Nebenbefund, nicht mitgemacht*: `vim.lsp.stop_client()` ist auf 0.12
deprecated und warnt bei jedem Stopp. Drei Aufrufstellen (`stop.lua`,
`restart.lua`, `recovery.lua`); als eigene Aufgabe notiert, weil der Umbau auf
`client:stop()` die Listen-Variante in `restart.lua` in eine Schleife auflösen
muss und mit dem `expect_stop`-Vorlauf nicht kollidieren darf.

*Bindings-Zettel*: `Usercmds/lsp.nvim.md` (neuer Abschnitt) und
`Autocmds/lsp.nvim.md` (neue Augroup `lsp_nvim_supervisor`, Kopfzahl jetzt 31
über 24). `Keymaps/lsp.nvim.md` nicht berührt — der Punkt fügt bewusst keine
Taste hinzu.


---

### M4a · `lsp.nvim` — ein Picker-Backend statt zwei

**Erledigt am 2026-08-30. `lua/lsp/tools/ts_type_lookup/symbol_picker.lua`,
6 neue Specs. `ts_telescope_picker.lua` geloescht.**

Die Haelfte von M4, die sich bauen liess. M4 stand als „Workspace-Symbol-/
Call-Hierarchy-Picker ueber den `picker`-Adapter" da; die Pruefung am
2026-08-30 ergab, dass es diesen Adapter nicht gibt (31 Zeilen
Presence-Reporting, die im eigenen Docstring festhalten, dass sie keine
Abstraktion sind). Der Punkt zerfiel damit in M4a — hier — und M4b, das jetzt
unter [Zurueckgestellt](#zurueckgestellt) steht.

Gebaut: `:TypeDefPick` benutzt dieselbe Oberflaeche wie `<leader>wos`. Vorher
waren es 171 Zeilen handgeschriebenes Telescope — eigener Finder, eigener
Entry-Maker, ein Previewer, der die Datei mit `readfile()` las und drei Zeilen
drumherum zeigte, und eine `<CR>`-Aktion, die ein Vsplit oeffnete. Alles, um
die Antwort auf **eine** `workspace/symbol`-Anfrage anzuzeigen, die fzf-lua mit
`lsp_workspace_symbols` beantwortet. Danach: 74 Zeilen, die delegieren. Die
Datei heisst jetzt `symbol_picker.lua` — der alte Name waere eine Luege
gewesen.

**Die Entscheidung, an der es haengt, ist eine Option**: `lsp_query`, nicht
`query`. Die erste geht als `workspace/symbol` an den Server, die zweite ist
fzf-luas Filter ueber das, was zurueckkam. Die zweite zu benutzen wuerde den
Server nach *allem* fragen und lokal filtern — was auf einem kleinen Projekt
funktioniert und auf einem grossen umfaellt, also genau dort auffaellt, wo es
zu spaet ist. Der Spec prueft beides: dass die eine gesetzt ist und die andere
**nicht**.

**Was M4a ausdruecklich nicht liefert, obwohl der Punkt es nahelegt:**
Telescope faellt *nicht* als Abhaengigkeit weg. `languages/webdev/astro` nutzt
`telescope.builtin` weiter fuer Komponenten-, Layout- und Seiten-Navigation
(`gC`, `gL`, `gP` und zwei Astro-Usercmds), hinter einem
`FileType astro`-Autocmd und einem lazy `require`. Weg ist ein **zweiter Picker
fuer dieselbe Liste**, nicht Telescope. Das steht so auch in `docs/FEATURES.md`
— die urspruengliche Formulierung „telescope faellt als Abhaengigkeit weg" war
zu grosszuegig, und ich habe sie beim Pruefen selbst geschrieben.

*Konkrete Auswirkung*: `:TypeDefPick` oeffnet dasselbe Fenster wie
`<leader>wos`, mit fzf-luas Preview und dessen Oeffnen-Aktionen, statt eines
Telescope-Fensters, dessen einzige Aktion ein Vsplit war.

*Verifiziert gegen das installierte fzf-lua*: `:TypeDefPick` loest
`lsp_workspace_symbols` auf und uebergibt `lsp_query = <cword>`,
`:TypeDefPick Foo` uebergibt `lsp_query = "Foo"`, und Telescope wird von
keinem der beiden geladen. Dazu: Suite gruen ueber 23 Spec-Dateien, Smoke
gruen, `luacheck` 0/0 ueber 202 Dateien, `stylua` sauber,
`gen_bindings.lua --check` sagt „current".

*Bindings-Zettel*: nicht beruehrt. `:TypeDefPick` gab es vorher und gibt es
nachher, mit derselben Grammatik; keine Keymap, kein Autocmd geaendert.

---

### M17/M13 · `documentation.nvim`-Verbund — ein `ECOSYSTEM.md`, fünf Repos erreichen es

**Erledigt am 2026-08-30. Fünf Repos, ein Commit je Repo:
`documentation.nvim` `0d09b50`, `runtime-analysis.nvim` `0d92977`,
`lib.nvim` `9240596`, `mdview.nvim` `1803e67`, `docmap-desktop` `309c7d0`,
dazu `a473f99` für `PLAN.md`/`PLAN-DONE.md`.**

Ursprünglich (`PLAN.md` M13): *„Das Architekturdokument liegt in einem Repo
und beschreibt vier. Wer in den anderen dreien danach sucht, findet nichts.
Dasselbe Muster wie dieser Plan — eine Quelle, drei Zeiger."* Aufwand S–M.

**Die Beschreibung untertrieb, und das ist die Notiz.** Es fehlte nicht bloss
ein Zeiger. `runtime-analysis.nvim` zitierte `docs/ECOSYSTEM.md` als
**repo-relativen Pfad an neun Stellen** — zweimal in `README.md`, sechsmal in
`lua/**`-Modulköpfen, einmal in `FEATURE_LOG.md` — und diesen Pfad gibt es
dort nicht. Jede einzelne war tot in dem Moment, in dem sie geschrieben wurde.
`lib.nvim` hatte eine zehnte, in Prosa korrekt zugeordnet, aber ohne Link —
also weiterhin nur auffindbar für jemanden, der schon weiss, wo er suchen muss.

**Und warum das nie jemand gemeldet hat**: beide vorhandenen Checks lehnen den
Fall ab, jeder aus einem genannten und richtigen Grund.
`doc-references-missing` löst *Code-Bezeichner* gegen die Modulkarte des
gescannten Repos auf; `dead-readme-link` löst *Markdown-Links* innerhalb **eines**
Repos auf und ruft vorher `strip_code` — ein blankes `` `docs/ECOSYSTEM.md` ``
ist für ihn absichtlich unsichtbar. Keiner von beiden ist defekt. Was fehlt,
ist eine dritte Form: `<repo>/<pfad>`, aufgelöst gegen deklarierte
Geschwister-Checkouts.

**Das ist die zweite Hälfte, die IDEAS.md §3.3 eigentlich wollte** — *„cross-repository
links checked by CI … die am meisten auf-These liegende Housekeeping-Idee, die
verfügbar ist"* — und sie ist nicht mitgebaut worden, sondern steht jetzt als
eigener Punkt **M17/M14** in `PLAN.md`. `external_repos` trägt die nötige
Zuordnung (`repo` plus optionales `local_path`, per `uv.fs_stat` geprüft, ohne
Netz) bereits, also ist es eine Erweiterung und kein neues Subsystem.

*Was ausgeliefert wurde*: zwei Kopfblöcke auf `ECOSYSTEM.md` selbst — einer
sagt, dass dies die Quelle ist und in welcher Form man sie von aussen zitiert,
einer hält fest, dass `docmap-desktop` **nach** der letzten Revision
(2026-08-11) dazukam und deshalb dort fehlt. Das ist kein Versäumnis: die App
ist ein zweiter *Host* für die Artefakt-und-Serve-Ebene, die Seam B schon
beschreibt — eine Notiz, keine Überarbeitung. Dazu je ein echter Link im
Doku-Index der vier Geschwister und alle neun toten Pfade mit dem besitzenden
Repo qualifiziert.

*Ein Detail, das sonst Zeit gekostet hätte*: Markdown zu ändern macht in
`documentation.nvim` und `runtime-analysis.nvim` die eingecheckte Karte
**stale** — der Markdown-Korpus ist Teil der IR. In beiden musste `docs/map/`
neu erzeugt werden, bevor das Map-Gate durchging. `lib.nvim` und `mdview.nvim`
prüfen keine Karte und brauchten keine.

*Bewusst nicht gemacht*: `mdview.nvim` bekam den Zeiger, aber keinen
Inhaltsdurchgang. `ECOSYSTEM.md` erwähnt es in einer Zeile („presentation:
Markdown to a browser"), und die stimmt noch.

---

### M17/M8 · `documentation.nvim` — `:DocMap impact`, gewichtet nach Runtime-Reichweite

**Erledigt am 2026-08-30. `documentation.nvim` `bd081b2`, auf `main` gepusht.
Dazu `f5ca3d5` fuer `PLAN.md`/`PLAN-DONE.md`.**

Ursprünglich: *„`impact` beantwortet ‚welche Funktionen berühren meine
geänderten Zeilen, und wer ruft sie'. Mit Telemetrie daneben wird daraus
‚… und wie oft ist das tatsächlich passiert' — eine Rangfolge statt einer
Liste."* Aufwand M.

**Kleiner als die Klasse sagte, und der Grund ist merkenswert**: beide Hälften
schlüsselten ihre Antworten längst gleich. `history.analyze` schlüsselt seine
Treffer `"<node>#<fn>"`; `telemetry_join.by_key` liefert Zeilen unter `ir_key`,
dessen eigene Annotation lautet *„the same key shape `check.used_keys`
returns"*. Es war eine Kreuzung über einen gemeinsamen Schlüssel, kein Bau —
zwei Funktionen und ein optionaler Parameter.

*Konkrete Auswirkung*: `:DocMap impact` antwortete als **Menge** — dreissig
berührte Funktionen, dreissig gleichrangige Zeilen, „womit fange ich an"
unbeantwortet. Jetzt als **Warteschlange**:

```
changed: runtime_reach(cfg, ir)   (1 caller)  · 4000 calls, 340 this week (yours)
  ← M.run calls it   (documentation.bindings.usrcmds.impact)
changed: M.run(ctx, arg)   (0 callers)  · 12 calls, none in the last week (yours)
```

**Die Entscheidung, die argumentiert werden musste statt kopiert.** `churn`
rangiert dieselbe Art Liste aus denselben Daten und **weigert sich
ausdrücklich**, Telemetrie eine Zeile bewegen zu lassen — `COMMANDS.md` sagt
warum: eine Rangfolge über den Code darf nicht davon abhängen, auf wessen
Maschine sie entstand, sonst bekommen zwei Entwickler zwei Ordnungen und keiner
hat unrecht. Hier das Gegenteil zu tun brauchte einen besseren Grund als
Bequemlichkeit, und es gibt einen: `churn` ist ein dauerhaftes, teilbares
Urteil **über den Code**; `impact` ist eine private Einmalantwort über **deine
eigene, uncommittete Arbeit** — einmal vor dem Commit gelesen, nie mit jemandem
verglichen. „Welche der Dinge, die ich gerade geändert habe, benutze ich
eigentlich" ist von Bauart her eine Frage über diese Maschine. Beide Header
tragen das Argument jetzt und zitieren einander, weil der nächste Leser sie
sonst zu **einer** Regel harmonisiert und dabei die falsche kaputt macht.

**Aktualität statt Gesamtzahl** — und das ist wiederum die Gegenentscheidung zu
`untested_hot` im selben Modul, aus derselben Art Grund. Jene Liste rangiert auf
Lebenszeit-Zahlen, weil ihre Frage („lief das je, ohne dass ein Test zusah")
keine über diese Woche ist. Diese fragt, ob ein Pfad lebt, und das beantwortet
nur Aktualität.

*Ein Refactor fiel dabei an*: die Formulierungsregel — nie „unused", immer „in
your sessions", und Abwesenheit ist nie eine Null — war eine Datei-lokale
Funktion in `churn.lua`, mit `IDEAS.md` §1.1 zitiert als *Anforderung an den
Render*. Es gibt jetzt zwei Renders. Sie ist nach
`telemetry_join.session_note` gewandert, neben die Daten, deren Bedeutung sie
ist, damit die drei Zustände nicht zweierlei heissen können.

*Der Basisfall ist als Identität abgesichert, nicht per Augenschein*: ohne
Telemetrie ist die Liste byte-gleich mit vorher — Reihenfolge eingeschlossen —
und zwar stillschweigend. `impact` ist kein Telemetrie-Kommando, also bleiben
die drei Ursachen von „keine Daten" hier ungenannt, statt eine Frage zu
beantworten, die niemand gestellt hat. `usrcmds/untested.lua` nennt sie, weil
dort danach gefragt wurde.

*Verifiziert*: alle vier Gates gruen (`stylua`, `luacheck`, Specs,
`map --check`), sechs neue Assertions in `runtime_joins_spec.lua` — dem Spec,
in dem die anderen beiden Kreuzungen schon liegen — plus ein Durchlauf gegen
den echten Arbeits-Diff dieses Repos, nicht nur gegen die Fixtures.

*Bindings-Zettel*: nicht berührt. Kein neuer Usercmd, keine neue Taste;
`:DocMap impact` gibt dieselbe Quickfix-Liste in anderer Reihenfolge aus.

---

### M17/M9 · `documentation.nvim` — `:DocMap why` × Call-Trees

**Erledigt am 2026-08-30. `documentation.nvim` `ff18561`, auf `main` gepusht.
Dazu `a746880` fuer `PLAN.md`/`PLAN-DONE.md`.**

Ursprünglich: *„`why <a> <b>` läuft heute den **statischen require-Graphen** ab.
Der Call-Tree ist die andere Kette: nicht ‚was lädt was', sondern ‚was ruft
was'. Zwei Antworten auf zwei Fragen, die leicht verwechselt werden."* Aufwand
M, einsortiert unter `runtime-analysis`.

**Und genau das war er nicht — kein Runtime-Punkt.** Die Call-Kanten liegen
seit `calls.build` in **jeder** erzeugten Karte: `from`, `from_fn`, `to`,
`to_fn`, `line`, `confidence`. Es brauchte weder Telemetrie noch ein Plugin
noch eine laufende Sitzung. Das ist der vierte von acht Einträgen dieses
Verbunds, dessen Beschreibung in irgendeiner Richtung danebenlag — und der
zweite an zwei Tagen.

**Was tatsächlich fehlte, war eine Traversierung**, und die Vorprüfung hat das
bestätigt, bevor eine Zeile geschrieben war: `deps.path` war der einzige
Pfadfinder im Baum und läuft ausschliesslich über `require`-Kanten; die
`calls`-Ansicht in `:DocBrowse` ist **ein** Hop rein oder raus, kein Lauf;
`core/calls.lua` exportierte `extract`, `identifier_counts` und `build` — und
keinen Pfad. Kanten ja, Weg nein.

*Konkrete Auswirkung*: `:DocMap why a b` beantwortete eine Frage und sah aus,
als beantworte es die andere. Jetzt beide, und die Call-Kette ist
**funktionsgenau**, weil die Kanten es sind:

```
loads · 1 hop, all at load time:  documentation.bindings.usrcmds.why → documentation.core.deps
calls · 1 hop:  documentation.bindings.usrcmds.why#M.run → documentation.core.deps#M.path
```

`deps.path` kann immer nur sagen „A erreicht B". Das hier sagt, **durch welche
Funktionen** — die Hälfte, die man vorher in der Deps-Ansicht von Hand
rekonstruiert hat.

**Der Ertrag ist die Uneinigkeit der beiden Ketten**, nicht ein Nebeneffekt.
Zwei Formen, beide in diesem Repo real:

- **Lädt, ruft aber nie.** Das oberste Modul `documentation` requiret
  `core.cli`, `core.diff` und beide Renderer und ruft in keinen davon hinein.
  Im require-Graphen allein ist das von einer lebendigen Abhängigkeit **nicht
  unterscheidbar** — genau deshalb musste die zweite Kette existieren, bevor es
  überhaupt jemand sehen konnte.
- **Ruft ohne require-Pfad.** Der statische Graph untertreibt die Verbindung:
  ein deferred oder dynamisch gebautes `require`, dem `deps` nicht folgen kann.

*Die Entscheidung, die bleibt*: heuristische Sprünge werden **durchlaufen und
markiert**, nicht verworfen. `build` kennzeichnet einen Bare-Name-Treffer als
`"heuristic"`; sie wegzulassen würde echte Ketten verstecken, sie
stillschweigend mitzunehmen würde eine Vermutung als Tatsache ausgeben.
`chain_confidence` kollabiert eine Kette auf ihren schwächsten Sprung — ein
heuristisches Glied macht die ganze Kette heuristisch, denn das *ist* die
Sicherheit einer Kette. Das `~` ist dasselbe Zeichen, das die Calls-Ansicht
schon für denselben Sachverhalt benutzt.

*Ein Detail, das die Fixtures nicht abdecken konnten*: dieses Repo hat **null**
heuristische Call-Kanten, die Markierung wird also nur von einer konstruierten
Assertion ausgeübt. Ausdrücklich gesagt, statt wie Abdeckung auszusehen.

*Verifiziert*: alle vier Gates gruen (`stylua`, `luacheck`, Specs,
`map --check`), zwölf Assertions im neuen `call_path_spec.lua` auf einem
Fixture-Baum, in dem die beiden Graphen wirklich auseinandergehen — plus ein
Durchlauf gegen die echte Karte dieses Repos, aus dem die vier
Lädt-ruft-aber-nie-Fälle oben stammen.

*Bindings-Zettel*: nicht berührt. Kein neuer Usercmd, keine neue Taste;
`:DocMap why` gibt mehr Zeilen in dieselbe Quickfix-Liste.

---

### M17/M14 · `documentation.nvim` — Cross-Repo-Doku-Verweise, per CI geprueft

**Erledigt am 2026-08-31. `documentation.nvim` `66c429f`,
`runtime-analysis.nvim` `ae7af45`, dazu `ce9f90e` fuer `PLAN.md`/`PLAN-DONE.md`.
Ausgeliefert als Check `sibling-reference-missing`.**

Der Punkt entstand am 2026-08-30 aus M17/M13: neun tote `docs/ECOSYSTEM.md`-
Verweise in `runtime-analysis.nvim`, jeder tot ab der Sekunde seines
Entstehens, und keiner der beiden vorhandenen Checks konnte sie melden.

**Groesser als angeschrieben — und das ist die Notiz.** Ich hatte gesagt,
`external_repos` trage die noetige Zuordnung bereits. Tut es nicht ganz:
`external_repos` **und** `tag_files` sind nach **Modul-Praefix** geschluesselt,
eine Doku-Zitierung nach **Repo-Verzeichnisname**. Fuer `lib.nvim` faellt beides
zusammen, fuer `documentation.nvim` nicht — dessen Praefix ist `documentation`,
und genau dorthin zeigten die neun toten Verweise. Dazu deklarierte
`documentation.nvim`s eigene `.docmap.json` ueberhaupt keine `external_repos`,
und das Schema verbot `local_path` per `additionalProperties: false`. Also:
Konfigurationsform **plus** Check, nicht Check allein.

*Was ausgeliefert wurde*: `name` auf `Documentation.ExternalRepo` (der
Verzeichnisname, von Hand gesetzt), `local_path` ins Schema aufgenommen und
**relativ zu `opts.root`** aufloesbar gemacht — damit eine eingecheckte
`.docmap.json` `../sibling` sagen kann und auf jeder Maschine stimmt, statt den
absoluten Pfad eines Entwicklers zu tragen.

**Zwei Fehlalarme auf echten Dokumenten, beide aus URL-foermigem Text, beide
per Regel ausgeschlossen statt weggestellt.** Der erste Lauf meldete
`lib.nvim/blob/main/lua/lib/nvim/notify/init.lua` aus dem eigenen
`FEATURE_LOG.md` — ein GitHub-Blob-Link enthaelt einen Repo-Namen gefolgt von
einem Pfad und passt damit auf jedes `<name>/<pfad>`-Muster. Volle URLs zu
strippen loeste die Haelfte; die andere war derselbe Link **ohne Schema**, den
kein URL-Stripper sieht. `<repo>/blob/<ref>/…` und `<repo>/tree/<ref>/…` sind
jetzt als die URL-Pfade ausgeschlossen, die sie sind. Beide Regeln stehen samt
ihrem Ausloeser im Quelltext, weil „warum ignoriert der Check das" sonst eine
Frage ohne Antwort ist.

*Die Disziplin, die ihn benutzbar haelt*: nur ein erstes Segment, das einem
**deklarierten** `name` entspricht, wird ueberhaupt betrachtet. Nichts wird aus
der Pfadform erschlossen. Ein Check, der raet, feuert ueberall und ist binnen
eines Tages abgeschaltet — schlechter als keiner.

*Ein Defekt, den die Suite gefangen hat, und genau dafuer ist sie da*:
`vim.fs.normalize` war der naheliegende Weg, Root und Relativpfad zu
verbinden, und steht nicht im Standalone-Shim. `shim_contract_spec.lua` fiel
darueber — der Spec, der geschrieben wurde, nachdem zweimal ein Release genau
daran zerbrochen war. Stattdessen blosse Konkatenation; `uv.fs_stat` loest `..`
selbst auf.

*Wo er tatsaechlich laeuft*: `documentation.nvim` und `runtime-analysis.nvim` —
die beiden Repos mit docmap-Konfiguration und Map-Gate. `lib.nvim` und
`mdview.nvim` haben weder `.docmap.json` noch `gen_map.lua`, dort gibt es keine
Oberflaeche dafuer. Das ausdruecklich zu sagen ist besser, als fuenf abgedeckte
Repos zu suggerieren.

*Verifiziert*: alle vier Gates gruen, zwoelf Assertions im neuen
`sibling_references_spec.lua` ueber einen Zwei-Baum-Fixture — plus je eine
Probe in beiden Repos gegen echte Checkouts: der tote Geschwister-Pfad wird
gemeldet, der lebendige daneben nicht.

*Bindings-Zettel*: nicht beruehrt. Kein Usercmd, keine Taste — ein Check-Code
mehr in `:DocMap check`.

---

### M17/M7c · `documentation.nvim` — der Befund statt des Umbaus

**Erledigt am 2026-08-31. `documentation.nvim` `1e95a40`. Ausgeliefert als
Check `file-holds-many-modules`.**

Der Punkt entstand in derselben Sitzung, in der **M17/M7b zurueckgestellt**
wurde (siehe dort). M7b wollte aus einem Scope einen Knoten machen; das ist
eine Id-Form-Aenderung quer durch die Pipeline. Was davon *heute* nuetzlich
ist, ist nicht der Umbau, sondern die Auskunft: eine Datei, die mehrere
Modul-Identitaeten traegt, wird gemeldet, statt still fuer alle zu antworten.

*Konkrete Auswirkung*: `:DocMap check` in einem Rust- oder Elixir-Baum sagt
jetzt `src/lib.rs holds 2 module identities the map cannot separate: lib, x`.
Vorher erbte `x` schweigend die Zahlen von `lib.rs` — Coverage, Summary,
Kanten — und kein Konsument konnte wissen, dass er die falsche Frage
beantwortet bekam.

**Der Test-Modul-Filter ist der ganze Check, nicht die Feinheit.** Rust
schreibt `#[cfg(test)] mod tests { … }` in die Datei, die es testet. Gemessen:
`docmap-desktop` hat elf Rust-Dateien, jede haelt genau ein Inline-Modul, und
es ist **jedes Mal** `mod tests` — daneben stehen ueberall freie Funktionen.
Ohne den Filter haette dieser Check auf dem einzigen echten Rust-Baum dieses
Oekosystems elfmal gefeuert und waere noch am selben Tag abgeschaltet worden.
Mit ihm: null Befunde, gegen genau diesen Checkout verifiziert.

*Was noch nicht zaehlt und warum*: eine `class`, ein `impl`-Block, ein `trait`
sind besessen, aber nicht von einem Modul — sie gehoeren zur Datei und zaehlen
zu deren eigener Identitaet. Ein einzelnes `defmodule` in einer `.ex`-Datei
ist die Identitaet der Datei, kein zweite; Elixir setzt `owner_kind = "module"`
auf **jede** Funktion, ein Check, der Besitzer statt Identitaeten zaehlt,
haette jede korrekte `.ex`-Datei der Welt gemeldet.

*Severity `info`, nicht `warn`*: Rust und Elixir werden absichtlich so
geschrieben. Es gibt nichts, was der Autor des geprueften Baums beheben
koennte — dieselbe Begruendung, aus der `missing-readme` ein `info` ist. Ein
`warn` haette ein korrektes Elixir-Repo dauerhaft gelb gefaerbt.

*Eine Disziplin, die im Quelltext steht*: gezaehlt wird ueber
`core/scopes.lua`, nie ueber `fn.owner` direkt. Dieses Modul erklaert sich
selbst zum einzigen Leser von `owner`/`owner_kind`, und eine zweite
Gruppierung in einem Check waere genau die Drift, die dieses Plugin zu finden
gebaut ist.

*Verifiziert*: alle vier lokalen Gates gruen (standalone ohne Rocks
uebersprungen), dreizehn Assertions im neuen `many_modules_spec.lua` ueber ein
synthetisches IR — ein Rust- oder Elixir-Fixture haette die Assertions an
Treesitter-Grammatiken gekoppelt, die ein lokaler Lauf nicht hat, und *was die
Backends setzen* ist ohnehin Sache von `lang_rust_spec.lua` und
`lang_elixir_spec.lua`. Dazu die Live-Probe gegen `docmap-desktop`.

*Nebenbefund, mitgenommen*: die Check-Liste in `README.md` fuehrte
`sibling-reference-missing` nicht — der Commit vom Vortag hatte sie dort
vergessen. Beide stehen jetzt drin.

*Bindings-Zettel*: nicht beruehrt. Kein Usercmd, keine Taste — ein Check-Code
mehr in `:DocMap check`.


---

### M5 · `nvim-config` — Sprung zur umschliessenden Struktur (ehemals `<leader>gtt`)

**Erledigt am 2026-08-30. `after/queries/{lua,json,python,rust,toml,yaml}/
textobjects.scm` und `lua/bindings/mappings/treesitter_structure.lua` — im
Config-Repo, nicht in `lsp.nvim`.**

Der Punkt stand unter `lsp.nvim` und ist dort nicht gelandet. Die Frage, die
ich vor dem Bauen gestellt hatte — „ist das ueberhaupt ein LSP-Feature?" — hat
der Auftraggeber beantwortet: solche Bewegungen laufen hier ueber Treesitter
und sollen dort bleiben. Damit aendert sich nicht nur der Ort, sondern die
Bauform: **es ist kein Feature-Modul geworden, sondern eine Konfiguration.**

*Was es tut*: `[u` setzt den Cursor auf den Kopf der Struktur, in der er
steht; nochmal gedrueckt eine Ebene weiter raus, bis zur aeussersten. `]u`
dasselbe abwaerts, zum schliessenden Ende. In einer Funktion klettert es
`for` → `if` → `function`, in einer Konfigurationstabelle Tabellenkopf um
Tabellenkopf.

**Der Kern ist eine Beobachtung, kein Code**: `goto_previous_start` von
`nvim-treesitter-textobjects` geht zur naechsten Uebereinstimmung *vor* dem
Cursor — und der Kopf des umschliessenden Knotens ist genau das. „Previous
start" und „eine Ebene raus" sind dieselbe Bewegung, und Wiederholung
klettert. Es war nichts zu implementieren.

**`nvim-treesitter-textobjects` war seit jeher installiert und nirgends
benutzt.** `plugins/treesitter.lua` fuehrt es mit `lazy = false` und ruft nie
hinein; im ganzen `lua/`-Baum gab es keine einzige Referenz. Die vier Tasten
sind der erste Nutzer.

**Was tatsaechlich zu schreiben war: eine Query-Zeile pro Sprache.** Das
mitgelieferte `@block.outer` ist `(_ (block)) @block.outer` — Funktionsrumpf,
`if`, `for`, `while`. Eine Lua-Tabelle ist kein `block`, und JSON hat gar
keine Bloecke (seine mitgelieferte textobjects-Query ist *eine* Zeile, fuer
Kommentare). Der Fall, fuer den die Bewegung gedacht war — die tief
verschachtelte Konfigurationstabelle — war also der einzige, den sie nicht
erreichte. Sechs Dateien unter `after/queries/`, jede mit `;; extends`, jede
drei bis sechs Zeilen.

*Eine Entscheidung, die im Zuschnitt gewandert ist*: ich hatte zuerst eine
eigene Capture `@structure.outer` gebaut, um die mitgelieferte nicht zu
ueberladen. Auf Nachfrage („kann man nicht die korrespondierende erweitern")
auf `@block.outer` umgestellt — in dieser Config benutzt nichts sonst die
Capture, „das, worin ich stehe" ist **ein** Begriff, und eine Capture haelt
die Bewegung bei einem Argument. Der Preis steht in den Query-Dateien:
`@block.outer` bedeutet hier etwas mehr als upstream dokumentiert, und wer
spaeter „ausfuehrbarer Block" streng braucht, trennt es wieder.

*Die Sorgfaltsregel dabei*: jeder Node-Name wurde an der **echten Grammatik
abgelesen** (Ahnenkette am Cursor ausgegeben), nicht geraten. Grund: ein
unbekannter Node-Name degradiert nicht, er laesst die ganze
`textobjects`-Query dieser Sprache nicht mehr parsen — ein Tippfehler haette
also `@function.outer` fuer die Sprache gleich mit erledigt. Deshalb sind nur
Sprachen dabei, deren Parser hier installiert ist und deren Query
nachweislich parst; `go`/`typescript` fehlen bewusst, funktionieren aber fuer
ihre *Bloecke* schon ohne eigene Datei.

*Verifiziert in der echten Config*, jeweils mit gedrueckter Taste, nicht ueber
die API:

| Sprache | von | `[u`-Kette |
| --- | --- | --- |
| lua (Konfigurationstabelle) | 9 | 9 → 8 → 7 → 6 → 5 → 4 → 3 |
| lua (Funktion mit `if`/`for`) | 6 | 6 → 5 → 4 → 3 → 1 |
| json | 5 | 5 → 4 → 3 → 2 → 1 |
| python | 4 | 4 → 3 → 2 → 1 |
| toml | 6 | 6 → 5 → 4 → 1 |
| yaml | 4 | 4 → 3 → 2 → 1 |
| rust | 4 | 4 → 3 → 2 → 1 |

`]u` ebenso abwaerts (in der Tabelle `9:6 → 9:30 → 10 → 11 → 12 → 13 → 14` —
der erste Schritt bleibt in derselben Zeile, weil dort die innerste Tabelle
endet; eine Zeilen-nur-Messung sieht darin faelschlich „keine Bewegung").
Alle sechs Query-Dateien parsen gegen die echte Grammatik, und die
`after/`-Datei laedt nachweislich *neben* der mitgelieferten.

*Bindings-Zettel*: `Keymaps/nvim-config.md` — neuer Abschnitt „Structure
movement", Changelog-Eintrag. Kein Plugin-Zettel betroffen, weil kein Plugin
betroffen ist.

**Nicht gebaut, und das ist der Punkt**: kein Modul in `lsp.nvim`, keine
Lua-Implementierung einer Baumsuche, kein `<leader>gtt`. Der Punkt stand
jahrelang als „Feature, das gewollt, aber nie gebaut wurde" auf der Liste —
die Antwort war, dass das Werkzeug dafuer schon im Ladenregal stand.

**Nachgereicht am selben Tag: zwei Abschalter**, auf Wunsch des Auftraggebers
und auf den zwei Ebenen, auf denen man das nicht wollen kann.

- *Das Plugin*: `plugins/treesitter.lua` ist dafuer auf
  `plugins.control.mode` umgestellt — dieselbe `modes`-Tabelle am Dateikopf,
  die `misc.lua` schon fuehrt, mit einer auskommentierten Zeile
  `["nvim-treesitter-textobjects"] = "disabled"`. Das ist die
  Installations-Spec, in der diese Config ohnehin ihr An/Aus fuehrt.
- *Nur die Tasten*: `setup({ enable = false })` am Aufruf in
  `bindings/mappings/init.lua`, im selben Muster wie `smart_del_key.setup({
  set_cr = true })`; `keys = { up = …, down = … }` verschiebt sie, `down =
  false` laesst eine Richtung weg.

**Und ein Fehler, den derselbe Durchgang gefunden hat**: die Tasten waren
zuerst `[b`/`]b`, weil ein Grep ueber `lua/` dort nichts fand. `[b ]b [B ]B`
sind aber **Neovims eigene 0.12-Defaults** fuer Buffer-Navigation — sie stehen
in keiner Config-Datei und waren nie frei. Der Grep war das falsche Werkzeug;
gefunden hat es erst die Frage an den laufenden Editor, und auch die nur, weil
ich `maparg().desc` gelesen habe statt nur „ist belegt": Neovims Default ist
ebenfalls ein Lua-Callback, ein Vorhandensein-Test haette „ja, gebunden"
gesagt und gemeint „ja, von jemand anderem". Jetzt `[u`/`]u`, gegen die im
laufenden Editor erhobene Belegung geprueft. Nebenbei sichtbar geworden:
`[s`/`]s` ist snacks.nvim' Scope-Bewegung, der naechste Nachbar dieser
Funktion.

Wichtiger als die Schalter selbst ist, **was ohne Plugin passiert**: das Modul
prueft die Verfuegbarkeit **einmal beim Setup** und bindet dann gar nichts,
statt die Tasten zu belegen und beim Druecken zu klagen. Eine belegte Taste,
die nur eine Warnung produziert, ist schlechter als eine freie — sie steht
einem anderen Mapping im Weg und sieht wie ein Defekt aus. Alle vier Zustaende
nachgemessen: Default bindet beide, `enable = false` bindet nichts, eigene
Tasten binden nur die eigenen, Plugin weg bindet nichts.

---

### Call Hierarchy · `lsp.nvim` — die Resthaelfte von M4

**Erledigt am 2026-08-30. Zwei Katalogeintraege, kein Modul.**

Der XS-Punkt, der aus M4 uebrig blieb, nachdem M4a das Backend
vereinheitlicht und M4b sich damit erledigt hatte. Call Hierarchy existierte
im Repo nirgends — weder Keymap noch Kommando noch `callHierarchy` im
Quelltext. Gebraucht wurde dafuer: nichts ausser zwei Zeilen im Katalog, weil
fzf-lua `lsp_incoming_calls` und `lsp_outgoing_calls` mitbringt und die vier
vorhandenen Picker-Eintraege das Muster sind.

`lsc` fragt, wer das Symbol unter dem Cursor aufruft; `lsC`, was es aufruft.
Das Paar folgt `lsd`/`lsD`: kleine Taste die haeufigere Richtung, geshiftet
das Gegenstueck. `lsi` war von den Implementierungen belegt und `<leader>c*`
in der Host-Config voll, also war die praefixlose `ls*`-Familie der einzige
stimmige Platz.

*Ehrlich zum Nutzen*: Neovim hat `vim.lsp.buf.incoming_calls` durchaus — das
ist also keine fehlende Faehigkeit, sondern eine benutzbare. Die native
Variante kippt in die Quickfix-Liste und verliert damit den Baum, den das
Protokoll zurueckgibt; fzf-luas Provider halten ihn durchklickbar und mit
Preview.

`default` bindet jetzt 49 Eintraege, `minimal` 33 — beide neuen sind in
`minimal`, aus demselben Grund wie die anderen Picker-Tasten: es gibt fuer
keine der beiden eine native Taste. `docs/BINDINGS.md` neu generiert
(`gen_bindings.lua --check` sagt „current"), Suite gruen ueber 23
Spec-Dateien.

*Bindings-Zettel*: `Keymaps/lsp.nvim.md` — neuer Abschnitt, Preset-Zeile auf
49/33.

---

### M9 · `gopath.nvim` + `pickers.nvim` + `lib.nvim` — Frecency fuer Alternate-Vorschlaege

**Erledigt am 2026-08-31 in einer Sitzung. `lib.nvim` `dd1c9ca` + `440bad0`,
`pickers.nvim` `786d2c0`, `gopath.nvim` `1721604`.**

*Die erste Notiz betrifft die Schaetzung*: der Punkt stand mit „drei Repos,
deshalb nicht in einer Session". Es ging in einer — weil der Quelltext vorher
gelesen wurde und die Antwort guenstig ausfiel: `frecency.lua` hatte **keinen
einzigen `require`**. Zu loesen waren nur der `cfg`-Parameter und, das war die
eigentliche Arbeit, der Modul-Singleton.

*Was ausgeliefert wurde*, in der Reihenfolge, in der es gebaut wurde:

1. **`lib.nvim.frecency`** — `store{ namespace }` liefert ein Handle mit
   `record`/`score`/`lookup`/`flush`/`clear`. Persistenz ueber
   `lib.nvim.cache.disk` (keine zweite Kopie der JSON-Logik), Ablage unter
   `stdpath("data")`, nicht `stdpath("cache")`: diese Zahlen werden ueber
   Monate verdient und lassen sich nicht regenerieren.
2. **`pickers.nvim`** — dasselbe Modul, jetzt von aussen. Was blieb, ist das,
   was wirklich diesem Plugin gehoert: die Konfigurationsform, die
   `BufReadPost`-Definition von „ein Besuch" und das Enabled-Gate. Oeffentliche
   API byte-gleich, 294 Assertions unveraendert gruen.
3. **`gopath.nvim`** — der eigentliche Nutzen: die Alternate-Liste wird nach
   dem geordnet, was du in genau diesem Dialog vorher gewaehlt hast.

**Zwei Defekte, die die Extraktion behoben statt mitgenommen hat**, beide
sichtbar erst dadurch, dass ein zweiter Konsument dazukam:

- Der Store war ein **Modul-Upvalue** auf einer festen `frecency.json`. Ein
  zweiter Konsument haette die Rankings des ersten mittrainiert. Das geteilte
  Modul schluesselt ein Handle nach dir+namespace und gibt dasselbe zurueck —
  zwei Handles auf eine Datei ueberschreiben sonst gegenseitig ihre Besuche,
  und das faellt erst Monate spaeter als „meine Zaehler setzen sich manchmal
  zurueck" auf.
- **`weight` wurde beim Verkabeln zum Argument.** Als Store-Option haette ein
  Handle, das die ganze Sitzung lebt, den Wert eingefroren, der bei seiner
  ersten Oeffnung konfiguriert war. Gefunden, weil pickers zuerst umgestellt
  wurde — genau der Grund, aus dem die Reihenfolge so gewaehlt war.

**Die Deckelung in gopath ist der Entwurf, nicht ein Detail.** Der Bonus
saettigt (`score / (score + K)` mal `max_bonus`) statt mit der Besuchszahl zu
wachsen. Ohne Deckel scoret ein einziger Besuch `log(2) × 100 ≈ 69` auf
derselben 0–100-Skala, auf der die Aehnlichkeit selbst liegt — die Liste waere
nach Historie sortiert und die Aehnlichkeit Dekoration. Bei 10 gedeckelt, mit
einer Schwelle, die alles ab 75 zulaesst: sortiert innerhalb eines Bandes um,
kann einen 95-%-Treffer nie unter einen mit 76 % schieben.

*Aufgezeichnet wird die **Wahl**, nicht das Oeffnen.* Eine Datei wird aus einem
Dutzend Gruenden geoeffnet; aus dieser Liste gewaehlt wird sie aus genau
einem. Sofort geschrieben statt beim Beenden — der Dialog ist selten genug,
dass der Write nichts kostet, und die Alternative ist, das Gelernte an einen
Absturz zu verlieren.

*Getrennte Namespaces, ausdruecklich*: ein Pfad, den du im Picker oft
oeffnest, sagt nichts darueber, welches Alternate du hier gemeint hast.

*Ein Datenformat-Bruch — erst dokumentiert, dann behoben, und das ist die
lehrreichere Haelfte*: pickers' Datei liegt weiter unter
`stdpath("data")/pickers.nvim/frecency.json`, hat aber jetzt die Form von
`cache.disk` (`{ saved_at, data }`). Die erste Fassung schrieb in
`PERSISTENCE.md`, ein aelterer Store lese leer und fange neu an — vertretbar,
weil das Feature per Default aus ist und hier nachweislich keine Datei
existierte. **Das war die falsche Entscheidung**, und die Begruendung verraet
warum: „per Default aus" sagt, wie *viele* Leute es trifft, nicht ob es
passieren soll. Diese Zaehler sind Monate echter Benutzung und lassen sich
nicht regenerieren.

Behoben in `lib.nvim` `2e73c25` + `pickers.nvim` `919880d`: `store:seed()`
uebernimmt Zaehler von anderswo und **verweigert** einen Store, der schon
etwas enthaelt — eine einmalige Migration, die zweimal laufen kann, ist
stiller Datenverlust. `migrate_legacy` liest die alte Form einmal pro
Verzeichnis, seedet und schreibt in der neuen Form zurueck; danach ist die
alte Form weg und der Zweig unerreichbar. Unterschieden werden die beiden an
der dekodierten Tabelle (die alte hat weder `saved_at` noch `data`), nicht an
einem Versionsfeld, das nie jemand geschrieben hat.

*Verifiziert*: lib.nvim-Suite gruen (28 neue Assertions), pickers 297/297,
gopath functional tests gruen (8 neue Assertions, darunter die zwei, die sonst
still brechen: der klare Sieger, der nicht invertiert werden darf, und das
Gleichstands-Paar — `table.sort` ist nicht stabil). stylua und luacheck in
allen drei Repos.

*Doku, in zwei Runden*: der Feature-Commit fasste `configuration.md`,
`FEATURES/NAVIGATION.md` und `RESOLUTION.md` an und liess vier Stellen
zurueck, die dasselbe anders erzaehlten — `doc/gopath.txt` (das `:help`, das
man ohne Browser liest), `RESOLUTION-DE.md` (die deutsche Haelfte, die still
hinterherhinkte und dadurch aktuell *aussieht*), `WORKFLOW.md` und die
Developer-Notes. Nachgezogen in `gopath.nvim` `4fcdbc5`.

*Ein offener Nebenbefund, nicht in diesem Zug erledigt*: `gopath.nvim/docs/map/`
ist eine eingecheckte docmap auf **Schema 2** (aktuell ist 6), ohne
`.docmap.json`, ohne `gen_map.lua` und ohne CI-Gate — sie kennt
`alternate/frecency.lua` nicht und kannte auch vorher schon nicht mehr den
aktuellen Stand. Das ist ein eigener Punkt (Karte regenerieren oder loeschen),
kein Teil von M9.

*Bindings-Zettel*: nicht beruehrt. Das neue `VimLeavePre` in lib.nvim ist
opt-in (`autoflush`) und wird von beiden Konsumenten ausgeschaltet — pickers
behaelt seine zwei Autocmds in seiner eigenen Gruppe, gopath registriert
keines.

---

### M17/M10 · `documentation.nvim` + `runtime-analysis.nvim` — Laufzeit-Evidenz als Check-Input

**Erledigt am 2026-08-31. `documentation.nvim` `b632673`,
`runtime-analysis.nvim` `0b3b895`, `docmap-desktop` `b699984`.**

**Die Haelfte war schon gebaut, und der Eintrag sagte es nicht.**
`dead-function` liest Telemetrie seit dem 2026-08-30 als Unterdrueckung — mit
genau der Begruendung, die §1.5 fuer die allgemeine Form nennt. Offen war die
zweite Stelle, an der dasselbe Argument gilt, und die ist die schaerfere.

`unreferenced-module` traegt sein Gegenargument seit jeher im eigenen
Quelltext: *„a module may legitimately be reached only through the
aggregator's string map rather than a literal require"*. Das ist kein
Sonderfall-Vorbehalt, das ist eine Beschreibung von `lib.nvim` — dessen ganze
Oberflaeche laeuft ueber `strategies/metatable.lua`, eine Namens-zu-Modulpfad-
Tabelle, die erst beim Zugriff requiret. Es gibt dort **kein** literales
`require`, das ein statischer Scan finden koennte. Der Check meldete diese
Module seither dauerhaft als verdaechtig.

*Was ausgeliefert wurde*: `loaded_diff.loaded_modules(opts)` — die grobe Frage
(*war dieses Modul ueberhaupt geladen*) neben dem Feld-Diff, den `rows` schon
beantwortet (*welche exportierten Funktionen liegen auf der Tabelle*).
`check_orphans` liest sie und ueberspringt, was die Evidenz deckt.

**Die eine Entwurfsentscheidung, die es wert ist, behalten zu werden: der
laufende Prozess ist die falsche Quelle.** `package.loaded` im Prozess, der
den Check ausfuehrt, ist vom Check selbst verunreinigt — `core/scan.lua`
requiret die Module des gepruefften Baums, um sie zu lesen. Ein Selbst-Scan
faende also fast alles „geladen" und unterdrueckte jeden Befund. Evidenz, die
durch die Beobachtung entsteht, ist keine Evidenz. Gelesen wird stattdessen
der **neueste Snapshot** — absichtlich genommen, in einer Sitzung, in der
jemand tatsaechlich gearbeitet hat.

*Gemessen an genau dem Baum, um den es geht.* `lib.nvim` gescannt, zehn seiner
Module geladen als Platzhalter fuer eine Sitzung: **71 Befunde vorher, 68
nachher, 0 neu erzeugt**. Die drei unterdrueckten sind exakt die vorhergesagte
Form — `lib.strategies.metatable` (der Aggregator selbst), `lib.lua.memo.memo`
und `lib.nvim.frecency`, dessen einzige Konsumenten in anderen Repos liegen.
Eine echte Sitzung laedt Hunderte statt zehn.

*Unterdrueckung, nie Eskalation* — die Linie aus `PLAN.md` §7, jetzt an einer
zweiten Stelle festgeschrieben: kein Snapshot, kein `runtime-analysis`, kein
eindeutiger Root-Prefix — jedes davon laesst den Check exakt so arbeiten wie
bisher. Das ist auch CIs Normalzustand.

*Verifiziert*: alle vier Gates gruen, neunzehn Assertions im neuen
`loaded_suppression_spec.lua`. Vier davon decken die Abwesenheitsfaelle ab —
kein Snapshot, kein runtime-analysis, eine werfende Probe, ein unlesbarer
Snapshot — weil „keine Daten aendern nichts" die Eigenschaft ist, die eine
Unterdrueckung sicher macht, und die still bricht.

*Nachgezogen, damit die Beschreibung nicht wieder driftet*: `IDEAS.md` §1.5 in
`runtime-analysis.nvim` las sich weiter wie ein Entwurf und nennt jetzt beide
Instanzen samt der zwei **verschiedenen** Routen (Telemetrie fuer die eine,
`loaded`-Snapshot fuer die andere).

*Bindings-Zettel*: nicht beruehrt. Kein Usercmd, keine Taste.

---

### M11 · `images.nvim` + casedesk — OCR, und wofuer sie eigentlich da ist

**Erledigt am 2026-08-31. `images.nvim` `9a8ff03` (+ `2f8da54` stylua),
`nvim-config` `a118958e`.**

**Der Eintrag hat den Nutzen an der falschen Stelle gesucht.** Er begruendete
M11 mit *Uebersetzung*: fremdsprachige Fehlermeldung, Text heraus, uebersetzen.
Das ist die kleinere Haelfte. Die groessere ist casedesk: `attachments.lua`
legt Kundendateien als Pixel unter `assets/` ab, und ab da ist ein Screenshot
fuer **jedes** textbasierte casedesk-Feature unsichtbar — `:Cases grep` findet
die Fehlermeldung nicht, `:Case ki` kann sie nicht in den Prompt legen, und der
einzige Weg, sie zu benutzen, ist Abtippen. Ein Tosca-Kunde schickt den
Screenshot einer Exception; der Stacktrace darin ist genau das, was den Case
identifiziert. Gebaut wurde deshalb beides, in einer Sitzung.

**Und der Punkt war kleiner als sein Aufwand-M, aus dem Grund, den der Eintrag
selbst vermutet hatte.** `language.translate`s oeffentliche Einstiege sind alle
bufferbezogen (`run_region` will `bufnr` plus Koordinaten). Landet der Text in
einem Buffer — und das will man ohnehin —, dann **ist** `:Translate` auf der
Visual-Selection schon die Kreuzung, ueber Tasten, die es gibt. Es wurde keine
Zeile Bruecke geschrieben; `images/ocr.lua` macht OCR und hoert dort auf, wo
ein Buffer anfaengt. Dazu kam, dass `convert.lua` das Muster fuer ein externes
Binary bereits vollstaendig vorgibt (argv, async `vim.system`, `vim.schedule`,
Callback) — `M.export` war eine 15-Zeilen-Vorlage.

*Was ausgeliefert wurde, Teil 1 — `images.nvim`*: `:Image ocr [path]
[--lang=<code>]`. Ohne Pfad das Bild unter dem Cursor, wie `info`/`export`/
`redact`. Das Ergebnis kommt in einen Scratch-Split mit `filetype=markdown`,
benannt nach dem Quellbild und wiederverwendet — ein zweiter Lauf auf demselben
Screenshot ersetzt das vorige Ergebnis, zwei verschiedene Bilder bekommen zwei
Buffer. SVG geht durch die vorhandene, gecachte SVG→PNG-Umwandlung, weil
tesseract nur Rasterformate liest.

**Ein Split, kein Popup**, und das ist die Entwurfsentscheidung, die den Rest
traegt: `:Image info` nimmt `kit.viewer`, `:Image zen` einen Float — beide sind
zum *Anschauen*. Erkannter Text ist Rohmaterial. Man korrigiert ein verlesenes
Zeichen, markiert einen Absatz und drueckt `:Translate`, yankt einen Stacktrace,
schreibt ihn neben ein Ticket. Ein Fenster, das auf `q` zugeht, ist fuer alles
davon falsch.

*Was ausgeliefert wurde, Teil 2 — casedesk*: `:Case ocr [nr] [--force]
[--lang=<code>]` schickt jedes Bild unter `assets/` durch `images.ocr` und
schreibt das Ergebnis als `<bild>.ocr.md` **neben** das Bild. Diese eine
Entscheidung ist die ganze Arbeit: `query.grep` laeuft ohnehin rekursiv ueber
jede `*.md` unter einem Case-Verzeichnis (`collect_recursive.files` ohne
Ausschluesse, gegen den Quelltext geprueft), also wird der erkannte Text
greppbar, **ohne dass dort eine Zeile geaendert werden musste**. Der Sidecar ist
ein gewoehnliches Dokument, kein Cache: H1, relativer Bildlink zurueck zur
Quelle, Vorbehalt als Blockquote, dann der Text — von Hand korrigierbar.

**Zwei Befunde, die der Eintrag nicht kennen konnte, weil sie erst beim
Nachsehen auf der Maschine auftauchten.**

*Erstens: „tesseract wird als vorhanden angenommen" war eine Haltung, keine
Tatsache.* Der UB-Mannheim-Installer — derselbe, den `install.json` jetzt
nennt — laesst sein „Add to PATH" ungehakt. Auf dieser Maschine lag
tesseract 5.4.0 unter `C:/Program Files/Tesseract-OCR/`, und weder Machine-
noch User-PATH kannten es. Der Fehler sieht dann exakt aus wie „nicht
installiert", direkt nachdem man installiert hat. PATH wird weiterhin zuerst
gefragt; die zwei bekannten Verzeichnisse werden nur geprueft, wenn PATH leer
bleibt, und `ocr.bin` schlaegt beides. `:checkhealth images` druckt, **welcher**
der drei Wege gegriffen hat — „gefunden" allein wuerde verschweigen, dass die
Shell `tesseract` immer noch nicht ausfuehren kann.

*Zweitens: die Sprachdaten sind ein eigener Download.* Installiert waren `eng`
und `osd`, kein `deu`. Ein falsches `-l` ist damit ein Normalzustand, kein
Tippfehler — die Meldung nennt deshalb, was **statt dessen** da ist, und
`:checkhealth` prueft `ocr.lang` teilweise (`"deu+eng"` scheitert an jeder
Haelfte einzeln).

**`:Case ki` bekommt den Text mit — `:Case similar` bewusst nicht.** Der Prompt
bekommt einen eigenen Abschnitt „Text aus den Screenshots (maschinell
gelesen)", neben `{facts}`, aber ausdruecklich nicht als dieselbe Klasse von
Beleg: Fakten sind aus Dateien geparst, die der Kunde geschickt hat, das hier
ist aus Pixeln geraten, und ein Modell muss den Unterschied sehen koennen, sonst
argumentiert es souveraen ueber eine verlesene Versionsnummer. Gelesen wird nur,
was schon auf Platte liegt; `:Case ki` startet nie selbst eine OCR — ein
Ein-Tasten-Befehl still in einen halbminuetigen tesseract-Lauf zu verwandeln
waere ein anderer Befehl unter demselben Namen.

`:Case similar` bleibt aussen vor, und das ist kein Vergessen: das Ranking ist
TF-IDF ueber `Summary.md` + `Notes.md`, und TF-IDF gewichtet **seltene**
Begriffe am hoechsten. Ein verlesenes Wort („Excepticn", „l0cked") ist
konstruktionsbedingt der seltenste Begriff im ganzen Korpus — jeder
Erkennungsfehler landete also mit maximalem Gewicht im Ranking. Das waere nicht
bloss nutzlos, sondern schaedlich.

*Die kleine Entscheidung, die sich noch auszahlen wird*: ob neu gelesen wird,
entscheidet die **mtime**, nicht blosse Existenz. `:Image redact` und
`:Case normalize` schreiben Attachments in place, und ein Sidecar vom Stand
*vor* der Schwaerzung waere schlimmer als gar keiner — er bewahrte genau den
Text auf, der unkenntlich gemacht wurde. Zweiter Lauf ueber denselben Case
kostet damit nichts (`skipped`), `--force` liest trotzdem alles neu. Und
gelaufen wird strikt ein Bild nach dem anderen: tesseract ist CPU-gebunden, ein
Case hat auch mal zwei Dutzend Anhaenge, und die Warteschlange ist keine
Sekunde langsamer als zwei Dutzend gleichzeitige Prozesse auf der Maschine, an
der gerade gearbeitet wird.

*Verifiziert*: `images.nvim`s Suite gruen, 23 Specs inklusive des neuen
`ocr_spec.lua` — das die Erkennung wirklich prueft, indem es sich mit
ImageMagick ein Bild mit bekanntem Text baut, statt „irgendetwas kam zurueck"
zu behaupten. End-to-end auf der echten Maschine: `:Image ocr` auf einem
erzeugten Screenshot liefert „Tosca error 4711 / Workspace locked", die
Flag-Form und der Sprachfehler ebenso; `:Case ocr` schreibt den Sidecar,
ueberspringt ihn beim zweiten Lauf und `render` baut den Prompt-Block. `stylua`
und `luacheck` sauber in beiden Repos.

*Bindings-Zettel*: nachgezogen. `docs/BINDINGS.md` (images.nvim),
`docs/NOTES/casedesk/Usercmds.md` (neue Zeile plus die `:Cases grep`-Zeile, die
seit heute nicht mehr stimmte), `docs/NOTES/casedesk/Workflow.md` §2,
`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Case.md` (Verbliste) und
`lua/bindings/usrcmds/case/docs/FEATURES.md`.

---

### M13 · `images.nvim` — Bildoperationen als Dateioperationen

**Erledigt am 2026-08-31. `images.nvim` `9d9a297`.**

**Die Namensfrage ist entschieden: `:Image`, nicht `:File`.** Der Eintrag stand
unter „ein Befehl, alle Operationen" und deutete damit auf `fileops.nvim`;
gebaut wurde unter `:Image`, und die Gruende sind beide praktisch. Die drei
vorhandenen Schreiboperationen (`export`, `redact` — und seit M11 `ocr`) liegen
schon dort, und `resolve.path_or_cursor` loest genau das Argument auf, das man
tippen will: das Bild unter dem Cursor. `fileops.nvim` haette beides erst
bekommen muessen. Beide Verben zu bedienen waere Doppelpflege gewesen.

*Was ausgeliefert wurde*, alle drei in `convert.lua` statt in einem neuen
Modul — dessen eigener Kopfkommentar nennt den Grund bereits: dieselbe
`magick`-Abhaengigkeit, dieselbe argv-plus-async-`vim.system`-Form, dieselbe
Fehlerbehandlung. Nach Thema getrennt waeren es zwei Module mit je einem
identischen Fehlerpfad geworden.

| | schreibt | |
|---|---|---|
| `:Image scale <size> [path]` | `photo.scaled.png` | `50%`, `800x600`, `800x`, `x600`, `800x600!` |
| `:Image optimise [path] [--quality=<n>]` | `photo.optimised.png` | Metadaten weg, beste Kompression |
| `:Image convert <format> [path]` | `photo.<format>` | gleicher Stamm, `<Tab>`-vervollstaendigt |

**Die Entscheidung, die den Punkt vor einem stillen Fehlschlag bewahrt: die
Geometrie wird in Lua geprueft, bevor `magick` laeuft.** `magick` behandelt ein
unlesbares `-resize`-Argument als *gar keine* Groessenaenderung und beendet sich
mit 0. Ein Tippfehler haette also eine `.scaled.`-Kopie in Originalgroesse
erzeugt — mit jedem Anzeichen von Erfolg. Genau dieselbe Klasse von Problem wie
bei `:Image ocr`s Sprachfehler: das externe Werkzeug ist zufrieden, das
Ergebnis ist falsch, und nur der Aufrufer kann den Unterschied kennen.

**`optimise` loescht ein Ergebnis, das nicht kleiner ist.** Wer optimiert,
will eine kleinere Datei; ihm eine groessere zu geben und das Erfolg zu nennen
waere eine Luege, und sie neben dem Original liegen zu lassen ist Muell, den er
danach wegraeumt. Die Meldung nennt beide Groessen so oder so — „schon optimal"
kommt mit Zahlen statt als Achselzucken.

*Was `-strip` tatsaechlich entfernt, und warum das der Punkt ist*: EXIF,
Farbprofile — und bei einem Screenshot den Fenstertitel. Das ist die
Metadatenzeile, an die niemand denkt, bevor er ein Bild an ein Ticket haengt.
PNG bekommt zusaetzlich ImageMagicks hoechste Kompressionsstufe, die
definitionsgemaess verlustfrei ist. JPEG wird in jedem Fall neu kodiert —
`magick` kann ein JPEG nicht strippen, ohne es zu dekodieren; ohne `--quality`
uebernimmt ImageMagick die Qualitaetseinstellung der Quelle, was diese
Neukodierung so nah an einen No-Op bringt, wie das Format es zulaesst.

*Die Quelle wird nie in place bearbeitet* — dieselbe Haltung wie bei `redact`,
und aus demselben Grund: das sind Anhaenge, ein Screenshot, den ein Kunde
geschickt hat. Eine Operation, die das Original ueberschreibt, ist ein
Rueckgaengig von verlorenem Beweismaterial entfernt. `convert` ist der einzige,
der auf einen existierenden Namen treffen kann, und er verweigert genau den
Fall, in dem Ziel und Quelle dieselbe Datei waeren.

*Ein PDF-Pfad, nicht zwei*: `:Image convert pdf` laeuft durch `to_pdf` —
inklusive `pdfport.nvim`s verlustfreiem `img2pdf`, wenn es installiert ist.
Zwei Wege, ein PDF zu erzeugen, die sich unterschiedlich verhalten, waeren
genau die Drift, vor der die Docs dieses Repos staendig warnen.

*Zur Namenskollision, die keine ist*: `images.scale` ist ein anderes Modul —
reine Anzeige-Arithmetik (Zellen, Seitenverhaeltnis, Anker), das nie eine Datei
anfasst. Der Befehl heisst trotzdem `:Image scale`, weil das das Wort ist, nach
dem man greift; die interne Funktion heisst `convert.resize`, damit Prosa ueber
`images.scale` weiter genau eine Sache bedeutet. In den Modul-Docs, der Vimdoc
und `M.scale`s Kommentar festgehalten.

*Verifiziert an einem echten 1,1-MB-Foto*: 3968×2640 → 800×532 bei 91 KB,
`--quality=60` → 437 KB, jpg→png sauber, jpg→jpg korrekt verweigert
(„shot.jpg is already jpg"). Suite gruen, `convert_spec.lua` um 40 Assertions
erweitert, darunter beide Ausgaenge von `optimise` (geschrieben *oder*
geloescht) und der Nachweis, dass die verkleinerte Datei wirklich schmaler ist
statt nur zu existieren. `stylua` und `luacheck` sauber ueber alle 59 Dateien.

*Bindings-Zettel*: `docs/BINDINGS.md` um drei Zeilen erweitert, Vimdoc um
`images-fileops` plus drei API-Eintraege, und `doc/tags` neu erzeugt — dabei
fiel auf, dass die OCR-Tags aus M11 dort noch fehlten.

---

### M17/QW6 · `documentation.nvim` — Fenced Blocks auf der generierten Seite

**Erledigt am 2026-08-31. `documentation.nvim` `ccab142`, `docmap-desktop`
`69125b3`.**

**Zum ersten Mal lag eine Beschreibung nach der *anderen* Seite daneben.** Acht
von zwoelf Eintraegen dieses Verbunds waren inzwischen falsch, und alle bisher
in dieselbe Richtung: schon gebaut, groesser als gedacht, kleiner als gedacht.
Dieser hier war zu *pessimistisch*. Die Features-Tab hat Fences schon immer
gesplittet — `renderFeatureBody` matcht `/^```/`, seit es sie gibt. Sie hat
dabei nur ihr eigenes `<pre><code>` geschrieben und die Sprache weggeworfen,
ein Zeichen bevor sie gebraucht wurde: das Muster sagte „hier faengt ein Fence
an" und nichts fing das `lua` danach ein. Zu bauen war also nicht „ein
Fence-Renderer", sondern „einer statt zweier, und mit der Sprache".

*Was ausgeliefert wurde*: ein `fenceHTML(src, lang)`, die Features-Tab
darauf umgeleitet, und die beiden Oberflaechen verkabelt, die ueberhaupt nicht
splitteten — der `@description`-Rumpf eines Moduls (ueber ein neues
`richText`, das an Fences trennt und alles andere an `prose` weiterreicht) und
`@example` (ueber `exampleHTML`).

**Die Entscheidung, die alles traegt: die Hervorhebung benutzt
`snipBodyHTML` wieder** — den Tokenizer, den die Quelltext-Ausschnitte auf
derselben Seite schon verwenden. Er ist glossargesteuert, kennt Strings und
Kommentare und ist nach Dateiendung geschluesselt; die Info-Zeichenkette eines
Fences *ist* diese Endung fuer die meisten Sprachen, also reicht ein
synthetischer Pfad `fence.lua`, um ihn ganz wiederzuverwenden. Die Folge ist
der Punkt: ein `lua`-Fence und ein Lua-Ausschnitt sehen identisch aus, teilen
die Keyword-Karte, und jede kuenftige Sprache faellt in dem Moment an, in dem
ein Backend sie deklariert.

*Und deshalb ausdruecklich **nicht** im Erzeuger* — die Variante, die vor dem
Bauen zur Wahl stand. Fertiges Markup in Lua vorzuberechnen haette (1) dieselbe
Lua-Zeile auf einer Seite zweimal verschieden ausgesehen lassen, (2)
Praesentation in eine Datenstruktur gelegt, die auch `docmap-desktop` und die
MCP-Schicht lesen, und (3) dem eigenen Kopfkommentar von `html.lua`
widersprochen: *„the IR is embedded as JSON rather than being expanded into
markup at generation time"*. Nachgesehen hat den Ausschlag gegeben, dass die
Detailansicht ohnehin **im Browser** aus dem JSON gerendert wird — der
„Erzeuger" ist bei dieser Seite gar nicht die Stelle, an der Markup entsteht.

**Ein Fehler, der beim Verkabeln auffiel, und er war einen Satz davon entfernt,
verhindert zu sein.** Die Keyword-Karte suchte ihr Glossar ueber
`closest(".fn-snip")` — ein dekoriertes Schluesselwort irgendwo sonst, also ab
sofort in einem Fence, haette keinen Container gefunden, kein Glossar gelesen
und beim Klick nichts gezeigt. Der Kommentar von `snippetHTML` beschreibt die
Absicht laengst: *„the path rides on the container … and the lookup walks up to
it, which is what `.closest` is for."* Als Klassenname geschrieben hiess das
still „und nur Ausschnitte". Der Selektor sagt jetzt `[data-path]`.

*Bewusst unveraendert*: ein `@example` ohne Fence bleibt escapt und sonst
nichts — ein Backtick in einem Shell-Beispiel ist ein Backtick, und `prose()`
darueber wuerde Markup erfinden. Ein nicht geschlossener Fence kommt genau so
zurueck, wie er dasteht, Eroeffnungszeile eingeschlossen: dieselbe Haltung, die
`prose()` bei einem unpaarigen Backtick einnimmt, aus demselben Grund — ein
halber Block ist ein Tippfehler, und ihn zu schlucken versteckt genau das, was
der Autor sehen muss.

**Gemessen, und die Zahl steht nicht in diesem Repo.** 5 Modul-Rumpfe hier
tragen einen Fence, `@example`-Bloecke gibt es **null** — das ist QW8s Zaehlung
vom August, unveraendert, und fuer sich genommen liesse das den Punkt
kosmetisch aussehen. Die Auszahlung liegt in den Features-Korpora:
**`lib.nvim` allein hat 43 ```` ```lua ````-Bloecke** unter `docs/FEATURES/`,
von denen bis heute jeder undekoriert gerendert wurde, dazu vier in
`filetree.nvim`. Das sind die Seiten, die jemand tatsaechlich liest, um eine
API zu lernen.

*Verifiziert*: die Suite gruen, und der neue `fence_render_spec.lua` hebt den
reinen Renderer aus der eingebetteten `JS`-Zeichenkette heraus und laesst ihn
in **node** gegen echte Eingaben laufen — 24 Zusicherungen ueber Hervorhebung,
Alias-Namen, Degradation bei unbekannter Sprache, Escaping, offene Fences,
`@example` und das Ueberspringen von Strings und Kommentaren. Ohne node
ueberspringt er, statt zu scheitern. Sein Nachbar `prose_render_spec.lua`
beginnt mit dem Satz, dass keine Lua-Spec ein `<code>`-Element sehen kann, und
begnuegt sich mit der Verkabelung; das war die ehrliche Antwort auf das, was
er erreichen konnte, und diese hier muss sich nicht mehr begnuegen. Die
Verkabelungshaelfte bleibt trotzdem — als Zusicherung, dass nie wieder jemand
sein eigenes `<pre><code>` schreibt.

*Bindings-Zettel*: nicht beruehrt. Kein Usercmd, keine Taste, keine Autocmd.

---

### M12 · `runtime-analysis.nvim` + `images.nvim` — Flamegraphs als Bild

**Erledigt am 2026-08-31. `runtime-analysis.nvim` `d7def81`.**
**Die zweite Haelfte des Eintrags bleibt offen und heisst jetzt M12b** — siehe
unten, sie war keine Kreuzung, sondern ein eigener Punkt.

**Der Eintrag setzte einen Flamegraph voraus, den es nicht gab.** „In 60×25
Zellen nur eine grobe Uebersicht — aber das Bild landet ohnehin als Datei auf
der Platte" beschreibt eine *Darstellungsumstellung*. `grep -i flame` ueber
`runtime-analysis.nvim` war leer: kein Modul, kein Befehl, nicht einmal das
Wort. Wie geschrieben haette der Punkt „einen Profiler bauen" bedeutet, und das
ist ein L.

**Was es stattdessen gab, und zwar genau richtig geschnitten**:
`telemetry/startup.lua` umhuellt das globale `require`, misst jeden Cache-Miss
gegen einen Stack, und jeder Eintrag traegt `depth`, `total_ms` und ein
`self_ms`, aus dem die Kinder herausgerechnet sind. Das *ist* ein Flamegraph —
Breite ist Zeit, Tiefe ist Verschachtelung, und der unbedeckte Streifen eines
Elternteils ist seine Eigenarbeit. Gefehlt hat nur das Bild. Der Punkt wurde
damit zu einem dritten Renderer neben `lines()` und `markdown()`, ueber
denselben Report.

*Ausgeliefert*: `:RATelemetry flamegraph [path]`, gerendert von
`telemetry/renderers/flamegraph.lua` — dort, wo `renderers/html.lua` und
`renderers/mdview.lua` schon liegen.

**Der Baum wird rekonstruiert, nicht aufgezeichnet, und das ist die eigentliche
Einsicht.** `startup.lua` speichert keinen Elternzeiger — nur eine Tiefe. Es
braucht auch keinen: Eintraege werden angehaengt, wenn ein Laden **beginnt**,
die Liste ist also eine Preorder-Traversierung, und Preorder plus eine Tiefe
pro Knoten legt den Baum eindeutig fest. `M.tree` laeuft sie mit einem Stack
ab, der nach Tiefe indiziert ist — derselbe Stack, den der Rekorder benutzt
hat, nachtraeglich wiederhergestellt.

*Und deshalb hat der Report ein `order` bekommen*: `modules` ist nach
Selbstzeit sortiert und wird von `top` abgeschnitten. Beides zerstoert die
Rekonstruktion — Sortieren verliert die Preorder, `top` wirft ganze Teilbaeume
weg — und **beides erzeugt trotzdem ein plausibel aussehendes Bild**. Das ist
der gefaehrliche Teil, und `order` existiert, damit es nicht passieren kann.

*SVG, weil es Text ist*: diffbar, ohne Bildbibliothek erzeugbar, und scharf bei
jedem Zoom — was hier zaehlt, weil die interessanten Frames die schmalen sind.
**Die images.nvim-Kreuzung brauchte daraufhin null Zeilen Code**: `:Image show`
wandelt SVG ohnehin ueber seinen gecachten Pfad in PNG um, gegen eine echte
Aufzeichnung geprueft (1200×186, 18 KB). Der Befehl bevorzugt images.nvim und
faellt sonst auf den System-Opener zurueck.

**Ein Fehler, der nur auf die eine Art zu finden war: das Ergebnis rastern und
hinsehen.** Die Farben waren als `hsl()` aus einem Hash der Modulwurzel
berechnet — im Browser korrekt, durch ImageMagicks librsvg-Delegate **komplett
schwarz**, weil dieses `hsl()` in einem `fill` nicht implementiert und auf den
Initialwert zurueckfaellt. Genau dieser Delegate ist der Weg, ueber den
images.nvim die Datei zeichnet: der Hauptkonsument haette schwarze Kaesten mit
schwarzer Schrift darauf bekommen. Jetzt eine feste Hex-Palette, per Spec
festgenagelt, damit es nicht als „schoenere Farbberechnung" zurueckkommt.

*Gemessen an einer echten Aufzeichnung* (33 Module ueber fuenf Plugin-Wurzeln,
sechs Ebenen tief, 22 ms): die Breiten verschachteln sich korrekt, die Labels
kuerzen sauber, eine Farbe pro Wurzel, Legende darunter — und das PNG ist
lesbar.

*Verifiziert*: Suite gruen, `flamegraph_spec.lua` neu — die Baumrekonstruktion
gegen handgebaute Sequenzen mit bekannter Form (verschachtelt, flach,
Tiefensprung), das SVG nur auf die Eigenschaften, auf die sich ein Leser
verlaesst (jeder Frame da, Inhalt escapt, leerer Fall sagt warum, keine
`hsl()`), und die `order`-Invariante gegen echte `require`-Aufrufe mit `top=1`
und `sort="name"`. Bewusst **nicht** auf Pixelgeometrie — das ist
Layout-Geschmack und wuerde bei jeder Anpassung brechen.

*Bindings-Zettel*: `docs/BINDINGS.md` um die Zeile erweitert;
`docs/FEATURES/TELEMETRY.md` um den Abschnitt. `install.json` unveraendert —
der Renderer braucht kein externes Werkzeug, `magick` deklariert images.nvim
fuer seinen eigenen SVG-Schritt selbst.

**Offen geblieben, als eigener Punkt M12b**: „Dieselbe Grafik gehoert
zusaetzlich in `documentation.nvim`, wo der Abschnitt fuer Runtime-Daten heute
nur Text zeigt." Nachgesehen, und das ist keine Kreuzung, sondern ein zweiter
Punkt: `documentation.nvim`s Telemetry-Panel verbindet **Aufrufzaehler pro
Funktion** mit der IR (`core/api.lua`, `telemetry_join`). Startup-Daten
kommen dort ueberhaupt nicht vor — es gibt keinen Abschnitt, in den das Bild
gehoerte, sondern es braeuchte einen eigenen Endpunkt und ein eigenes
Analysis-Werkzeug. Der Eintrag las sich, als gaebe es die Oberflaeche schon.

---

## Zurueckgestellt

Punkte, die aus `PLUGIN_ROADMAPS.md` heraus sind, ohne gebaut worden zu sein.
Nicht geloescht: ein Punkt, der still verschwindet, kommt in einem halben Jahr
als neue Idee wieder, und dann fehlt die Begruendung, die es schon einmal gab.

---

### M4b · `lsp.nvim` — der Picker-Adapter (Roadmap-Abschnitt 7)

**Zurueckgestellt am 2026-08-30. Nicht gebaut, nicht geplant.**

*Was er waere*: `lsp.integrations.picker` zu einer echten Abstraktion ueber
fzf-lua, telescope, snacks und pickers.nvim ausbauen, die vier Picker-Keymaps
und `:TypeDefPick` darueber routen, und darauf dann Workspace-Symbole und Call
Hierarchy anbieten. Aufwand L, nicht das M, das an M4 stand.

**Warum zurueckgestellt, und zwar in dieser Reihenfolge:**

1. **Es gibt nichts mehr zu abstrahieren.** Eine Abstraktion ueber N Backends
   lohnt sich, wenn N > 1 *benutzt* wird. Nach M4a benutzt dieses Plugin fuer
   Symbol- und Diagnostics-Listen genau eines: fzf-lua. Der Adapter wuerde eine
   Indirektion mit einer einzigen Implementierung dahinter einziehen — genau
   das, was `integrations/picker.lua` in seinem eigenen Docstring als
   nutzlos abgelehnt hat („an indirection with a single implementation behind
   it buys nothing"). M4a hat das Problem nicht geloest, das M4b loesen wollte;
   es hat es **entfernt**.
2. **Die Faehigkeit, die M4 zusaetzlich versprach, ist eine Zeile.** Call
   Hierarchy existiert im Repo nirgends — aber fzf-lua bringt
   `lsp_incoming_calls` und `lsp_outgoing_calls` mit. Wer sie will, braucht
   zwei Katalogeintraege im Muster der vier vorhandenen, kein
   Abstraktionsgeruest. Das ist ein XS-Punkt, kein L-Punkt, und er haengt nicht
   an M4b.
3. **Der Nutzen ist hypothetisch.** Er faellt erst an, wenn jemand den Picker
   *wechselt*. Das ist bisher nicht passiert und steht auf keiner Liste.

**Was ihn wieder aufmachen wuerde** — und das ist der Punkt, an dem er hier
herausgeholt gehoert, nicht neu erfunden:

- Ein zweiter Picker kommt tatsaechlich in Gebrauch (snacks.picker verdraengt
  fzf-lua, oder eine zweite Maschine fuehrt einen anderen).
- Oder: die vier Keymaps sollen konfigurierbar werden, statt als
  `<cmd>FzfLua …<cr>`-Strings im Katalog zu stehen — dann ist der Adapter die
  Form, die diese Konfiguration bekommt.

Bis dahin ist die ehrliche Antwort auf „welchen Picker benutzt lsp.nvim" ein
Name und keine Schnittstelle.


---

### M17/M12 · `documentation.nvim`-Verbund — Runtime-Tab im ausgelieferten Artefakt

**Zurueckgestellt am 2026-08-30. Nicht gebaut — weil die Substanz schon
gebaut ist.**

*Was er waere*: „`ECOSYSTEM.md` §7 surface 2 — ein Runtime-Reiter, **immer**
zur Laufzeit gefuellt, nie eingebacken." Aufwand M, drei Repos.

**Gegen den Quelltext geprueft, und die Beschreibung stimmt nicht mehr:**

1. **Die Oberflaeche existiert.** `core/render/html.lua` liefert `Telemetry`
   und `Loaded` als `plugin-gated` Analysis-Werkzeuge, die ihre Daten zur
   **Ansichtszeit** per `fetch("/api/telemetry")`, `/api/loaded` und deren
   `…/snapshots`-Geschwistern holen. Nichts eingebacken, das
   Byte-Vergleichs-Gate bleibt unberuehrt.
2. **Der ehrliche Leerzustand ist sogar Prinzip.** `core/api.lua` schreibt ihn
   als Regel fest: *„Absence answers `{ available = false, reason = … }` … A
   panel that says why it is empty beats one that is silently blank."*
3. **Beide Hosts antworten.** `editor/serve.lua` in Neovim,
   `docmap-desktop/src-tauri/src/server.rs` ausserhalb.
4. **Auch §7s Surface 1 ist da**, die das Dokument als „start here" markiert:
   `:DocBrowse` hat die Modi `telemetry` (8) und `loaded` (9).

*Was tatsaechlich offen bleibt*, ist keine Oberflaeche, sondern eine
**Gruppierung**: die zwei Panels liegen unter siebzehn Analysis-Werkzeugen
statt unter einem eigenen Top-Level-Reiter. Das ist XS–S, nicht M.

**Was ihn wieder aufmacht**: der erste von M8 bis M11. Dann bekommt der Reiter
einen dritten Bewohner, und die Umgruppierung traegt sich selbst. Vorher ist
sie ein beschrifteter Rahmen um zwei Panels — Aufwand vor Nutzen.


---

### M17/M7b · `documentation.nvim` — ein Scope ist kein Knoten

**Zurueckgestellt am 2026-08-31. Nicht gebaut — stattdessen wurde der Befund
ausgeliefert, siehe [M17/M7c](#m17m7c-documentationnvim--der-befund-statt-des-umbaus).**

*Was er waere*: aus einem Scope einen Knoten machen. Ein Rust `mod x { … }`,
ein zweites `defmodule` in einer `.ex`-Datei bekaemen eine eigene `id`, eine
eigene Summary, eigene Coverage und eigene Kanten, statt als Gruppierung unter
ihrer Datei zu haengen. Der Report fuehrte ihn als **M** und als den einzigen
verbliebenen Punkt, der *falsch* statt *fehlend* ist.

**Warum zurueckgestellt, und zwar in dieser Reihenfolge:**

1. **Es ist kein M, es ist ein L.** `Documentation.Node.id` **ist** der
   repo-relative Pfad — im Walk, in `stats`, in `parent`/`children`, in jeder
   `id`, im ausgelieferten Artefakt. Ein Knoten, der kein Pfad ist, bricht
   diese Invariante an 31 Lua-Dateien des Plugins und 23 Stellen im
   Rust-Server von `docmap-desktop`, dazu Schema-Bump und beide Konsumenten.
2. **Der Nutzen im eigenen Korpus ist null — nachgezaehlt, nicht geschaetzt.**
   `docmap-desktop` ist der einzige Rust-Baum unter den 31 Repos und haelt elf
   Inline-Module, davon elf `mod tests`. Elixir kommt in keinem Repo vor. Der
   Rest ist Lua, eine Sprache ganz ohne diese Konstruktion. Gebaut, wuerde
   M7b zuerst Test-Module zu Knoten befoerdern und den Baum damit
   verschlechtern.
3. **Die Quelle plant ihn selbst nicht ein.** `docmap-desktop/docs/PLAN.md`
   schreibt bei M7b woertlich „not scheduled by that argument alone" — der
   Eintrag stehe da, damit die Form der Antwort aufgeschrieben ist, falls die
   Frage je gestellt wird. Beim Hochstufen in den konsolidierten Report ist
   dieser Satz verlorengegangen.

**Was ihn wieder aufmachen wuerde:**

- Ein Rust- oder Elixir-Projekt mit echten Inline-Modulen wird kartiert — dann
  meldet `file-holds-many-modules` es von selbst, und der Befund ist die
  Wiedervorlage.
- Oder eine Frage wird tatsaechlich auf Modul-Identitaet geschluesselt: „was
  braucht dieses Modul", „wie dokumentiert ist es". Heute stellt sie niemand.
