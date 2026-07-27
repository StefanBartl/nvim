# lib.nvim.ui.kit — Migrations-Audit (native Prompts → kit)

Ziel: native `vim.ui.*`/`vim.fn.confirm`/`vim.fn.input`-Aufrufe sowie
Eigenbau-Floats in allen `C:\repos\*.nvim`-Plugins (nicht lib.nvim selbst) und
der nvim-Config durch `lib.nvim.ui.kit` ersetzen. Ja/Nein bzw. ≤4-Optionen
Prompts → `kit.confirm` (Buttons). Mehr/dynamische Optionen → `kit.select`.
Freitext → `kit.input`.

Hinweis zur Zählweise: Datei:Zeile bezieht sich auf den Stand beim Audit
(2026-07-25, Nachträge 2026-07-26/27) — kann sich bei künftigen Edits
verschieben. Audit deckt jedes `E:\repos\*.nvim`-Repo plus die nvim-Config ab.

Alles bereits abgeschlossene ist aus diesem Dokument entfernt — nur noch
offene Punkte unten. Fertiggestellte Migrationen inkl. Commit-Hashes stehen
in der Git-Historie dieser Datei.

## 1. Ja/Nein & ≤4-Optionen-Prompts → `kit.confirm` (Buttons)

### nvim-Config
- `lua/config/lazygit/actions/replace.lua:9` (Kommentar) — **kein
  Migrationskandidat, bewusst so gebaut**: Codekommentar begründet explizit,
  warum hier kein `vim.fn.confirm` (und damit auch kein `kit.confirm`) genutzt
  wird — ein LazyGit-Terminal-Float besitzt den Screen, ein blockierender
  Prompt wäre unsichtbar und sein Input würde von LazyGit verschluckt.
  Stattdessen No-Op-Fallback (`:badd` statt Save-Prompt). Gleiche Kategorie wie
  der Terminal-Float-Sonderfall, der zuvor bei `replacer.nvim`/`diff.nvim`
  dokumentiert war (inzwischen migriert, siehe Git-Historie) — nicht anfassen
  ohne das Terminal-Float-Problem zu lösen.

## 2. Auswahllisten (>4 Optionen / dynamisch) → `kit.select` ✅ vollständig erledigt

Alle "respektiert User-Backend"-Fälle (open.nvim, gopath/alternate,
emojis.nvim, diff.nvim/run_buffers, cascade.nvim/word_cycle) sind migriert,
via `kit.select`s neuer `respect_override`-Option (siehe lib.nvim Commit
`2e02157`): löst zur Laufzeit über `debug.getinfo(vim.ui.select, "S").source`
auf, ob `vim.ui.select` noch Neovims eingebaute Implementierung ist
(`runtime/lua/vim/ui.lua`) oder von einem Plugin überschrieben wurde — im
zweiten Fall wird an `vim.ui.select` delegiert (respektiert also weiterhin
telescope-ui-select/fzf-lua/dressing.nvim), im ersten Fall nutzt es kits
eigenen themed Chooser statt der schlichten Neovim-Builtin-Liste. Kein
Backend-Respekt-Verhalten wurde aufgegeben. `pickers.nvim/lua/pickers/
sources/system.lua` (der einzige verbliebene Kandidat hier) war schon auf
`kit.input` migriert (Freitext, kein Select) — nur der Modul-Docstring
zitierte noch `vim.ui.input`.

## 3. Freitext-Eingaben → `kit.input` ✅ vollständig erledigt

Alle vier Stellen, die bewusst auf `vim.ui.input`/`vim.fn.input` geblieben
waren, brauchten dasselbe fehlende Feature (`completion = "file"`) — siehe
Abschnitt 5 (`completion = "file"`-Tab-Completion) für den lib.nvim-Fix und
die Liste aller vier migrierten Call-Sites.

## 4. Eigenbau-Floats (Menü/Picker) → `kit.menu`/`kit.select`/`kit.layout`

Alles migriert. `recommender.nvim`s Custom-Highlight-Picker (Chain/Alias
farblich abgesetzt, 3 Zeilen pro Eintrag) wurde zum Auslöser für
`kit.select`s neues Feature "rich items" (Phase 9 in lib.nvim, siehe
UI-KIT-CONCEPT.md §13b): Items können jetzt mehrzeilige Tabellen mit
Highlight-Spans pro Spalte sein statt nur einzeiliger Strings. Navigation
läuft über logische Item-Indizes statt roher Buffer-Zeilen, sodass ein
Klick irgendwo in einem mehrzeiligen Item korrekt auflöst. `rendering.lua`
verlor dadurch fast die Hälfte seines Codes (kein eigenes
`nvim_open_win`/`vim.hl.range`/Stride-Tracking mehr); `keymaps.lua` behält
nur noch die Aktionen, die kit.select nicht kennt (y/A/Backspace/U — lesen
das aktuelle Item über das neu öffentliche `kit.chooser.current_item()`,
ohne zu schließen).

## 5. Fehlende UI-Bausteine in lib.nvim.ui.kit

Alle drei ursprünglich fehlenden Bausteine sind inzwischen gebaut
(`kit.viewer`, `kit.form`, `kit.live_input`) und an jedem Call-Site im Audit
migriert — inklusive `buffer_ctx.nvim`s Guard-Clause-Template: `boiler.get()`
akzeptiert jetzt einen optionalen `callback`-Parameter, den auch die
synchronen Templates (alle außer Guard-Clause) unverändert aufrufen, sodass
Call-Sites einheitlich die Callback-Form nutzen können, ohne pro Eintrag zu
verzweigen. Nur Guard-Clause ist als `is_async` markiert und läuft über
`kit.form` statt Zeilen direkt zurückzugeben.

Sekret-/Passwort-Eingabe ✅ erledigt (2026-07-27) — `kit.input({secret=true})`
(Phase 10, Commit `fa4c2f6` in lib.nvim, gepusht auf `main`; siehe
UI-KIT-CONCEPT.md §13c) maskiert die Eingabe zeichenweise über `conceal`
(`opts.mask` überschreibt das Standard-`"*"`), neu berechnet aus dem echten
Buffer-Inhalt bei jedem Edit (Paste, Backspace, Edits in der Mitte — alles
funktioniert ohne Keystroke-Diffing). `on_submit` bekommt weiterhin den
echten Klartext; Undo ist auf diesem Buffer deaktiviert (`undolevels = -1`),
Swapfile war auf jedem kit-Scratch-Buffer ohnehin schon aus. Der einzige
`vim.fn.inputsecret`-Call-Site im Audit —
`sandbox.nvim/lua/sandbox/bindings/usrcmds/registry_commands.lua:30`
(Registry-Passwort) — ist ebenfalls migriert: Passwort-Prompt wandert dafür
in den `on_submit` des Username-Feldes (kit.input ist Callback-basiert,
inputsecret war blockierend-synchron), `on_cancel` liefert jetzt eine
explizite "cancelled"-Meldung bei `<Esc>`, die der alte inputsecret-Pfad nur
über einen leeren String erraten konnte. Neuer
`tests/sandbox/bindings/usrcmds/registry_commands_spec.lua`. Commit
`5e9a7f2` in sandbox.nvim, gepusht auf `main`.

`completion = "file"`-Tab-Completion ✅ erledigt (2026-07-27) —
`kit.input({completion="file"})` (Phase 11, Commit `6e6d985` in lib.nvim,
gepusht auf `main`; siehe UI-KIT-CONCEPT.md §13d) verkabelt `<Tab>` mit
echter Ins-Completion: `vim.fn.getcompletion()` löst das Fragment vor dem
Cursor auf, `vim.fn.complete()` öffnet Neovims natives Popup — kein
Eigenbau-Picker, `<C-n>`/`<C-p>` funktionieren wie überall sonst auch.
`<Tab>`/`<S-Tab>` cyclen das offene Popup statt es neu zu triggern, `<CR>`
übernimmt zuerst den markierten Kandidaten (zweites `<CR>` submittet).
Akzeptiert jeden `getcompletion()`-Typ, nicht nur `"file"`. Dabei einen
echten Bug gefangen und gefixt: die erste Fassung machte `<CR>`s Handler zu
einer `<expr>`-Mapping, was das Schließen des Floats beim Submit für **jeden**
`kit.input`-Aufruf lautlos brach (Neovim blockt Fenster-/Buffer-Änderungen
während einer `<expr>`-Auswertung — Textlock). Alle vier Call-Sites im Audit,
die exakt dieses fehlende Feature zitiert hatten, sind jetzt migriert:
- `diff.nvim/lua/diff/core/init.lua:197` (`prompt_file`) — Commit `20d450b`.
- `dap.nvim/lua/wkddap/languages/{zig,rust,c,assembly}.lua` (5 Call-Sites,
  Coroutine-yield/resume-Idiom) — Commit `6a91aeb`.
- `color_my_ascii.nvim/lua/color_my_ascii/commands/fence/export.lua:178` —
  Commit `e7e5c6c`.
- nvim-Config `lsp/debug_adapters/dotnet.lua:24` — Commit `177e898b`.

Damit ist Abschnitt 5 vollständig abgeschlossen — alle drei ursprünglich
fehlenden kit-Bausteine (`viewer`, `form`, `live_input`) plus beide
nachträglich ergänzten `kit.input`-Erweiterungen (`secret`, `completion`)
sind gebaut und an jedem bekannten Call-Site im Audit migriert.

