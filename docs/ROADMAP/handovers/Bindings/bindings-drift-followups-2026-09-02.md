# Handover — Drift-Folgearbeiten 2026-09-02

Fortsetzung von [TASKS-2026-09-02.md](../personal/All/FINISH/ERLEDIGT/TASKS-2026-09-02.md), dessen
sieben Punkte alle zu sind. Hier stehen die vier Nacharbeiten, die der
Driftreport übrig gelassen hatte. **Alle vier sind zu** — Punkt 4 seit dem
Nachtrag am Ende dieser Datei, und er endete ohne Umzug: den vermuteten
Konflikt gibt es nicht.

## Wo weiterarbeiten

| | |
| --- | --- |
| Repo | nvim-config (`C:/Users/bartl/AppData/Local/nvim`) |
| Branch | `claude/nvim-config-tasks-56c97f` |
| Worktree | `C:/Users/bartl/AppData/Local/nvim/.claude/worktrees/plugin-roadmap-review-277621` |
| Stand | alles committet und nach `origin/main` gepusht |
| lib.nvim | `E:/repos/lib.nvim`, `main`, sauber — `bfa09e5` gehört zu diesem Block |

Der Branch ist mit `origin/main` deckungsgleich; es geht auch direkt auf `main`
weiter, der Worktree ist nur der Arbeitsplatz gewesen.

**Wichtig für jede Messung:** der Korpus (`docs/NOTES/**`) wird über
`vim.fn.stdpath("config")` gelesen, also aus dem **Haupt-Checkout**, nicht aus
dem Worktree. Solange die Doku-Änderungen nur im Worktree liegen, misst ein
`:Bindings check` den alten Stand. Das Mess-Skript unten hat dafür einen
Schalter. Nach einem `git pull` im Haupt-Checkout erübrigt sich das.

---

## Status

| # | Punkt | Status |
| --- | --- | --- |
| 1 | Die filetype-gebundenen lsp.nvim-Commands nachtragen | ✅ |
| 2 | pickers.nvim: den Generator dokumentieren, `check` Familien beibringen | ✅ |
| 3 | Ein Ort für die Commands der Config selbst (`:MyOpt*`, `:WKDOptions*`) | ✅ |
| 4 | `<leader>th` ist mehrfach beansprucht | ✅ — **die Annahme war falsch**, siehe unten |

Wirkung der drei fertigen Punkte, gemessen am selben Lauf:

| | vorher | nachher |
| --- | ---: | ---: |
| Befunde gesamt | 262 | **207** |
| `usercmd-undocumented` | 109 | **54** |
| `usercmd-not-live` | 9 | 9 |
| `keymap-not-live` | 137 | 137 |

---

## 1 — Die filetype-gebundenen lsp.nvim-Commands ✅

`Usercmds/lsp.nvim.md` erklärte in „Zwei Ausnahmen, die keine Aliase sind"
seit jeher, *warum* `:TypeDef*`, `:Astro*` & Co. eigene Namen behalten — die
Liste stand nur nirgends. Neuer Abschnitt „Die filetype-gebundenen Commands"
mit 22 Zeilen, nach Modul gruppiert: Astro (9), TypeScript-Typen (5),
eslint/prettier (4), lua_ls (3), Markdown-Wörter (3), Completion (1).

Die Beschreibungen sind aus den `desc`-Feldern der jeweiligen
`usercmd.create`-Aufrufe in lsp.nvim gezogen, nicht erfunden.

## 2 — pickers.nvim: der Generator statt seiner 23 Ergebnisse ✅

Zwei Hälften.

**Doku:** `Usercmds/pickers.nvim.md` bekommt eine Tabellenzeile
`:*Files` / `:*Grep` / `:*Smart` plus einen Abschnitt, der den Generator
(`bindings/collections.lua`) beschreibt. Bewusst *keine* Liste der 23 Namen —
die entstehen aus einer Schleife über die Collection-Liste der Config, und
eine handgeschriebene Kopie davon wäre genau der Fehler, den dieses Repo
sonst überall benennt.

**Code:** `records.command_globs()` liest `*`-Familien, `records.family_claims()`
sammelt sie, und `drift.lua` akzeptiert ein Live-Command als abgedeckt, wenn
eine Familie passt.

Zwei Einschränkungen, beide durch Messen gefunden und nicht vorher gedacht:

* **Nur Tabellenzeilen, nie Fließtext.** Die lose erste Fassung las auch
  Prosa und ließ damit 18 Familien los, darunter `^Lsp[%w_]+$`, `^Diff[%w_]+$`
  und `^Copy[%w_]+$`. Der Korpus schreibt `:Lsp*` in Sätzen als Typografie,
  nicht als Anspruch auf jeden passenden Namen.
* **Eine Familie deckt nur Commands ihres eigenen Plugins.** Sonst schluckte
  `:*Files` aus `pickers.nvim.md` auch diffview.nvims `:DiffviewFocusFiles`
  und `:DiffviewToggleFiles`. Der Abgleich läuft über `command_owner` — also
  über genau die Eigentümerspalte, die vorher in diesem Block entstanden ist.

Nebenbei entfernt: ein selbstverschuldeter Falschbefund. Die Tabellenzeile,
die den `path:L1-L2`-Fix beschreibt, enthielt selbst ein `` `:Name` `` und
wurde prompt als dokumentiertes, nicht registriertes Command gemeldet.

## 3 — Ein Ort für die Commands der Config selbst ✅

Der Driftreport folgerte, der nach Plugins geschnittene Korpus habe für
`:MyOpt*`/`:WKDOptions*` keinen Platz. **Das war ein Trugschluss:**
`Usercmds/nvim-config.md` ist genau dieser Ort und nennt
`wkdoptions/commands/register.lua` seit jeher als Quelle — die sieben Zeilen
fehlten schlicht. Nachgetragen im Abschnitt „Options", mit der Erklärung,
warum die Namen so unzusammenhängend aussehen: ein generischer Registrar mit
Default-Namen (`WKDOptSet`, `WKDHighlightSet`), den beide Aufrufer
überschreiben (`MyOpt*` bzw. `WKDOptionsHL*`). Keiner der Default-Namen
existiert in einer laufenden Session, weshalb ein Grep im Registrar nach den
Live-Namen nichts findet.

---

## 4 — `<leader>th` ✅ ein globaler Anspruch, kein Konflikt

**Der Auftrag lautete ursprünglich: vierfach vergeben (NvChad, filetree.nvim,
language.nvim, lsp.nvim). Nach der Prüfung sind es zwei — und die beiden
kollidieren nicht, sie verdecken einander.**

Die Tabelle ist der Stand *vor* der Klärung; die Zeilen tragen nach, wie sie
ausgegangen sind.

| Anspruch | Befund |
| --- | --- |
| **lsp.nvim** — Inlay Hints global umschalten | **Gewinnt live.** `nvim_get_keymap("n")` liefert genau eine Bindung für `<leader>th`, desc „LSP: Toggle inlay hints (global)", aus `lsp.nvim/lua/lsp/bindings/actions.lua:192` |
| **NvChad** — Theme-Picker | **Kein Anspruch — geklärt, siehe unten.** Die Zeile `NvChad/lua/nvchad/mappings.lua:67` (`require("nvchad.themes").open()`) existiert, aber diese Config lädt das Modul nie: `package.loaded["nvchad.mappings"]` ist nach einem vollen Start `false`. `lua/wkdnvchad/init.lua:14` ruft ein *anderes* Modul (`wkdnvchad.mappings`), dessen `all = true` nur `<Tab>`, `<S-Tab>`, `<leader>bc`, `<leader>tr`, `<leader>tl` und `<leader>tt` setzt |
| **filetree.nvim** — Trash-History | **Echter zweiter Anspruch, aber buffer-lokal.** `<leader>th` ist der Default des Config-Feldes `keymap_history` (`features/fileops/trash/init.lua:62`). Nachgemessen: die Taste kommt **nicht** über neo-trees `window.mappings` — dort steht sie in keiner Quelle —, sondern über filetrees eigenen tree-attach-Dispatcher, buffer-lokal am Baum-Buffer. Damit ist es Shadowing, keine Kollision |
| **language.nvim** — Thesaurus | **Kein Anspruch.** `config/DEFAULTS.lua:117` hat `keymap = false` mit dem Kommentar „opt-in"; die Taste wird per Default nicht gebunden. Der Kommentar in `thesaurus/init.lua:145` (`3<leader>th`) beschreibt nur, wie ein Count wirken *würde* |

### Die offene Frage, beantwortet (2026-09-02, nachmittags)

**Nein.** `wkdnvchad.mappings.setup({ all = true })` setzt NvChads
`<leader>th` nicht. Es ist ein anderes Modul und bindet ausschließlich
`<Tab>`, `<S-Tab>`, `<leader>bc`, `<leader>tr`, `<leader>tl` und `<leader>tt`
(`lua/wkdnvchad/mappings/init.lua`). NvChads eigenes `lua/nvchad/mappings.lua`,
in dem der Theme-Picker steht, wird von dieser Config **nirgends** `require`d —
nach einem vollen Start ist `package.loaded["nvchad.mappings"]` `false`. Der
einzige weitere Treffer im Repo ist eine Legacy-Notiz unter
`docs/NOTES/ExternPlugins/Legacy-Notes-Import/`.

Damit endet der Auftrag, ohne dass etwas umzieht. Gemessen headless gegen den
echten Config-Start:

```
global n-mode hits: 1
  lhs=" th"  desc=LSP: Toggle inlay hints (global)
    src=E:/repos/lsp.nvim/lua/lsp/bindings/actions.lua:192
package.loaded['nvchad.mappings'] = false
```

Und im geöffneten Baum (`:Neotree show filesystem`, dann
`nvim_buf_get_keymap`): ebenfalls genau ein Treffer,
`filetree: show trash history`.

**Was es stattdessen ist: Cross-Scope-Shadowing** — die Kategorie, die
`Keymaps/Collisions.md` schon für `<leader>ps`, `gP` und `+`/`-` führt. Dort
steht `<leader>th` jetzt als vierte Zeile, mit beiden widerlegten Ansprüchen
daneben, damit diese Untersuchung kein drittes Mal gemacht wird.
`Keymaps/lsp.nvim.md` und `Keymaps/filetree.nvim.md` verweisen darauf.

**Ein Unterschied zu den drei bestehenden Zeilen, der benannt gehört:** deren
Begründung — „im Baum gibt es keine Datei, auf die die globale Taste wirken
könnte, also geht nichts verloren" — trägt hier nicht. lsp.nvims Toggle ist
*global*, keine Aktion auf dem Knoten unter dem Cursor. Im Baum ist er also
wirklich unerreichbar, nicht bloß gegenstandslos. Ausweg: Baum verlassen, oder
`<leader>tH` fürs aktuelle Filetype.

**Zwei Sackgassen, die eine Neuauflage sich sparen kann.** Beide sahen nach
einem Fund aus und waren keiner:

* filetrees `attach.lua` schreibt seine Keymaps mit `w.mappings[k] = v`
  bedingungslos in neo-trees `window.mappings` — es sah so aus, als
  überschriebe das die `noop`s der Config. Gemessen: tut es nicht.
  `<leader>th` steht in *keiner* `window.mappings`; filetree bindet die Taste
  über seinen tree-attach-Dispatcher buffer-lokal.
* neo-trees `normalize_map_key("<leader>th")` liefert `"<leader>th"` zurück,
  unverändert. Es gibt also keine zweite Schreibweise (`" th"`), unter der ein
  Eintrag „versteckt" läge.

**Nebenbefund, der nirgends stand:** die Config schaltet `<leader>th` in
neo-trees beiden read-only-Quellen bewusst ab —
`config/neotree/keymaps/diagnostics.lua:78` und `document_symbols.lua:75`
mappen sie auf `noop`, zusammen mit den übrigen dateiverändernden Tasten. In
einer Diagnoseliste gibt es nichts zu löschen. Steht jetzt in
`Collisions.md`.

**Freie `t`-Tasten** (aus Punkt 1 des Hauptblocks, damals gegen nvim-config,
NvChad-Defaults und alle Repos unter `E:\repos` geprüft): `ta td ti tj tk tm
tu ty tz` — `tb` ist seither an lsp.nvims Lightbulb vergeben. Ein Gegencheck
gegen die laufende Session bestätigt sie: global belegt sind unter `<leader>t`
nur `tB tH tb tft th tl tq tr tt`.

Falls je etwas umziehen sollte, gehören mit: das Cheatsheet des betroffenen
Repos, die `Keymaps/*.md` in der Config, und `Keymaps/Collisions.md`.

---

## Werkzeuge, die beim Weitermachen helfen

**Driftlauf gegen den Worktree-Korpus** (misst Code *und* Doku dieses
Branches, ohne den Haupt-Checkout anzufassen):

```
DRIFT_WORKTREE_CORPUS=1 DRIFT_OUT=<datei> nvim --headless -c "luafile <scratch>/drift_run.lua" -c "qa!"
```

Das Skript liegt im Scratchpad dieser Session und ist damit weg. Es tut drei
Dinge, die eine Neuauflage wieder brauchen wird:

1. Die `bindings_explorer`-Module über `package.preload` aus dem Worktree
   laden. **Ein `rtp`-Prepend reicht nicht** — `vim.loader` cacht die
   Zuordnung Modulname → Datei auf der Platte, und auch `vim.loader.reset()`
   holt danach weiter die Kopie des Haupt-Checkouts.
2. `config.roots()` auf die Doku-Bäume des Worktrees umbiegen.
3. `drift.check(nil, { repo = true })` laufen lassen und nach `kind` zählen.

Ab jetzt geht auch einfach `:Bindings report repo` — die Route schreibt
denselben Bericht als Markdown und ist in diesem Block entstanden.

## Was danach immer noch offen ist

Aus dem Driftreport, unverändert und bewusst nicht angefasst:

* **54 undokumentierte Live-Commands** bleiben, davon der große Rest
  Fremdinfrastruktur (`:Gitsigns`, `:Mason*`, `:Noice*`, Vimscript-Plugins),
  die dieser Korpus nie abgedeckt hat. Eine Scope-Entscheidung, keine
  Fleißarbeit.
* **137 `keymap-not-live`** — fast alle buffer-lokale Tasten einer UI, die in
  einer headless-Session nicht offen ist. Der Bericht sagt das selbst und
  bietet „Open it and re-run" an.
* **7 `keymap-not-in-repo`** — debugging.nvims zur Laufzeit gebautes
  `prefix .. "m"`, der dokumentierte Falschbefund der Grep-Achse.
