# Handover — BINDINGS-Drift, was noch offen ist

## Table of content

  - [Aktueller Stand](#aktueller-stand)
  - [Wo weiterarbeiten](#wo-weiterarbeiten)
  - [Offene Punkte](#offene-punkte)
    - [5 — Die Scope-Entscheidung, die seit vier Blöcken offen ist](#5-die-scope-entscheidung-die-seit-vier-blcken-offen-ist)
  - [Was ausdrücklich *nicht* offen ist](#was-ausdrcklich-nicht-offen-ist)

---

## Aktueller Stand

Stand 2026-09-02, spätabends. **Die Punkte 1 bis 4 sind gebaut und
ersatzlos entfernt**; was von ihnen dauerhaft gilt, steht dort, wo es
hingehört:

| Was | Wo es steht |
| --- | --- |
| Wie man misst, und die sechs Fallen dabei | [`bindings_explorer/docs/MEASURING.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md) |
| Alle gemessenen Stände mit Datum | dieselbe Datei, „Gemessene Stände" |
| Was die Routen tun und warum so | [`bindings_explorer/docs/FEATURES.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md) |
| Die `**Repo:**`-Zeile als Korpus-Element | [`BINDINGS-FORMAT.md`](../../../NOTES/BINDINGS-FORMAT.md) §5 |
| `<leader>th`, Cross-Scope-Shadowing, freie `t`-Tasten | [`Keymaps/Collisions.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md) |
| Der cmdlog-Fund und seine Aufklärung | [`Keymaps/cmdlog.nvim.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md) |
| Der Wortlaut der erledigten Blöcke 1–2 | [ERLEDIGT-Archiv](../../personal/All/FINISH/ERLEDIGT/Bindings/bindings-drift-followups-2026-09-02.md) |

**Wo der Prüfer heute steht:**

| Route | Befunde | Aufschlüsselung |
| --- | ---: | --- |
| `:Bindings check` | **7** | 7 `autocmd-not-live`, sonst nichts |
| `:Bindings check extern` | **45** | 4 `autocmd-not-live`, 41 `usercmd-undocumented` |
| `:Bindings check all` | **52** | 11 / 41 |

Von 167 auf 52 in vier Schritten, und **keiner davon hat einen Befund
weggeworfen**:

| Schritt | all | Was er tat |
| --- | ---: | --- |
| Ausgangsstand | 167 | |
| Punkt 1 — `getscriptinfo` | 167 | elf sitzungsabhängige sids durch Namen ersetzt |
| Punkt 4 — dreizehn Zeilen + drei Blätter | 168 | −13 undokumentiert, +14 not-live |
| Punkt 3 — Stamm-Auflösung | 54 | `keymap-not-live` 84 → 0, `usercmd-not-live` 31 → 2 |
| Punkt 2 — Usercmd-Fallback | **52** | `usercmd-not-live` 2 → 0 |

### Die Zahl, die neben jeder dieser Zahlen stehen muss

**1377 dokumentierte Zeilen wurden in diesem Lauf gar nicht geprüft**, weil
ihr Plugin nicht geladen war (extern 541, personal 836). Der Bericht druckt
das jetzt selbst, direkt unter der übersprungenen Plugin-Liste — vorher stand
dort nur die Anzahl *Plugins*, und 17 übersprungene Plugins klingen nach
weniger als 541 ungeprüften Zeilen.

Punkt 3 hat 84 `keymap-not-live` nicht repariert, sondern als das kenntlich
gemacht, was sie waren: Aussagen über Plugins, die diese Session nie geladen
hat. **Wo sie wirklich hingehören**, zeigt ein Lauf mit allen 17
Extern-Plugins per `Lazy! load` geladen — `skipped` 0, `keymap-not-live`
**16**, genau die Handvorhersage; 13 davon reine Notationsdifferenzen.
Dieselbe Frage stellt `:Bindings check repo extern` ohne Laden: 18
`keymap-not-in-repo` in 1146 ms.

Dazu unverändert die zwei Autocmds-Zahlen unter jedem Bericht (112
dokumentierte Zeilen nicht prüfbar, 122 Registrierungen zuzuordnen).

---

## Wo weiterarbeiten

|          |                                                                            |
| -------- | -------------------------------------------------------------------------- |
|   Repo   |             nvim-config (`C:/Users/bartl/AppData/Local/nvim`)              |
|  Branch  |         `main` — dort steht alles, siehe die Anmerkung darunter           |
| Worktree |                        keiner mehr nötig, siehe unten                      |
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

## Offene Punkte

Einer, und er ist kein Bauauftrag: die einzige Frage des ganzen Blocks, die
nicht durch Messen zu klären ist.

---

### 5 — Die Scope-Entscheidung, die seit vier Blöcken offen ist

**Soll `ExternPlugins/Bindings` fremde Commands ohne Cheatsheet überhaupt
abdecken?**

Die 41 undokumentierten Live-Commands, nach den erledigten Punkten:

| Gruppe | n | Anmerkung |
| --- | ---: | --- |
| lazy.nvim `cmd`-Stubs | 15 | existieren nur, um das Laden auszulösen — markdown-preview 3, mason 2, minty 2, nvim-tree 2, vim-table-mode 2, render-markdown/resty/screenkey/zen-mode je 1 |
| Neovims eigene | 4 | `:Inspect` `:InspectTree` `:EditQuery` `:Man` — nie im Scope |
| **Plugin ohne jedes Blatt** | **22** | hier steht die Entscheidung an |

Die 22 im Einzelnen:

| Plugin | n | Commands |
| --- | ---: | --- |
| `git-conflict.nvim` | 9 | `:GitConflictChooseBase/Both/None/Ours/Theirs`, `:GitConflictListQf`, `:GitConflictNextConflict`, `:GitConflictPrevConflict`, `:GitConflictRefresh` |
| `vim-matchup` | 6 | `:DoMatchParen` `:NoMatchParen` `:MatchupReload` `:MatchupWhereAmI` `:MatchupClearTimes` `:MatchupShowTimes` |
| `nvim-puppeteer` | 3 | `:PuppeteerEnable/Disable/Toggle` |
| `plenary.nvim` | 2 | `:PlenaryBustedFile` `:PlenaryBustedDirectory` |
| `vim-startuptime` | 1 | `:StartupTime` |
| `nvim-web-devicons` | 1 | `:NvimWebDeviconsHiTest` |

**Wer die Frage beantworten will, beantwortet sie an git-conflict.nvim**: ein
Plugin, das benutzt wird und im Korpus nicht vorkommt. Lohnt sich ein
`Usercmds/GitConflict.md`, oder ist ein Plugin ohne Cheatsheet legitim?

Drei Beobachtungen dazu, die seit dem letzten Stand dazugekommen sind:

* **Die Eigentümerspalte nennt jetzt Namen.** `vim-matchup`, `plenary.nvim`
  und `vim-startuptime` standen vorher als `vimscript script_id=N` da und
  waren als Gruppe gar nicht erkennbar (Punkt 1).
* **Ein Blatt kostet mehr als seine Zeilen.** `Usercmds/Noice.md` hat 13
  undokumentierte Commands beseitigt und dabei zeitweise 14 `not-live`
  erzeugt — beseitigt erst durch Punkt 3. Wer ein Blatt für ein lazy-Plugin
  schreibt, schreibt Zeilen, die der Standardlauf nur überspringen kann.
* **Die Grenze verläuft vielleicht nicht am Plugin, sondern am Gebrauch.**
  `:PlenaryBustedFile` und `:StartupTime` sind Werkzeug-Commands, die man
  einmal im Quartal tippt; die neun von git-conflict sind ein Workflow.

Nebenbei aufgefallen und eine eigene Frage: **`:NvimTreeFocus`/`:NvimTreeToggle`
sind lazy-Stubs von `nvim-tree.lua`, und diese Config benutzt neo-tree.** Ob
nvim-tree überhaupt installiert bleiben soll, ist keine Korpus-Frage.

---

## Was ausdrücklich *nicht* offen ist

Damit es nicht ein weiteres Mal untersucht wird:

* **Die Options-Pfade in `Keymaps/insights.nvim.md`** (`def_cfg.keymaps.jump`
  & Co. in der Key-Spalte) sind **kein** Format-Defekt. `first_token` liest die
  Form `` `pfad` (`taste`) `` richtig und nimmt die Klammer-Gruppe; die Zeilen
  werden geprüft und sind bestätigt. Eine frühere Gegenmessung kam von einem
  eigenen Dump, der `first_token` nicht benutzt hat.
* **`<leader>th`** ist kein Konflikt, sondern Cross-Scope-Shadowing, und steht
  vollständig in `Keymaps/Collisions.md`. Zwei der vier ursprünglich
  vermuteten Ansprüche existieren nicht.
* **Die 7 `keymap-not-in-repo`** von `debugging.nvim` sind dessen zur Laufzeit
  gebautes `prefix .. "m"` — der dokumentierte Falschbefund der Grep-Achse,
  nur unter `:Bindings check repo` sichtbar. Kein Handlungsbedarf, solange die
  Achse als Grep gekennzeichnet ist. **Dieselbe Klasse, neu belegt:** noice
  generiert seine 17 Einzelcommands aus den Keys seiner Command-Tabelle
  (`"Noice" .. key`), im Quelltext steht `stats` und nie `NoiceStats` — 13
  `usercmd-not-in-repo` unter `check repo extern`, alle unecht.
* **`:UnicodeDownload`/`:DigraphNew` bleiben unauffindbar**, und das ist keine
  Lücke, die man schließt. Sie stehen als `com! -bang UnicodeDownload …`,
  also **unquoted**, und `repo.mentions` matcht nur Quoted-Literals.
* **Die Familien-Notation gilt auch für Augroups** (`records.wildcard_pattern`).
  Der Korpus schrieb `ra_telemetry_<namespace>` und `LspSignaturePopup_<winid>`
  längst; die Notation musste nicht erfunden werden. Gebunden an Tabellenzeile
  und Eigentümer wie die Command-Familien, nur in die
  Undokumentiert-Richtung, eigene Zeichenklasse (Augroupnamen enthalten `.`
  und `-`). `autocmd-undocumented` fiel damit von 16 auf **0**.
* **Das Autocmds-Blatt für nvim-config existiert** (`Autocmds/nvim-config.md`).
  55 Aufrufstellen: 40 in 26 Augroups, 15 ohne jede Augroup. Zwei Zeilen sind
  bewusst Generatoren statt Listen.
* **Die Autocmds-Achse ist gebaut** (`21ed8082`). Beide Richtungen, die
  Zählfalle über `(Augroup, Event)`-Paare umgangen. Begründung und Grenzen in
  FEATURES.md, „Die Autocmds-Achse".
* **`:NoiceError` gibt es nicht** und gab es nie: noice baut seine
  Einzelcommands aus den Keys seiner Command-Tabelle, und der Key heißt
  `errors`. Der Name stand nur in der lazy-`cmd`-Liste dieser Config — der
  Stub lud noice, tat sonst nichts, und beim zweiten Aufruf kam E492.
  Korrigiert in `lua/plugins/ui.lua`.
* **conform.nvim und nvim-treesitter haben sehr wohl eigene Usercmds.** Beide
  Blätter behaupteten das Gegenteil; der Prüfer hat es gefunden. Bei
  Treesitter hatte die Prosa des Blattes zwei Commands (`:TSInstall`,
  `:TSUpdate`) als *entfallen* erwähnt — und eine Erwähnung reicht der
  Undokumentiert-Richtung, auch wenn sie das Gegenteil behauptet.
* **cmdlog.nvims `ctrl-f`/`ctrl-t`** sind erledigt: der Code hat sie seit dem
  Merge `ed60f8f` nicht mehr, die Doku ist in beiden Repos nachgezogen.
* **Der Teilstring-Resolver ist geprüft und verworfen.** „Längster passender
  Teilstring" liegt über dem echten Korpus zweimal still daneben
  (`Telescope` → `telescope-file-browser.nvim`, `NeoTree` →
  `neo-tree-tests-source.nvim`), der kürzeste verschiebt nur, welche Paare er
  falsch macht. Die drei Schritte in `stem_plugin` lösen 21 der 24 Stämme
  auf, die drei übrigen tragen ihre `**Repo:**`-Zeile.

---
