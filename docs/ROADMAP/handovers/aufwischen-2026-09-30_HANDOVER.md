# Handover — „Aufwischen" 2026-09-30

Lebendes Dokument: wird nach **jedem** erledigten Task aktualisiert. Wer hier
einsteigt, liest erst diese Datei, dann den Plan
[`reports/aufwischen-2026-09-30-implementierungsplan.md`](../reports/aufwischen-2026-09-30-implementierungsplan.md)
(dort stehen Befunde, Designs und Begründungen je Task).

**Stand:** 2026-10-01, nach dem Review-Durchlauf aller Nicht-Doku-Commits (alle ✅).
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

## Review-Durchlauf (Auftrag des Nutzers, Reasoning `ultracode`, 2026-10-01)

Alle Nicht-Doku-Commits dieses Chats auf Bugs / Security / Performance prüfen und Funde sofort fixen;
Handover nach **jedem** Commit aktualisieren. Geprüfte Commits bekommen unten ✅ (Review durch den Nutzer-
`ultracode`-Modus). Reihenfolge: markdown → ui/lib → images → filetree → pickers → nvim-config → cascade →
buffer-ctx/casedesk/gopath.

| Geprüfter Commit | Befund | Fix-Commit |
|---|---|---|
| markdown `03b0867` (Env-Ziele) | `%VAR%` griff bei prozentkodierten Zielen (`%E2%80%93x.md`) und `$foo.md`; Config-Lookup pro Link bei jedem Speichern | markdown `4247bbf` |
| markdown `779c4d1` (Blockquote-Breite) | Padding konnte bei `wrap` breiter als das Fenster werden → leere Folgezeilen | markdown `5c618d3` |
| ui `10082fc` (Toast-Breite) | `ui.notify` reicht ganze Befehlsausgaben durch; Umbruch eines 64-KB-Strings quadratisch, Float höher als der Bildschirm | ui `d3ea28a` (8 KB, `max_lines` = 20, Ellipse) |
| lib `53417e1`, `360a137` (Toast-Spiegel / Popup) | Spiegel nachgezogen; `popup.setup({ width = nil })` konnte eine explizite Breite nicht zurücksetzen | lib `e8a75f3` (`width = false`), Spiegel `e2faeb4` |
| lib `664667c`, `62c559a` (`link_cursor`, `insert_links`) | async Einfügen konnte den Cursor eines Fensters bewegen, das inzwischen einen anderen Buffer zeigt; `previous_window()` falsch für Befehle aus dem Editor | lib `c368b5d` (`place(…, buf)`), `e8a75f3` (`insertion_window()`) |
| images `242f3ed` (`env`-Modus, Cursor) | Case-Folding der Env-Roots auf allen Systemen (Linux: `/Repos` = `/repos`); Einfügepunkt aus einem Fenster gelesen, das inzwischen einen anderen Buffer zeigt (Link scheiterte still, Cursor-Fallback setzte den Cursor im falschen Buffer) | images `c27f16a` (Windows-only Folding, Warnung + Cursor-Guard, Test) |
| filetree `9a0e0dc` (`MI`) | per `:Filetree mdlink insert` im Editor getippt wählte `previous_window()` den zuvor besuchten Split; Ordner mit abschließendem `/` ergaben leeren Titel | filetree `3a932e2`, nutzt `insertion_window()` |
| markdown `4247bbf` (eigener Fix) | **Regression:** beim Neuschreiben ging `\` in `[/\\]` verloren → `$VAR\x`, `%VAR%\x`, `.\$VAR\x` nicht mehr erkannt | markdown `6d7e2c5` + Regressionstests (Long-Bracket-Strings) |
| filetree `3a932e2` (eigener Fix) | gleiche Backslash-Regression in `link_name` | filetree `990f067` + Windows-Test |
| pickers `7fbd2aa`, `6e34dcf` (Einfügen, Feedback) | `:p` gibt Ordnern ein `/` → leerer Titel (`markdown_link` und `link_insert`); `copied [fmt] <langer Pfad>` konnte die Cmdline sprengen → Hit-Enter ohne noice; Zielfenster | pickers `688f03f` (`link_name`, `shorten_for_echo`, `insertion_window`) |
| nvim-config `27a46759` (`:Clipboard`) | Meldung `copied … -> <langer Pfad>` konnte die Cmdline sprengen (Hit-Enter ohne noice); `$NVIM_CONFIG_DIR`-Folding case-insensitiv auf allen Systemen | nvim-config `fd32956e` (Tail-Kürzung, Folding nur Windows) |
| cascade `236ace2` (Listen-Schritte) | **Bug:** `z)` + 1 erzeugte `aa)` (`alpha.to_alpha(27)`), das der Parser nicht als Marker liest → Item verlässt die Liste still | cascade `1ff1069` (Buchstaben enden bei `z`, Test) |
| ohne Befund (gelesen, Randfälle geprüft) | markdown `19fabae` (`wrap_link`), cascade `f5baa6d` (Keymaps), buffer-ctx `006a306`, casedesk `dd58bc1`, gopath `f1cfe5c`, nvim-config `b11c2356` (Specs: nur Kommentare + `default_path_mode = "env"`, mit der echten Config geladen) | – |

Nebenbefund (nicht angefasst): `nvim-data/swap` enthält ~600 Swap-Dateien (u. a. von abgebrochenen Headless-Läufen);
sie lösen in Testläufen `E326: Too many swap files` aus → Tests mit `nvim -n` starten. Aufräumen nur nach Rückfrage.
Falle beim Testen: `nvim --headless -u NONE` hat `stdpath("config")` (= Haupt-Checkout) **im rtp** — Module der
Config dort mit `rtp:prepend(worktree)` laden, sonst wird die alte Version getestet; und Testskripte dürfen nichts in
`stdpath("config")` anlegen (ich habe dort versehentlich ein leeres Verzeichnis erzeugt und wieder entfernt).

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
   („Offen"), `ui.nvim/ROADMAP/ROADMAP.md`. **Noice-Feature-Matrix-Report: erledigt**
   (`docs/ROADMAP/reports/noice-feature-abdeckung-2026-10-01.md`; Kernbefunde: zwei parallele
   Meldungs-Pipelines — `lib.nvim.notify`-Toasts umgehen `vim.notify` und damit noice; Nvim 0.12.2 bringt
   experimentell `vim._core.ui2` mit, kann aber kein Routing/Skip; nur `ext_messages` erreicht native Meldungen;
   „übrige externe Plugins" aus dem Roadmap-Punkt **nicht** geprüft, nur gelistet). Der Roadmap-Punkt in
   `00_ROADMAP.md` Z. ~96 gehört dem Nutzer (Datei lokal modifiziert) — **nicht abgehakt**.
   **TUI-Spike: erledigt** (2026-10-01) — `docs/ROADMAP/reports/ext-messages-tui-spike-2026-10-01.md`
   (10 Punkte belegt/widerlegt, Kind-Katalog, Attach-Policy-Empfehlung „nur attachen, wenn ein Renderer
   existiert" + detachen bei `:Noice disable`); Konzept in WKDBooks um „Spike-Ergebnisse" ergänzt; Harness als
   Rezept `TOOLS/tui-spike-harness.md` + `TOOLS/scripts/tui-spike/`.
   Kernergebnisse: Logger allein = Meldungen **und** Cmdline weg; noice-Koexistenz ok (Logger sieht ungefilterten
   Strom, aber nicht `vim.notify`/lib-Toasts; `:redir`/`:silent`/`execute` unsichtbar); noice + `ui2` = Doppelanzeige;
   Ringpuffer-Kosten vernachlässigbar.
   **Übrige externe Plugins: erledigt** (2026-10-01) — `docs/ROADMAP/reports/externe-plugins-feature-abdeckung-2026-10-01.md`
   (31 Plugins: 11 Engine/Host, 5 teilweise ersetzbar, 5 Zulieferer, 9 ohne Pendant, 1 nicht installiert; Matrix je Cluster
   Git/Picker/Tree/Completion/Editing/UI/Tests, Lückenliste, Abhängigkeitsketten, Reichweite+Wartung per `gh api`).
   Befunde: `plenary` (Upstream kündigt Archivierung an; kein eigenes Plugin braucht es), `telescope-github` + `nvim-notify`
   ohne Nutzung, `search.nvim` ↔ `pickers.tabs` (in der Config nicht aktiviert), 13 direkte Telescope/fzf-lua-Maps trotz
   pickers.nvim, nvim-treesitter-Pin mit veraltetem Kommentar (Neovim ist 0.12.2), **gitsuite-Doku sagt native Hunk-Implementierung,
   Code hat keine für stage/reset** (nicht korrigiert). Nichts entfernt/ersetzt. Nicht ausgeführt, nur gelesen/gezählt.
   **Offen:** nichts aus dem Roadmap-Punkt; Entscheidungen stehen in §9 des Reports. **Kein Bau** (Nutzer: erst Review/Abgleich).
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
- **Backslashes in Lua-Edit-Skripten werden halbiert** (Tool-/Shell-Schicht): `"[/\\]"` kam als `"[/\]"` an und
  stylua machte daraus `"[/]"` — dadurch ging in markdown `4247bbf` die Backslash-Unterstützung verloren
  (behoben in `6d7e2c5`), ebenso in filetree/pickers `link_name`. **Regel:** Code mit Backslashes nur mit dem
  Edit-Tool schreiben, Tests mit Long-Bracket-Strings `[[C:\x]]` oder `string.char(92)`; nach dem Schreiben
  `grep -n '\[/\]'` o. Ä. gegenprüfen. Nie unquotierte Heredocs (`<<EOF`) mit Backticks (`` ` ``) — die Shell
  führt sie aus.
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

## Commit-Liste dieses Chats (✅ = vom Nutzer-`ultracode`-Modus reviewt; Doku-Commits ✅ ohne Review)

| Repo | Commit | Beschreibung | Review |
|---|---|---|---|
| markdown.nvim | `03b0867` | fix(links): no `./` before env-rooted targets, repair | ✅ (Fix `4247bbf`) |
| markdown.nvim | `779c4d1` | feat(hl): blockquote width | ✅ (Fix `5c618d3`) |
| markdown.nvim | `4247bbf` | fix(links): Env-Referenz = ganzes erstes Segment, Config-Lookup nur für Kandidaten | ✅ (Fix `6d7e2c5`) |
| markdown.nvim | `6d7e2c5` | fix(links): Backslash-Separatoren wiederhergestellt (Regression von `4247bbf`) | ✅ |
| markdown.nvim | `5c618d3` | fix(hl): Blockquote-Padding nie breiter als das Fenster | ✅ |
| cascade.nvim | `f5baa6d` | feat(keymaps): rotation → `cl/cL` | ✅ (ohne Befund) |
| ui.nvim | `10082fc` | feat(toast): width min/max/padding/wrap | ✅ (Fix `d3ea28a`) |
| lib.nvim | `53417e1` | feat(toast): mirror + popup wrap width | ✅ |
| lib.nvim | `664667c` | feat(markdown): link_cursor | ✅ (Fix `c368b5d`) |
| gopath.nvim | `f1cfe5c` | feat(api): shorten_path | ✅ (ohne Befund) |
| images.nvim | `242f3ed` | feat(paste): env mode, mode words, cursor | ✅ (Fix `c27f16a`) |
| images.nvim | `c27f16a` | fix(paste): Env-Folding nur Windows; kein Einfügen/Cursor in Fenster mit anderem Buffer | ✅ |
| markdown.nvim | `19fabae` | feat(links): wrap_link cursor + insert mode | ✅ (ohne Befund) |
| lib.nvim | `62c559a` | feat: insert_links, previous_window | ✅ (Fix `c368b5d`, `e8a75f3`) |
| filetree.nvim | `9a0e0dc` | feat(markdown_links): `MI` fügt Links ein, Cursor in den Link | ✅ (Fix `3a932e2`) |
| filetree.nvim | `3a932e2` | fix(markdown_links): MI ins aktuelle Editorfenster; Ordner-Links behalten Titel | ✅ (Fix `990f067`) |
| filetree.nvim | `990f067` | fix(markdown_links): `link_name` entfernt auch abschließende Backslashes | ✅ |
| pickers.nvim | `7fbd2aa` | feat(entry_actions): Links ins Fenster hinter dem Picker einfügen | ✅ (Fix `688f03f`) |
| ui.nvim | `a1574ca` | fix(toast): theme zindex.toast (70), Toast lag unter snacks-Pickern | ✅ |
| lib.nvim | `360a137` | fix(toast): Spiegel zu ui.nvim | ✅ |
| ui.nvim | `d3ea28a` | fix(toast): begrenzte Arbeit (8 KB, max_lines, Ellipse) | ✅ |
| lib.nvim | `e2faeb4` | fix(toast): Spiegel zu `d3ea28a` | ✅ |
| lib.nvim | `c368b5d` | fix(link_cursor): `place()` prüft den Buffer des Fensters | ✅ |
| lib.nvim | `e8a75f3` | feat(window): `insertion_window()`; fix(popup): `width = false` | ✅ |
| pickers.nvim | `6e34dcf` | feat(entry_actions): Aktionen melden, was sie taten, auch in :messages | ✅ (Fix `688f03f`) |
| pickers.nvim | `688f03f` | fix(entry_actions): Ordner-Links mit Titel, Feedback passt in die Cmdline, Einfügen ins aktuelle Fenster | ✅ |
| nvim-config | `27a46759` | feat(usrcmds): `:Clipboard [path] reports|handovers` | ✅ (Fix `fd32956e`) |
| nvim-config | `fd32956e` | fix(usrcmds): `:Clipboard`-Meldung passt in die Cmdline; Folding nur Windows | ✅ |
| nvim-config | `b11c2356` | chore(specs): neue Plugin-Optionen (images env, Toast, Blockquote, Link-Cursor, Picker/filetree) | ✅ (ohne Befund) |
| buffer-ctx.nvim | `006a306` | feat(insert): `:Insert mdlink` setzt den Cursor in den Link | ✅ (ohne Befund) |
| casedesk.nvim | `dd58bc1` | feat(insert): `:Case insert asset` setzt den Cursor in den Link | ✅ (ohne Befund) |
| nvim-config | (Report) | docs: Report Markdown-Link-Einfügestellen | ✅ |
| WKDBooks | `1afb268` | docs(roadmap): Message-Log + Recent-Popup + Live-Chips Konzept (3 Roadmaps) | ✅ |
| cascade.nvim | `236ace2` | feat(lists): `<C-y>`/`<C-x>` auf Marker + Ebenen-Variante | ✅ (Fix `1ff1069`) |
| cascade.nvim | `1ff1069` | fix(lists): Buchstaben-Listen enden bei `z` | ✅ |
| nvim-config | (Spec) | chore(specs): `lists.features.shift` (nur Kommentar) | ✅ |
| nvim-config | (Report) | docs: noice.nvim Feature-Abdeckung | ✅ |
| nvim-config | `264531a0`, `7bf3d7ce` | docs: Plan-Report + Handover | ✅ |
| nvim-config | `4fa89614` | docs: ext_messages TUI-Spike-Report + Handover | ✅ |
| nvim-config | `e01f6fc7` | docs: Report externe Plugins Feature-Abdeckung + Handover | ✅ |
| WKDBooks | `2ab6d71` | docs: Spike-Ergebnisse im Message-Log-Konzept + TUI-Harness-Rezept/Skripte | ✅ |
