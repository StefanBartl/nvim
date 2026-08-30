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
