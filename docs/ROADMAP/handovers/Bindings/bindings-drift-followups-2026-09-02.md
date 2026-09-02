# Handover — Drift-Folgearbeiten 2026-09-02

Fortsetzung von [TASKS-2026-09-02.md](../personal/All/FINISH/ERLEDIGT/TASKS-2026-09-02.md), dessen
sieben Punkte alle zu sind. Hier stehen die vier Nacharbeiten, die der
Driftreport übrig gelassen hatte. **Drei sind fertig, die vierte ist nur
untersucht** — die Untersuchung steht unten, damit sie nicht nochmal gemacht
werden muss.

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
| 4 | `<leader>th` ist mehrfach beansprucht | 🔶 nur untersucht, siehe unten |

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

## 4 — `<leader>th` 🔶 offen, aber durchgemessen

**Der Auftrag lautete ursprünglich: vierfach vergeben (NvChad, filetree.nvim,
language.nvim, lsp.nvim). Nach der Prüfung sind es zwei.**

| Anspruch | Befund |
| --- | --- |
| **lsp.nvim** — Inlay Hints global umschalten | **Gewinnt live.** `nvim_get_keymap("n")` liefert genau eine Bindung für `<leader>th`, desc „LSP: Toggle inlay hints (global)", aus `lsp.nvim/lua/lsp/bindings/actions.lua:192` |
| **NvChad** — Theme-Picker | **Echter zweiter Anspruch.** `NvChad/lua/nvchad/mappings.lua:67`, `require("nvchad.themes").open()`. Ob er in dieser Config überhaupt gesetzt wird, ist **nicht geklärt** — `lua/wkdnvchad/init.lua:14` ruft `require("wkdnvchad.mappings").setup({ all = true })`, und was `all = true` einschließt, war der nächste Schritt |
| **filetree.nvim** — Trash-History | **Kein Konflikt.** `<leader>th` ist dort der Default des Config-Feldes `keymap_history`, registriert aus `attach.lua` mit `scope = "tree"` — buffer-lokal am Baum-Buffer, wie die beiden neo-tree-Keymaps der Config auch |
| **language.nvim** — Thesaurus | **Kein Anspruch.** `config/DEFAULTS.lua:117` hat `keymap = false` mit dem Kommentar „opt-in"; die Taste wird per Default nicht gebunden. Der Kommentar in `thesaurus/init.lua:145` (`3<leader>th`) beschreibt nur, wie ein Count wirken *würde* |

**Nächster Schritt:** klären, ob `wkdnvchad.mappings.setup({ all = true })`
NvChads `<leader>th` tatsächlich setzt. Falls ja, ist es dieselbe Lage wie bei
`<leader>tl` in Punkt 1 des Hauptblocks — eine der beiden Funktionen verliert
je nach Ladereihenfolge ihre Taste, und die willkürlichere zieht um.

**Freie `t`-Tasten** (aus Punkt 1 des Hauptblocks, damals gegen nvim-config,
NvChad-Defaults und alle Repos unter `E:\repos` geprüft): `ta td ti tj tk tm
tu ty tz` — `tb` ist seither an lsp.nvims Lightbulb vergeben.

Wenn es umzieht, gehören mit: das Cheatsheet des betroffenen Repos, die
`Keymaps/*.md` in der Config, und `Keymaps/Collisions.md`.

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
