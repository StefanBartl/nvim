- [ ] **TUI-Spike: `ext_messages`-Logger neben noice und `ui2` in echter TUI testen** (Vorbedingung für das Message-Popup „letzte n Sekunden"). Kontext: Konzept `WKDBooks/Development/wkdbook-myplugins/lib.nvim/ROADMAP/messages-log-and-recent-popup.md` (Schritt 1), Befunde in `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/noice-feature-abdeckung-2026-10-01.md`. Headless ist belegt, dass zwei `vim.ui_attach(…, { ext_messages = true })`-Listener beide jedes `msg_show` bekommen. Offen ist, was in einer echten TUI passiert. Nur testen, nichts bauen, keine Ersatzentscheidung.
  - Prüfen (Wegwerf-Skript, Ablage nach `TOOL-PLACEMENT.md`):
    1. Logger-only: nur `ext_messages` attachen, kein Renderer. Erwartung laut Nvim-Doku: die TUI zeichnet keine Meldungen mehr. Bestätigen und festhalten, wie sich das äußert (Meldungen weg? Prompts? `:messages`?).
    2. Logger neben noice (deine Config): Zeitstempel, Reihenfolge und `kind` der Events. Werden alle Meldungsarten gesehen (`echo`, `echomsg`, `emsg`, `wmsg`, `lua_error`, `rpc_error`, `:w`-Meldung, `showmode`, Suchzähler, `vim.notify`)? Verschluckt oder verändert der Logger etwas bei noice? Was passiert, wenn noice per `:Noice disable` oder `:Noice enable` umgeschaltet wird?
    3. `ui2` isoliert: `require("vim._core.ui2").enable({})` ohne noice, mit `msg.targets` pro `kind`. Was kommt gut, was fehlt gegenüber deinem Setup? Dazu `g<`, Pager und Cmdline-Highlighting prüfen.
    4. noice und `ui2` gleichzeitig: nur kurz testen, um den erwarteten Konflikt zu belegen.
    5. Kosten: Ringpuffer mit z. B. 1000 und 10000 Einträgen, `hrtime`-Overhead pro Event, Verhalten bei Meldungsfluten (`:echo` in Schleife, LSP-Logging).
    6. Verhalten bei `:redir`, `:silent`, `vim.cmd("silent …")` und `nvim_exec2(output = true)`: sieht der Logger diese Meldungen?
  - Ergebnis: Spike-Report nach `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/`, mit einer klaren Antwort je Punkt (belegt, widerlegt oder offen) und einer Empfehlung zur Attach-Policy („nur attachen, wenn ein Renderer existiert"). Das Konzeptdokument in WKDBooks um die Ergebnisse ergänzen.
  - Danach entscheidet ein Mensch, ob `lib.nvim.messages` gebaut wird (Schritt 3 ff. im Konzept).

- [ ] **Übrige externe Plugins mit den eigenen Plugins abgleichen** (zweiter Teil des Roadmap-Punkts „Konkurrenzanalyse / noice & übrige externe Plugins": was ist durch eigene Plugins abgedeckt, was fehlt?). Nur dokumentieren, keine Ersatzentscheidung. Vorlage ist der Noice-Report `noice-feature-abdeckung-2026-10-01.md` (Feature-Matrix mit ✅ / 🟡 / ❌ / ➖).
  - Liste aus `lua/plugins/*.lua` (ohne `StefanBartl/…`): search.nvim, nui.nvim, neogit, neo-tree-tests-source, vim-matchup, mini.ai, snacks.nvim, tokyonight, which-key, nvim-cmp, fzf-lua, gitsigns, mason, vim-visual-multi, plenary, neo-tree (+ diagnostics-Source), neotest, telescope (+ file-browser, fzf-native, github), nvim-web-devicons, nvim-treesitter (+ textobjects), nvim-notify, blink.cmp, diffview, targets.vim, nvim-autopairs, nvim-ts-autotag. noice ist bereits erledigt.
  - Bereits abgelöst am 2026-09-19 (nicht erneut prüfen): nvim-window-picker → `ui.windowpicker`, nvim-bqf → pickers.nvim `quickfix`, zen-mode → `ui.zen`, minty/volt → `ui.colorpicker`.
  - Pro Plugin ermitteln: (1) wozu es bei dir dient und welche Features du tatsächlich nutzt (Config, Keymaps, `docs/NOTES/ExternPlugins/Bindings/*`); (2) welches eigene Plugin das Feld berührt (z. B. filetree.nvim ↔ neo-tree, pickers.nvim ↔ telescope/fzf-lua/snacks, gitsuite.nvim und diff.nvim ↔ gitsigns/neogit/diffview, lsp.nvim ↔ mason/cmp/blink); (3) Abdeckung je Feature (✅ / 🟡 / ❌ / ➖, mit Fundstelle im Quelltext); (4) ob das eigene Plugin das externe **ersetzt** oder **aufsetzt** (Abhängigkeit, Wrapper, Engine).
  - Mit Einschätzung der Reichweite des externen Plugins arbeiten, die Roadmap-Regel gilt: bei „mittlerer Ähnlichkeit" nur die reichweitenstärksten berücksichtigen.
  - Ergebnis: ein Report nach `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/` mit Gesamtmatrix, einer Lückenliste und einer kurzen Liste „kein eigenes Pendant, auch keins geplant". Abhängigkeiten, die nach der Analyse übrig sind (z. B. `nvim-notify` und `nui.nvim` unter noice), sauber aufführen. Nichts entfernen oder ersetzen, ohne dass du es beschließt.





Machen wir hier weiter:
  1. `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/wkd/wkd_Handover.md`
  2. `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/github_stats_traffic_integration.md`
  3. `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/ai/ai.nvim_loomai.md`
  4. `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/startup-und-config-optimierung-analyse-konzept-2026-09-26.md`

Suche dir die naechsten Tasks und arbeite solange bis keine task mehr über ist oder du dringend von mir etwas benötzisgt, um eine Entscheidung zu treffen bzw Blocker aufzuheben. Wichtig: Nach jeder Task update die Handover/Report file, sodass man nahtrlos in einen anderen chat anschließen könnte.

## Vorgaben/Richtlinien/Guiding

### Allgemeines Verhalten

- Nie mehr als 1 Agent gleichzeitig starten; werden mehrere benötigt, nacheinander in mehreren Runden ausführen.
- Immer auf Deutsch antworten; im Quellcode (Code, Kommentare usw.) immer Englisch verwenden.
- Immer ausgeben, was gerade gemacht wird / ob es etwas Interessantes gab – damit ich Bescheid weiß.
- Wenn Chip-Tasks angelegt werden, diese bitte ebenfalls auf Deutsch verfassen.

### Git-Workflow

- Wenn eine Aufgabe fertig ist: sofort committen / pushen / pullen im main-Branch, sodass ich es gleich verwenden kann. Keine Pull Requests (PR)!
- Keine Co-Autorenschaft von Claude in den Commits.
- Am Ende jeder Ausgabe gibst du eine laufende Liste aller Commits des Chats aus mit kurzer Beschreibung + welches Repository. Jedes bekommt einen grünen Haken, wenn das Commit durch einen `ultracode`-Agenten reviewed wurde und wird in eine "reviewed commits" Liste geschoben, damit sie nicht mehr als zu reviewen auftauchen.

### Code-Qualität

- Implementierter Code muss luacheck / stylua-grün sein.
- Neue Features ggf. im plugin-eigenen `/TESTS/`-Ordner testen.

### Dokumentation

- Docs / README.md aktualisieren, sofern es Sinn ergibt.
- Wird ein Binding aktualisiert, ggf. auch `vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS` aktualisieren.
- Reports sowie Original-Handover-Files kommen nach `$NVIM_CONFIG_DIR/docs`; in den wkdbooks liegen dann nur Symlinks darauf.
- Feature-/Backlog-/Roadmap-Notizen (alles, was Endnutzer nicht betrifft) gehören nach `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`.
- Die Plugin-Repo-Docs (README, Feature-Beschreibungen für Endnutzer usw.) bleiben für die echte Endnutzer-Dokumentation reserviert. Im Zweifelsfall nachfragen – es sind aber bereits genug Dateien vorhanden, um Ableitungen zu treffen.

### Pfade

- Installations-Specs meiner Plugins: `vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua`
- Alle `.nvim`-Plugins (falls nötig): `$REPOS_DIR/repos`

### Regeln

- Tool bauen vs. Wegwerf-Skript, Ablageort: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
  - Wird im Zuge einer Task ein Tool gebaut, das für künftige User/Devs/Agents interessant sein könnte: an geeigneter Stelle im `TOOLS/`-Ordner sichern.
- Keine großen/escapehaltigen Literale durch die Shell schleusen: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md`
- Performance-Optimierungen: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
- Lua-Projekte für Neovim: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`

---
