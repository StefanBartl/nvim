# Plugin-Roadmaps — konsolidierter Report

Stand: 2026-08-29. Quelle: `docs/ROADMAP.md` bzw. `docs/ROADMAP/` aus allen 31
`*.nvim`-Repos unter `C:\repos`, plus die drei Dokumente, auf die diese
Roadmaps als eigentliche Warteschlange verweisen (`docmap-desktop/docs/PLAN.md`
sowie die damaligen `images.nvim`-CROSS-PLUGIN- und
`lib.nvim`-dependency-installer-Notizen).

> **Wo die Quellen jetzt liegen.** Am 2026-08-29 wurden sämtliche
> `docs/ROADMAP`-Bäume aus den Plugin-Repos herausgelöst und nach
> `C:\repos\WKDBooks\Development\wkdbook-myplugins\<plugin>\ROADMAP\`
> verschoben — nichts gelöscht, 105 Dateien. Die Repos selbst tragen keine
> Verweise mehr darauf, weder Links noch Prosa-Zitate. Dateipfade wie
> `images.nvim/docs/ROADMAP/TERMINALS.md`, die dieser Report weiter unten
> nennt, meinen also den Stand *vor* dem Umzug; die Datei liegt heute unter
> `wkdbook-myplugins/images.nvim/ROADMAP/TERMINALS.md`. Einzige Ausnahme:
> `docmap-desktop/docs/PLAN.md` ist nie umgezogen und liegt weiterhin dort.

Dieser Report erledigt den offenen MERGED.md-Punkt *"Pro offenem
ROADMAP-Punkt einen konkreten Umsetzungsplan ausarbeiten"* für die
Plugin-Seite: er sammelt jeden offenen Punkt, sagt, worin die Umsetzung
konkret besteht, und schätzt Aufwand und Nutzen.

---

## Table of content

  - [Legende](#legende)
  - [Kurzfassung](#kurzfassung)
  - [1.0 Erledigt](#10-erledigt)
    - [QW3 · `lsp.nvim` — Inlay-Hints-Toggle](#qw3-lspnvim-inlay-hints-toggle)
    - [QW4 · `lsp.nvim` — Diagnostics-Debounce auf `publishDiagnostics`](#qw4-lspnvim-diagnostics-debounce-auf-publishdiagnostics)
    - [QW7 · `lsp.nvim` — "installed vs. attached"-Zeile in `:checkhealth lsp`](#qw7-lspnvim-installed-vs-attached-zeile-in-checkhealth-lsp)
    - [QW9 · `images.nvim` — Trial-Run für die `reposcope.nvim`-Kreuzung](#qw9-imagesnvim-trial-run-fr-die-reposcopenvim-kreuzung)
  - [1.1 Quick Wins (XS–S, Nutzen mittel bis hoch)](#11-quick-wins-xss-nutzen-mittel-bis-hoch)
    - [QW1 · `mdview.nvim` — `experimental.any_file` in echtem Neovim durchtesten](#qw1-mdviewnvim-experimentalany_file-in-echtem-neovim-durchtesten)
    - [QW5 · `lsp.nvim` — Hover-Cache über `lib.lua.memo`](#qw5-lspnvim-hover-cache-ber-libluamemo)
    - [QW6 · `lsp.nvim` — `formatter_priority` verkabeln oder als report-only festschreiben](#qw6-lspnvim-formatter_priority-verkabeln-oder-als-report-only-festschreiben)
    - [QW8 · `lsp.nvim` — Multi-Root-/Monorepo-Workspace-Switcher](#qw8-lspnvim-multi-root-monorepo-workspace-switcher)
  - [1.2 Mittel (M)](#12-mittel-m)
    - [M1 · `lsp.nvim` — Fehler provozieren als Testhilfe (`:LspDoctor deep`)](#m1-lspnvim-fehler-provozieren-als-testhilfe-lspdoctor-deep)
    - [M2 · `lsp.nvim` — Code-Action-Indikator](#m2-lspnvim-code-action-indikator)
    - [M3 · `lsp.nvim` — Auto-Restart mit Backoff bei Client-Crash](#m3-lspnvim-auto-restart-mit-backoff-bei-client-crash)
    - [M4 · `lsp.nvim` — Workspace-Symbol-/Call-Hierarchy-Picker über den `picker`-Adapter](#m4-lspnvim-workspace-symbol-call-hierarchy-picker-ber-den-picker-adapter)
    - [M5 · `lsp.nvim` — Sprung zur Lua-Tabellen-/Funktionswurzel (ehemals `<leader>gtt`)](#m5-lspnvim-sprung-zur-lua-tabellen-funktionswurzel-ehemals-leadergtt)
    - [M6 · `lsp.nvim` — Profile-Presets (`preset = "lean"|"default"|"full"`)](#m6-lspnvim-profile-presets-preset-leandefaultfull)
    - [M7 · `lsp.nvim` — Per-Projekt-Override (`.nvim-lsp.json` im Repo-Root)](#m7-lspnvim-per-projekt-override-nvim-lspjson-im-repo-root)
    - [M9 · `gopath.nvim` — Frecency-Lernen für Alternate-Vorschläge](#m9-gopathnvim-frecency-lernen-fr-alternate-vorschlge)
    - [M10 · `images.nvim` — Sixel-Backend](#m10-imagesnvim-sixel-backend)
    - [M11 · `images.nvim` — OCR-Kreuzung mit `language.nvim`](#m11-imagesnvim-ocr-kreuzung-mit-languagenvim)
    - [M12 · `images.nvim` — Flamegraphs als Bild (`runtime-analysis.nvim`)](#m12-imagesnvim-flamegraphs-als-bild-runtime-analysisnvim)
    - [M13 · `images.nvim` — Bildoperationen als Dateioperationen (`fileops.nvim`)](#m13-imagesnvim-bildoperationen-als-dateioperationen-fileopsnvim)
    - [M14 · `filetree.nvim` — `cwd_mode`-Badge optimieren](#m14-filetreenvim-cwd_mode-badge-optimieren)
    - [M16 · `lib.nvim` — `deps.health`-Migrationen](#m16-libnvim-depshealth-migrationen)
    - [M17 · `documentation.nvim` / `runtime-analysis.nvim` / `docmap-desktop` — M7 bis M13](#m17-documentationnvim-runtime-analysisnvim-docmap-desktop-m7-bis-m13)
  - [1.3 Groß (L)](#13-gro-l)
    - [L1 · `images.nvim` — Kitty-APC-Backend](#l1-imagesnvim-kitty-apc-backend)
    - [L3 · `lsp.nvim` — das Signature-Help-Modul schrumpfen](#l3-lspnvim-das-signature-help-modul-schrumpfen)
    - [L4 · `mdview.nvim` — das nvim-Highlighting im Browser spiegeln](#l4-mdviewnvim-das-nvim-highlighting-im-browser-spiegeln)
    - [L5 · `documentation.nvim`-Verbund — L1 bis L9 aus `PLAN.md`](#l5-documentationnvim-verbund-l1-bis-l9-aus-planmd)
  - [1.4 Braucht dich](#14-braucht-dich)
    - [BD2 · `open.nvim` — die Nicht-Windows-Reveal-Pfade auf echter Hardware prüfen](#bd2-opennvim-die-nicht-windows-reveal-pfade-auf-echter-hardware-prfen)
    - [BD3 · `lib.nvim` — Windows-Elevation im Dependency-Installer](#bd3-libnvim-windows-elevation-im-dependency-installer)
    - [BD4 · `mdview.nvim` — externe Renderer-Website (opt-in)](#bd4-mdviewnvim-externe-renderer-website-opt-in)
    - [BD5 · `mdview.nvim` — PDF-Seiten-Preview im Link-Hover](#bd5-mdviewnvim-pdf-seiten-preview-im-link-hover)
  - [2.1 Repos mit offener Arbeit](#21-repos-mit-offener-arbeit)
    - [`color_my_ascii.nvim` — zwei Konzepte ohne Umsetzungsentscheidung](#color_my_asciinvim-zwei-konzepte-ohne-umsetzungsentscheidung)
  - [2.2 Repos ohne offene Arbeit](#22-repos-ohne-offene-arbeit)
  - [3.1 Die Audit-Dokumente sind veraltet — und zwar systematisch](#31-die-audit-dokumente-sind-veraltet-und-zwar-systematisch)
  - [3.2 `ROADMAP.md` heißt in diesen Repos vier verschiedene Dinge](#32-roadmapmd-heit-in-diesen-repos-vier-verschiedene-dinge)
  - [3.3 Die Warteschlangen liegen zu dritt außerhalb der Roadmaps](#33-die-warteschlangen-liegen-zu-dritt-auerhalb-der-roadmaps)
  - [3.4 Zwei Punkte hängen aneinander und sollten zusammen gebaut werden](#34-zwei-punkte-hngen-aneinander-und-sollten-zusammen-gebaut-werden)

---

## Legende

**Aufwand** (Klassen wie in `docmap-desktop/docs/PLAN.md`, damit die Zahlen
vergleichbar bleiben):

| | |
|---|---|
| **XS** | unter einer Stunde |
| **S** | wenige Stunden |
| **M** | ein Arbeitstag oder mehr |
| **L** | mehrere Sessions |

**Nutzen**: hoch / mittel / niedrig — gemessen daran, ob der Punkt einen
echten Defekt schließt (hoch), eine vorhandene Fähigkeit verbessert (mittel)
oder eine neue, bisher nicht vermisste Fähigkeit hinzufügt (niedrig).

**Braucht dich**: der Punkt lässt sich nicht delegieren, weil er eine
laufende interaktive Session, fremde Hardware, ein anderes Betriebssystem
oder eine Namens-/Scope-Entscheidung verlangt.

---

## Kurzfassung

- **31 Plugins geprüft.** 20 davon haben **keine offene Arbeit** in ihrer
  Roadmap — die Datei ist entweder leer oder sagt ausdrücklich, dass alles
  ausgeliefert ist.
- **Offene Arbeit liegt in 8 Repos**: `lsp.nvim`, `images.nvim`,
  `mdview.nvim`, `open.nvim`, `filetree.nvim`, `gopath.nvim`, `lib.nvim`,
  sowie der Dreier-Verbund `documentation.nvim` / `runtime-analysis.nvim` /
  `docmap-desktop`.
- **Insgesamt 38 offene Punkte**, davon 4 Quick Wins (XS/S mit Nutzen
  mittel bis hoch) und 4, die dich brauchen. Vier weitere Quick Wins (QW3,
  QW4, QW7, QW9) sind erledigt und stehen unter 1.0.
- **Ein Querschnittsbefund, der Zeit spart**: die Audit-Dokumente
  (`Arch&Coding.md`, `Checklist.md`, `Zentral-Prinzipien.md`) in acht Repos
  führen noch Lücken (`❌`), die längst geschlossen sind — stichprobenhaft
  geprüft, und **alle fünf Stichproben waren veraltet**. Details in Teil 3.

---

# Teil 1 — Die offene Arbeit, nach Verhältnis sortiert

---

## 1.0 Erledigt

Fertige Punkte wandern hierher statt an Ort und Stelle abgehakt zu werden — so
bleibt 1.1 bis 1.4 eine Liste offener Arbeit und nicht eine Mischung aus
beidem.

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

**Vier Bedingungen, falls gebaut wird** (Aufwand: S–M, die Arbeit liegt in
reposcope, nicht in images.nvim): auf Anforderung statt automatisch; kein
Bild → kein Hover und kein Platzhalter; **Negativ-Cache** neben dem
Positiv-Cache, sonst leitet der Zwei-Drittel-Fall seine eigene Leere bei
jedem Neustart neu her; und ein Größenlimit weit unter `images.remote`s
20-MB-Default. Alles Nötige existiert bereits —
`images.browse.draw_in_window()` zeichnet in ein fremdes Fenster,
`images.remote` lädt asynchron in einen SHA256-Cache.

---

## 1.1 Quick Wins (XS–S, Nutzen mittel bis hoch)

---

### QW1 · `mdview.nvim` — `experimental.any_file` in echtem Neovim durchtesten

**Aufwand XS · Nutzen hoch · braucht dich**

Implementiert am 2026-08-24, aber nur über den Lua-Harness (55 Tests), das
Client-vitest (95 Tests) und einen Browser-Check über den Relay im
Standalone-`--watch` verifiziert. Der Pfad durch reales Neovim ist
ungetestet — das Feature gilt damit nicht als fertig.

*Umsetzung*: `setup({ experimental = { any_file = true } })`, dann fünf
Fälle abarbeiten, die die Roadmap bereits benennt: (1) `.lua`/`.py` öffnen +
`:MDView start`, rendert es hervorgehoben? (2) Scroll-Sync (proportional
erwartet, keine exakte Zeilenmarke). (3) `:MDViewBreadcrumbs` auf einer
`.py`/`.sh` mit `#`-Kommentaren — es dürfen keine Fake-Überschriften
gesammelt werden. (4) Terminal, `:help`, Quickfix, mdviews eigener
Log-Buffer bleiben ausgeschlossen. (5) `any_file = false` verhält sich exakt
wie vorher.

*Warum zuerst*: kostet eine halbe Stunde und entscheidet, ob ein bereits
gebautes Feature ausgeliefert werden kann oder Nacharbeit braucht.

---

### QW5 · `lsp.nvim` — Hover-Cache über `lib.lua.memo`

**Aufwand S · Nutzen mittel**

Wiederholter Hover auf derselben Position bei gleicher Buffer-Version spart
einen Roundtrip. Schlüssel: `(bufnr, changedtick, row, col)`.

---

### QW6 · `lsp.nvim` — `formatter_priority` verkabeln oder als report-only festschreiben

**Aufwand XS (Doku) bis S (Verkabelung) · Nutzen mittel**

`formatter_priority` wird ausschließlich von `lspdoctor/inspect.lua:161`
gelesen, also nur *berichtet*; `formatter/conform.lua` erwähnt den Key mit
keinem Wort. Er wird damit nicht durchgesetzt — wer ihn setzt, ändert nur,
was `:LspDoctor` als bevorzugte Reihenfolge anzeigt, nicht welcher Formatter
tatsächlich läuft.

Zwei Wege: entweder conform.lua liest die Liste und ordnet
`formatters_by_ft` danach, oder der Key wird als reine Report-Option
dokumentiert. Der zweite ist eine Zeile, der erste die ehrlichere Semantik.

---

### QW8 · `lsp.nvim` — Multi-Root-/Monorepo-Workspace-Switcher

**Aufwand S · Nutzen mittel**

Formalisiert, was in `root_scope_picker` halb existiert. Kein neues Konzept,
nur ein sauberer Einstiegspunkt.

---

## 1.2 Mittel (M)

---

### M1 · `lsp.nvim` — Fehler provozieren als Testhilfe (`:LspDoctor deep`)

**Aufwand M · Nutzen hoch**

Der stärkste offene Punkt in `lsp.nvim`: ein Scratch-Buffer mit garantiert
fehlerhaftem Inhalt (Go: fehlende Klammer, JS: `const x =`) und die Prüfung,
ob innerhalb eines Timeouts Diagnostics ankommen. Das unterscheidet "keine
Fehler" von "Diagnostics kommen überhaupt nicht an" — der Fall, der sonst
Stunden kostet. Es ist der einzige Check, der die Kette End-to-End prüft
statt Zustände abzufragen.

---

### M2 · `lsp.nvim` — Code-Action-Indikator

**Aufwand M · Nutzen mittel**

Sign oder Virtual Text, wenn `textDocument/codeAction` etwas zurückgibt.
Sichtbarkeit statt blindem `lsa`.

---

### M3 · `lsp.nvim` — Auto-Restart mit Backoff bei Client-Crash

**Aufwand M · Nutzen mittel**

`core/attach.lua` hat heute keine Crash-Behandlung.

---

### M4 · `lsp.nvim` — Workspace-Symbol-/Call-Hierarchy-Picker über den `picker`-Adapter

**Aufwand M · Nutzen mittel**

Ersetzt das ad-hoc-Telescope in `ts_type_lookup` durch die konsistente
Picker-UI, die der Adapter schon bereitstellt.

---

### M5 · `lsp.nvim` — Sprung zur Lua-Tabellen-/Funktionswurzel (ehemals `<leader>gtt`)

**Aufwand M · Nutzen mittel**

Aus B2 gerettet: aus einer tief verschachtelten Lua-Tabelle an den Kopf der
umschließenden Struktur springen, optional zentriert. Die Taste war jahrelang
auf ein Modul gemappt, das nie existierte — das Feature war also gewollt, nur
nie gebaut.

---

### M6 · `lsp.nvim` — Profile-Presets (`preset = "lean"|"default"|"full"`)

**Aufwand M · Nutzen mittel**

Ein Schalter statt 20 Einzeloptionen für "schlank auf schwacher Maschine".

---

### M7 · `lsp.nvim` — Per-Projekt-Override (`.nvim-lsp.json` im Repo-Root)

**Aufwand M–L · Nutzen mittel**

Server X in Projekt Y abschalten, ohne die globale Config anzufassen.

---

### M9 · `gopath.nvim` — Frecency-Lernen für Alternate-Vorschläge

**Aufwand M (repo-übergreifend) · Nutzen mittel**

Häufig gewählte Alternates nach oben sortieren. `pickers.nvim` hat die
Implementierung bereits in `smart/frecency.lua` — die gehört über `lib.nvim`
geteilt, nicht in gopath nachgebaut. Drei Repos (lib.nvim + pickers.nvim +
gopath.nvim), deshalb nicht in einer Session.

*Reihenfolge*: erst `lib.nvim.frecency` als Extraktion aus pickers (das
Verhalten ist dort bewiesen), dann pickers auf die geteilte Fassung
umstellen, dann gopath anschließen. Der letzte Schritt ist der kleinste.

---

### M10 · `images.nvim` — Sixel-Backend

**Aufwand M–L · Nutzen mittel**

Für Terminals, die Sixel können, aber kein OSC 1337 (xterm mit
`--enable-sixel-graphics`, mlterm, Windows Terminal ab 1.22). Nach OSC 1337
die zweitgrößte Reichweite.

*Vorbedingung, die dadurch erst Sinn ergibt*: die Terminal-Erkennung via
`ESC [ > q` (XTVERSION, **S**). Solange es genau ein Backend gibt, entscheidet
Erkennung nur, ob eine Warnung erscheint; mit einem zweiten Backend wird sie
zur Voraussetzung. Also: Sixel und XTVERSION-Detection sind ein Paket.

---

### M11 · `images.nvim` — OCR-Kreuzung mit `language.nvim`

**Aufwand M · Nutzen mittel**

Text aus einem Bild extrahieren, dann übersetzen oder prüfen — für
Screenshots von Fehlermeldungen in fremdsprachigen Systemen ein echter
Supportfall. Die offene Frage ist entschieden: `tesseract` wird als vorhanden
angenommen (Windows eingeschlossen), Verbesserung statt Voraussetzung — wie
ImageMagick sonst auch.

---

### M12 · `images.nvim` — Flamegraphs als Bild (`runtime-analysis.nvim`)

**Aufwand M · Nutzen mittel**

In 60×25 Zellen nur eine grobe Übersicht — aber das Bild landet ohnehin als
gewöhnliche Datei auf der Platte und ist mit Zoom in Browser oder mdview in
voller Auflösung lesbar. Dieselbe Grafik gehört zusätzlich in
`documentation.nvim`, wo der Abschnitt für Runtime-Daten heute nur Text zeigt.

---

### M13 · `images.nvim` — Bildoperationen als Dateioperationen (`fileops.nvim`)

**Aufwand M · Nutzen niedrig–mittel**

Convert, Scale, Optimise unter dem "ein Befehl, alle Operationen"-Thema.
ImageMagick wird als vorhanden angenommen, sonst Fallback-Kette oder Feature
aus.

---

### M14 · `filetree.nvim` — `cwd_mode`-Badge optimieren

**Aufwand S–M · Nutzen niedrig**

`component()` liefert das Badge als reinen Text für das, was die Statusline
zeichnet (natives `%{v:lua…}`, heirline oder lualine — alle drei dokumentiert,
keins eine Abhängigkeit). Der Redraw-Pfad rechnet bei jedem Aufruf neu, und
`refresh()` bittet den Host um ein Redraw statt umgekehrt. Es ist das Stück,
das angefasst wird, wenn die persönliche Config je ihr Statusline-Framework
wechselt — bis dahin billig und korrekt zu machen lohnt.

---

### M16 · `lib.nvim` — `deps.health`-Migrationen

**Aufwand S · Nutzen mittel · mechanisch · nur noch ein Repo**

`images.nvim` (`health.lua:128`) und `language.nvim` (`health.lua:184`) rufen
bereits `deps.health.report_for`. Offen ist allein `pdfport.nvim`, das
`check_exe` noch selbst rollt — acht Aufrufstellen in einer Datei
(`lua/pdfport/health.lua`). Der geteilte Ersatz existiert (`report`, plus
`from_tools`, das eine geparste Spec direkt in `:checkhealth` brückt).

---

### M17 · `documentation.nvim` / `runtime-analysis.nvim` / `docmap-desktop` — M7 bis M13

**Aufwand je M · Nutzen mittel bis hoch**

Diese drei Repos haben ihre Warteschlange seit 2026-08-20 in genau einem
Dokument: `docmap-desktop/docs/PLAN.md`. Die Roadmaps der beiden
nvim-Plugins sind bewusst nur noch Prosa-Ausblick und verweisen dorthin.
Offen sind dort:

| # | Was | Klasse |
|---|---|---|
| **M7** | Phase-0-IR: besitzender Scope, eine Datei / viele Module | M, Engine |
| **M8** | `:DocMap impact`, gewichtet nach Runtime-Reichweite | M |
| **M9** | `:DocMap why` × Call-Trees | M |
| **M10** | Runtime-Evidenz als Check-*Input* (nur als Unterdrückung) | M |
| **M11** | Endpoint-Inventar × Request-History × Response-Shape | M |
| **M12** | Runtime-Tab im ausgelieferten Artefakt | M |
| **M13** | Ein `ECOSYSTEM.md`, vier Repos lesen es | S–M |
| **QW6** | Fenced Blocks auf der generierten Seite (war mal ein Quick Win, ist heute M) | M |

**Die dortige Empfehlung, unverändert übernommen**: **M7 zuerst** — es ist
der einzige offene Punkt, der etwas *anderes* aufhält (tieferes Python und
Rust haben ohne besitzenden Scope keinen Ort für Klassen und `impl`-Blöcke),
und er berührt jeden Konsumenten von `Documentation.FunctionInfo`. Danach
**M12**, weil M8 bis M11 diese Oberfläche brauchen, bevor sie überhaupt etwas
zeigen können.

---

## 1.3 Groß (L)

---

### L1 · `images.nvim` — Kitty-APC-Backend

**Aufwand L · Nutzen hoch**

Für Kitty und Ghostty. Bringt dort zusätzlich Unicode-Placeholder und damit
**echtes Inline-Rendering im Textfluss** — das eine, was das Plugin heute
grundsätzlich nicht kann. Der größte Fähigkeitssprung auf der ganzen Liste,
und entsprechend teuer.

---

### L3 · `lsp.nvim` — das Signature-Help-Modul schrumpfen

**Aufwand L · Nutzen niedrig**

`tools/lsp_signature/**` ist eine vollständige Eigenimplementierung (~800
LOC). Die Roadmap sagt selbst: "vorerst nur beobachten". Bleibt so.

---

### L4 · `mdview.nvim` — das nvim-Highlighting im Browser spiegeln

**Aufwand M (war L) · Nutzen mittel — die Hälfte des Wegs steht schon**

Aus dem `SCHLACHTPLAN.md`. Vier Schritte, würde die JS-Abhängigkeiten
(hljs/shiki) ersetzen:

1. **gebaut** — `color_my_ascii.highlight_export.runs_for_block(bufnr, block)`
   liefert die Spans eines Fence als row/col/hl_group, gelesen aus den
   `ColorMyAscii`-Extmarks. Genau die Export-Funktion, die der Plan als
   `tokenize_block` beschreibt.
2. **gebaut** — dieselbe Datei löst `hl_group -> #hex` über `nvim_get_hl`
   auf (`resolve_attrs`/`int_to_hex`), heute für `:Fence export --html`.
3. offen — Transport der Spans pro Codeblock an den Client, gebunden an die
   `data-sourcepos` des `<pre>`.
4. offen — der Client legt die Spans um den Code.

*Die eine Einschränkung*: `runs_for_block` liest die Extmarks, die
color_my_ascii selbst gemalt hat — es liefert also nur dort etwas, wo
color_my_ascii den Block schon eingefärbt hat. Die Alternative aus dem Plan
(Treesitter direkt in mdview, allgemeiner, keine Fremdabhängigkeit) bleibt
davon unberührt.

---

### L5 · `documentation.nvim`-Verbund — L1 bis L9 aus `PLAN.md`

**Aufwand je L · Nutzen gemischt**

Jeder Punkt ist zuerst eine **Scope-Entscheidung**, erst danach eine
technische Aufgabe: Call-Edges für die restlichen achtzehn Sprachen (L1),
i18n vollständig (L2), die fünfzehn weiteren Sprachen (L3), API-Traffic als
Messung (L4), Multi-Language-Telemetrie (L5), einen Agenten die Checklisten
laufen lassen (L6), Extension-API Stufe 3 mit Schreibrichtung (L7), zwei
Artefakte in der Seite vergleichen (L8), ganz ohne Neovim (L9).

Vollständige Begründung je Punkt steht in `PLAN.md`; hier nicht dupliziert,
weil dieses Dokument sonst zur zweiten Wahrheit wird — genau das Problem, das
`PLAN.md` 2026-08-20 gelöst hat.

---

## 1.4 Braucht dich

---

### BD2 · `open.nvim` — die Nicht-Windows-Reveal-Pfade auf echter Hardware prüfen

**Aufwand S · Nutzen mittel · braucht einen Linux- und einen macOS-Host**

Der Linux-Zweig wählt inzwischen einen select-fähigen Manager (nautilus,
nemo, `dolphin --select`, thunar, caja) und hält `xdg-open` von Dateien fern —
eine Datei zu übergeben startet sonst deren Standardanwendung statt eines
Dateimanagers. Diese Reihenfolge ist **aus den dokumentierten Flags
abgeleitet, nicht ausgeführt**. macOS `open -R` ist genauso unverifiziert.

---

### BD3 · `lib.nvim` — Windows-Elevation im Dependency-Installer

**Aufwand S · Nutzen mittel · braucht eine Maschine, die Elevation wirklich verlangt**

`choco` will eine elevierte Shell, `winget` wirft eine eigene UAC-Abfrage. Das
aktuelle Design reicht beides an das Terminal weiter, in dem der Nutzer den
Befehl abschickt — die richtige Grenze, aber bisher nur durchdacht, nicht
ausprobiert.

---

### BD4 · `mdview.nvim` — externe Renderer-Website (opt-in)

**Aufwand M · Nutzen niedrig · Entscheidung liegt bei dir**

Rendering optional an eine externe Website auslagern. **Der Vorbehalt**: das
widerspricht dem Loopback-only-Modell, Dokumentinhalt verließe das Gerät. Nur
als ausdrückliches Opt-in mit klarem Datenschutzhinweis denkbar.
`browser.open_url` deckt einen Teil des Bedarfs bereits ab.

*Empfehlung*: ablehnen und aus der Roadmap streichen, oder als "explizit nicht
geplant" festschreiben. Ein offener Punkt, den man aus Prinzip nicht baut,
kostet bei jedem Durchgang erneut Lesezeit.

---

### BD5 · `mdview.nvim` — PDF-Seiten-Preview im Link-Hover

**Aufwand M–L · Nutzen niedrig · bewusst zurückgestellt seit 2026-08-17**

Der Browser-Hover zeigt für `.pdf`-Ziele nur den Dateinamen; der
In-Editor-Hover in `markdown.nvim` rendert dagegen Seite 1 inline, weil
`pdfport.render_page` dort im selben Prozess sitzt. Über den Browser wäre der
Weg: Anfrage in eine Server-Queue, bis zu 250 ms bis Neovim pollt, mehrere
hundert ms für `pdftoppm`, und das PNG landet im Temp-Verzeichnis — also
**nicht** über `/asset` auslieferbar, weil diese Route bewusst auf das
Dokumentverzeichnis begrenzt ist. Ergebnis: rund eine Sekunde Latenz für einen
Hover plus eine neue Route, die die Verzeichnisbindung aufweichen müsste.

*Der saubere Weg, falls je gewollt*: beim Doc-Push vorrendern statt beim Hover
anfragen. Neovim kennt beim Senden die Links, könnte referenzierte PDFs vorab
rastern und die PNGs **neben das Dokument** legen — `/asset` greift dann
unverändert. Preis: Rasterarbeit für PDFs, die niemand hovert, und
Schreibzugriff neben dem Dokument (Cache-Verzeichnis, Aufräumen,
`.gitignore`-Frage).

*Empfehlung*: liegen lassen, bis ein konkreter Fall auftritt.

---

# Teil 2 — Plugin für Plugin

---

## 2.1 Repos mit offener Arbeit

| Plugin | Offen | Schwerpunkt |
|---|---|---|
| `lsp.nvim` | 13 | Feature-Tabelle §14 plus 2 Punkte aus der geretteten LSPDoctor-Analyse |
| `images.nvim` | 8 | Backends (Sixel, Kitty APC), Detection, 5 Cross-Plugin-Kreuzungen |
| `mdview.nvim` | 3 + 1 | 1 Testfreigabe, 2 Grundsatzfragen, plus L4 aus dem SCHLACHTPLAN |
| `lib.nvim` | 2 | eine `deps.health`-Migration, Windows-Elevation |
| `open.nvim` | 1 | plattformabhängig, braucht dich |
| `filetree.nvim` | 1 | Badge-Optimierung |
| `gopath.nvim` | 1 | Frecency (repo-übergreifend) |
| `documentation.nvim`-Verbund | 8 + 9 | zentral in `docmap-desktop/docs/PLAN.md` |
| `color_my_ascii.nvim` | 2 Konzepte | siehe unten |

---

### `color_my_ascii.nvim` — zwei Konzepte ohne Umsetzungsentscheidung

**je M–L · Nutzen mittel**

Die Roadmap sagt korrekt "keine offenen Punkte", aber zwei Konzeptdokumente
unter `docs/ROADMAP/` beschreiben je einen ungebauten Weg:

- **`fence_highlighter_api.md`** — können andere Plugins, externe Apps oder
  CLI-Tools das Highlighting *innerhalb* eines Fence übernehmen oder steuern?
  Zwei Bausteine existieren: `color_my_ascii.api.fences` (stabile,
  sprachagnostische Fence-Erkennung, gecacht pro `(bufnr, changedtick)`, wird
  heute schon von `markdown.nvim` konsumiert) und `color_my_ascii.fence_hl`
  (malt Markerzeilen und Blockinneres). Was fehlt, ist die Übergabe nach außen.
- **`lsp_integration_fence.md`** — zwei Wege zu vollem LSP (Completion, Hover,
  Diagnostics) innerhalb eines Fence.

Beide hängen an L4 (`mdview.nvim`) — und dessen erster Schritt ist
inzwischen gebaut: `color_my_ascii.highlight_export.runs_for_block` gibt die
Spans eines Fence zurück, statt sie nur zu malen, und `to_html` löst die
Highlight-Gruppen nach `#hex` auf. Damit existiert der kleinste sinnvolle
Baustein der Fence-Highlighter-API bereits; offen ist, ihn als *öffentliche*
Schnittstelle zu deklarieren statt als Interna von `:Fence export`.

---

## 2.2 Repos ohne offene Arbeit

Zwanzig Plugins. Aufgeteilt danach, *warum* nichts offen ist — das ist der
Unterschied zwischen "fertig" und "noch nie befüllt":

**Ausdrücklich abgearbeitet** (die Roadmap sagt, dass alles ausgeliefert ist,
und verweist auf ein Feature-Log oder einen Entscheidungsnachweis):

`cascade.nvim`, `color_my_ascii.nvim`, `dap.nvim`, `debugging.nvim`,
`emojis.nvim`, `github_stats.nvim` (alle acht Befunde aus `KONZEPT.md`
gebaut, plus zwei Fixes, die dabei anfielen), `insights.nvim`,
`markdown.nvim`, `migrate.nvim`, `pdfport.nvim` (P0–P3 plus die Verkabelung
der Aufrufer), `pickers.nvim`, `recommender.nvim`, `replacer.nvim` (sehr
lange Shipped-Liste, kein offener Rest), `reposcope.nvim`, `sandbox.nvim`,
`sessions.nvim`

**Leere Roadmap-Datei** (nur Überschrift und Trennlinie — kein Signal, ob
fertig oder nie gepflegt):

`buffer-ctx.nvim`, `cmdlog.nvim`, `diff.nvim`, `language.nvim`,
`lib.nvim/docs/ROADMAP/ROADMAP.md` (die echte lib.nvim-Arbeit steht in
`dependency-installer.md` daneben, nicht in der Roadmap-Datei),
`spotlight.nvim`, `fileops.nvim`

*Befund dazu*: bei diesen sieben ist "keine offene Arbeit" eine Annahme, keine
Aussage. Das ist billig zu reparieren — ein Satz je Datei nach dem Muster, das
`emojis.nvim`, `dap.nvim` und `open.nvim` schon verwenden ("leer aus Absicht,
nicht aus Vernachlässigung"). **Aufwand XS gesamt, Nutzen mittel**, weil es
bei jedem künftigen Durchgang genau diese Rückfrage spart.

---

# Teil 3 — Querschnittsbefunde

---

## 3.1 Die Audit-Dokumente sind veraltet — und zwar systematisch

In acht Repos standen in
`docs/ROADMAP/{Arch&Coding,Checklist,Zentral-Prinzipien}.md` noch Lücken mit
`❌`. Fünf Stichproben, alle geprüft, **alle fünf veraltet**:

| Behauptete Lücke | Tatsächlicher Stand |
|---|---|
| `open.nvim`: kein `.stylua.toml`, kein `.luacheckrc`, keine CI | `.luacheckrc` und `.github/workflows/ci.yml` existieren |
| `open.nvim`: `lib.usercmd` ungenutzt, `platform.lua` rollt Erkennung selbst | `usrcmds.lua` nutzt `lib.nvim.bindings.usercmd.composer`, `platform.lua` delegiert an `lib.nvim.cross.platform.is_*` |
| `pdfport.nvim`: `lib.notify`/`lib.map`/`lib.usercmd`/`lib.autocmd` alle ungenutzt | alle vier laufen über `lib.nvim` |
| `markdown.nvim`: kein `@types/`-Ordner, keine stylua/luacheck/CI | `lua/markdown/@types` existiert, `.luacheckrc` und CI ebenfalls |
| `github_stats.nvim`: kein lokal lauffähiger Test-Runner | `ci.yml` ruft `scripts/test.sh` |

Die Dokumente selbst sagen, ihre Konvention sei "abgearbeitete Befunde werden
entfernt, nicht abgehakt" — genau das ist bei diesen fünf nicht passiert.

**Konsequenz für diesen Report**: die `❌`-Zeilen in den Audit-Dateien wurden
**nicht** als offene Arbeit gezählt. Wer sie als Aufgabenliste liest, arbeitet
Dinge nach, die längst erledigt sind.

**Erledigt am 2026-08-29** (WKDBooks `205f152`): jede `❌`-Zeile in allen
Audit-Dateien wurde einzeln gegen den Code geprüft. Der erste Durchgang hatte
nur einen **VERALTET**-Block vorangestellt und die falschen Zeilen
stehengelassen — also genau das getan, was die Konvention dieser Dokumente
verbietet. Jetzt sind die überholten Befunde korrigiert, und der Block sagt
nur noch, was nachgezogen wurde, plus den Satz, dass ein verbliebenes `❌`
geprüft und weiterhin offen ist.

*Korrigiert*: `open.nvim` und `pdfport.nvim` §6 Testbarkeit (beide führen
"kein `test/`-Verzeichnis" als größte Lücke, beide haben `TESTS/` mit sechs
Specs und CI); `open.nvim` §7 Tooling plus drei Folgestellen im selben
Dokument, die auf "kein Test-Suite geplant" aufbauten; `open.nvim`
`lib.usercmd`/`lib.cross`; `pdfport.nvim` `lib.notify`/`lib.map`/
`lib.usercmd`/`lib.autocmd` plus zwei Folgestellen; `markdown.nvim` A3 und A7;
`github_stats.nvim` `@see` und der Test-Entry.

*Zwei Nebenbefunde*: die alten Blöcke behaupteten, `.stylua.toml` fehle
weiterhin — die Konfiguration liegt in allen vier Repos als `stylua.toml` ohne
Punkt, was stylua genauso liest. Und der Vorwurf, `github_stats`-Specs
referenzierten nicht-existente Module, war ein Lesefehler:
`dashboard.renderer`/`dashboard.navigator` sind keine `require`s, sondern die
`describe`-Überschrift in `TESTS/dashboard_spec.lua:250`.

*Geprüft und bewusst stehengelassen*: `github_stats`' `safe_call`,
strukturierte Fehlertypen, `@error`/`@raises`, Snapshot/Restore und
Tabellen-Vorreservierung (alle fünf zutreffend, drei mit eigener Begründung im
Dokument), sowie `pdfport`s `cleanup_all`.

*Was offen bleibt*: die `🟡`-Zeilen wurden nur dort mitgezogen, wo eine
korrigierte `❌`-Zeile sie direkt widerlegt — systematisch durchgeprüft sind
sie nicht.

---

## 3.2 `ROADMAP.md` heißt in diesen Repos vier verschiedene Dinge

Die Datei ist mal Aufgabenliste, mal Shipped-Log, mal Index über einen Ordner,
mal Prosa-Ausblick, der auf die eigentliche Warteschlange woanders verweist:

| Rolle | Repos |
|---|---|
| **Offene Aufgaben** | `open.nvim`, `mdview.nvim` |
| **Shipped-Log** (nur Erledigtes) | `replacer.nvim`, `reposcope.nvim`, `debugging.nvim`, `gopath.nvim` |
| **Index über `docs/ROADMAP/`** | `color_my_ascii`, `debugging`, `github_stats`, `insights`, `markdown`, `migrate`, `open`, `pdfport`, `filetree` |
| **Prosa-Ausblick, Queue liegt woanders** | `documentation.nvim`, `runtime-analysis.nvim` |
| **Leer** | 7 Repos, siehe 2.2 |

Das ist der Grund, warum diese Analyse nicht durch Überfliegen möglich war: in
`replacer.nvim` sieht eine 40-Zeilen-Liste nach Backlog aus und ist eine
Erledigt-Liste; in `open.nvim` sieht eine 2-Punkte-Liste nach Kleinigkeit aus
und ist die einzige echte offene Arbeit im Repo.

**Empfehlung, unabhängig davon, ob die Repo-Dateien bleiben oder gehen**: eine
Zeile ganz oben in jeder `ROADMAP.md`, die ihre Rolle nennt. Aufwand XS je
Repo.

---

## 3.3 Die Warteschlangen liegen zu dritt außerhalb der Roadmaps

Drei Dokumente tragen deutlich mehr offene Arbeit als sämtliche
`ROADMAP.md`-Dateien zusammen, und keines davon heißt so:

- `docmap-desktop/docs/PLAN.md` — 17 offene Punkte für drei Repos
- `lib.nvim/docs/ROADMAP/dependency-installer.md` — 4 offene Punkte, versteckt
  unter "Recommendation", "Open questions" und "Still worth doing"
- `images.nvim/docs/ROADMAP/CROSS-PLUGIN.md` — 5 offene Kreuzungen, verteilt
  über die Abschnitte "Medium" und "Open"

`PLAN.md` ist dabei kein Versehen, sondern eine bewusste, gut begründete
Zentralisierung (die Queue lag vorher in fünf Dateien und widersprach sich).
Die anderen beiden sind gewachsen.

---

## 3.4 Zwei Punkte hängen aneinander und sollten zusammen gebaut werden

- **Sixel (M10) und XTVERSION-Detection**: Erkennung lohnt erst mit einem
  zweiten Backend, das zweite Backend braucht Erkennung. Ein Paket.
- **mdview L4 und die `color_my_ascii`-Fence-API**: die Exportfunktion, die
  L4 braucht, ist der erste sinnvolle Schritt der Fence-Highlighter-API — und
  sie steht schon (`highlight_export.runs_for_block`). Was fehlt, ist die
  Entscheidung, sie als öffentliche API zu führen, bevor mdview sie
  konsumiert. Zweimal gebaut wäre es zweimal falsch.

---

# Teil 4 — Empfohlene Reihenfolge

Nicht als Plan, sondern als Vorschlag mit Begründung. Erst das, was etwas
abschließt oder anderes freigibt; dann Nutzen vor Aufwand.

1. **QW1** (`mdview` any_file testen, XS) — entscheidet über ein bereits
   gebautes Feature.
2. **M17/M7** (Phase-0-IR im documentation-Verbund, M) — der einzige Punkt auf
   der ganzen Liste, der etwas anderes aufhält.
3. **M1** (`lsp.nvim` Diagnostics provozieren, M) — der einzige
   End-to-End-Check der LSP-Kette.
4. **QW5, QW6, QW8** (`lsp.nvim`-Quick-Wins, je XS–S) — in einem Rutsch, sie
   liegen alle im selben Modulumfeld. QW3, QW4 und QW7 sind daraus schon
   erledigt (siehe 1.0).
5. Danach nach Bedarf: **M17/M12** (Runtime-Tab), **M10 + Detection**
   (`images` Sixel-Paket), **M9** (Frecency über drei Repos).

**Nicht angehen, mit Begründung**: L3 (`lsp` Signature-Help — die Roadmap
sagt selbst "vorerst nur beobachten"), BD4/BD5 (`mdview` externe Website und
PDF-Hover — beide teuer, beide klein im Nutzen, beide besser als "explizit
nicht geplant" festgeschrieben als offen gelassen).

---

