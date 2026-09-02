# Handover — BINDINGS-Drift, was noch offen ist

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

| Route | Befunde |
| --- | ---: |
| `:Bindings check` | **1** (`:LibLogger`, bestätigter Nicht-Befund) |
| `:Bindings check extern` | **154** — die Punkte unten |
| `:Bindings check all` | 155 |

## Wo weiterarbeiten

| | |
| --- | --- |
| Repo | nvim-config (`C:/Users/bartl/AppData/Local/nvim`) |
| Branch | `claude/bindings-drift-followups-7946d4`, deckungsgleich mit `origin/main` |
| Worktree | `.claude/worktrees/plugin-roadmap-review-3cb74b` |
| Stand | alles committet und gepusht, Haupt-Checkout nachgezogen |

Vor jeder Messung: [MEASURING.md](../../../../lua/bindings/usrcmds/bindings_explorer/docs/MEASURING.md),
Abschnitt „Die fünf Fallen". Headless ohne diese drei Vorkehrungen sind die
Zahlen unten nicht reproduzierbar.

---

# Offene Punkte

Alle fünf sind gemessen, keiner ist gebaut. Die Reihenfolge ist die
vorgeschlagene: 1 ist ein Defekt, 2–3 senken die Zahl, 4–5 sind
Korpus-Entscheidungen.

## 1 — Die Eigentümerspalte druckt eine Zahl, die zwischen zwei Läufen wechselt

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

## 2 — Der Quelltext-Fallback fehlt auf der Usercmd-Achse

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

## 3 — Extern-Stämme lassen sich nicht auf lazy-Plugins auflösen

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

## 4 — Elf Cheatsheet-Zeilen, deren Sheet schon existiert

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

## 5 — Die Scope-Entscheidung, die seit drei Blöcken offen ist

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

# Was ausdrücklich *nicht* offen ist

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
* **cmdlog.nvims `ctrl-f`/`ctrl-t`** sind erledigt: der Code hat sie seit dem
  Merge `ed60f8f` nicht mehr, die Doku ist in beiden Repos nachgezogen. Die
  Entscheidung war „Doku auf die Realität ziehen", nicht „Feature
  wiederherstellen".
