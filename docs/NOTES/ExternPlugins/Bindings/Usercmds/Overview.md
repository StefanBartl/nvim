# Usercmds — was dieser Korpus abdeckt, und was bewusst nicht

Eine Meta-Datei, kein Cheatsheet. Sie dokumentiert kein Plugin, sondern die
**Regel**, nach der entschieden wird, ob ein fremdes Plugin hier eines
bekommt — und sie nennt namentlich die Commands, die bewusst keines haben.

`records.lua` markiert `Overview.md` als `meta`
(siehe dort `META_FILES`, neben `All.md` und `Collisions.md`). Das hat zwei
Folgen, und beide sind hier gewollt:

* Ein Command, der in dieser Datei steht, gilt für die
  **Undokumentiert-Richtung** als erwähnt und erzeugt keinen Befund mehr.
* Für die **Nicht-live-Richtung** zählt er *nicht* — diese Datei besitzt
  nichts, sie verweist nur. Eine Zeile hier kann also nie als „dokumentiert,
  aber nicht registriert" zurückkommen.

Das ist genau die Eigenschaft, die eine Ignore-Liste im Quelltext hätte —
nur steht die Begründung hier, im Korpus, statt in einer Tabelle, die
niemand liest.

---

## Table of content

  - [Die Regel](#die-regel)
  - [Bewusst ohne eigenes Blatt](#bewusst-ohne-eigenes-blatt)
  - [Nicht im Scope: Neovims eigene](#nicht-im-scope-neovims-eigene)
  - [Nicht im Scope: lazy-`cmd`-Stubs](#nicht-im-scope-lazy-cmd-stubs)
  - [Was die Null nicht heißt](#was-die-null-nicht-heit)

---

## Die Regel

Entschieden am **2026-09-02**, an Punkt 5 des Drift-Handovers, nachdem die
Frage vier Blöcke lang offen stand.

> **Ein fremdes Plugin bekommt ein Usercmds-Blatt, wenn seine Commands zu
> einem Arbeitsablauf gehören. Werkzeug-Commands, die man einmal im Quartal
> tippt, bekommen stattdessen eine Zeile hier.**

Die Grenze verläuft also **am Gebrauch, nicht am Plugin**. Der Testfall war
`git-conflict.nvim`: neun Commands, ein täglich benutztes Plugin, und im
Korpus kam es nicht vor — das hat ein Blatt bekommen. `:StartupTime` hat
keines bekommen, obwohl es genauso ein fremdes Live-Command ist.

Warum nicht einfach alles dokumentieren: ein Blatt kostet mehr als seine
Zeilen. Es wird von da an bei jedem Lauf geprüft, und für ein lazy geladenes
Plugin schreibt man damit Zeilen, die der Standardlauf nur überspringen kann
(`Usercmds/Noice.md` hat das vorgeführt — 13 undokumentierte Commands
beseitigt und zeitweise 14 `not-live` erzeugt).

Warum nicht einfach gar nichts dokumentieren: dann bleiben 22 Befunde
dauerhaft im Bericht stehen, und ein Bericht mit dauerhaftem Rauschen wird
nicht gelesen.

---

## Bewusst ohne eigenes Blatt

Fünf Commands aus vier Plugins. Alle fünf sind Werkzeuge, keine
Arbeitsabläufe: man tippt sie, wenn man etwas untersucht oder repariert,
nicht wenn man etwas tut.

| Command | Plugin | Was es tut | Warum kein Blatt |
|---|---|---|---|
| `:PlenaryBustedFile` | `plenary.nvim` | Führt eine einzelne busted-Testdatei in einer Neovim-Instanz aus. | Test-Runner der Bibliothek. Wer ihn braucht, arbeitet gerade an einem Plugin und kennt ihn; die Personal-Repos rufen ihn aus ihren eigenen Test-Skripten auf, nicht von Hand. |
| `:PlenaryBustedDirectory` | `plenary.nvim` | Dasselbe für ein ganzes Verzeichnis. | dito |
| `:StartupTime` | `vim-startuptime` | Misst und visualisiert die Startzeit. | Ein Command, ein Zweck, kein Zustand und keine Argumente, die man nachschlagen müsste. Diese Config hat mit `startup.lua` ohnehin eine eigene Startphasen-Messung. |
| `:NvimWebDeviconsHiTest` | `nvim-web-devicons` | Zeigt alle Icon-Highlights zur Sichtprüfung. | Ein Debug-Command der Icon-Bibliothek. Er wird benutzt, wenn ein Theme kaputt aussieht, und dann sucht man ihn nicht im Cheatsheet. |
| `:BlinkCmp {status\|build\|build-log}` | `blink.cmp` | `status` ruft `:checkhealth blink.cmp`, `build` baut die Fuzzy-Matcher-Bibliothek neu, `build-log` zeigt deren Build-Log. | Wartung der Completion-Engine, kein Bedienelement. Man tippt es einmal nach einem Update, wenn die Completion stumm bleibt. Die Keymaps, mit denen man blink tatsächlich benutzt, stehen in [Keymaps/Blink.md](../Keymaps/Blink.md). |

Wer eines davon doch regelmäßig benutzt, verschiebt es in ein eigenes Blatt —
die Regel oben ist der Maßstab, nicht diese Liste.

---

## Nicht im Scope: Neovims eigene

`:Inspect` `:InspectTree` `:EditQuery` `:Man`

Sie kommen aus Neovims Runtime (`_core/defaults.lua`, `plugin/man.lua`), nicht
aus einem Plugin. Der Korpus dokumentiert, was diese Config und ihre Plugins
mitbringen; Neovims eigene Oberfläche steht in `:help`. Sie stehen hier nur,
damit die Frage nicht ein zweites Mal gestellt wird.

---

## Nicht im Scope: lazy-`cmd`-Stubs

Fünfzehn Commands, die lazy.nvim aus der `cmd`-Liste eines Specs erzeugt und
die genau eines tun: das Plugin laden. Danach löscht lazy sie wieder und das
Plugin legt seine echten an — `Usercmds/Noice.md` beschreibt diesen
Lebenszyklus im Detail, samt der Falle, dass beide Sätze nie gleichzeitig
existieren.

| Plugin | Stubs |
|---|---|
| `markdown-preview.nvim` | `:MarkdownPreview` `:MarkdownPreviewStop` `:MarkdownPreviewToggle` |
| `mason.nvim` | `:Mason` `:MasonUpdate` |
| `minty` | `:Huefy` `:Shades` |
| `nvim-tree.lua` | `:NvimTreeToggle` `:NvimTreeFocus` |
| `vim-table-mode` | `:TableModeToggle` `:Tableize` |
| `render-markdown.nvim` | `:RenderMarkdown` |
| `resty.nvim` | `:Resty` |
| `screenkey.nvim` | `:Screenkey` |
| `zen-mode.nvim` | `:ZenMode` |

Einen Stub zu dokumentieren hieße, den Ladeauslöser zu dokumentieren statt
das Feature. Wo eines dieser Plugins ein Blatt verdient, gehört dort sein
*geladener* Command-Satz hinein, nicht der Stub.

**Eine Anmerkung zu `nvim-tree.lua`:** diese Config benutzt neo-tree, und
kein Spec unter `lua/` deklariert nvim-tree. Es bleibt trotzdem installiert —
`filetree.nvim` unterstützt es als Adapter-Alternative, und es lädt ohnehin
nur auf Command. Kein Handlungsbedarf, entschieden am 2026-09-02.

---

## Was die Null nicht heißt

Nach den Entscheidungen oben meldet `:Bindings check all` **null**
undokumentierte Live-Commands. Diese Null ist eine Aussage über die
*Session*, nicht über den Korpus, und das ist gemessen, nicht vermutet.

Derselbe Lauf, mit den 17 Extern-Plugins per `Lazy! load` geladen — also dem
Zustand, den ein benutzter Editor nach einer Weile erreicht. Gemessen am
Vormittag des 2026-09-02, **bevor** die Blätter dieses Abschnitts
geschrieben waren:

| | Standardlauf | alle geladen |
| --- | ---: | ---: |
| `usercmd-undocumented` | 0 | **80** |
| `keymap-not-live` | 0 | 16 |
| übersprungene Stämme (extern) | 17 | 0 |

Die 80 waren, nach Eigentümer:

| Plugin | n | Anmerkung |
| --- | ---: | --- |
| `vim-fugitive` | 30 | `:G` `:Git` `:GDelete` `:GMove` `:GRename` `:Gdiffsplit` … — hat ein Keymaps-Blatt, aber keines für seine Commands |
| `nvim-dap` | 13 | `Usercmds/Dap.md` dokumentiert den eigenen Wrapper `dap.nvim`, nicht nvim-daps eigene |
| `nvim-dap-view` | 11 | `:DapView*` — dieselbe Lücke |
| `vim-visual-multi` | 7 | Keymaps-Blatt vorhanden, Commands nicht |
| `vim-test` | 6 | im Korpus bisher gar nicht |
| `nvim-dap-virtual-text` | 4 | `:DapVirtualText*` — die Eigentümerspalte sagt hier `vimscript script_id=-8`, siehe unten |
| `neogit` | 3 | |
| `unicode.vim`, `diffview.nvim` | je 2 | |
| `neotest`, `blink.cmp` | je 1 | |

**Erledigt am 2026-09-02**, nach derselben Regel. Sechs neue Blätter —
[`Fugitive`](./Fugitive.md) (36 Commands), [`DapView`](./DapView.md) (11),
[`Diffview`](./Diffview.md) (7), [`VisualMulti`](./VisualMulti.md) (7),
[`Neogit`](./Neogit.md) (4), [`DapVirtualText`](./DapVirtualText.md) (4) —
und drei erweiterte: [`Dap`](./Dap.md) um nvim-daps eigene fünfzehn,
[`Neotest`](./Neotest.md) um `:Neotest` und vim-tests sechs,
[`Unicode`](./Unicode.md) um zwei Aliase. `:BlinkCmp` steht als Werkzeug in
der Tabelle oben.

`usercmd-undocumented` steht damit auch bei voll geladenen Plugins auf
**0** — und der Standardlauf blieb bei 11 Befunden, die neuen Blätter
erzeugen also keine `not-live`-Zeilen.

**Der Nebenfund dieser Runde:** vier Blätter behaupteten, ihr Plugin bringe
„keine Usercmds mit (reine API-Lib)" — `Conform`, `Treesitter`, `Dap` und
`Neotest`. Jedes Mal falsch, und jedes Mal aus demselben Grund: die Aussage
galt für die Bibliothek und nicht für ihr `plugin/`-Verzeichnis. nvim-dap
allein hat fünfzehn.

**Zu `vimscript script_id=-8`:** das ist der ausdrückliche Rückfall der
Eigentümerspalte und bedeutet „Vimscript, Herkunft ungeklärt". Eine negative
`script_id` gehört keinem gesourceten Skript, `vim.fn.getscriptinfo` kann sie
nicht auflösen, und dann druckt der Bericht lieber ein erkennbares
Nicht-Ergebnis als einen geratenen Namen. Dass es hier auftaucht, ist der
erste echte Beleg dafür, dass dieser Rückfall gebraucht wird.
