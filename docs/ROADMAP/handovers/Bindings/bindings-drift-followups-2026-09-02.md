# Handover — Drift-Folgearbeiten 2026-09-02

Fortsetzung von [TASKS-2026-09-02.md](../personal/All/FINISH/ERLEDIGT/TASKS-2026-09-02.md), dessen
sieben Punkte alle zu sind. Hier stehen die vier Nacharbeiten, die der
Driftreport übrig gelassen hatte. **Alle vier sind zu** — Punkt 4 seit dem
Nachtrag weiter unten, und er endete ohne Umzug: den vermuteten Konflikt gibt
es nicht.

> **Ab „Block 2" (2026-09-02, nachmittags) geht es nicht mehr um diese vier.**
> Der Anschlussauftrag lautete „korrigiere die 200 Befunde"; daraus ist ein
> eigener Block geworden, der ganz unten steht. **Wer hier weiterarbeitet,
> springt direkt zu [Block 2](#block-2--die-200-befunde-2026-09-02-nachmittags)
> und dort zu „Was als Nächstes zu bauen ist".**

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

### Nachtrag 2026-09-02: die Zahlen oben waren zu hoch, und warum

Die 137 (und die 207/262 weiter oben) stammen aus headless-Messläufen — und
**in einem solchen Lauf ist die Messung selbst falsch.** Diese Config
registriert ihre eigenen Commands und Keymaps in
`startup.on("UIReady", …)`, und `UIReady` ist VimEnter plus `vim.schedule`.
Ein `nvim --headless -c "luafile …"` führt sein Skript *vor* VimEnter aus:
`bindings.usrcmds` und `bindings.mappings` werden nie geladen, und alles, was
sie gebunden hätten, meldet der Check als dokumentiert-und-nicht-registriert.

Derselbe Lauf, einmal ohne und einmal mit geladener Phase:

| | Phase ausstehend | Phase gelaufen |
| --- | ---: | ---: |
| Befunde gesamt | 200 | **111** |
| `keymap-not-live` | 137 | **52** |
| `usercmd-not-live` | 9 | **1** |
| `usercmd-undocumented` | 54 | 58 |

Interaktiv sieht man das nie — wer `:Bindings check` im Editor aufruft, hat
die Phase längst hinter sich. Deshalb ist es unbemerkt in jeden headless
geschriebenen Bericht gewandert, aus dem danach zitiert wurde, diesen
eingeschlossen.

`:Bindings check` und `:Bindings report` sagen es seither selbst: `describe`
setzt die Warnung ganz nach oben, `report.render` in den Lauf-Kopf und als
Blockquote über die Zahlen, die sie entwertet. Beide fragen
`startup.pending()`.

**Stand danach (111), nach Handlungsbedarf sortiert:**

* **4 eigene undokumentierte Commands** — `:ContextOpen`,
  `:ToggleInlineDiff`, `:LibAutocmdDocsCheck`, `:LibUsercmdDocsCheck`.
  Nachgetragen, damit 111 → 107.
* **54 undokumentierte Live-Commands, alle fremd** — die Eigentümerspalte
  weist das jetzt nach, statt es zu vermuten: git-conflict (9), noice (4),
  treesitter (3), Mason, Vimscript-Plugins, Neovims eigene. Unverändert eine
  Scope-Entscheidung: soll `ExternPlugins/Bindings` sie abdecken?
* **52 `keymap-not-live`** — reposcope (21), pickers (17), cmdlog (9),
  insights (3), lib (2). Alle buffer-lokal in einer UI, die nicht offen ist.
  Korrekt gemeldet; kleiner zu kriegen nur durch Messen mit offenen UIs.
* **7 `keymap-not-in-repo`** — unverändert debugging.nvims berechnetes
  `prefix .. "m"`.

---

# Block 2 — „die 200 Befunde" (2026-09-02, nachmittags)

Anschlussauftrag: *„jetzt müssen die 200 Befunde noch korrigiert werden."*
Die Prämisse stimmte nicht — 200 waren nie 200 Probleme — und was übrig
blieb, ist unten aufgeteilt. **Eine Sache ist entschieden und noch nicht
gebaut**, sie steht als Letztes.

## Wo weiterarbeiten

| | |
| --- | --- |
| Repo | nvim-config (`C:/Users/bartl/AppData/Local/nvim`) |
| Branch | `claude/bindings-tasks-6256e4`, deckungsgleich mit `origin/main` |
| Worktree | `.claude/worktrees/plugin-documentation-workflows-042b81` |
| Stand | **alles committet und nach `origin/main` gepusht**, Haupt-Checkout nachgezogen |
| Letzter Commit | `f64ff903` feat(bindings): eigen und fremd sind zwei Fragen |

**Achtung, fremde Arbeit im selben Worktree:** `docs/TESTING/hover.md` ist
dort modifiziert und gehört einer *parallelen* Session (Umbenennung aus
`image_hover.md`). Nicht mitcommitten. Für einen Rebase musste sie einmal
beiseite — byteweise gesichert und mit identischer MD5 zurückgelegt.

## Was in diesem Block gebaut wurde

| Commit | Was |
| --- | --- |
| `e616a325` | Startphasen-Wächter: `check`/`report` merken, wenn `UIReady` nie lief |
| `262b3816` | Die vier eigenen undokumentierten Commands nachgetragen |
| `030c8e1e` | Zahlen in diesem Handover korrigiert |
| `f64ff903` | Scope-Achse `personal` / `extern` / `all` |

### Der Fund, der die Zahl erklärt

Diese Config registriert ihre Commands und Keymaps in
`startup.on("UIReady", …)`, und `UIReady` ist VimEnter + `vim.schedule`. Ein
`nvim --headless -c "luafile …"` führt sein Skript **vor** VimEnter aus —
`bindings.usrcmds` und `bindings.mappings` werden nie geladen. **89 der 200
Befunde waren die Messung, nicht die Doku.** Interaktiv sieht man das nie.

`drift.describe` stellt die Warnung jetzt ganz nach oben, `report.render` in
den Lauf-Kopf plus Blockquote; beide über `startup.pending()`, per `pcall`.

### Die Scope-Achse

| Route | Dokumentierte Seite | Live-Commands ohne Cheatsheet | Befunde |
| --- | --- | --- | ---: |
| `:Bindings check` | `PersonelPlugins/BINDINGS` | nur eigene | **53** |
| `:Bindings check extern` | `ExternPlugins/Bindings` | nur fremde | 379 |
| `:Bindings check all` | beide | beide | 432 |

`report` spiegelt alle drei. Exakt additiv: 53 + 379 = 432. `search`/`browse`
sind ausgenommen und lesen in jedem Scope beide Bäume (655 Personal- + 552
Extern-Records) — ausdrücklicher Wunsch: wer eine Taste sucht, sucht sie
unabhängig davon, wer sie registriert.

„Eigen" hängt an `config.repo_dirs()` + `nvim-config`, nicht an einer
handgepflegten Liste. Ist sie nicht auflösbar, wird **nicht** gefiltert und
der Bericht sagt das im Kopf.

## Bilanz

| | |
| --- | ---: |
| Ausgangszahl | 200 |
| Messartefakt (UIReady) | −89 |
| eigene Doku-Lücken, nachgetragen | −4 |
| fremde, jetzt außerhalb des Default-Scopes | −54 |
| **`:Bindings check` heute** | **53** |

Die 53 = 52 `keymap-not-live` + 1 `usercmd-not-live` (`:LibLogger`,
dokumentiert sich selbst als lazy).

---

## Was als Nächstes zu bauen ist — **entschieden, nicht gebaut**

**Auftrag: Repo-Fallback im Default.** Findet der Live-Check eine
dokumentierte Taste nicht, soll der Quelltext des Plugins gegriffen werden,
bevor ein `keymap-not-live` entsteht.

### Warum, und warum nicht der naheliegende Weg

Die Frage im Chat war: *„warum tauchen die buffer-lokalen in `check`
überhaupt auf — könnte man die nicht generell ausgliedern?"*

Dazu drei gemessene Punkte, damit sie nicht neu erhoben werden:

1. **Buffer-lokal gewinnt immer**, und zwar per Präzedenzregel, **nicht**
   weil zuletzt registriert. Beide Reihenfolgen getestet:

   ```
   buffer-lokal zuerst, global danach  -> buffer=1
   global zuerst, buffer-lokal danach  -> buffer=1
   nach nvim_buf_delete                -> buffer=0 (global ist zurück)
   ```

2. **`keymap-not-live` ist kein Kollisionscheck.** Dort wird nie
   buffer-lokal gegen global verglichen. Die Achse fragt nur: „das
   Cheatsheet dokumentiert diese Taste — gibt es sie?" Über den
   Live-Zustand ist das bei einer buffer-lokalen Taste nur beantwortbar,
   solange der Buffer offen ist.

3. **Deshalb wäre pauschales Ausgliedern ein schlechter Tausch:** eine
   buffer-lokale Taste, die ein Plugin entfernt oder umbenannt hat, fiele
   danach nie mehr auf — still.

### Die Messung, die den Weg begründet

Die Repo-Achse grept Quelltext und braucht **keinen offenen Buffer**. Fragt
man sie so, wie `drift.lua` sie fragt (Cheatsheet-Token, `ignore_case`, plus
`config.config_lua_root()` als zweite Suchstelle):

```
keymap-not-live               52
  im Quelltext gefunden       48   <- still korrekt, kein Buffer nötig
  nicht gefunden               4   <- blieben echte Befunde
```

Und von den 4 sind **drei gar keine Tasten**, sondern Options-Pfade in der
Key-Spalte von `Keymaps/insights.nvim.md` (`def_cfg.keymaps.jump`,
`def_cfg.keymaps.preview`, `ui_cfg.follow_key`) — ein Format-Defekt, keine
Drift. Der vierte ist `cmdlog.nvim`s `ctrl-f` (fzf-lua-Notation, nicht
vim-Notation). **Real bleibt einer.**

Kosten, gemessen: `check` ohne Repo-Achse **165 ms**, Fallback-Greps
**+427 ms** (nur die Plugins mit Befunden, hier fünf). Der Default wird also
~3,5× langsamer. Die Entscheidung dafür ist gefallen, mit dieser Zahl vor
Augen.

### Umsetzungsskizze

Alles in `lua/bindings/usrcmds/bindings_explorer/drift.lua`, in `M.check`:

1. **`repo_dirs` immer auflösen**, nicht nur bei `want_repo`
   (heute ~Z. 912–936: `if want_repo then … config.repo_dirs() … end`).
   `config_lua` entsprechend immer setzen.
2. **`checkable` braucht das Token.** Der Eintrag hält heute nur `lhs`
   (normalisiert); für den Grep wird `extract_lhs_token(rec)` gebraucht —
   dasselbe, was der bestehende `repo_keymaps`-Zweig einträgt.
3. **In der Verdikt-Schleife** (heute ~Z. 1025–1041, `for _, entry in
   ipairs(checkable)`), im `else`-Zweig von `is_live`, vor dem Anlegen des
   Findings:
   * `repo.mentions(dir, entry.token, { ignore_case = true })`, bei
     `~= true` zusätzlich gegen `config_lua`.
   * Treffer → **wie `found_count` zählen** (durch die Quelle bestätigt),
     kein Finding. Wichtig fürs Verdikt: sonst kippt eine Tabelle
     fälschlich in „not verifiable from here".
   * Kein Treffer → Finding wie bisher. Die Aussage ist jetzt **stärker**
     (weder live noch im Quelltext) — die Abschnittsnotiz in `SECTIONS`
     (`"not found globally, nor in any buffer open right now"`) gehört
     entsprechend nachgezogen.
   * Achse konnte nicht antworten (kein Checkout / nicht lesbar) → Finding
     wie bisher, und das `unverifiable`-Verdikt greift weiter.
4. **`repo.reset()`** läuft heute nur `if want_repo`. Muss künftig auch
   laufen, wenn nur der Fallback die Bäume indiziert hat — sonst bleiben die
   ~28 MiB für den Rest der Session liegen.
5. **Gegenprobe:** `keymap-not-live` muss von 52 auf 4 fallen, die anderen
   Achsen unverändert. Danach die drei Options-Pfade in
   `Keymaps/insights.nvim.md` als Format-Defekt separat fixen.

### Danach noch offen

* **54 fremde undokumentierte Commands** — durch die Scope-Achse aus dem
  Default heraus, aber inhaltlich unentschieden: soll
  `ExternPlugins/Bindings` sie je abdecken?
* **`:Bindings check extern` meldet 379** — ein Korpus, der nie geprüft
  wurde. Keine Regression, eine neue Achse. Ungesichtet.
* **7 `keymap-not-in-repo`** — unverändert debugging.nvims berechnetes
  `prefix .. "m"`.

## Fallen, die diese Session gekostet haben

1. **`vim.loader` cacht Modulname → Datei auf den Haupt-Checkout.** Ein
   `rtp`-Prepend reicht nicht, `vim.loader.reset()` auch nicht. Worktree-Code
   nur über `package.preload` + `loadfile` laden:

   ```lua
   for _, n in ipairs({ "config", "records", "source", "repo", "drift", "report", "status" }) do
     local mod = "bindings.usrcmds.bindings_explorer." .. n
     package.loaded[mod] = nil
     package.preload[mod] = assert(loadfile(WT .. "/lua/bindings/usrcmds/bindings_explorer/" .. n .. ".lua"))
   end
   ```

2. **Headless misst falsch, solange `UIReady` aussteht.** Vor jeder Messung:

   ```lua
   require("bindings.usrcmds")
   require("bindings.mappings").setup()
   local st = require("startup")
   for _, m in ipairs(st.marks) do
     if m.label == "usrcmds" or m.label == "mappings" then m.at = m.at or st.elapsed() end
   end
   ```

3. **`(cond) and nil or x` kollabiert in Lua** zum `or`-Zweig. Hat hier
   `corpus_scope = "all"` erzeugt, was auf keine Wurzel passt — die
   dokumentierte Seite meldete still null Befunde (54 statt 432). Immer ein
   explizites `if`.

4. **`f.notation` ist die Vergleichsform, nicht die Anzeigeform.** Ein
   eigener Dump liest sonst rohe Termcodes (`\x80kD`); `drift.describe`
   rendert korrekt über `vim.fn.keytrans`. Beinahe als Werkzeugfehler
   gemeldet, war keiner.

5. **Korpus kommt aus `stdpath("config")`**, also aus dem Haupt-Checkout.
   Für Messungen gegen Worktree-Doku `config.roots` umbiegen — oder vorher
   pushen und im Haupt-Checkout pullen.

