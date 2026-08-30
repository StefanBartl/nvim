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
