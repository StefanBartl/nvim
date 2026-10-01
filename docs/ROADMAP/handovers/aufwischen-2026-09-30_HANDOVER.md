# Handover — „Aufwischen" 2026-09-30

Lebendes Dokument: wird nach **jedem** erledigten Task aktualisiert. Wer hier
einsteigt, liest erst diese Datei, dann den Plan
[`reports/aufwischen-2026-09-30-implementierungsplan.md`](../reports/aufwischen-2026-09-30-implementierungsplan.md)
(dort stehen Befunde, Designs und Begründungen je Task).

**Stand:** 2026-10-01, nach dem Task „cascade: Listen-Schrittweite (`<C-y>`/`<C-x>` auf Marker, `<C-S-y>`/`<C-S-x>` Ebene)".
**Arbeitsweise (global):** Antworten deutsch, Code/Kommentare englisch; max. 1 Agent
gleichzeitig; nach jedem Task sofort auf `main` pushen; **keine** Co-Author-Zeile;
vor `git add` immer `git status`; Edit-Skripte mit Backslashes **in eine Datei
schreiben bzw. das Edit-Tool nehmen** (Bash-Heredocs fressen Escapes; Lua-Langstrings
`[[...]]` brechen an `]]`, dann `[=[ ... ]=]` nehmen); kein bares `git stash`.
Repos liegen als Checkouts unter `E:\repos\<name>.nvim` (alle auf `main`).

## Erledigt (gepusht, je 1 Commit)

| Task | Repo | Commit | Kurz |
|---|---|---|---|
| T2 `./` vor `$VAR` | markdown.nvim | `03b0867` | Env-Ziele (`$V/…`, `${V}/…`, `%V%/…`) bleiben unangetastet; `links.repair_env_prefix` (Default an) repariert `./$VAR/…`, nur wenn Variable gesetzt |
| T1 Blockquote-Breite | markdown.nvim | `779c4d1` | `blockquote_hl.width = "block"\|"line"\|"window"\|<n>`, Default `block`; Padding via eol-Virtual-Text, Blockbreite pro Buffer per `changedtick` gecacht |
| T8 cascade weicht aus | cascade.nvim | `f5baa6d` | Rotation `<leader>cf/cF` → `<leader>cl/cL` (cf/cg/cF/cG gehören casedesk); `sort` bleibt `cS` |
| T4 Toast-Breite (ui) | ui.nvim | `10082fc` | `ui.kit.toast`: Breite = Text + Padding, min `min_width` (40), max `width` (`"40%"`), Wrap, Resize-fest; `ui.setup({ toast = {…} })` / `ui.kit.toast.setup` |
| T4 Toast-Breite (lib) | lib.nvim | `53417e1` | gespiegelte Kopie (Drift-Test grün); `notify.popup` wrappt an `toast.inner_width()` statt fest 38; `popup.setup({ toast = {…} })` leitet weiter |
| T5a Helper | lib.nvim | `664667c`, `62c559a` | `lib.nvim.markdown.link_cursor` (`locate/place/insert/insert_links`, `setup`), `window.find_usable.previous_window` |
| T5 gopath-API | gopath.nvim | `f1cfe5c` | `require("gopath").shorten_path(abs)` → `$VAR/rest` oder nil (+ Variablenname) |
| T5b images | images.nvim | `242f3ed` | `:Image paste [env\|abs\|rel\|repos] [name]`, `paste.env_roots`, `paste.link_cursor`; Cursor nach Insert in den Alt-Text + Insert-Modus |
| T6 Toast-zindex + Feedback | ui.nvim, lib.nvim, pickers.nvim | `a1574ca`, `360a137`, `6e34dcf` | Ursache: Toast zindex 50 < snacks 52/54; Fix + Meldungen in `:messages` |
| T5c pickers insert | pickers.nvim | `7fbd2aa` | `keys.markdown_link_insert` (`<M-n>`/`MI`, fzf `alt-n`): Einträge als Links ins Fenster hinter dem Picker, Cursor in den Link; `link_insert = { path, cursor }` |
| T5c filetree `MI` | filetree.nvim | `9a0e0dc` | `MI` / `:Filetree mdlink insert`: Marks (sonst aktueller Node) als Links ins vorherige Fenster, Cursor in den ersten Link + Insert; `insert_path` = buffer (Default) / cwd / absolute / env, `env_roots`, `cursor` |
| T5c markdown wrap | markdown.nvim | `19fabae` | `wrap_link` nutzt den Helper; `links.cursor` (`enable/startinsert/path_cursor`) |

### Cursor-Regel (entschieden, gilt überall)
Titel leer → Cursor in den Titel (`[|]`); Titel gefüllt → in den Pfad/URL (Ende,
`path_cursor = "start"` möglich); Titel gefüllt + Pfad leer → in `()`; bei mehreren Links
entscheidet der **erste**; immer Insert-Modus (`startinsert`), abschaltbar.

### Bekannte, nicht zu verantwortende Testausfälle
- cascade `TESTS/health_spec.lua:475` (vue-Parser ist auf dieser Maschine installiert)
- ui.nvim `ui.context … kotlin` (Parser-abhängig)
- markdown-Runner meldet am Ende „Error in command line" (besteht auch ohne meine Änderungen)

## Offen — in dieser Reihenfolge weitermachen

1. ~~filetree.nvim `MI`~~ — **erledigt** (`9a0e0dc`). Vorbild für die Picker-Aktion:
   `features/paths/markdown_links/init.lua` (`insert_current`, `insert_target`, `build_insert_links`).
2. ~~pickers.nvim Link-Einfügen-Aktion~~ — **erledigt** (`7fbd2aa`): `keys.markdown_link_insert`
   (`<M-n>` / Chord `MI`, fzf-lua fest `alt-n`; `<M-i>` ging nicht — snacks/fzf-lua `toggle_ignored`,
   der Test `keys: no default direct lhs shadows an engine default` fängt das), neues Modul
   `entry_actions/link_insert.lua`, `link_insert = { path, cursor }` in der Config, alle 3 Adapter.
   Schließt den Picker, fügt per `vim.schedule` ein.
3. ~~T6 Picker-Feedback~~ — **erledigt**. **Ursache gefunden und im echten snacks-Picker
   headless reproduziert/verifiziert** (Skript-Muster: `Snacks.picker.files{}` öffnen,
   `Snacks.picker.get()[1]:action("copy_env_rooted")`, Fenster + zindex dumpen — geht in
   `nvim --headless` mit der echten Config): Toast hatte `zindex 50`, snacks-Layout 52, dessen
   Fenster 54 → Toast lag **unter** dem Picker. Fix an der Wurzel: `ui.kit.toast` nutzt jetzt
   `theme.zindex.toast` (70) — ui.nvim `a1574ca`, lib.nvim-Spiegel `360a137`. Dazu pickers
   `6e34dcf`: Erfolgsmeldungen `copied [fmt] …` / `opened x` / `inserted N markdown link(s)` über
   `lib.nvim.notify` mit `messages = true` (landen auch in `:messages`, wie filetree), Test
   „feedback". Der ursprünglich geplante `pickers.feedback`-Titel-Kanal wurde **nicht** gebaut
   (nicht nötig; bei Bedarf Titel/Footer des snacks-Pickers als zusätzlicher Kanal).
4. ~~`:Clipboard`~~ — **erledigt** (`27a46759`): auf Wunsch des Nutzers `:Clipboard [path] reports|handovers`
   (`path` optional und erstes Unterkommando, damit später weitere Optionen neben `path` kommen;
   Targets sind Daten in `M.TARGETS`, `enable({ targets, form = "absolute"|"env" })`), keine Keymap.
   Modul `lua/bindings/usrcmds/clipboard/init.lua`, README ergänzt. Getestet headless (Modul mit
   Worktree im `rtp`; **Achtung:** `nvim --headless` mit der vollen Config lädt den **Haupt-Checkout**,
   nicht den Worktree).
5. ~~Personal-Spec nachziehen~~ — **erledigt** (`b11c2356`): `view.lua` (images: `paste = {…}` jetzt aktiv mit
   `default_path_mode = "env"` als Nutzer-Default, `env_roots`/`link_cursor` kommentiert), `edit.lua`
   (markdown: `links.repair_env_prefix`, `links.cursor`, `blockquote_hl.width`; cascade-Kommentar zu `cl/cL`),
   `foundation.lua` (`popup.setup`: `width = nil`, `toast = { width, min_width, padding }`), `navigate.lua`
   (pickers `keys.markdown_link_insert`, `link_insert`; filetree `markdown_links` `keymap_insert`/`insert_path`/
   `env_roots`/`cursor`), `docs/NOTES/ExternPlugins/Bindings/Keymaps/Casedesk.md` (Kollisionsnotiz → gelöst;
   `config_smart` liegt schon auf `<leader>CF`). Noch **nicht** gesetzt: `lib.nvim.markdown.link_cursor.setup`
   global (nur über die Plugin-Optionen steuerbar). Ui.nvim-Spec: ein `ui.setup({ toast = … })` gibt es in
   der Config nicht, `toast` läuft über `popup.setup`.
6. ~~Report „Markdown-Link-Einfügestellen"~~ — **erledigt**: `reports/markdown-link-einfuegestellen-2026-10-01.md`
   (alle Stellen, vorher/nachher, Optionen, Commits; mdview/media/hover/gopath/recommender/insights ohne
   Treffer; color_my_ascii/open/documentation bewusst unverändert). Dabei zusätzlich umgesetzt, weil
   „jedes Usercmd, das einen Link einfügt": buffer-ctx `:Insert mdlink` (`006a306`) und casedesk
   `:Case insert asset` (`dd58bc1`) nutzen jetzt `link_cursor.place`.
7. **T7 Message-Popup** — Roadmap-Einträge **erledigt** (WKDBooks `1afb268`): Konzept
   `lib.nvim/ROADMAP/messages-log-and-recent-popup.md` (Befund, Schichten, Spezifikation, Roadmap-Abgleich,
   Umsetzungsplan) + Verweise in `lib.nvim/ROADMAP/ROADMAP.md`, `debugging.nvim/ROADMAP/ROADMAP.md`
   („Offen"), `ui.nvim/ROADMAP/ROADMAP.md`. **Offen:** der Noice-Feature-Matrix-Report (Punkt in
   `00_ROADMAP.md` Z. ~97, Datei gehört dem Nutzer und ist lokal modifiziert — nicht anfassen; Report
   nach `docs/ROADMAP/reports/`), danach TUI-Spike. **Kein Bau** (Nutzer: erst Review/Abgleich).
   Hinweis: WKDBooks hat lokale Nutzer-Änderungen (`Spickzettel/…`) — nur exakte Pfade stagen, kein
   `git pull --rebase` mit dirty tree (vorher `git fetch`, ahead/behind prüfen).
8. ~~cascade: Aufzählungszahlen schrittweise ändern~~ — **erledigt** (cascade `236ace2`).
   **Korrektur zur früheren Notiz:** gemeint waren `<C-y>`/`<C-x>` (nicht `<C-a>`) — `<C-y>`/`<C-x>`
   sind in der Config cascades `cycle_word_next/prev` (preset); die Listen-Logik hängt dort ein.
   - `<C-y>`/`<C-x>` (und `+`/`-`) **auf/vor dem Marker** einer geordneten Liste: Item + alle **folgenden**
     Geschwister derselben Ebene ±count; Vorangehende, Kinder und Fortsetzungszeilen bleiben; kein
     Renumber (Startzahl/Lücken bleiben); Dot-Repeat; Cursor im Text → altes Wort-/Zahlenverhalten.
   - Ganze Ebene (auch davor): `shift_level_next/prev` auf **`<C-S-y>`/`<C-S-x>`** und Alias
     **`<leader>c+`/`<leader>c-`** (Terminal liefert `<C-S-y>` nur mit kitty-Protokoll/modifyOtherKeys
     unabhängig von `<C-y>`; das Leader-Alias geht überall). `g<C-a>`-Fallback wurde **nicht** gebaut.
   - Ziffern bis 0, Buchstaben/Römisch durch ihre Folge (Case bleibt, mehrdeutige c/d/i/l/m/v/x je Lauf
     aufgelöst); außerhalb des Bereichs ändert sich nichts + Hinweis. `lists.features.shift` schaltet beides.
   - Verifiziert mit der **echten Config** und echten Tasten (`feedkeys`): `<C-x>` auf `2.`, `3<C-y>`,
     `<leader>c+` + `.`, `<C-y>` auf der `3` im Text.
   - Offen/Annahme: „Ebene" = gleiche Einrückung im selben Block (verschachtelte Unterlisten zählen nicht).
     Nicht geprüft: ob dein Terminal (WezTerm?) `<C-S-y>` sendet — sonst `<leader>c+`/`c-` nehmen.

## Fallen, die ich getroffen habe
- **nvim-Config: Worktree vs. Haupt-Checkout.** Dieses Dokument liegt im Worktree
  `…/nvim/.claude/worktrees/nvim-plugin-cleanup-daf894` (Branch `claude/nvim-plugin-cleanup-daf894`).
  `$NVIM_CONFIG_DIR` ist der Haupt-Checkout `C:\Users\bartl\AppData\Local\nvim`; dort hat der
  Nutzer `docs/ROADMAP/00_ROADMAP.md` lokal geändert. **Routine nach jedem Handover-Update:**
  committen, im Worktree `git pull --rebase origin main` + `git push origin HEAD:main`, dann im
  Haupt-Checkout `git fetch && git merge --ff-only origin/main` (klappt, solange die eingehenden
  Commits keine lokal geänderten Dateien des Nutzers berühren — vorher
  `git diff --name-only HEAD origin/main` prüfen).
- `lib.nvim.notify.popup` hängt an **`ui.kit.toast` aus ui.nvim**, nicht an lib.nvims Kopie
  (Kit ist nach ui.nvim migriert, lib-Kopie „frozen"; Drift-Test `ui.nvim/TESTS/kit_drift_spec.lua`).
- Popup-Toast-Footer `… (:Lib notify last)` ist 22 Spalten breit — Tests mit kleiner `width` beachten.
- `:startinsert` wird in `nvim -l`-Läufen nie verarbeitet → Tests stubben `vim.cmd`.
- Shell-Tools fielen einmal mit „classifier error" aus; Retry half.

## Commit-Liste dieses Chats (grüner Haken = `ultracode`-Review; bisher **keiner** reviewed)

| Repo | Commit | Beschreibung | Review |
|---|---|---|---|
| markdown.nvim | `03b0867` | fix(links): no `./` before env-rooted targets, repair | – |
| markdown.nvim | `779c4d1` | feat(hl): blockquote width | – |
| cascade.nvim | `f5baa6d` | feat(keymaps): rotation → `cl/cL` | – |
| ui.nvim | `10082fc` | feat(toast): width min/max/padding/wrap | – |
| lib.nvim | `53417e1` | feat(toast): mirror + popup wrap width | – |
| lib.nvim | `664667c` | feat(markdown): link_cursor | – |
| gopath.nvim | `f1cfe5c` | feat(api): shorten_path | – |
| images.nvim | `242f3ed` | feat(paste): env mode, mode words, cursor | – |
| markdown.nvim | `19fabae` | feat(links): wrap_link cursor + insert mode | – |
| lib.nvim | `62c559a` | feat: insert_links, previous_window | – |
| filetree.nvim | `9a0e0dc` | feat(markdown_links): `MI` fügt Links ein, Cursor in den Link | – |
| pickers.nvim | `7fbd2aa` | feat(entry_actions): Links ins Fenster hinter dem Picker einfügen | – |
| ui.nvim | `a1574ca` | fix(toast): theme zindex.toast (70), Toast lag unter snacks-Pickern | – |
| lib.nvim | `360a137` | fix(toast): Spiegel zu ui.nvim | – |
| pickers.nvim | `6e34dcf` | feat(entry_actions): Aktionen melden, was sie taten, auch in :messages | – |
| nvim-config | `27a46759` | feat(usrcmds): `:Clipboard [path] reports|handovers` | – |
| nvim-config | `b11c2356` | chore(specs): neue Plugin-Optionen (images env, Toast, Blockquote, Link-Cursor, Picker/filetree) | – |
| buffer-ctx.nvim | `006a306` | feat(insert): `:Insert mdlink` setzt den Cursor in den Link | – |
| casedesk.nvim | `dd58bc1` | feat(insert): `:Case insert asset` setzt den Cursor in den Link | – |
| nvim-config | (Report) | docs: Report Markdown-Link-Einfügestellen | ✅ |
| WKDBooks | `1afb268` | docs(roadmap): Message-Log + Recent-Popup + Live-Chips Konzept (3 Roadmaps) | ✅ |
| cascade.nvim | `236ace2` | feat(lists): `<C-y>`/`<C-x>` auf Marker + Ebenen-Variante | – |
| nvim-config | (Spec) | chore(specs): `lists.features.shift` | – |
| nvim-config | `264531a0`, `7bf3d7ce` | docs: Plan-Report + Handover | ✅ |
