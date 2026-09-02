# Handover — BINDINGS-Drift, was noch offen ist

## Table of content

  - [Aktueller Stand](#aktueller-stand)
  - [Wo weiterarbeiten](#wo-weiterarbeiten)
  - [Offen: die 80 Commands, die nur ein benutzter Editor zeigt](#offen-die-80-commands-die-nur-ein-benutzter-editor-zeigt)
  - [Was ausdrücklich *nicht* offen ist](#was-ausdrcklich-nicht-offen-ist)

---

## Aktueller Stand

Stand 2026-09-02, nachts. **Alle fünf Punkte dieser Datei sind zu** — vier
gebaut, einer entschieden. Was von ihnen dauerhaft gilt, steht dort, wo es
hingehört:

| Was | Wo es steht |
| --- | --- |
| Wie man misst, und die sechs Fallen dabei | [`bindings_explorer/docs/MEASURING.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md) |
| Alle gemessenen Stände mit Datum | dieselbe Datei, „Gemessene Stände" |
| Was die Routen tun und warum so | [`bindings_explorer/docs/FEATURES.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md) |
| Die `**Repo:**`-Zeile als Korpus-Element | [`BINDINGS-FORMAT.md`](../../../NOTES/BINDINGS-FORMAT.md) §5 |
| **Wann ein fremdes Plugin ein Blatt bekommt** | [`Usercmds/Overview.md`](../../../NOTES/ExternPlugins/Bindings/Usercmds/Overview.md) |
| `<leader>th`, Cross-Scope-Shadowing, freie `t`-Tasten | [`Keymaps/Collisions.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md) |
| Der cmdlog-Fund und seine Aufklärung | [`Keymaps/cmdlog.nvim.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md) |
| Der Wortlaut der erledigten Blöcke 1–2 | [ERLEDIGT-Archiv](../../personal/All/FINISH/ERLEDIGT/Bindings/bindings-drift-followups-2026-09-02.md) |

**Wo der Prüfer heute steht:**

| Route | Befunde | Aufschlüsselung |
| --- | ---: | --- |
| `:Bindings check` | **7** | 7 `autocmd-not-live` |
| `:Bindings check extern` | **4** | 4 `autocmd-not-live` |
| `:Bindings check all` | **11** | 11 `autocmd-not-live` |

Alle drei Usercmd-Kategorien und beide Keymap-Kategorien stehen auf **0**.
Übrig sind ausschließlich Autocmds, die feature-gated sind oder auf einen
Trigger warten (`LspFormatOnSave`, `LspNvimSagaWinbarDepth`, `HoverDismiss`,
`ReloadNvChad`, …).

Von 167 auf 11 in fünf Schritten, und **keiner davon hat einen Befund
weggeworfen**:

| Schritt | all | Was er tat |
| --- | ---: | --- |
| Ausgangsstand | 167 | |
| Punkt 1 — `getscriptinfo` | 167 | elf sitzungsabhängige sids durch Namen ersetzt |
| Punkt 4 — dreizehn Zeilen + drei Blätter | 168 | −13 undokumentiert, +14 not-live |
| Punkt 3 — Stamm-Auflösung | 54 | `keymap-not-live` 84 → 0, `usercmd-not-live` 31 → 2 |
| Punkt 2 — Usercmd-Fallback | 52 | `usercmd-not-live` 2 → 0 |
| Punkt 5 — Scope-Entscheidung | **11** | `usercmd-undocumented` 41 → 0 |

### Die Zahl, die neben jeder dieser Zahlen stehen muss

**1377 dokumentierte Zeilen wurden in diesem Lauf gar nicht geprüft**, weil
ihr Plugin nicht geladen war (extern 541, personal 836). Der Bericht druckt
das jetzt selbst, direkt unter der übersprungenen Plugin-Liste — vorher stand
dort nur die Anzahl *Plugins*, und 17 übersprungene Plugins klingen nach
weniger als 541 ungeprüften Zeilen.

Punkt 3 hat 84 `keymap-not-live` nicht repariert, sondern als das kenntlich
gemacht, was sie waren: Aussagen über Plugins, die diese Session nie geladen
hat. Wo sie wirklich hingehören, steht im nächsten Abschnitt.

Dazu unverändert die zwei Autocmds-Zahlen unter jedem Bericht (112
dokumentierte Zeilen nicht prüfbar, 122 Registrierungen zuzuordnen).

---

## Wo weiterarbeiten

|          |                                                                            |
| -------- | -------------------------------------------------------------------------- |
|   Repo   |             nvim-config (`C:/Users/bartl/AppData/Local/nvim`)              |
|  Branch  |         `main` — dort steht alles, siehe die Anmerkung darunter           |
| Worktree |                        keiner mehr nötig                                   |
|  Stand   |          alles committet und gepusht, Haupt-Checkout nachgezogen           |

An diesem Block haben mehrere Sessions aus eigenen Worktrees gearbeitet und
alle nach `origin/main` gepusht. `main` ist die einzige Quelle, die man dazu
noch braucht.

Vor jeder Messung: [MEASURING.md](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md),
Abschnitt „Die sechs Fallen". Headless ohne diese Vorkehrungen sind die
Zahlen oben nicht reproduzierbar — und seit Punkt 3 gehört **Falle 5** dazu:
ein `luafile` läuft vor `VimEnter`, hat also `VeryLazy` nie gefeuert und
überspringt mehr als ein echter Editor.

---

## Offen: die 80 Commands, die nur ein benutzter Editor zeigt

Der einzige offene Punkt, und er ist aus der Arbeit an Punkt 5 entstanden,
nicht aus dem ursprünglichen Bericht.

**Die Null oben gilt für eine Session, die 17 Extern-Plugins nie geladen
hat.** Derselbe Lauf, mit allen per `Lazy! load` geladen — also dem Zustand,
den ein benutzter Editor nach einer Weile erreicht:

| | Standardlauf | alle geladen |
| --- | ---: | ---: |
| `usercmd-undocumented` | **0** | **80** |
| `keymap-not-live` | 0 | **16** |
| übersprungene Stämme (extern) | 17 | 0 |
| `fallback_confirmed` | — | 321 |

Die 80 nach Eigentümer:

| Plugin | n | Lage |
| --- | ---: | --- |
| `vim-fugitive` | 30 | `:G` `:Git` `:GDelete` `:GMove` `:GRename` `:Gdiffsplit` … — hat ein Keymaps-Blatt, aber keines für Commands |
| `nvim-dap` | 13 | `Usercmds/Dap.md` dokumentiert den eigenen Wrapper `dap.nvim`, nicht nvim-daps eigene |
| `nvim-dap-view` | 11 | `:DapView*` — dieselbe Lücke |
| `vim-visual-multi` | 7 | Keymaps-Blatt vorhanden, Commands nicht |
| `vim-test` | 6 | im Korpus bisher gar nicht |
| `nvim-dap-virtual-text` | 4 | `:DapVirtualText*` |
| `neogit` | 3 | |
| `unicode.vim`, `diffview.nvim` | je 2 | |
| `neotest`, `blink.cmp` | je 1 | |

**Die Regel dafür steht schon** — [`Usercmds/Overview.md`](../../../NOTES/ExternPlugins/Bindings/Usercmds/Overview.md):
Arbeitsablauf bekommt ein Blatt, Werkzeug bekommt eine Zeile. Angewendet
hieße das ungefähr: `Usercmds/Fugitive.md` (30) und der `Dap`-Komplex (28)
sind Blätter, `vim-test` und `nvim-dap-virtual-text` wären zu entscheiden.

Die 16 verbliebenen `keymap-not-live` sind dagegen **kein** offener Punkt:
13 davon sind die dokumentierten Notationsdifferenzen (Telescope schreibt
`<A-c>`, die Quelle `<M-c>`; VisualMulti trägt den Leader `\\` im Key), plus
`["x]y<C-G>`, das eine Register-Notation ist und keine Taste. Höchstens vier
echte Kandidaten, alle in MEASURING.md aufgeführt.

---

## Was ausdrücklich *nicht* offen ist

Damit es nicht ein weiteres Mal untersucht wird:

* **Die Options-Pfade in `Keymaps/insights.nvim.md`** (`def_cfg.keymaps.jump`
  & Co. in der Key-Spalte) sind **kein** Format-Defekt. `first_token` liest die
  Form `` `pfad` (`taste`) `` richtig und nimmt die Klammer-Gruppe; die Zeilen
  werden geprüft und sind bestätigt.
* **`<leader>th`** ist kein Konflikt, sondern Cross-Scope-Shadowing, und steht
  vollständig in `Keymaps/Collisions.md`.
* **git-conflicts Default-Keymaps** (`co` `ct` `cb` `c0` `]x` `[x`) sind
  **buffer-lokal und werden erst gesetzt, wenn der Buffer einen Konflikt
  enthält**. `]x`/`[x` erscheinen auch bei Diffview — auch dort buffer-lokal,
  in dessen eigenen Fenstern. Die beiden treffen sich nicht.
* **Die 7 `keymap-not-in-repo`** von `debugging.nvim` sind dessen zur Laufzeit
  gebautes `prefix .. "m"` — der dokumentierte Falschbefund der Grep-Achse.
  **Dieselbe Klasse, neu belegt:** noice generiert seine 17 Einzelcommands aus
  den Keys seiner Command-Tabelle (`"Noice" .. key`), im Quelltext steht
  `stats` und nie `NoiceStats` — 13 `usercmd-not-in-repo` unter
  `check repo extern`, alle unecht.
* **`:UnicodeDownload`/`:DigraphNew` bleiben unauffindbar**, und das ist keine
  Lücke, die man schließt. Sie stehen als `com! -bang UnicodeDownload …`,
  also **unquoted**, und `repo.mentions` matcht nur Quoted-Literals.
* **`vimscript script_id=-8`** ist kein Defekt, sondern der ausdrückliche
  Rückfall der Eigentümerspalte: eine negative `script_id` gehört keinem
  gesourceten Skript, `getscriptinfo` kann sie nicht auflösen, und dann ist
  ein erkennbares Nicht-Ergebnis besser als ein geratener Name.
  `nvim-dap-virtual-text`s vier Commands sind der erste echte Beleg dafür,
  dass dieser Zweig gebraucht wird.
* **`nvim-tree.lua` bleibt installiert.** Diese Config benutzt neo-tree, und
  kein Spec unter `lua/` deklariert nvim-tree — `filetree.nvim` unterstützt es
  aber als Adapter-Alternative, und es lädt nur auf Command. Entschieden am
  2026-09-02.
* **Die Familien-Notation gilt auch für Augroups** (`records.wildcard_pattern`),
  gebunden an Tabellenzeile und Eigentümer, nur in die
  Undokumentiert-Richtung. `autocmd-undocumented` fiel damit von 16 auf **0**.
* **Das Autocmds-Blatt für nvim-config existiert** (`Autocmds/nvim-config.md`).
  55 Aufrufstellen: 40 in 26 Augroups, 15 ohne jede Augroup.
* **Die Autocmds-Achse ist gebaut** (`21ed8082`). Beide Richtungen, die
  Zählfalle über `(Augroup, Event)`-Paare umgangen.
* **`:NoiceError` gibt es nicht** und gab es nie: noice baut seine
  Einzelcommands aus den Keys seiner Command-Tabelle, und der Key heißt
  `errors`. Der Stub lud noice, tat sonst nichts, und beim zweiten Aufruf kam
  E492. Korrigiert in `lua/plugins/ui.lua`.
* **conform.nvim und nvim-treesitter haben sehr wohl eigene Usercmds.** Beide
  Blätter behaupteten das Gegenteil; der Prüfer hat es gefunden.
* **cmdlog.nvims `ctrl-f`/`ctrl-t`** sind erledigt: der Code hat sie seit dem
  Merge `ed60f8f` nicht mehr, die Doku ist in beiden Repos nachgezogen.
* **Der Teilstring-Resolver ist geprüft und verworfen.** „Längster passender
  Teilstring" liegt über dem echten Korpus zweimal still daneben
  (`Telescope` → `telescope-file-browser.nvim`, `NeoTree` →
  `neo-tree-tests-source.nvim`). Die drei Schritte in `stem_plugin` lösen 21
  der 24 Stämme auf, die drei übrigen tragen ihre `**Repo:**`-Zeile.
* **`:LibLogger` ist kein Befund mehr**, und die frühere Behauptung, das
  Literal stehe in lib.nvim nirgends, war falsch gemessen — es steht in
  `lua/lib/nvim/logger/command.lua:42`. Die Korrektur steht als Blockquote in
  MEASURING.md.

---
