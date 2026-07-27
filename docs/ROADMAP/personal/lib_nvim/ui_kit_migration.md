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

## 2. Auswahllisten (>4 Optionen / dynamisch) → `kit.select`

Alle "respektiert User-Backend"-Fälle (open.nvim, gopath/alternate,
emojis.nvim, diff.nvim/run_buffers, cascade.nvim/word_cycle) sind migriert,
via `kit.select`s neuer `respect_override`-Option (siehe lib.nvim Commit
`2e02157`): löst zur Laufzeit über `debug.getinfo(vim.ui.select, "S").source`
auf, ob `vim.ui.select` noch Neovims eingebaute Implementierung ist
(`runtime/lua/vim/ui.lua`) oder von einem Plugin überschrieben wurde — im
zweiten Fall wird an `vim.ui.select` delegiert (respektiert also weiterhin
telescope-ui-select/fzf-lua/dressing.nvim), im ersten Fall nutzt es kits
eigenen themed Chooser statt der schlichten Neovim-Builtin-Liste. Kein
Backend-Respekt-Verhalten wurde aufgegeben.

- `pickers.nvim/lua/pickers/sources/system.lua` — kein Select, aber siehe
  Abschnitt 3 (Freitext).

## 3. Freitext-Eingaben → `kit.input`

Fast vollständig migriert — verbleibend nur die folgenden bewusst nicht
migrierten Sonderfälle (dokumentiert im jeweiligen Code):

- `diff.nvim/lua/diff/core/init.lua:197` (`prompt_file`) — braucht
`completion = "file"` (Cmdline-Tab-Completion), für die `kit.input` (reiner
Insert-Mode-Buffer) noch kein Äquivalent hat.
- `dap.nvim/lua/wkddap/languages/{zig,rust,c,assembly}.lua`s "Path to
executable"-Prompts — gleiche `completion="file"`-Einschränkung wie bei
diff.nvim, plus nvim-dap-Coroutine-Kontext (`coroutine.wrap()`).
- `color_my_ascii.nvim/lua/color_my_ascii/commands/fence/export.lua:178`
(No-Path-Prompt in `M.run`) — gleicher Grund (`completion = 'file'`).
- nvim-Config `lsp/debug_adapters/dotnet.lua:24` (DLL-Pfad) — gleicher Grund
wie dap.nvim/diff.nvim (`completion="file"` + nvim-dap-Coroutine-Kontext).

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
echten Klartext; Undo ist auf diesem Buffer deaktiviert
(`undolevels = -1`), Swapfile war auf jedem kit-Scratch-Buffer ohnehin schon
aus. Migrationskandidat noch offen:
`sandbox.nvim/lua/sandbox/bindings/usrcmds/registry_commands.lua:30` —
einziger `vim.fn.inputsecret`-Call-Site im Audit, noch nicht auf
`kit.input({secret=true})` umgestellt.
