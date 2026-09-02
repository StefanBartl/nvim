# Handover — BINDINGS-Drift, was noch offen ist

## Table of content

  - [Aktueller Stand](#aktueller-stand)
  - [Wo weiterarbeiten](#wo-weiterarbeiten)
  - [Offene Punkte](#offene-punkte)
    - [1 — Die Eigentümerspalte druckt eine Zahl, die zwischen zwei Läufen wechselt](#1-die-eigentmerspalte-druckt-eine-zahl-die-zwischen-zwei-lufen-wechselt)
    - [2 — Der Quelltext-Fallback fehlt auf der Usercmd-Achse](#2-der-quelltext-fallback-fehlt-auf-der-usercmd-achse)
    - [3 — Extern-Stämme lassen sich nicht auf lazy-Plugins auflösen](#3-extern-stmme-lassen-sich-nicht-auf-lazy-plugins-auflsen)
    - [4 — Elf Cheatsheet-Zeilen, deren Sheet schon existiert](#4-elf-cheatsheet-zeilen-deren-sheet-schon-existiert)
    - [5 — Die Scope-Entscheidung, die seit drei Blöcken offen ist](#5-die-scope-entscheidung-die-seit-drei-blcken-offen-ist)
    - [7 — Die Config hat kein Autocmds-Blatt](#7-die-config-hat-kein-autocmds-blatt)
  - [Was ausdrücklich *nicht* offen ist](#was-ausdrcklich-nicht-offen-ist)

---

## Aktueller Stand

Stand 2026-09-02, abends. Die Blöcke 1–3 dieser Datei sind erledigt und
ersatzlos entfernt; was von ihnen dauerhaft gilt, steht jetzt dort, wo es
hingehört:

| Was | Wo es steht |
| --- | --- |
| Wie man misst, und die fünf Fallen dabei | [`bindings_explorer/docs/MEASURING.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md) |
| Alle gemessenen Stände mit Datum | dieselbe Datei, „Gemessene Stände" |
| Was die Routen tun und warum so | [`bindings_explorer/docs/FEATURES.md`](../../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md) |
| `<leader>th`, Cross-Scope-Shadowing, freie `t`-Tasten | [`Keymaps/Collisions.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md) |
| Der cmdlog-Fund und seine Aufklärung | [`Keymaps/cmdlog.nvim.md`](../../../NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md) |
| Der Wortlaut der erledigten Blöcke 1–2 | [ERLEDIGT-Archiv](../../personal/All/FINISH/ERLEDIGT/Bindings/bindings-drift-followups-2026-09-02.md) |

**Wo der Prüfer heute steht:**

| Route | Befunde | davon Autocmds |
| --- | ---: | --- |
| `:Bindings check` | **56** | 8 nicht registriert, 47 nicht dokumentiert |
| `:Bindings check extern` | **158** | 4 nicht registriert |
| `:Bindings check all` | **214** | 12 / 47 |

Vor der Autocmds-Achse waren es 1 / 154 / 155; die Differenz ist
ausschließlich sie. Dazu zwei Zahlen unter jedem Bericht: **102 dokumentierte
Zeilen nicht prüfbar**, **116 Registrierungen zuzuordnen** — damit eine kleine
Befundzahl nicht mit einer gründlichen Prüfung verwechselt wird.

**Nachgemessen 2026-09-02, später Abend** (headless, UIReady-Phase
nachgeholt, Haupt-Checkout deckungsgleich mit `origin/main` — also ohne die
Worktree-Vorkehrungen aus Fallen 2 und 3): **1 / 154 / 155, unverändert**.
Aufschlüsselung extern: `keymap-not-live` 84, `usercmd-not-live` 16,
`usercmd-undocumented` 54. Die Zahlen oben gelten also weiter, und keiner der
Commits seit ihrer Aufnahme hat sie bewegt.

---

## Wo weiterarbeiten

|          |                                                                            |
| -------- | -------------------------------------------------------------------------- |
|   Repo   |             nvim-config (`C:/Users/bartl/AppData/Local/nvim`)              |
|  Branch  |         `main` — dort steht alles, siehe die Anmerkung darunter           |
| Worktree |                        keiner mehr nötig, siehe unten                      |
|  Stand   |          alles committet und gepusht, Haupt-Checkout nachgezogen           |

An diesem Block haben zwei Sessions parallel gearbeitet, aus zwei Worktrees
(`plugin-roadmap-review-3cb74b` auf `claude/bindings-drift-followups-7946d4`
und `plugin-roadmap-review-277621` auf `claude/nvim-config-tasks-56c97f`).
Beide haben nach `origin/main` gepusht, beide sind damit deckungsgleich, und
`main` ist die einzige Quelle, die man dazu noch braucht — die zwei Branches
stehen hier nur, damit ein Blick in `git log` sie einordnen kann.

Vor jeder Messung: [MEASURING.md](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md),
Abschnitt „Die fünf Fallen". Headless ohne diese drei Vorkehrungen sind die
Zahlen unten nicht reproduzierbar.

---

## Offene Punkte

Alle fünf sind gemessen, keiner ist gebaut. Die Reihenfolge ist die
vorgeschlagene: 1 ist ein Defekt, 2–3 senken die Zahl, 4–5 sind
Korpus-Entscheidungen. Punkt 6 (die Autocmds-Achse) ist **gebaut** und steht
jetzt unter „Was ausdrücklich *nicht* offen ist"; was er zutage gefördert hat,
steht als Punkt 7 daneben.

---

### 1 — Die Eigentümerspalte druckt eine Zahl, die zwischen zwei Läufen wechselt

**Ein Defekt, kein Ausbau.** `command_owner` fällt für Vimscript-Commands auf
`("vimscript script_id=%d"):format(def.script_id)` zurück
(`drift.lua`, ~Z. 681). Die `script_id` ist aber **sitzungsabhängig**.
Zweimal derselbe Lauf:

```
TodoLocList   sid=25  ->  sid=12
StartupTime   sid=9   ->  sid=25
DoMatchParen  sid=13  ->  sid=16
```

Der Bericht behauptet damit eine Herkunft, die nichts identifiziert und beim
nächsten Aufruf anders lautet. **11 der 54 undokumentierten Commands** tragen
dieses Label.

**Lösung, gemessen und funktionierend:** `vim.fn.getscriptinfo({ sid = N })`
liefert den echten Pfad —

```
sid=12  lazy/todo-comments.nvim/plugin/todo.vim   TodoFzfLua TodoLocList
sid=16  lazy/vim-matchup/plugin/matchup.vim       DoMatchParen NoMatchParen
sid=10  lazy/plenary.nvim/plugin/plenary.vim      PlenaryBustedDirectory …
```

— und das ist genau die Form, die `owner_of_path` für Lua-Quellen bereits
verarbeitet. Der Pfad muss also nur dort hineingereicht werden, statt die id
zu formatieren.

**Zwei Folgen, die dranhängen:** `owner_plugin` verwirft heute jedes
`^vimscript script_id=` ausdrücklich als „third-party by construction"
(`drift.lua:582`) — mit einem echten Namen greift die Scope-Trennung dort
wieder. Und zwei der elf bekämen damit ein Cheatsheet-Ziel, das es gibt:
`:TodoFzfLua`/`:TodoLocList` gehören zu `todo-comments.nvim`, und
`TodoComments` ist einer der 24 Stämme des Extern-Korpus.

---

### 2 — Der Quelltext-Fallback fehlt auf der Usercmd-Achse

Der Fallback (siehe FEATURES.md) läuft nur auf der Keymap-Achse. Auf der
Usercmd-Achse wäre er dieselbe Frage an dieselbe Quelle — **case-sensitiv**,
so wie die bestehende opt-in-Achse Commandnamen schon fragt (sonst trifft
`:Images` das Wort „images" in jeder zweiten Zeile).

Gemessen:

| Scope | `usercmd-not-live` heute | mit Fallback |
| --- | ---: | ---: |
| `personal` | 1 | **1** |
| `extern` | 16 | **2** |

`personal` bleibt bei 1, und das ist das gewünschte Ergebnis: `:LibLogger`
steht in lib.nvim nirgends als Quoted-Literal, die Achse behält ihre eine
ehrliche Meldung.

**Warum extern so stark fällt — der eigentliche Fund:** 13 der 16 sind gar
keine Plugin-Commands, sondern **Wrapper dieser Config selbst**, im
extern-Korpus dokumentiert und dort ausdrücklich als `[custom]` markiert:

| Sheet | Commands | Registriert in |
| --- | ---: | --- |
| `Usercmds/Neotest.md` | 8 | `lua/config/neotest/{commands,debug,utils}/` |
| `Usercmds/Lazygit.md` | 2 | `lua/config/lazygit/actions/` |
| `Usercmds/NeoTree.md` | 2 | `config.neotree.checkhealth` / `.sources.switcher` |
| `Usercmds/NvChadUI.md` | 1 | `lua/nvchad/au.lua` (lokale Override-Kopie) |

Sie sind nur deshalb nicht live, weil ihre Plugins lazy sind — der `lua/`-Baum
dieser Config findet alle 13.

Übrig blieben `:UnicodeDownload` und `:DigraphNew`. Die stehen in
`plugin/unicode.vim` als `com! -bang UnicodeDownload …`, also **unquoted**, und
sind für `repo.mentions` strukturell unsichtbar. Das ist keine Lücke, die man
schließt, sondern eine, die man benennt.

---

### 3 — Extern-Stämme lassen sich nicht auf lazy-Plugins auflösen

**Die strukturelle Ursache hinter 84 der 154 Befunde.** Kein einziger
Cheatsheet-Stamm des Extern-Korpus trifft einen lazy-Plugin-Namen:

```
Diffview -> diffview.nvim      Fugitive -> vim-fugitive
Telescope -> telescope.nvim    VisualMulti -> vim-visual-multi
NeoTree -> neo-tree.nvim       NvChadUI -> NvChad
```

Zwei Folgen, beide sichtbar:

* `repo_dirs[rec.plugin]` trifft nie → der Fallback kann dort nur den
  `lua/`-Baum der Config fragen, nie den Baum des Plugins.
* `is_plugin_loaded(rec.plugin)` kennt den Namen nicht und behandelt ihn als
  „immer geladen" → **`skipped` ist im extern-Scope immer 0**, jede Zeile wird
  gegen den Live-Zustand geprüft, ob ihr Plugin geladen ist oder nicht.

Mit den Verzeichnissen von Hand aufgelöst gemessen:

| | n |
| --- | ---: |
| `keymap-not-live` | 84 |
| stünde als Quoted-Literal im Plugin-Baum | **66** |
| nur roh auffindbar (Vimscript, unquoted) | 2 |
| bliebe übrig | **16** |

Von den 16 sind 13 reine Notationsdifferenzen — Telescope schreibt `<A-c>`,
die Quelle `<M-c>` (8×); die VisualMulti-Zeilen tragen den Leader `\\` im Key,
die Quelle nicht (5×) — plus `["x]y<C-G>`, das keine Taste ist, sondern eine
Register-Notation. **Echte Kandidaten: höchstens 2.**

**Die Falle beim Resolver:** der naive „längster passender Teilstring" liegt
zweimal daneben, und zwar still —

```
Telescope -> telescope-file-browser.nvim   (statt telescope.nvim)
NeoTree   -> neo-tree-tests-source.nvim    (statt neo-tree.nvim)
```

Ein exakter normalisierter Treffer zuerst, Teilstring nur als Rückfall und
dann der **kürzeste** statt der längste, wäre die naheliegende Korrektur —
ungeprüft. Alternativ eine kleine explizite Zuordnung im Korpus selbst, etwa
eine Kopfzeile im Cheatsheet, die das Repo nennt. Das hätte den Vorteil, dass
es nicht rät.

---

### 4 — Elf Cheatsheet-Zeilen, deren Sheet schon existiert

Die billigsten Zeilen im ganzen Bericht: das Sheet gibt es, nur die Zeile
fehlt. Reine Doku-Arbeit, keine Codeänderung.

| Sheet | Fehlende Commands |
| --- | --- |
| `Usercmds/Conform.md` | `:ConformInfo` |
| `Usercmds/Gitsigns.md` | `:Gitsigns` |
| `Usercmds/Noice.md` | `:NoiceAll` `:NoiceDismiss` `:NoiceError` `:NoiceHistory` |
| `Usercmds/Treesitter.md` | `:TSInstallFromGrammar` `:TSLog` `:TSUninstall` |
| `Usercmds/NvChadUI.md` | `:NvCheatsheet` `:Nvdash` |

Plus zwei weitere, sobald Punkt 1 gebaut ist: `:TodoFzfLua`/`:TodoLocList` in
`Usercmds/TodoComments.md`.

---

### 5 — Die Scope-Entscheidung, die seit drei Blöcken offen ist

**Soll `ExternPlugins/Bindings` fremde Commands ohne Cheatsheet überhaupt
abdecken?** Die Frage ist nie beantwortet worden, und sie ist die einzige, die
nicht durch Messen zu klären ist.

Was die 54 undokumentierten Live-Commands sind, nach Punkt 4 abgezogen:

| Gruppe | n | Anmerkung |
| --- | ---: | --- |
| Sheet existiert (Punkt 4) | 11 | zu erledigen, unabhängig von dieser Frage |
| Neovims eigene | 4 | `:Inspect` `:InspectTree` `:EditQuery` `:Man` — nie im Scope |
| lazy.nvim `cmd`-Stubs | ~20 | existieren nur, um das Laden auszulösen |
| Plugin ohne jedes Sheet | 19 | hier steht die Entscheidung an |

Der größte einzelne Block der 19 ist **git-conflict.nvim mit 9 Commands** —
ein Plugin, das benutzt wird und im Korpus nicht vorkommt. Wer die Frage
beantworten will, beantwortet sie am besten an diesem Beispiel: lohnt sich ein
`Usercmds/GitConflict.md`, oder ist ein Plugin ohne Cheatsheet legitim?

Die anderen zehn: markdown-preview (3), nvim-puppeteer (3), mason (2), minty
(2), nvim-tree (2), vim-table-mode (2), render-markdown, resty, screenkey,
zen-mode, nvim-web-devicons (je 1). **`:NvimTreeFocus`/`:NvimTreeToggle` fallen
dabei auf** — diese Config benutzt neo-tree; ob nvim-tree noch installiert
sein soll, ist eine eigene Frage.

---

### 7 — Die Config hat kein Autocmds-Blatt

**Der strukturelle Fund der neuen Achse.** 35 der 47 undokumentierten
Autocmds gehören `nvim-config` selbst — registriert in `lua/config/**` und
`lua/wkdnvchad/**` —, und ein `Autocmds/nvim-config.md` gibt es nicht. Der
Korpus ist nach Plugins geschnitten, und für die Autocmds der Config hat er
nie einen Ort gehabt.

Dieselbe Lücke, die die Usercmd-Seite mit `:MyOpt*`/`:WKDOptions*` hatte, mit
einem Unterschied: dort existierte `Usercmds/nvim-config.md` bereits und es
fehlten nur die Zeilen. Hier fehlt das Blatt.

Die übrigen 12 verteilen sich so:

| Eigentümer | n | Anmerkung |
| --- | ---: | --- |
| `nvim-config` | 35 | kein Blatt — der Punkt oben |
| runtime-analysis.nvim | 15 | `ra_telemetry_<plugin>`, eine **generierte Familie** |
| lib.nvim | 1 | `LibNvimUsrCmdsHelptags` |

Die 15 sind derselbe Fall wie pickers.nvims 23 Scope-Commands: eine Augroup
pro telemetriefähigem Plugin, aus einer Schleife. Derselbe Vorschlag also —
den Generator dokumentieren, nicht seine Ergebnisse. Ob die Familien-Notation
(`records.command_globs`, heute nur für Commands) dafür auf Augroups
ausgedehnt wird, ist die Entwurfsfrage dahinter.

Und noch eine Zahl, die zu diesem Punkt gehört: **102 dokumentierte Zeilen
sind nicht prüfbar**, weil ihr Sheet die Augroup in keiner Spalte nennt. Die
Prosa-Rückfallebene fängt das für die eine Richtung ab; für die andere bleibt
es eine Format-Entscheidung am Korpus.

---

## Was ausdrücklich *nicht* offen ist

Damit es nicht ein drittes Mal untersucht wird:

* **Die Options-Pfade in `Keymaps/insights.nvim.md`** (`def_cfg.keymaps.jump`
  & Co. in der Key-Spalte) sind **kein** Format-Defekt. `first_token` liest die
  Form `` `pfad` (`taste`) `` richtig und nimmt die Klammer-Gruppe; die Zeilen
  werden geprüft und sind bestätigt. Eine frühere Gegenmessung kam von einem
  eigenen Dump, der `first_token` nicht benutzt hat.
* **`<leader>th`** ist kein Konflikt, sondern Cross-Scope-Shadowing, und steht
  vollständig in `Keymaps/Collisions.md`. Zwei der vier ursprünglich
  vermuteten Ansprüche existieren nicht.
* **Die 7 `keymap-not-in-repo`** sind unverändert `debugging.nvim`s zur
  Laufzeit gebautes `prefix .. "m"` — der dokumentierte Falschbefund der
  Grep-Achse, nur unter `:Bindings check repo` sichtbar. Kein Handlungsbedarf,
  solange die Achse als Grep gekennzeichnet ist.
* **Die Autocmds-Achse ist gebaut** (`21ed8082`), Punkt 6 dieser Datei.
  Beide Richtungen: vorwärts gegen `nvim_get_autocmds`, rückwärts gegen
  lib.nvims Registry. Die Zählfalle (Aufrufstellen gegen
  Event-Registrierungen) ist umgangen, indem beide Seiten zu
  `(Augroup, Event)`-Paaren flachgeklopft werden und nie eine Zahl mit einer
  anderen verglichen wird. Begründung und Grenzen in
  [FEATURES.md](../../../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md),
  Abschnitt „Die Autocmds-Achse"; die Messung in MEASURING.md.
* **Die zwei Autocmds von `b260fc8`** sind nachgetragen (lsp.nvim `89f68fc`,
  nvim-config `b7e3df80`) — die *Seite* stimmt wieder. Was daraus folgt, ist
  Punkt 6: dass sie es nicht von selbst getan hat.
* **cmdlog.nvims `ctrl-f`/`ctrl-t`** sind erledigt: der Code hat sie seit dem
  Merge `ed60f8f` nicht mehr, die Doku ist in beiden Repos nachgezogen. Die
  Entscheidung war „Doku auf die Realität ziehen", nicht „Feature
  wiederherstellen".

---

