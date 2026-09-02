# Handover — BINDINGS-Drift, was noch offen ist

## Table of content

  - [Aktueller Stand](#aktueller-stand)
  - [Wo weiterarbeiten](#wo-weiterarbeiten)
  - [Die 80 Commands, die nur ein benutzter Editor zeigt](#die-80-commands-die-nur-ein-benutzter-editor-zeigt)
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
| `:Bindings check` | **10** | 10 `autocmd-not-live` |
| `:Bindings check extern` | **4** | 4 `autocmd-not-live` |
| `:Bindings check all` | **14** | 14 `autocmd-not-live` |

Alle drei Usercmd-Kategorien und beide Keymap-Kategorien stehen auf **0**.
Übrig sind ausschließlich Autocmds, die feature-gated sind oder auf einen
Trigger warten (`LspFormatOnSave`, `LspNvimSagaWinbarDepth`, `HoverDismiss`,
`ReloadNvChad`, …).

Von 167 auf 14 in fünf Schritten plus einem Nachtrag, und **keiner davon
hat einen Befund weggeworfen**:

| Schritt | all | Was er tat |
| --- | ---: | --- |
| Ausgangsstand | 167 | |
| Punkt 1 — `getscriptinfo` | 167 | elf sitzungsabhängige sids durch Namen ersetzt |
| Punkt 4 — dreizehn Zeilen + drei Blätter | 168 | −13 undokumentiert, +14 not-live |
| Punkt 3 — Stamm-Auflösung | 54 | `keymap-not-live` 84 → 0, `usercmd-not-live` 31 → 2 |
| Punkt 2 — Usercmd-Fallback | 52 | `usercmd-not-live` 2 → 0 |
| Punkt 5 — Scope-Entscheidung | 11 | `usercmd-undocumented` 41 → 0 |
| Nachtrag — drei fehlende Autocmds | **14** | `autocmd-undocumented` 3 → 0, dafür +3 `not-live` |

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

## Die 80 Commands, die nur ein benutzter Editor zeigt

**Erledigt.** Entstanden aus der Arbeit an Punkt 5, nicht aus dem
ursprünglichen Bericht — und im selben Zug abgearbeitet.

**Die Null oben gilt für eine Session, die 17 Extern-Plugins nie geladen
hat.** Derselbe Lauf, mit allen per `Lazy! load` geladen — also dem Zustand,
den ein benutzter Editor nach einer Weile erreicht:

| | Standardlauf | alle geladen, vorher | alle geladen, jetzt |
| --- | ---: | ---: | ---: |
| `usercmd-undocumented` | 0 | 80 | **0** |
| `usercmd-not-live` | 0 | 0 | **0** |
| `keymap-not-live` | 0 | 16 | **10** |
| extern gesamt | 4 | 140 | **13** |
| `all` gesamt | 14 | 151 | **21** |
| übersprungene Stämme (extern) | 17 | 0 | 0 |

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

**Angewendet wurde die Regel aus** [`Usercmds/Overview.md`](../../../NOTES/ExternPlugins/Bindings/Usercmds/Overview.md):
Arbeitsablauf bekommt ein Blatt, Werkzeug bekommt eine Zeile.

Sechs neue Blätter — `Fugitive` (36 Commands), `DapView` (11), `Diffview`
(7), `VisualMulti` (7), `Neogit` (4), `DapVirtualText` (4) — und drei
erweiterte: `Dap` um nvim-daps eigene fünfzehn, `Neotest` um `:Neotest` und
vim-tests sechs, `Unicode` um zwei Aliase. `:BlinkCmp` ist als Werkzeug in
Overview.md gelandet, vim-tests sechs sind bewusst **im Neotest-Blatt**
gelandet und nicht in einem eigenen: vim-test kommt als Dependency des
Adapters `neotest-vim-test` mit, nicht als eigenes Werkzeug dieser Config.

**Die Kontrolle, die zählt:** der Standardlauf bleibt bei 11 (die 14 kamen
erst durch den Autocmd-Nachtrag darunter). Die neuen
Blätter erzeugen also keine `not-live`-Befunde — anders als
`Usercmds/Noice.md` in Punkt 4, das genau das getan hatte. Der Unterschied
ist die Stamm-Auflösung: jedes neue Blatt trägt einen Namen, den
`stem_plugin` auf sein Plugin abbildet, und ein nicht geladenes Plugin wird
übersprungen statt gemeldet.

**Der Nebenfund:** vier Blätter behaupteten, ihr Plugin bringe „keine
Usercmds mit (reine API-Lib)" — `Conform`, `Treesitter`, `Dap` und
`Neotest`. Jedes Mal falsch, und jedes Mal aus demselben Grund: die Aussage
galt für die Bibliothek und nicht für ihr `plugin/`-Verzeichnis. nvim-dap
allein hat fünfzehn Commands.

### Kleiner Nebenfund: neun Zeilen mit fehlender dritter Spalte

Beim Nachzählen des Korpus aufgefallen, nicht beim Prüfen. `records.list()`
liefert heute **2333** Datensätze (2026-08-30 waren es 1940), und **neun**
davon haben eine dreispaltige Kopfzeile bei nur zwei Zellen:

* `Usercmds/documentation.nvim.md`, Z. 99–106 — acht `:DocMap`-Zeilen, denen
  die „schreibt?"-Spalte fehlt (`:DocMap serve` und `:DocMap helptags` direkt
  darüber haben sie).
* `Usercmds/lib.nvim.md`, Z. 15 — dieselbe Form.

**Folgenlos für jede Achse**: die Zuordnung läuft über den Header-Index auf
die Command-Spalte, und die ist vorhanden. Es ist eine reine
Format-Abweichung. Was in die fehlende Spalte gehört, sagt nur die jeweilige
Quelle — deshalb ist hier nichts geraten und nichts geändert worden; die
FEATURES.md-Behauptung „in keinem einzigen weicht die Zellenzahl ab" ist
korrigiert.

---

### Die 16 Keymap-Zeilen, einzeln nachgesehen — null echte Kandidaten

Hier stand „höchstens vier echte Kandidaten". Einzeln angesehen sind es
**null**; die Überschrift der jeweiligen Tabelle sagt es meist selbst.

| Klasse | n | Was getan wurde |
| --- | ---: | --- |
| Abgeschalteter Plugin-Default (`VM_default_mappings = 0`) | 3 | `**Nicht live:**`-Marker |
| Taste einer fremden Oberfläche (LazyGit-TUI) | 1 | `**Nicht live:**`-Marker |
| Verweistabelle auf andere Blätter | 1 | `**Nicht live:**`-Marker |
| Keine Taste, sondern Vim-Doku-Notation | 1 | Notation korrigiert |
| Buffer-lokal, UI nicht offen | 10 | nichts — korrekt gemeldet |

`keymap-not-live` steht damit bei geladenen Plugins auf **10**, und die zehn
sind ausschließlich die dokumentierte Nicht-Befund-Klasse 1: sieben Tasten im
Telescope-Picker, `zo` im Trouble-Fenster, zwei im VM-Modus. Sie wären live,
sobald das jeweilige Fenster offen ist.

**Der `**Nicht live:**`-Marker ist neu** und in
[`BINDINGS-FORMAT.md`](../../../NOTES/BINDINGS-FORMAT.md) §6 beschrieben: eine
Zeile unter der Überschrift nimmt die Tabellen eines Abschnitts von der
Live-Prüfung aus. Drei Sorten Tabelle brauchen ihn — abgeschaltete Defaults,
Tasten einer fremden Oberfläche, Verweistabellen. Nur die Live-Richtung ehrt
ihn; die Zeilen bleiben in `browse` und zählen als Dokumentation, und der
Bericht druckt die Zahl der markierten Zeilen (aktuell 16).

**Der eine echte Fehler:** `Keymaps/Fugitive.md` schrieb die Vim-Doku-Notation
für „optionales Register, dann `y<C-G>`" als wäre sie eine Taste. Live
nachgesehen heißt die Map schlicht `y<C-G>`. Korrigiert.

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
