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

- `pickers.nvim/lua/pickers/sources/system.lua` — kein Select, aber siehe
  Abschnitt 3 (Freitext).
- `open.nvim/lua/open/picker.lua:20` — `vim.ui.select` über Handler-Kandidaten.
  **Vorsicht**: Kommentar sagt explizit, das ist bewusst so gebaut, damit
  `vim.ui.select`-Overrides (telescope-ui-select, fzf-lua, dressing.nvim) vom
  User respektiert werden. Migration würde dieses Verhalten ändern/entfernen —
  eher niedrige Priorität bzw. Rücksprache nötig.
- `gopath.nvim/lua/gopath/alternate/ui.lua:38` — `vim.ui.select` über
  ähnliche Dateien beim "File not found"-Fallback. Kommentar sagt ebenfalls
  bewusst: respektiert User-Backend (telescope/dressing). Gleiche Vorsicht wie
  bei open.nvim.
- `emojis.nvim/lua/emojis/picker.lua:97` (`select_fallback`) — reiner
  Fallback wenn weder Telescope noch fzf-lua verfügbar sind; ähnlich wie
  open.nvim bewusst multi-backend. Niedrige Priorität.
- `recommender.nvim/lua/recommender/float/rendering.lua` — Eigenbau-Picker mit
  Syntax-Highlighting pro Eintrag (chain/alias farblich abgesetzt). Funktional
  ein `kit.select`, aber mit Rendering, das kit vermutlich nicht abdeckt —
  niedrige Priorität, eher Kandidat für ein kit-Feature "custom highlight per
  item" als für eine 1:1-Migration.
- `diff.nvim/lua/diff/core/init.lua:433` (`run_buffers`) — `vim.ui.select`
  via `resolve_select_fn()`. **Vorsicht (neu entdeckt beim Abarbeiten
  dieser Liste)**: `resolve_select_fn()` löst bewusst zuerst gegen
  pickers.nvim (falls installiert und nicht abgewählt) auf, sonst
  `vim.ui.select` — dieselbe "respektiert User-Backend"-Kategorie wie
  open.nvim/gopath-alternate. Nicht migrieren ohne das Backend-Respekt-
  Verhalten aufzugeben.
- `cascade.nvim/lua/cascade/cycle/word_cycle.lua:142` (`M.pick`) —
  **Vorsicht (neu entdeckt)**: Kommentar sagt explizit "Telescope-backed if
  the user has `telescope-ui-select.nvim` registered, else Neovim's builtin
  list" — gleiche Kategorie wie open.nvim, nicht migrieren.

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

- `recommender.nvim/lua/recommender/float/rendering.lua` — siehe Abschnitt 2,
  niedrige Priorität wegen Custom-Highlighting.

## 5. Fehlende UI-Bausteine in lib.nvim.ui.kit

Alle drei ursprünglich fehlenden Bausteine sind inzwischen gebaut
(`kit.viewer`, `kit.form`, `kit.live_input`) und an jedem Call-Site im Audit
migriert — inklusive `buffer_ctx.nvim`s Guard-Clause-Template: `boiler.get()`
akzeptiert jetzt einen optionalen `callback`-Parameter, den auch die
synchronen Templates (alle außer Guard-Clause) unverändert aufrufen, sodass
Call-Sites einheitlich die Callback-Form nutzen können, ohne pro Eintrag zu
verzweigen. Nur Guard-Clause ist als `is_async` markiert und läuft über
`kit.form` statt Zeilen direkt zurückzugeben.

Kein neuer Baustein nötig, aber erwähnenswert: Sekret-/Passwort-Eingabe
(`sandbox.nvim/registry_commands.lua:30`, `vim.fn.inputsecret`) hat aktuell
keine kit-Entsprechung — falls `kit.input` maskierte Eingabe unterstützen
soll, wäre das der einzige Call-Site dafür im Audit.

## 6. Priorisierung / Reihenfolge-Vorschlag (verbleibend)

1. **Abschnitt 2's "Vorsicht"-Fälle** (open.nvim, gopath/alternate,
   emojis.nvim, diff.nvim/run_buffers, cascade.nvim/word_cycle) — alle
   respektieren bewusst das vom User konfigurierte Picker-Backend; nur nach
   expliziter Rücksprache migrieren, ob dieses Verhalten aufgegeben werden
   soll.
2. **`recommender.nvim`s Custom-Highlight-Picker** (Abschnitte 2+4) — eher
   ein Kandidat für ein neues kit-Feature ("custom highlight per item") als
   für eine 1:1-Migration.
